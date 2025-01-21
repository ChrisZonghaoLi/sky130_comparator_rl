import numpy as np
import pprint
import laygo2
import laygo2.interface
import laygo2_tech as tech
import yaml
import os

# import other subcircuits 
from diff_pair import diff_pair
from latch import latch

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
pg_name = 'placement_basic'
# signal routing grid
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
libname = 'double_tail'
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
# signal routing
pg, r12, r23, r34 = grids[pg_name], grids[r12_name], grids[r23_name], grids[r34_name]
# power line routing
r34_pwr = grids[r34_pwr_name]
r12_pwr = grids[r12_pwr_name]
r23_pwr = grids[r23_pwr_name]
r3_pwr = grids[r3_pwr_name]
r45_pwr = grids[r45_pwr_name]
r5_pwr = grids[r5_pwr_name]

lib = laygo2.object.database.Library(name=libname)

def double_tail(nf, mosfet, cellname = 'comparator'):
    
      print('--------------------')
      print('Now Creating '+cellname)
      
      nf_M1, nf_M3, nf_M5, nf_M6, nf_M7, nf_M10, nf_M12 = nf #  [12, 2, 10, 2, 2, 4, 6]
      M1, M3, M5, M6, M7, M10, M12 = mosfet
      
      global diff_pair, latch
      print("Create subckt layout of diff_pair.")
      diff_pair(nf_M1, nf_M3, nf_M5,
                        M1, M3, M5)
      print("Create subckt layout of latch.")
      latch(nf_M6, nf_M7, nf_M10, nf_M12,
                    M6, M7, M10, M12)

      # 2. Create a design hierarchy
      dsn = laygo2.object.database.Design(name=cellname, libname=libname)
      lib.append(dsn)
      
      # 3. Create instances.
      print("Create instances")
      # load updated template
      tlib = laygo2.interface.yaml.import_template(filename=ref_dir_template+'double_tail_templates.yaml')
      # create instances
      diff_pair = tlib['diff_pair'].generate(transform='MX', name='diff_pair') # flip diff pair share the same VSS with latch
      latch = tlib['latch'].generate(name='latch')

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
      
      with open(ref_dir_template+'double_tail_templates.yaml', 'r') as stream:
          try:
              double_tail_templates = yaml.safe_load(stream)
          except yaml.YAMLError as exc:
              print(exc)
              
      # remove diff_pair layout offset
      diff_pair_bbox = double_tail_templates['double_tail']['diff_pair']['bbox'] # the actual physical layout bbox of the diff_pair before LAYGO shifts it
      diff_pair_bottom_left = np.array(diff_pair_bbox[0])
      diff_pair_offset_h = int(diff_pair_bottom_left[0] / placement_resolution_h)
      # place diff_pair
      mn_diff_pair = np.array([-diff_pair_offset_h,0])
      dsn.place(grid=pg, inst=diff_pair, mn=mn_diff_pair)

      # place latch
      _distance_v = np.array([0,6]) # having some vertical distance to seperate latch and pre-amp layout
      mn_latch = pg.mn.top(diff_pair) - mn_diff_pair #+ _distance_v
      dsn.place(grid=pg, inst=latch, mn=mn_latch)      

      # 5. Create and place wires.
      # wire connection of pre-amp and latch: Di_p
      mn_M4_M9 = [r23.mn(diff_pair.pins['Di_p'])[1], 
                                     r23.mn(latch.pins['Di_p'])[1]   ]
      track_M4_M9 = [mn_M4_M9[1][0] ,None]
      r_M4_M9 = dsn.route_via_track(grid=r23, mn=mn_M4_M9, track=track_M4_M9)
      # wire connection of pre-amp and latch: Di_n
      mn_M3_M6 = [r23.mn(diff_pair.pins['Di_n'])[1], 
                                     r23.mn(latch.pins['Di_n'])[0]   ]
      track_M3_M6 = [mn_M3_M6[1][0] ,None]
      r_M3_M6 = dsn.route_via_track(grid=r23, mn=mn_M3_M6, track=track_M3_M6)
      
      # Create VDD power ring to connect VDD of pre-amp and latch
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

      # first, having VDD jump up to higher metal for latch
      # via3
      # mn_VDD_latch = [r23_pwr.mn(latch.pins['VDD'])[0], r23_pwr.mn(latch.pins['VDD'])[1]]
      mn_VDD_latch = via_array(r23_pwr.mn(latch.pins['VDD'])) 
      r_VDD_latch = dsn.via(grid=r23_pwr, mn=mn_VDD_latch)
      # m3
      mn_VDD_latch = [r3_pwr.mn(latch.pins['VDD'])[0], r3_pwr.mn(latch.pins['VDD'])[1]]
      r_VDD_latch = dsn.route(grid=r3_pwr, mn=mn_VDD_latch)
      # via4
      mn_VDD_latch = via_array(r34_pwr.mn(latch.pins['VDD'])) 
      r_VDD_latch = dsn.via(grid=r34_pwr, mn=mn_VDD_latch)
      # m4
      mn_VDD_latch = [r34_pwr.mn(latch.pins['VDD'])[0], r34_pwr.mn(latch.pins['VDD'])[1]]
      r_VDD_latch = dsn.route(grid=r34_pwr, mn=mn_VDD_latch)
     
      # second, having VDD jump up to higher metal for diff-amp
      # via3
      # mn_VDD_latch = [r23_pwr.mn(latch.pins['VDD'])[0], r23_pwr.mn(latch.pins['VDD'])[1]]
      mn_VDD_diff_pair = via_array(r23_pwr.mn(diff_pair.pins['VDD'])) 
      r_VDD_diff_pair = dsn.via(grid=r23_pwr, mn=mn_VDD_diff_pair)
      # m3
      mn_VDD_diff_pair = [r3_pwr.mn(diff_pair.pins['VDD'])[0], r3_pwr.mn(diff_pair.pins['VDD'])[1]]
      r_VDD_diff_pair = dsn.route(grid=r3_pwr, mn=mn_VDD_diff_pair)
      # via4
      mn_VDD_diff_pair = via_array(r34_pwr.mn(diff_pair.pins['VDD'])) 
      r_VDD_diff_pair = dsn.via(grid=r34_pwr, mn=mn_VDD_diff_pair)
      # m4
      mn_VDD_diff_pair = [r34_pwr.mn(diff_pair.pins['VDD'])[0], r34_pwr.mn(diff_pair.pins['VDD'])[1]]
      r_VDD_diff_pair = dsn.route(grid=r34_pwr, mn=mn_VDD_diff_pair)

      # now construct the VDD ring
      x_center = r45_pwr.mn.bottom(diff_pair)[0] - mn_diff_pair[0]
      mn_VDD_1 = [ [x_center, r45_pwr.mn(diff_pair.pins['VDD'])[0][1]],
                                [x_center, r45_pwr.mn(latch.pins['VDD'])[0][1]]   ]
      
      if r45_pwr.mn.width(diff_pair) >= r45_pwr.mn.width(latch):
           _width = r45_pwr.mn.width(diff_pair) + 2 # adding some margin
      else:
           _width = r45_pwr.mn.width(latch) + 2
      track_VDD_1 = [x_center - np.array(_width/2).astype(np.int64), None]
      r_VDD_1 = dsn.route_via_track(grid=r45_pwr, mn=mn_VDD_1, track=track_VDD_1)

      mn_VDD_2 = [ [x_center, r45_pwr.mn(diff_pair.pins['VDD'])[1][1]],
                                [x_center, r45_pwr.mn(latch.pins['VDD'])[1][1]]   ]
      track_VDD_2 = [x_center + np.array(_width/2).astype(np.int64), None]
      r_VDD_2 = dsn.route_via_track(grid=r45_pwr, mn=mn_VDD_2, track=track_VDD_2)
      
      # Create VSS of pre-amp and latch, which is shared by them
      mn_VSS_latch = via_array(r23_pwr.mn(latch.pins['VSS'])) 
      r_VSS_latch = dsn.via(grid=r23_pwr, mn=mn_VSS_latch)
      # m3
      mn_VSS_latch = [r3_pwr.mn(latch.pins['VSS'])[0], r3_pwr.mn(latch.pins['VSS'])[1]]
      r_VSS_latch = dsn.route(grid=r3_pwr, mn=mn_VSS_latch)
      # via4
      mn_VSS_latch = via_array(r34_pwr.mn(latch.pins['VSS'])) 
      r_VSS_latch = dsn.via(grid=r34_pwr, mn=mn_VSS_latch)
      # m4
      mn_VSS_latch = [r34_pwr.mn(latch.pins['VSS'])[0], r34_pwr.mn(latch.pins['VSS'])[1]]
      r_VSS_latch = dsn.route(grid=r34_pwr, mn=mn_VSS_latch)
      
      # 6. Create pins. In LAYGO, pin names are unique
      pin_VDD = dsn.pin(name='VDD', grid=r34_pwr, mn=r34_pwr.mn.bbox(latch.pins['VDD'])) # VDD
      pin_VSS = dsn.pin(name='VSS', grid=r34_pwr, mn=r34_pwr.mn.bbox(latch.pins['VSS'])) # VSS
      pin_Vin_p = dsn.pin(name='Vin_p', grid=r12, mn=r12.mn.bbox(diff_pair.pins['Vin_p'])) # Vin_p
      pin_Vin_n = dsn.pin(name='Vin_n', grid=r12, mn=r12.mn.bbox(diff_pair.pins['Vin_n'])) # Vin_n
      pin_Di_n = dsn.pin(name='Di_n', grid=r23, mn=r23.mn.bbox(diff_pair.pins['Di_n'])) # Di_n   
      pin_Di_p = dsn.pin(name='Di_p', grid=r23, mn=r23.mn.bbox(diff_pair.pins['Di_p'])) # Di_p   
      pin_Voutn = dsn.pin(name='Vout_n', grid=r23, mn=r23.mn.bbox(latch.pins['Vout_n'])) # Voutn
      pin_Voutp = dsn.pin(name='Vout_p', grid=r23, mn=r23.mn.bbox(latch.pins['Vout_p'])) # Voutp
      pin_CLK= dsn.pin(name='CLK', grid=r12, mn=r12.mn.bbox(diff_pair.pins['CLK'])) # CLK_bar
      pin_CLK_bar = dsn.pin(name='CLK_bar', grid=r12, mn=r12.mn.bbox(latch.pins['CLK_bar'])) # CLK_bar

      # 7. Export to physical database.
      print("Export design")
      print("")
      
      # Magic TCL script export
      laygo2.interface.magic.export(lib, filename=ref_dir_MAG_exported +libname+'_'+cellname+'.tcl', cellname=None, libpath=ref_dir_layout, scale=1, reset_library=False, tech_library='sky130A')
      # 8. Export to a template database file.
      nat_temp = dsn.export_to_template()
      laygo2.interface.yaml.export_template(nat_temp, filename=ref_dir_template+libname+'_templates.yaml', mode='append')

