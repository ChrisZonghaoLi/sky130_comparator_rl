import numpy as np
import pprint
import laygo2
import laygo2.interface
import laygo2_tech as tech 
import yaml
import os

# Parameter definitions #############
# Variables
cell_type = ['switches']
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

def switches(nf_M8, nf_M10,
                         M8, M10, cellname = 'switches'):

      print('--------------------')
      print('Now Creating '+cellname)
      print('Now Creating '+cellname)
      print(f'M8, M10: {M8}, {M10}')
      print(f'nf_M8, nf_M10: {nf_M8}, {nf_M10}')
      
      # 2. Create a design hierarchy
      dsn = laygo2.object.database.Design(name=cellname, libname=libname)
      lib.append(dsn)
      
      # 3. Create instances.
      print("Create instances")
      # nf_M8 = 2
      # nf_M10 = 6 
      ip0 = tpmos.generate(name='M8', transform='MX', params={'nf': nf_M8, 'tie': 'S', 'mosfet': M8}) # M8
      ip1 = tpmos.generate(name='M10', transform='MX', params={'nf': nf_M10, 'tie': 'S', 'mosfet': M10}) # M10

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
      
      # VDD
      rvdd0 = dsn.route(grid=r12, mn=[r12.mn(ip1.pins['RAIL'])[0], r12.mn(ip0.pins['RAIL'])[1]])
      
      # 6. Create pins.
      pin_CLK = dsn.pin(name='CLK', grid=r12, mn=r12.mn.bbox(r_CLK)) # CLK
      pin_VDD = dsn.pin(name='VDD', grid=r12, mn=r12.mn.bbox(rvdd0))
      pin_O = dsn.pin(name='O', grid=r23, mn=r23.mn.bbox(ip0.pins['D']))
      pin_Di = dsn.pin(name='Di', grid=r23, mn=r23.mn.bbox(ip1.pins['D']))

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
    ckt_fname = 'strong_arm_device_size.yaml'
    with open(ckt_fname, 'r') as stream:
        try:
            device_info = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
    
    nf_M8 = device_info['M8']['nf']
    M8 = device_info['M8']['mosfet']
    nf_M10 = device_info['M10']['nf']
    M10 = device_info['M10']['mosfet']

    switches(nf_M8=nf_M8, nf_M10=nf_M10, 
                    M8=M8, M10=M10)
