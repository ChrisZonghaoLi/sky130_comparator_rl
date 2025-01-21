import numpy as np
import pprint
import laygo2
import laygo2.interface
import laygo2_tech as tech
import yaml
import os

# import other subcircuits 
from diff_pair import diff_pair
from inverter import inverter
from switches import switches

# Parameter definitions #############
# Variables
cell_type = ['comparator']
# Templates
tpmos_name = 'pmos_sky'
tnmos_name = 'nmos_sky'
tpwell_name = 'pwell_sky'
tnwell_name = 'nwell_sky'
tptap_name = 'ptap_sky'
tntap_name = 'ntap_sky'
# Grids
# signal routing grid
pg_name = 'placement_basic'
r12_name = 'routing_12_basic'
r23_name = 'routing_23_basic'
r34_name = 'routing_34_basic'
# power routing grid
r12_pwr_name = 'routing_12_pwr'
r23_pwr_name = 'routing_23_pwr'
r3_pwr_name = 'routing_3_pwr'
r34_pwr_name = 'routing_34_pwr'
r45_pwr_name = 'routing_45_pwr'
r5_pwr_name = 'routing_5_pwr'
# Design hierarchy
libname = 'strong_arm'
# cellname in for loop
ref_dir_template = '' #export this layout's information into the yaml in this dir 
ref_dir_MAG_exported = './TCL/'
ref_dir_layout = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout'
# End of parameter definitions ######

# Generation start ##################
# 1. Load templates and grids.
print("Load templates")
templates = tech.load_templates_comparator()
tnmos = templates[tnmos_name]
tpmos = templates[tpmos_name]
tpwell = templates[tpwell_name]
tnwell = templates[tnwell_name]
tptap = templates[tptap_name]
tntap = templates[tntap_name]
# print(templates[tnmos_name])
# print(templates[tpmos_name])
# print(templates[tpwell_name])
# print(templates[tnwell_name])
# print(templates[tptap_name])
# print(templates[tntap_name])

print("Load grids")
grids = tech.load_grids_comparator(templates=templates)
# signal routing grid
pg, r12, r23, r34 = grids[pg_name], grids[r12_name], grids[r23_name], grids[r34_name]
# power line routing
r34_pwr = grids[r34_pwr_name]
r12_pwr = grids[r12_pwr_name]
r23_pwr = grids[r23_pwr_name]
r3_pwr = grids[r3_pwr_name]
r45_pwr = grids[r45_pwr_name]
r5_pwr = grids[r5_pwr_name]

lib = laygo2.object.database.Library(name=libname)

