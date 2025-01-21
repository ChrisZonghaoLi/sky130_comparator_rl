import numpy as np
import pprint
import laygo2
import laygo2.interface
import laygo2_tech as tech 
import yaml
import os

# import other subcircuits 
from inverter import inverter

# Parameter definitions #############
# Variables
cell_type = ['latch']
# Templates
tpmos_name = 'pmos_sky'
tnmos_name = 'nmos_sky'
tpwell_name = 'pwell_sky'
tnwell_name = 'nwell_sky'
tptap_name = 'ptap_sky'
tntap_name = 'ntap_sky'
# Grids
pg_name = 'placement_basic'
r12_name = 'routing_12_basic'
r23_name = 'routing_23_basic'
r12_pwr_name = 'routing_12_pwr'
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
print(templates[tnmos_name])
print(templates[tpmos_name])
print(templates[tpwell_name])
print(templates[tnwell_name])
print(templates[tptap_name])
print(templates[tntap_name])

print("Load grids")
grids = tech.load_grids_comparator(templates=templates)
pg, r12, r12_pwr, r23 = grids[pg_name], grids[r12_name],  grids[r12_pwr_name], grids[r23_name]
print(grids[pg_name], grids[r12_name], grids[r12_pwr_name], grids[r23_name], sep="\n")

lib = laygo2.object.database.Library(name=libname)

