import numpy as np
import pprint
import laygo2
import laygo2.interface
import yaml
import laygo2_tech as tech 

# Parameter definitions #############
# Variables
cell_type = ['switches']
# nf_list = [2,4,12]
# Templates
tpmos_name = 'pmos_sky'
tnmos_name = 'nmos_sky'
tpwell_name = 'pwell_sky'
tnwell_name = 'nwell_sky'
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
tpmos = templates[tpmos_name]
tnwell =  templates[tnwell_name]
print(templates[tpmos_name])
print(templates[tnwell_name])

print("Load grids")
grids = tech.load_grids_comparator(templates=templates)
pg, r12, r23 = grids[pg_name], grids[r12_name], grids[r23_name]
print(grids[pg_name], grids[r12_name], grids[r23_name], sep="\n")

lib = laygo2.object.database.Library(name=libname)

for celltype in cell_type:
   # for nf in nf_list:
      cellname = 'switches' # celltype+'_'+str(nf)+'x'
      print('--------------------')
      print('Now Creating '+cellname)
      
      # 2. Create a design hierarchy
      dsn = laygo2.object.database.Design(name=cellname, libname=libname)
      lib.append(dsn)
      
      # 3. Create instances.
      print("Create instances")
      nf_M8 = 2
      nf_M10 = 6 
      ip0 = tpmos.generate(name='M8', transform='MX', params={'nf': nf_M8, 'tie': 'S', 'mosfet': 'pfet_01v8_0p42_nf2'}) # M8
      ip1 = tpmos.generate(name='M10', transform='MX', params={'nf': nf_M10, 'tie': 'S', 'mosfet': 'pfet_01v8_0p42_nf2'}) # M10

      nwell_0 = tnwell.generate(name='Nwell_M8', transform='MX', params={'nf': nf_M8}) # nwell for M8
      nwell_1 = tnwell.generate(name='Nwell_M10', transform='MX', params={'nf': nf_M10}) # nwell for M8

      # 4. Place instances.
      mn_M8 = np.array([0,0]) 
      mn_M10 = mn_M8 - pg.mn.width_vec(ip1)
      dsn.place(grid=pg, inst=ip0, mn=mn_M8)
      dsn.place(grid=pg, inst=ip1, mn=mn_M10)
      dsn.place(grid=pg, inst=nwell_0, mn=mn_M8) # pwell for M8
      dsn.place(grid=pg, inst=nwell_1, mn=mn_M10) # nwell for M10
      
      # 5. Create and place wires.
      print("Create wires")
      # CLK
      mn_CLK = [r23.mn(ip0.pins['G'])[0], r23.mn(ip1.pins['G'])[0]]
      r_CLK = dsn.route(grid=r23, mn=mn_CLK)

      # Drain connection of M8
      extension_drain_M8 = 3
      mn_M8_drain = [r23.mn(ip0.pins['D'])[1], 
                            [r23.mn(ip0.pins['D'])[1][0], r23.mn(ip0.pins['D'])[1][1] - extension_drain_M8]]
      r_start_M8, r_drain_M8, r_end_M8 = dsn.route(grid=r23, mn=mn_M8_drain, via_tag=[True, True])
      
      # Drain connection of M10
      extension_drain_M10 = 7
      mn_M10_drain = [r23.mn(ip1.pins['D'])[1], 
                            [r23.mn(ip1.pins['D'])[1][0], r23.mn(ip1.pins['D'])[1][1] - extension_drain_M10]]
      r_start_M10, r_drain_M10, r_end_M10 = dsn.route(grid=r23, mn=mn_M10_drain, via_tag=[True, True])
      
      # VDD
      rvdd0 = dsn.route(grid=r12, mn=[r12.mn(ip1.pins['RAIL'])[0], r12.mn(ip0.pins['RAIL'])[1]])
      
      # 6. Create pins.
      pin_CLK = dsn.pin(name='CLK', grid=r12, mn=r12.mn.bbox(r_CLK)) # CLK
      pin_VDD = dsn.pin(name='VDD', grid=r12, mn=r12.mn.bbox(rvdd0))
      pin_O = dsn.pin(name='O', grid=r23, mn=r23.mn.bbox(r_drain_M8))
      pin_Di = dsn.pin(name='Di', grid=r23, mn=r23.mn.bbox(r_drain_M10))

      # 7. Export to physical database.
      print("Export design")
      print("")
      
      # Magic TCL script export
      laygo2.interface.magic.export(lib, filename=ref_dir_MAG_exported +libname+'_'+cellname+'.tcl', cellname=None, libpath=ref_dir_layout, scale=1, reset_library=False, tech_library='sky130A')
      # 8. Export to a template database file.
      nat_temp = dsn.export_to_template()
      laygo2.interface.yaml.export_template(nat_temp, filename=ref_dir_template+libname+'_templates.yaml', mode='append')