def strong_arm(nf, mosfet, cellname = 'comparator'):
    
      print('--------------------')
      print('Now Creating '+cellname)
      
      nf_M1, nf_M3, nf_M5, nf_M7, nf_M8, nf_M10 = nf 
      M1,M3, M5, M7, M8, M10 = mosfet
      
      global diff_pair, inverter, switches
      print("Create subckt layout of diff_pair.")
      diff_pair(nf_M1=nf_M1, nf_M7=nf_M7,
                      M1=M1, M7=M7)
      print("Create subckt inverter of latch.")
      inverter(nf_M3=nf_M3, nf_M5=nf_M5, 
                    M3=M3, M5=M5)
      print("Create subckt inverter of latch.")
      switches(nf_M8=nf_M8, nf_M10=nf_M10, 
                    M8=M8, M10=M10)
      
      # 2. Create a design hierarchy
      dsn = laygo2.object.database.Design(name=cellname, libname=libname)
      lib.append(dsn)
      
      # 3. Create instances.
      # load updated template
      tlib = laygo2.interface.yaml.import_template(filename=ref_dir_template+'strong_arm_templates.yaml')
      print("Create instances")
      diff_pair = tlib['diff_pair'].generate(name='diff_pair')
      inv0 = tlib['inverter'].generate(name='inv0')
      inv1 = tlib['inverter'].generate(name='inv1', transform='MY')
      sw0 = tlib['switches'].generate(name='sw0')
      sw1 = tlib['switches'].generate(name='sw1', transform='MY')

      # Pwell and Nwell
      pwell_0 = tpwell.generate(name='Pwell_0', params={'nf': pg.mn.width(diff_pair)}) # pwell fill
      pwell_1 = tpwell.generate(name='Pwell_1', params={'nf': pg.mn.width(inv0)}) # pwell fill
      pwell_2 = tpwell.generate(name='Pwell_2', params={'nf': 2}) # pwell fill for ntaps
      pwell_3 = tpwell.generate(name='Pwell_3', transform='MY', params={'nf': 2}) # pwell fill for ntaps
      nwell_0 = tnwell.generate(name='Nwell_0', params={'nf': 2*pg.mn.width(inv0)}) # nwell fill

      # Ptaps and Ntaps
      ntap_0 = tntap.generate(name='Ntap_0', params={'nf': 2, 'tie': 'TAP0'})
      ntap_1 = tntap.generate(name='Ntap_1', params={'nf': 2, 'tie': 'TAP0'})
      ptap_0 = tptap.generate(name='Ptap_0', transform='MX', params={'nf': 2, 'tie': 'TAP0'})

      # 4. Place instances.
      # diff_pair.bbox
      # in LAYGO2, it seems that if the instance bbox has negative value, the bbox will be shifted so
      # that its origin left-bottom point is always [0,0], unless its 'mn' value has been redefined.
      # However, this shift of the bbox does not shift the actual layout of the instance. Therefore, some
      # offset should be taken care of. This offset is usually those negative values of the bbox.
      # load technology parameters again
      tech_fname = './laygo2_tech/comparator_tech.yaml'
      with open(tech_fname, 'r') as stream:
          try:
              tech_params = yaml.safe_load(stream)
          except yaml.YAMLError as exc:
              print(exc)
      placement_resolution_v = tech_params['grids']['skywater130_microtemplates_dense']['placement_basic']['horizontal']['scope'][1] # vertical (I know even it says horizontal...) placement grid resolution
      placement_resolution_h = tech_params['grids']['skywater130_microtemplates_dense']['placement_basic']['vertical']['scope'][1] # horizontal placement grid resolution 
      
      with open(ref_dir_template+'strong_arm_templates.yaml', 'r') as stream:
          try:
              strong_arm_templates = yaml.safe_load(stream)
          except yaml.YAMLError as exc:
              print(exc)
              
      # remove diff_pair layout offset
      diff_pair_bbox = strong_arm_templates['strong_arm']['diff_pair']['bbox'] # the actual physical layout bbox of the diff_pair before LAYGO shifts it
      diff_pair_bottom_left = np.array(diff_pair_bbox[0])
      diff_pair_offset_h = int(diff_pair_bottom_left[0] / placement_resolution_h)
      # place diff_pair
      mn_diff_pair = np.array([-diff_pair_offset_h,0])
      dsn.place(grid=pg, inst=diff_pair, mn=mn_diff_pair)
      # pwell fill in the diff_pair
      mn_pwell0 = pg.mn.left(diff_pair) - mn_diff_pair - np.array([1,0])
      dsn.place(grid=pg, inst=pwell_0, mn=mn_pwell0) 

      # remove inverter layout offset
      inverter_bbox = strong_arm_templates['strong_arm']['inverter']['bbox'] # the actual physical layout bbox of the inverter before LAYGO shifts it
      inverter_bottom_left = np.array(inverter_bbox[0])
      inverter_offset_h = int(inverter_bottom_left[0] / placement_resolution_h)
      mn_inverter = np.array([-inverter_offset_h,0])
      # place inverter 1
      mn_inv0 = mn_inverter + pg.mn.height_vec(diff_pair) + np.array(0.5*pg.mn.width_vec(diff_pair)).astype(np.int64) - \
                             pg.mn.width_vec(inv0)  - np.array([1,0]) # 1 is the distance between left and right inverter, this is dependent to the diff-pair layout
      dsn.place(grid=pg, inst=inv0, mn=mn_inv0)
      # place inverter 2, form a latch together with inverter 1
      mn_inv1 = -mn_inverter + np.array(pg.mn.width_vec(inv1)).astype(np.int64) + pg.mn.height_vec(diff_pair) + \
                              np.array(0.5*pg.mn.width_vec(diff_pair)).astype(np.int64) + np.array([1,0])  
      dsn.place(grid=pg, inst=inv1, mn=mn_inv1)
      # pwell fill in the NMOS in the inverter
      mn_pwell1 = pg.mn.bottom(inv0) - mn_inverter
      dsn.place(grid=pg, inst=pwell_1, mn=mn_pwell1) 
      # nwell fill in the PMOS in the inverter
      mn_nwell0 = mn_inv0 + np.array(pg.mn.height_vec(inv0)/2).astype(np.int64)
      dsn.place(grid=pg, inst=nwell_0, mn=mn_nwell0) 
      # place ptaps for PMOS
      dsn.place(grid=pg, inst=ptap_0, mn=mn_inv0 + pg.mn.height_vec(inv0) + pg.mn.width_vec(inv0) - np.array(pg.mn.width_vec(ptap_0)/2).astype(np.int64) + np.array([1,0])) 
      
      # remove switch layout offset
      sw_bbox = strong_arm_templates['strong_arm']['switches']['bbox'] # the actual physical layout bbox of the inverter before LAYGO shifts it
      sw_bottom_left = np.array(sw_bbox[0])
      sw_offset_h = int(sw_bottom_left[0] / placement_resolution_h)
      sw_offset_v = int(sw_bottom_left[1] / placement_resolution_v)
      mn_sw = np.array([-sw_offset_h,-sw_offset_v])
      # place PMOS switches on the left
      mn_sw0 = mn_sw + pg.mn.height_vec(diff_pair) + pg.mn.height_vec(inv0) - pg.mn.height_vec(sw0) + np.array(0.5*pg.mn.width_vec(diff_pair)).astype(np.int64) - \
          pg.mn.width_vec(inv0) - np.array([1,0]) - pg.mn.width_vec(sw0)
      dsn.place(grid=pg, inst=sw0, mn=mn_sw0)
      # place PMOS switches on the left
      mn_sw1 = mn_sw * np.array([-1,1]) + pg.mn.height_vec(diff_pair) + pg.mn.height_vec(inv0) - pg.mn.height_vec(sw0) + np.array(0.5*pg.mn.width_vec(diff_pair)).astype(np.int64) + \
          pg.mn.width_vec(inv0) + np.array([1,0]) + pg.mn.width_vec(sw0) # similar strategy as the inverter layout
      dsn.place(grid=pg, inst=sw1, mn=mn_sw1)
      
      # placing Ntaps for NMOS
      mn_ntap_0 = mn_diff_pair-pg.mn.width_vec(ntap_0)-np.array([2,0])
      mn_nyap_1 = -mn_diff_pair+pg.mn.width_vec(diff_pair)+np.array([2,0])
      dsn.place(grid=pg, inst=ntap_0, mn=mn_ntap_0)
      dsn.place(grid=pg, inst=ntap_1, mn=mn_nyap_1)
      # fill up the Ntaps will pwell
      mn_pwell_2 = pg.mn.bottom_right(ntap_0)
      mn_pwell_3 = pg.mn.bottom_left(ntap_1)
      dsn.place(grid=pg, inst=pwell_2, mn=mn_pwell_2)
      dsn.place(grid=pg, inst=pwell_3, mn=mn_pwell_3)

      # 5. Create and place wires.
      print("Create wires")
      # Switch connection: M8
      mn_M8 = [r23.mn(sw0.pins['O'])[0], r23.mn(inv0.pins['O'])[1]]
      # track_M8 = [None, r23.mn(sw0.pins['O'])[0][1]]
      r_M8 = dsn.route(grid=r23, mn=mn_M8)
      
      # Switch connection: M10
      mn_M10 = [r23.mn(sw0.pins['Di'])[1], r23.mn(diff_pair.pins['Di_n'])[1]]
      track_M10 = [None, r23.mn(diff_pair.pins['Di_n'])[1][1]]
      r_M10 = dsn.route_via_track(grid=r23, mn=mn_M10, track=track_M10)
      via_M10 = dsn.via(grid=r23, mn=mn_M10[0])

      # Switch connection: M9
      mn_M9 = [r23.mn(sw1.pins['O'])[0], r23.mn(inv1.pins['O'])[1]]
      # track_M9 = [None, r23.mn(sw1.pins['O'])[0][1]]
      r_M9 = dsn.route(grid=r23, mn=mn_M9)
      
      # Switch connection: M11
      mn_M11 = [r23.mn(sw1.pins['Di'])[0], r23.mn(diff_pair.pins['Di_p'])[1]]
      track_M11 = [None, r23.mn(diff_pair.pins['Di_p'])[1][1]]
      r_M11 = dsn.route_via_track(grid=r23, mn=mn_M11, track=track_M11)
      via_M10 = dsn.via(grid=r23, mn=mn_M11[0])

      # Voutn connection 
      Voutn_offset_v = -3
      mn_Voutn = [[r23.mn(inv0.pins['O'])[0][0], r23.mn(sw0.pins['O'])[0][1]+Voutn_offset_v], 
                              [r23.mn(inv1.pins['I'])[0][0], r23.mn(sw0.pins['O'])[0][1]+Voutn_offset_v]]
      r_Voutn = dsn.route(grid=r23, mn=mn_Voutn, via_tag=[True, True])

      # Voutp connection 
      Voutp_offset_v = 5
      mn_Voutp = [[r23.mn(inv0.pins['I'])[0][0], r23.mn(sw0.pins['O'])[0][1]-Voutp_offset_v], 
                              [r23.mn(inv1.pins['O'])[0][0], r23.mn(sw0.pins['O'])[0][1]-Voutp_offset_v]]
      r_Voutp = dsn.route(grid=r23, mn=mn_Voutp, via_tag=[True, True])

      # clock signal route
      mn_CLK_left = [r23.mn(sw0.pins['CLK'])[0], r23.mn(diff_pair.pins['CLK'])[0]]
      track_CLK_left = [r23.mn(sw0.pins['CLK'])[0][0], None]
      r_CLK_left = dsn.route_via_track(grid=r23, mn=mn_CLK_left, track=track_CLK_left)

      # clock signal route
      mn_CLK_right = [r23.mn(sw1.pins['CLK'])[1], r23.mn(diff_pair.pins['CLK'])[1]]
      track_CLK_right = [r23.mn(sw1.pins['CLK'])[1][0], None]
      r_CLK_right = dsn.route_via_track(grid=r23, mn=mn_CLK_right, track=track_CLK_right)

      # Power routing for VDD and VSS
      def via_array(mn_pin, spacing=1):
          '''
          This funtion will generate an array automatically with a given spacing depending on the grid

          Returns
          -------
          List of via coordinates.

          '''
          mn_array = [mn_pin[0]]
          # generate array horizontally
          if mn_pin[0][0] != mn_pin[1][0]:
              y = mn_pin[0][1]
              x = mn_pin[0][0]
              for i in range(int(mn_pin[1][0] - mn_pin[0][0])):
                  if x + spacing <= mn_pin[1][0]:
                      x = x + spacing 
                      mn_array.append([x,y])
          
          return mn_array
      
      # VDD
      # m2
      mn_VDD = [r12.mn(sw0.pins['VDD'])[0], r12.mn(sw1.pins['VDD'])[1]]
      r_VDD = dsn.route(grid=r12, mn=mn_VDD)
      # via3
      mn_VDD = via_array([r23_pwr.mn(sw0.pins['VDD'])[0], r23_pwr.mn(sw1.pins['VDD'])[1]]) 
      r_VDD = dsn.via(grid=r23_pwr, mn=mn_VDD)
      # m3
      mn_VDD = [r3_pwr.mn(sw0.pins['VDD'])[0], r3_pwr.mn(sw1.pins['VDD'])[1]]
      r_VDD = dsn.route(grid=r3_pwr, mn=mn_VDD)
      # via4
      mn_VDD = via_array([r34_pwr.mn(sw0.pins['VDD'])[0], r34_pwr.mn(sw1.pins['VDD'])[1]]) 
      r_VDD = dsn.via(grid=r34_pwr, mn=mn_VDD)
      # m4
      mn_VDD = [r34_pwr.mn(sw0.pins['VDD'])[0], r34_pwr.mn(sw1.pins['VDD'])[1]]
      r_VDD = dsn.route(grid=r34_pwr, mn=mn_VDD)
      # via5
      mn_VDD = via_array([r45_pwr.mn(sw0.pins['VDD'])[0], r45_pwr.mn(sw1.pins['VDD'])[1]], spacing=5) 
      r_VDD = dsn.via(grid=r45_pwr, mn=mn_VDD)
      # m5
      mn_VDD = [r5_pwr.mn(sw0.pins['VDD'])[0], r5_pwr.mn(sw1.pins['VDD'])[1]]
      r_VDD = dsn.route(grid=r5_pwr, mn=mn_VDD)
      
      # connect all ntaps and VSS
      # m2
      mn_VSS = [r12.mn(ntap_0.pins['RAIL'])[0], r12.mn(ntap_1.pins['RAIL'])[1]]
      r_VSS = dsn.route(grid=r12, mn=mn_VSS)
      # via3
      mn_VSS = via_array([r23_pwr.mn(ntap_0.pins['RAIL'])[0], r23_pwr.mn(ntap_1.pins['RAIL'])[1]]) 
      r_VSS = dsn.via(grid=r23_pwr, mn=mn_VSS)
      # m3
      mn_VSS = [r3_pwr.mn(ntap_0.pins['RAIL'])[0], r3_pwr.mn(ntap_1.pins['RAIL'])[1]]
      r_VSS = dsn.route(grid=r3_pwr, mn=mn_VSS)
      # via4
      mn_VSS = via_array([r34_pwr.mn(ntap_0.pins['RAIL'])[0], r34_pwr.mn(ntap_1.pins['RAIL'])[1]]) 
      r_VSS = dsn.via(grid=r34_pwr, mn=mn_VSS)
      # m4
      mn_VSS = [r34_pwr.mn(ntap_0.pins['RAIL'])[0], r34_pwr.mn(ntap_1.pins['RAIL'])[1]]
      r_VSS = dsn.route(grid=r34_pwr, mn=mn_VSS)
      # via5
      mn_VSS = via_array([r45_pwr.mn(ntap_0.pins['RAIL'])[0], r45_pwr.mn(ntap_1.pins['RAIL'])[1]], spacing=5) 
      r_VSS = dsn.via(grid=r45_pwr, mn=mn_VSS)
      # m5
      mn_VSS = [r5_pwr.mn(ntap_0.pins['RAIL'])[0], r5_pwr.mn(ntap_1.pins['RAIL'])[1]]
      r_VSS = dsn.route(grid=r5_pwr, mn=mn_VSS)
      
      # 6. Create pins. In LAYGO, pin names are unique
      pin_VDD = dsn.pin(name='VDD', grid=r5_pwr, mn=mn_VDD)
      pin_VSS = dsn.pin(name='VSS', grid=r5_pwr, mn=mn_VSS)
      pin_CLK = dsn.pin(name='CLK', grid=r12, mn=r12.mn.bbox(diff_pair.pins['CLK']))
      pin_Di_p = dsn.pin(name='Di_p', grid=r23, mn=r23.mn.bbox(diff_pair.pins['Di_p']))
      pin_Di_n = dsn.pin(name='Di_n', grid=r23, mn=r23.mn.bbox(diff_pair.pins['Di_n']))
      pin_Vin_p = dsn.pin(name='Vin_p', grid=r12, mn=r12.mn.bbox(diff_pair.pins['Vin_p']))
      pin_Vin_n = dsn.pin(name='Vin_n', grid=r12, mn=r12.mn.bbox(diff_pair.pins['Vin_n']))
      pin_Vout_p = dsn.pin(name='Vout_p', grid=r23, mn=r23.mn.bbox(inv1.pins['O']))
      pin_Vout_n = dsn.pin(name='Vout_n', grid=r23, mn=r23.mn.bbox(inv0.pins['O']))

      # pvdd0 = dsn.pin(name='VDD', grid=r12, mn=r12.mn.bbox(rvdd0))
      
      # 7. Export to physical database.
      print("Export design")
      print("")
      
      # Magic TCL script export
      laygo2.interface.magic.export(lib, filename=ref_dir_MAG_exported +libname+'_'+cellname+'.tcl', cellname=None, libpath=ref_dir_layout, scale=1, reset_library=False, tech_library='sky130A')
      # 8. Export to a template database file.
      nat_temp = dsn.export_to_template()
      laygo2.interface.yaml.export_template(nat_temp, filename=ref_dir_template+libname+'_templates.yaml', mode='append')