def latch(nf_M6, nf_M7, nf_M10, nf_M12, 
                  M6, M7, M10, M12,
                  cellname='latch'):

      print('--------------------')
      print('Now Creating '+cellname)
      print(f'M6, M7, nf_M10, M12: {M6}, {M7}, {M10}, {M12}')
      print(f'nf_M6, nf_M7, nf_M10, nf_M12: {nf_M6}, {nf_M7}, {nf_M10}, {nf_M12}')

      # 2. Create a design hierarchy
      dsn = laygo2.object.database.Design(name=cellname, libname=libname)
      lib.append(dsn)
      
      nf_M9 = nf_M6
      M9 = M6
      
      # 3. Create instances. From right to left on the schematic.
      global inverter
      print("Create subckt layout of inverter.")
      inverter(nf_M7, nf_M10, M7, M10)
      # load update template library
      tlib = laygo2.interface.yaml.import_template(filename=ref_dir_template+'double_tail_templates.yaml')
      # then generate instances
      inv0 = tlib['inverter'].generate(name='inv0')
      inv1 = tlib['inverter'].generate(name='inv1', transform='MY')
      
      in0 = tnmos.generate(name='M9', params={'nf': nf_M9, 'tie': 'S', 'mosfet': M9}) # M9, NMOS
      in1 = tnmos.generate(name='M6', params={'nf': nf_M6, 'tie': 'S', 'mosfet': M6}) # M6, NMOS
      ip0 = tpmos.generate(name='M12', transform='MX', params={'nf': nf_M12, 'tie': 'S', 'mosfet': M12}) # M12, top PMOS

      ntap_0 = tntap.generate(name='Ntap_0', params={'nf': 2, 'tie': 'TAP0'})
      ntap_1 = tntap.generate(name='Ntap_1', params={'nf': 2, 'tie': 'TAP0'})
      ptap_0 = tptap.generate(name='Ptap_0', transform='MX', params={'nf': 2, 'tie': 'TAP0'})
      ptap_1 = tptap.generate(name='Ptap_1', transform='MX', params={'nf': 2, 'tie': 'TAP0'})

      # 4. Place instances.
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

      # we do the placement from right to left
      # remove inverter layout offset
      inverter_bbox = double_tail_templates['double_tail']['inverter']['bbox'] # the actual physical layout bbox of the inverter before LAYGO shifts it
      inverter_bottom_left = np.array(inverter_bbox[0])
      inverter_offset_h = int(inverter_bottom_left[0] / placement_resolution_h)
      mn_inverter = np.array([-inverter_offset_h,0])
      # place inverter 1
      mn_inv0 = mn_inverter #mn_inverter
      dsn.place(grid=pg, inst=inv0, mn=mn_inv0)
      # place inverter 2
      mn_inv1 = -mn_inverter
      dsn.place(grid=pg, inst=inv1, mn=mn_inv1)
      # place switch M9
      mn_M9 = -mn_inverter + pg.mn.bottom_right(inv0)
      dsn.place(grid=pg, inst=in0, mn=mn_M9)
      # place switch M6
      mn_M6 = mn_inverter + pg.mn.bottom_left(inv1) - pg.mn.width_vec(in1)
      dsn.place(grid=pg, inst=in1, mn=mn_M6)
      # place switch M12
      dist_inv0_inv1 = int(mn_inv0[0] - mn_inv1[0])
      mn_M12 = mn_inverter + pg.mn.height_vec(inv0) + pg.mn.height_vec(ip0) - np.array(0.5 * pg.mn.width_vec(ip0)).astype(np.int64) - \
          np.array([int(dist_inv0_inv1/2),0])
      dsn.place(grid=pg, inst=ip0, mn=mn_M12)
 
      # place tap
      mn_ntap0 = mn_M9 + pg.mn.width_vec(in0)
      dsn.place(grid=pg, inst=ntap_0, mn=mn_ntap0)
      # place tap
      mn_ntap1 = mn_M6 - pg.mn.width_vec(ntap_1)
      dsn.place(grid=pg, inst=ntap_1, mn=mn_ntap1)
      # place tap
      mn_ptap0 = mn_M12 + pg.mn.width_vec(ip0)
      dsn.place(grid=pg, inst=ptap_0, mn=mn_ptap0)
      # place tap
      mn_ptap1 = mn_M12 - pg.mn.width_vec(ptap_1)
      dsn.place(grid=pg, inst=ptap_1, mn=mn_ptap1)
 
      # placing pwell fill for NMOS, whose dimension is a funtion of the distance between two Ntaps
      N_pwell0 = int(mn_ntap0[0] - mn_ntap1[0])
      pwell_0 = tpwell.generate(name='Pwell_fill0', params={'nf': N_pwell0}) # pwell fill
      mn_pwell0 = mn_ntap1
      dsn.place(grid=pg, inst=pwell_0, mn=mn_pwell0)
      # placing nwell fill for inverter PMOS, which is a function of the distance between two inverters
      N_nwell0 = int(pg.mn.width(inv0) + pg.mn.width(inv1)) - 2
      if mn_inv0[0] == mn_inv1[0]: # it means when NMOS in inverters are larger than PMOS 
          nwell_0 = tnwell.generate(name='Nwell_fill0', params={'nf': N_nwell0}) # pwell fill
          mn_nwell0 = mn_inv1 + np.array(pg.mn.height_vec(inv1)/2).astype(np.int64) - pg.mn.width_vec(inv1)
          dsn.place(grid=pg, inst=nwell_0, mn=mn_nwell0)
      # placing nwell fill for top PMOS, which is a function of the distance between two Ptaps
      N_nwell1 = int(mn_ptap0[0] - mn_ptap1[0])
      nwell_1 = tnwell.generate(name='Nwell_fill1', transform='MX', params={'nf': N_nwell1}) # pwell fill
      mn_nwell1 = mn_ptap1
      dsn.place(grid=pg, inst=nwell_1, mn=mn_nwell1)

      # 5. Create and place wires.
      print("Create wires")
      # inverter routing
      # Voutn connection 
      Voutn_offset_v = 1
      mn_Voutn = [[r23.mn(inv1.pins['I'])[1][0], r23.mn(inv1.pins['I'])[1][1] - Voutn_offset_v], 
                              [r23.mn(inv0.pins['O'])[0][0], r23.mn(inv1.pins['I'])[1][1] - Voutn_offset_v]]
      r_Voutn = dsn.route(grid=r23, mn=mn_Voutn, via_tag=[True, True])
      # Voutp connection 
      Voutp_offset_v = 3
      mn_Voutp = [[r23.mn(inv1.pins['O'])[0][0], r23.mn(inv1.pins['O'])[0][1] + Voutp_offset_v], 
                              [r23.mn(inv0.pins['I'])[0][0], r23.mn(inv1.pins['O'])[0][1] + Voutp_offset_v]]
      r_Voutp = dsn.route(grid=r23, mn=mn_Voutp, via_tag=[True, True])
      
      # drain connection of M8 and M9
      r_M8_M9_drain = dsn.route(grid=r23, mn=[r23.mn(in0.pins['D'])[0], r23.mn(inv0.pins['O'])[0]])
      
      # drain connection of M6 and M7
      r_M6_M7_drain = dsn.route(grid=r23, mn=[r23.mn(in1.pins['D'])[0], r23.mn(inv1.pins['O'])[0]])
      
      # source connection of PMOS of inv1 and inv0
      r_inv0_inv1_source = dsn.route(grid=r23, mn=[r23.mn(inv1.pins['VDD'])[0], r23.mn(inv0.pins['VDD'])[1]])
      
      # source connection of inverters to the drain of head PMOS M12
      _center_M12_drain = np.array([ (r23.mn(ip0.pins['D'])[0][0] + r23.mn(ip0.pins['D'])[1][0]) / 2, 
                                                                r23.mn(ip0.pins['D'])[0][1]]).astype(np.int64)
      _center_inv_source = np.array([ (r23.mn(inv1.pins['VDD'])[1][0] + r23.mn(inv0.pins['VDD'])[0][0]) / 2, 
                                                                r23.mn(inv1.pins['VDD'])[1][1]]).astype(np.int64)

      r_inv_M12 = dsn.route(grid=r23, mn=[_center_M12_drain, _center_inv_source], via_tag = [True, True])
      
      # VSS wire connection
      r_VSS = dsn.route(grid=r12_pwr, mn=[r12_pwr.mn(ntap_0.pins['RAIL'])[1], r12_pwr.mn(ntap_1.pins['RAIL'])[0]]) 
      # VDD wire connection
      r_VDD = dsn.route(grid=r12_pwr, mn=[r12_pwr.mn(ptap_0.pins['RAIL'])[1], r12_pwr.mn(ptap_1.pins['RAIL'])[0]])
      
      # 6. Create pins.
      pin_Di_p = dsn.pin(name='Di_p', grid=r12, mn=r12.mn.bbox(in0.pins['G'])) # Di_p
      pin_Di_n = dsn.pin(name='Di_n', grid=r12, mn=r12.mn.bbox(in1.pins['G'])) # Di_n
      pin_CLK_bar = dsn.pin(name='CLK_bar', grid=r12, mn=r12.mn.bbox(ip0.pins['G'])) # CLK_bar

      pin_VSS = dsn.pin(name='VSS', grid=r12, mn=[r12.mn.bbox(inv1.pins['VSS'])[0], r12.mn.bbox(inv0.pins['VSS'])[1]]) # VSS
      pin_VDD = dsn.pin(name='VDD', grid=r12, mn=r12.mn.bbox(r_VDD)) # VDD

      pin_Voutn = dsn.pin(name='Vout_n', grid=r23, mn=r23.mn.bbox(r_Voutn[1])) # Voutn
      pin_Voutp = dsn.pin(name='Vout_p', grid=r23, mn=r23.mn.bbox(r_Voutp[1])) # Voutp

      # 7. Export to physical database.
      print("Export design")
      print("")
      
      # Magic TCL script export
      laygo2.interface.magic.export(lib, filename=ref_dir_MAG_exported +libname+'_'+cellname+'.tcl', cellname=None, libpath=ref_dir_layout, scale=1, reset_library=False, tech_library='sky130A')
      # 8. Export to a template database file.
      nat_temp = dsn.export_to_template()
      laygo2.interface.yaml.export_template(nat_temp, filename=ref_dir_template+libname+'_templates.yaml', mode='append')


if __name__ == "__main__":
    os.system('python laygo2_size_converter.py')
    ckt_fname = 'double_tail_device_size.yaml'
    with open(ckt_fname, 'r') as stream:
        try:
            device_info = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
            
    nf_M6 = device_info['M6']['nf']
    M6 = device_info['M6']['mosfet']
    nf_M7 = device_info['M7']['nf']
    M7 = device_info['M7']['mosfet']
    nf_M10 = device_info['M10']['nf']
    M10 = device_info['M10']['mosfet']  
    nf_M12 = device_info['M12']['nf']
    M12 = device_info['M12']['mosfet']  
            
    latch(nf_M6=nf_M6, nf_M7=nf_M7, nf_M10=nf_M10, nf_M12=nf_M12,
              M6=M6, M7=M7, M10=M10, M12=M12)
    
    
    
    
    
    
    
    
    