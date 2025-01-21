import numpy as np
import pprint
import laygo2
import laygo2.interface
import laygo2_tech as tech
import os
import yaml

# Parameter definitions #############
# Variables
cell_type = ['diff_pair']
# Templates
tpmos_name = 'pmos_sky'
tnmos_name = 'nmos_sky'
tpwell_name = 'pwell_sky'
# Grids
pg_name = 'placement_basic'
r12_name = 'routing_12_cmos'
r23_name = 'routing_23_cmos'
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
tpwell =  templates[tpwell_name]
print(templates[tnmos_name])
print(templates[tpwell_name])

print("Load grids")
grids = tech.load_grids_comparator(templates=templates)
pg, r12, r23 = grids[pg_name], grids[r12_name], grids[r23_name]
print(grids[pg_name], grids[r12_name], grids[r23_name], sep="\n")

lib = laygo2.object.database.Library(name=libname)

def diff_pair(nf_M1, nf_M3, nf_M5, 
                        M1, M3, M5,
                        cellname = 'diff_pair'):   
      cellname = 'diff_pair' 
      print('--------------------')
      print('Now Creating '+cellname)
      
      # 2. Create a design hierarchy
      dsn = laygo2.object.database.Design(name=cellname, libname=libname)
      lib.append(dsn)
      
      # 3. Create instances.
      print("Create instances")
      nf_M7 = 12
      nf_M1 = 12
      nf_M2 = nf_M1
      in0 = tnmos.generate(name='M7', params={'nf': nf_M7, 'tie': 'S'}) # M7, tail NMOS
      in1 = tnmos.generate(name='M1', params={'nf': nf_M1, 'tie': 'S'}) # M1, input
      in2 = tnmos.generate(name='M2', params={'nf': nf_M2, 'tie': 'S'}) # M2, input
      
      pwell_0 = tpwell.generate(name='Pwell_M7', params={'nf': nf_M7}) # pwell for M7
      pwell_1 = tpwell.generate(name='Pwell_M1', params={'nf': nf_M1}) # pwell for M1
      pwell_2 = tpwell.generate(name='Pwell_M2', params={'nf': nf_M2}) # pwell for M1

      # 4. Place instances.
      mn_M7 = [0,0]
      dsn.place(grid=pg, inst=in0, mn=mn_M7) # placement of M7
      offset_in1 = int(nf_M7/2) * np.array([1,0])
      offset_in2 = np.array([1,0]) 
      mn_M1 = pg.mn.top_left(in0) - pg.mn.width_vec(in1) + offset_in1
      mn_M2 = pg.mn.top(in0)  + offset_in2
      dsn.place(grid=pg, inst=in1, mn=mn_M1) # placement of M1
      dsn.place(grid=pg, inst=in2, mn=mn_M2) # placement of M2
      # place pwell
      dsn.place(grid=pg, inst=pwell_0, mn=mn_M7) 
      dsn.place(grid=pg, inst=pwell_1, mn=mn_M1) 
      dsn.place(grid=pg, inst=pwell_2, mn=np.array(mn_M2) ) 

      # 5. Create and place wires.
      print("Create wires")
      # IN
      mn_Vin_p = [r12.mn(in1.pins['G'])[0], r12.mn(in1.pins['G'])[1]] 
      r_Vin_p = dsn.route(grid=r12, mn=mn_Vin_p)
      mn_Vin_n = [r12.mn(in2.pins['G'])[0], r12.mn(in2.pins['G'])[1]] 
      r_Vin_n = dsn.route(grid=r12, mn=mn_Vin_n)
      
      # CLK
      mn_CLK = [r12.mn(in0.pins['G'])[0], r12.mn(in0.pins['G'])[1]] 
      r_CLK = dsn.route(grid=r12, mn=mn_CLK)
      
      # M7 horizontal drain extension 
      extension_M7_drain = 3
      mn_M7_drain =  [np.array([r12.mn(in0.pins['D'])[0][0] - extension_M7_drain, r12.mn(in0.pins['D'])[0][1]]), 
                                      np.array([r12.mn(in0.pins['D'])[1][0] + extension_M7_drain, r12.mn(in0.pins['D'])[0][1]])]
      r_M7_drain = dsn.route(grid=r12, mn=mn_M7_drain)

      # M1 source connect to the M7 drain
      mn_M1_M7 =  [np.array([mn_M7_drain[0][0], mn_M7_drain[0][1]]),
                                     np.array([mn_M7_drain[0][0], r12.mn(in1.pins['RAIL'])[0][1]])]
      track_M1_M7 = [mn_M7_drain[0][0], None]
      r_M1_M7 = dsn.route_via_track(grid=r12, mn=mn_M1_M7, track=track_M1_M7)
      _mn_M1_M7 = [mn_M1_M7[1], r12.mn(in1.pins['RAIL'])[0]] # in case if M1 is way smaller than M7
      _r_M1_M7 = dsn.route(grid=r12, mn=_mn_M1_M7)
      
      # M2 source connect to the M7 drain
      mn_M2_M7 =  [np.array([mn_M7_drain[1][0], mn_M7_drain[1][1]]),
                                     np.array([mn_M7_drain[1][0], r12.mn(in2.pins['RAIL'])[0][1]])]
      track_M2_M7 = [mn_M7_drain[1][0], None]
      r_M2_M7 = dsn.route_via_track(grid=r12, mn=mn_M2_M7, track=track_M2_M7)
      _mn_M2_M7 = [mn_M2_M7[1], r12.mn(in2.pins['RAIL'])[1]] # in case if M2 is way smaller than M7
      _r_M2_M7 = dsn.route(grid=r12, mn=_mn_M2_M7)
      
      # M1 drain connect to latch stage
      extension_M1_drain_h = 2
      extension_M1_drain_v = 2
      mn_M1_drain =  [r12.mn(in1.pins['D'])[0], 
                                      np.array([r12.mn(in1.pins['D'])[1][0] + extension_M1_drain_h, r12.mn(in1.pins['D'])[0][1] + extension_M1_drain_v ])]
      track_M1_drain = [mn_M1_drain[1][0], None]
      r_M1_drain = dsn.route_via_track(grid=r12, mn=mn_M1_drain, track=track_M1_drain)
      
      # M2 drain connect to latch stage
      extension_M2_drain_h = 2 * int(nf_M2/2) # need to shift it back, depending on how many fingers it has
      extension_M2_drain_v = extension_M1_drain_v
      mn_M2_drain =  [r12.mn(in2.pins['D'])[0], 
                                      np.array([r12.mn(in2.pins['D'])[1][0] - extension_M2_drain_h, r12.mn(in2.pins['D'])[0][1] + extension_M2_drain_v ])]
      track_M2_drain = [mn_M2_drain[1][0], None]
      r_M2_drain = dsn.route_via_track(grid=r12, mn=mn_M2_drain, track=track_M2_drain)
      
      # VSS
      r_VSS = dsn.route(grid=r12, mn=[r12.mn(in0.pins['RAIL'])[0], r12.mn(in0.pins['RAIL'])[1]])
      
      # 6. Create pins.
      pin_CLK = dsn.pin(name='CLK', grid=r12, mn=r12.mn.bbox(r_CLK)) # CLK
      pin_Vin_p = dsn.pin(name='Vin_p', grid=r12, mn=r12.mn.bbox(r_Vin_p)) # Vin_p
      pin_Vin_n = dsn.pin(name='Vin_n', grid=r12, mn=r12.mn.bbox(r_Vin_n)) # Vin_n   
      pin_Di_n = dsn.pin(name='Di_n', grid=r12, mn=r12.mn.bbox(r_M1_drain[2])) # Di_n   
      pin_Di_p = dsn.pin(name='Di_p', grid=r12, mn=r12.mn.bbox(r_M2_drain[2])) # Di_p   

      p_VSS = dsn.pin(name='VSS', grid=r12, mn=r12.mn.bbox(r_VSS))
      
      # 7. Export to physical database.
      print("Export design")
      print("")
      
      # Magic TCL script export
      laygo2.interface.magic.export(lib, filename=ref_dir_MAG_exported +libname+'_'+cellname+'.tcl', cellname=None, libpath=ref_dir_layout, scale=1, reset_library=False, tech_library='sky130A')
      # 8. Export to a template database file.
      nat_temp = dsn.export_to_template()
      laygo2.interface.yaml.export_template(nat_temp, filename=ref_dir_template+libname+'_templates.yaml', mode='append')