if __name__ == "__main__":

    write_back = 'tl_pex' #'xschem'
    TL_PEX_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/comparator_transfer_learning/pex/'    

    if write_back == 'xschem':
        os.system('ipython laygo2_size_converter.py')
    elif write_back == 'tl_pex':
        os.system(f'cd {TL_PEX_DIR}; ipython laygo2_size_converter_strong_arm.py')
    else:
        raise Exception('Wrong write-back mode.')
        
    ckt_fname = 'strong_arm_device_size.yaml'
    with open(ckt_fname, 'r') as stream:
        try:
            device_info = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)

    # diff_pair
    nf_M1 = device_info['M1']['nf']
    M1 = device_info['M1']['mosfet']
    nf_M7 = device_info['M7']['nf']
    M7 = device_info['M7']['mosfet']
    # inverter
    nf_M3 = device_info['M3']['nf']
    M3 = device_info['M3']['mosfet']
    nf_M5 = device_info['M5']['nf']
    M5 = device_info['M5']['mosfet']
    # switches
    nf_M8 = device_info['M8']['nf']
    M8 = device_info['M8']['mosfet']
    nf_M10 = device_info['M10']['nf']
    M10 = device_info['M10']['mosfet'] 
    
    nf = [nf_M1, nf_M3, nf_M5, nf_M7, nf_M8, nf_M10]
    mosfet = [M1, M3, M5, M7, M8, M10]
    print("Generating layout of double_tail comparator.")
    
    # generate the complete layout
    strong_arm(nf=nf, mosfet=mosfet)          
    STRONG_ARM_TCL_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/laygo2_workspace_sky130/laygo2_example/strong_arm/TCL'
    if os.system(f'cd {STRONG_ARM_TCL_DIR}/; magic -dnull -noconsole -rcfile .maginit strong_arm_comparator_total.tcl') == 0:  # run magic to generate the entire comparator layout
        print('=== Magic has generated the entire comparator layout! ===')
    else:  
        raise Exception('=== Magic error during layout generation. ===')
        
    # run magic to extract the circuit for LVS for Netgen
    STRONG_ARM_NETGEN_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/netgen/strong_arm'
    os.system(f'cd {STRONG_ARM_TCL_DIR}/; magic -dnull -noconsole -rcfile .maginit strong_arm_comparator_lvs.tcl') # run magic to extract LVS netlist from layout, 
    if write_back == 'xschem':
        os.system(f'cd {STRONG_ARM_NETGEN_DIR}/; ipython reformat_netlist.py') # run a script to convert the original Xschem comparator netlist to be compatible to netgen 
    if write_back == 'tl_pex':
        os.system(f'cd {TL_PEX_DIR}; ipython reformat_netlist_lvs_strong_arm.py') # run a script to convert the original Xschem comparator netlist to be compatible to netgen 
    if os.system(f'cd {STRONG_ARM_NETGEN_DIR}/; ./run_netgen_lvs') == 0: # run netgen LVS 
        print('=== LVS passed, circuits match uniquely! ===')
    else:  
        raise Exception('=== LVS error, check the <comp.out> for details. ===')

    # run magic to extract the circuit for PEX for simulation
    XSCHEM_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/xschem'
    if os.system(f'cd {STRONG_ARM_TCL_DIR}/; magic -dnull -noconsole -rcfile .maginit strong_arm_comparator_pex.tcl')  == 0: # run magic to extract PEX netlist from layout
        print('=== PEX extraction done! ===')
    else:  
        raise Exception('=== PEX extraction error! ===')
    if write_back == 'xschem':
        os.system(f'cd {XSCHEM_DIR}/; ipython reformat_netlist_strong_arm.py') # write the PEX extracted circuit back to the testbench
    if write_back == 'tl_pex':
        os.system(f'cd {TL_PEX_DIR}; ipython reformat_netlist_pex_strong_arm.py') # run a script to convert the original Xschem comparator netlist to be compatible to netgen 

    
    