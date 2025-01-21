import numpy as np
import pprint
import laygo2
import laygo2.interface
import laygo2_tech as tech

# Parameter definitions #############
# Variables
cell_type = ['inverter']
# Templates
tpmos_name = 'pmos_sky'
tnmos_name = 'nmos_sky'
tpwell_name = 'pwell_sky'
tnwell_name = 'nwell_sky'
# Grids
pg_name = 'placement_basic'
r12_name = 'routing_12_basic'
r23_name = 'routing_23_basic'
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
tpwell =  templates[tpwell_name]
tnwell =  templates[tnwell_name]
print(templates[tnmos_name])
print(templates[tpmos_name])
print(templates[tpwell_name])
print(templates[tnwell_name])

print("Load grids")
grids = tech.load_grids_comparator(templates=templates)
pg, r12, r23 = grids[pg_name], grids[r12_name], grids[r23_name]
print(grids[pg_name], grids[r12_name], grids[r23_name], sep="\n")

lib = laygo2.object.database.Library(name=libname)

def inverter(nf_M7, nf_M10, cellname='inverter'):
      print('--------------------')
      print('Now Creating '+cellname)
      print(f'nf_M7, nf_M10: {nf_M7}, {nf_M10}')

      # 2. Create a design hierarchy
      dsn = laygo2.object.database.Design(name=cellname, libname=libname)
      lib.append(dsn)
      
      # 3. Create instances.
      print("Create instances")
      in0 = tnmos.generate(name='M7', params={'nf': nf_M7, 'tie': 'S', 'mosfet': 'nfet_01v8_0p42_nf2'}) # M7
      ip0 = tpmos.generate(name='M10', transform='MX', params={'nf': nf_M10, 'tie': 'S', 'mosfet': 'pfet_01v8_0p42_nf2'}) # M10
      
      pwell_0 = tpwell.generate(name='Pwell_M7', params={'nf': nf_M7}) # pwell for M7
      nwell_0 = tnwell.generate(name='Nwell_M10', transform='MX', params={'nf': nf_M10}) # nwell for M10

      # 4. Place instances.
      mn_M7 = [0,0]
      mn_M10 = pg.mn.top_left(in0) + pg.mn.height_vec(ip0) - np.array([int((nf_M10 - nf_M7)/2),0])  # in this approach, even when nf_M7 != nf_M10, the layout is still symmetric
      dsn.place(grid=pg, inst=in0, mn=[0,0])
      dsn.place(grid=pg, inst=ip0, mn=mn_M10)
      dsn.place(grid=pg, inst=pwell_0, mn=mn_M7) # pwell for M7
      dsn.place(grid=pg, inst=nwell_0, mn=mn_M10) # nwell for M10

      # 5. Create and place wires.
      print("Create wires")
      # IN
      mn_IN = [r23.mn(in0.pins['G'])[0], r23.mn(ip0.pins['G'])[0]]
      track_IN = [r23.mn(in0.pins['G'])[0,0]-1, None]
      rin0 = dsn.route_via_track(grid=r23, mn=mn_IN, track=track_IN)

      # OUT
      mn_OUT = [r23.mn(in0.pins['D'])[0], r23.mn(ip0.pins['D'])[0]]
      track_OUT = [r23.mn(in0.pins['D'])[1,0], None]
      rout0 = dsn.route_via_track(grid=r23, mn=mn_OUT, track=track_OUT)
      
      # VDD
      rvdd = dsn.route(grid=r12, mn=[r12.mn(ip0.pins['RAIL'])[0], r12.mn(ip0.pins['RAIL'])[1]])
      # VSS
      rvss = dsn.route(grid=r12, mn=[r12.mn(in0.pins['RAIL'])[0], r12.mn(in0.pins['RAIL'])[1]])
      
      # 6. Create pins.
      pin_I = dsn.pin(name='I', grid=r23, mn=r23.mn.bbox(rin0[2]))
      pin_O = dsn.pin(name='O', grid=r23, mn=r23.mn.bbox(rout0[2]))
      pin_VDD = dsn.pin(name='VDD', grid=r12, mn=r12.mn.bbox(rvdd))
      pin_VSS = dsn.pin(name='VSS', grid=r12, mn=r12.mn.bbox(rvss))

      # 7. Export to physical database.
      print("Export design")
      print("")
      
      # Magic TCL script export
      laygo2.interface.magic.export(lib, filename=ref_dir_MAG_exported +libname+'_'+cellname+'.tcl', cellname=None, libpath=ref_dir_layout, scale=1, reset_library=False, tech_library='sky130A')
      # 8. Export to a template database file.
      nat_temp = dsn.export_to_template()
      laygo2.interface.yaml.export_template(nat_temp, filename=ref_dir_template+libname+'_templates.yaml', mode='append')

if __name__ == "__main__":

    inverter(nf_M7=2, nf_M10=4)
    
    