if __name__ == "__main__":
    
    write_back = 'tl_pex' # 'xschem'
    TL_PEX_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/comparator_transfer_learning/pex/'

    if write_back == 'xschem':
        os.system('ipython laygo2_size_converter.py')
    elif write_back == 'tl_pex':
        os.system(f'cd {TL_PEX_DIR}; ipython laygo2_size_converter_double_tail.py')
    else:
        raise Exception('Wrong write-back mode.')
        
    ckt_fname = 'double_tail_device_size.yaml'
    with open(ckt_fname, 'r') as stream:
        try:
            device_info = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
            
    # diff_pair
    nf_M1 = device_info['M1']['nf']
    M1 = device_info['M1']['mosfet']
    nf_M3 = device_info['M3']['nf']
    M3 = device_info['M3']['mosfet']
    nf_M5 = device_info['M5']['nf']
    M5 = device_info['M5']['mosfet']
    # latch (include inverter)
    nf_M6 = device_info['M6']['nf']
    M6 = device_info['M6']['mosfet']
    nf_M7 = device_info['M7']['nf']
    M7 = device_info['M7']['mosfet']
    nf_M10 = device_info['M10']['nf']
    M10 = device_info['M10']['mosfet']  
    nf_M12 = device_info['M12']['nf']
    M12 = device_info['M12']['mosfet']  
    
    nf = [nf_M1, nf_M3, nf_M5, nf_M6, nf_M7, nf_M10, nf_M12]
    mosfet = [M1, M3, M5, M6, M7, M10, M12]
    print("Generating layout of double_tail comparator.")
    # nf = [12, 2, 10, 2, 2, 4, 6]
    # nf = [4, 4, 4, 4, 4, 4, 4]
    # nf = [2, 2, 2, 2, 2, 2, 2]
    
    # generate the complete layout
    double_tail(nf=nf, mosfet=mosfet)
    DOUBLE_TAIL_TCL_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/laygo2_workspace_sky130/laygo2_example/double_tail/TCL'
    if os.system(f'cd {DOUBLE_TAIL_TCL_DIR}/; magic -dnull -noconsole -rcfile .maginit double_tail_comparator_total.tcl') == 0:  # run magic to generate the entire comparator layout
        print('=== Magic has generated the entire comparator layout! ===')
    else:  
        raise Exception('=== Magic error during layout generation. ===')
        
    # run magic to extract the circuit for LVS for Netgen
    DOUBLE_TAIL_NETGEN_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/netgen/double_tail'
    os.system(f'cd {DOUBLE_TAIL_TCL_DIR}/; magic -dnull -noconsole -rcfile .maginit double_tail_comparator_lvs.tcl') # run magic to extract LVS netlist from layout
    if write_back == 'xschem':
        os.system(f'cd {DOUBLE_TAIL_NETGEN_DIR}/; ipython reformat_netlist.py') # run a script to convert the original Xschem comparator netlist to be compatible to netgen 
    if write_back == 'tl_pex':
        os.system(f'cd {TL_PEX_DIR}; ipython reformat_netlist_lvs_double_tail.py') # run a script to convert the original Xschem comparator netlist to be compatible to netgen 
    if os.system(f'cd {DOUBLE_TAIL_NETGEN_DIR}/; ./run_netgen_lvs') == 0: # run netgen LVS 
        print('=== LVS passed, circuits match uniquely! ===')
    else:  
        raise Exception('=== LVS error, check the <comp.out> for details. ===')

    # run magic to extract the circuit for PEX for simulation
    XSCHEM_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/xschem'
    if os.system(f'cd {DOUBLE_TAIL_TCL_DIR}/; magic -dnull -noconsole -rcfile .maginit double_tail_comparator_pex.tcl')  == 0: # run magic to extract PEX netlist from layout
        print('=== PEX extraction done! ===')
    else:  
        raise Exception('=== PEX extraction error! ===')
    if write_back == 'xschem':
        os.system(f'cd {XSCHEM_DIR}/; ipython reformat_netlist_double_tail.py') # write the PEX extracted circuit back to the testbench
    if write_back == 'tl_pex':
        os.system(f'cd {TL_PEX_DIR}; ipython reformat_netlist_pex_double_tail.py') # run a script to convert the original Xschem comparator netlist to be compatible to netgen 

     
     
     
     
     
     
     
     
     
     
     
     
