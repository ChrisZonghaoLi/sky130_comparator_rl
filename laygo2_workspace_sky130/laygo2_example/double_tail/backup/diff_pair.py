import numpy as np
import pprint
import laygo2
import laygo2.interface
import yaml
import laygo2_tech as tech 
import os

# Parameter definitions #############
# Variables
cell_type = ['diff_pair']
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
pg, r12, r12_pwr, r23 = grids[pg_name], grids[r12_name], grids[r12_pwr_name], grids[r23_name]
print(grids[pg_name], grids[r12_name], grids[r12_pwr_name], grids[r23_name], sep="\n")

lib = laygo2.object.database.Library(name=libname)

def diff_pair(nf_M1, nf_M3, nf_M5, 
                        M1, M3, M5,
                        cellname = 'diff_pair'):
    
      print('--------------------')
      print('Now Creating '+cellname)
      print(f'M1, M3, M5: {M1}, {M3}, {M5}')
      print(f'nf_M1, nf_M3, nf_M5: {nf_M1}, {nf_M3}, {nf_M5}')

      # 2. Create a design hierarchy
      dsn = laygo2.object.database.Design(name=cellname, libname=libname)
      lib.append(dsn)
      
      # 3. Create instances.
      print("Create instances")
      nf_M2 = nf_M1
      nf_M4 = nf_M3
      
      in0 = tnmos.generate(name='M5', params={'nf': nf_M5, 'tie': 'S', 'mosfet': 'nfet_01v8_0p42_nf2'}) # M5, tail NMOS
      in1 = tnmos.generate(name='M1', params={'nf': nf_M1, 'tie': 'S', 'mosfet': 'nfet_01v8_0p84_nf2'}) # M1, input
      in2 = tnmos.generate(name='M2', params={'nf': nf_M2, 'tie': 'S', 'mosfet': 'nfet_01v8_0p84_nf2'}) # M2, input
      in3 = tpmos.generate(name='M3', transform='MX', params={'nf': nf_M3, 'tie': 'S', 'mosfet': 'pfet_01v8_0p42_nf2'}) # M3, PMOS switch
      in4 = tpmos.generate(name='M4', transform='MX', params={'nf': nf_M4, 'tie': 'S', 'mosfet': 'pfet_01v8_0p42_nf2'}) # M4, PMOS switch
      
      ntap_0 = tntap.generate(name='Ntap_0', params={'nf': 2, 'tie': 'TAP0'})
      ntap_1 = tntap.generate(name='Ntap_1', params={'nf': 2, 'tie': 'TAP0'})
      ptap_0 = tptap.generate(name='Ptap_0', transform='MX', params={'nf': 2, 'tie': 'TAP0'})

      pwell_0 = tpwell.generate(name='Pwell_M5', params={'nf': nf_M5}) # pwell for M5
      pwell_1 = tpwell.generate(name='Pwell_M1', params={'nf': nf_M1}) # pwell for M1
      pwell_2 = tpwell.generate(name='Pwell_M2', params={'nf': nf_M2}) # pwell for M2
      pwell_3 = tpwell.generate(name='Pwell_fill1', params={'nf': 2}) # pwell fill
      pwell_4 = tpwell.generate(name='Pwell_fill2', params={'nf': 2}) # pwell fill
      pwell_5 = tpwell.generate(name='Pwell_fill3', params={'nf': 2}) # pwell fill
      nwell_0 = tnwell.generate(name='Nwell_M3', transform='MX', params={'nf': nf_M3}) # nwell for M3
      nwell_1 = tnwell.generate(name='Nwell_M4', transform='MX', params={'nf': nf_M4}) # nwell for M3
      nwell_2 = tnwell.generate(name='Nwell_fill', transform='MX', params={'nf': 2}) # nwell fill

      # 4. Place instances.
      mn_M5 = [0,0]
      dsn.place(grid=pg, inst=in0, mn=mn_M5) # placement of M5
      offset_in1 = int(nf_M5/2) * np.array([1,0])
      offset_in2 = np.array([1,0]) 
      mn_M1 = pg.mn.top_left(in0) - pg.mn.width_vec(in1) + offset_in1
      mn_M2 = pg.mn.top(in0)  + offset_in2
      dsn.place(grid=pg, inst=in1, mn=mn_M1) # placement of M1
      dsn.place(grid=pg, inst=in2, mn=mn_M2) # placement of M2
      # place pwell
      dsn.place(grid=pg, inst=pwell_0, mn=mn_M5) 
      dsn.place(grid=pg, inst=pwell_1, mn=mn_M1) 
      dsn.place(grid=pg, inst=pwell_2, mn=mn_M2) 
      dsn.place(grid=pg, inst=pwell_3, mn=pg.mn.bottom_right(in1)) 

      # placing PMOS
      mn_M3 = pg.mn.top_left(in1) + pg.mn.height_vec(in3) + pg.mn.width_vec(in1) - pg.mn.width_vec(in3) 
      dsn.place(grid=pg, inst=in3, mn=mn_M3) # placement of M3
      mn_M4 = pg.mn.top_left(in2) + pg.mn.height_vec(in3) 
      dsn.place(grid=pg, inst=in4, mn=mn_M4) # placement of M3
      # place pwell
      dsn.place(grid=pg, inst=nwell_0, mn=mn_M3) 
      dsn.place(grid=pg, inst=nwell_1, mn=mn_M4) 
      dsn.place(grid=pg, inst=nwell_2, mn=pg.mn.top_right(in3)) 

      # place ptaps for PMOS
      dsn.place(grid=pg, inst=ptap_0, mn=mn_M3 + pg.mn.width_vec(in3) - np.array([1,0]))  # np.array([1,0]) may subject to change if ptap_0 size also changes

      # placing Ntaps for NMOS
      mn_ntap_0 = mn_M5-pg.mn.width_vec(ntap_0)-np.array([2,0])
      mn_nyap_1 = mn_M5+pg.mn.width_vec(in0)+np.array([2,0])
      dsn.place(grid=pg, inst=ntap_0, mn=mn_ntap_0)
      dsn.place(grid=pg, inst=ntap_1, mn=mn_nyap_1)
       # fill up the Ntaps will pwell
      mn_pwell1 = pg.mn.bottom_right(ntap_0)
      mn_pwell2 = pg.mn.bottom_right(in0)
      dsn.place(grid=pg, inst=pwell_4, mn=mn_pwell1)
      dsn.place(grid=pg, inst=pwell_5, mn=mn_pwell2)

      # 5. Create and place wires.
      print("Create wires")
      # IN
      mn_Vin_p = [r12.mn(in1.pins['G'])[0], r12.mn(in1.pins['G'])[1]] 
      r_Vin_p = dsn.route(grid=r12, mn=mn_Vin_p)
      mn_Vin_n = [r12.mn(in2.pins['G'])[0], r12.mn(in2.pins['G'])[1]] 
      r_Vin_n = dsn.route(grid=r12, mn=mn_Vin_n)
      
      # CLK
      mn_CLK1 = [r12.mn(in0.pins['G'])[0], r12.mn(in0.pins['G'])[1]] 
      r_CLK1 = dsn.route(grid=r12, mn=mn_CLK1)
      # PMOS CLK
      mn_CLK2 = [r12.mn(in3.pins['G'])[0], r12.mn(in4.pins['G'])[1]] 
      r_CLK2 = dsn.route(grid=r12, mn=mn_CLK2)
      # wired up two CLK
      mn_CLK3 = [r23.mn.center(r_CLK1), r23.mn.center(r_CLK2)]
      r_CLK3 = dsn.route(grid=r23, mn=mn_CLK3, via_tag=[True, True])

      # M5 horizontal drain extension 
      extension_M5_drain = 3
      mn_M5_drain =  [np.array([r12.mn(in0.pins['D'])[0][0] - extension_M5_drain, r12.mn(in0.pins['D'])[0][1]]), 
                                      np.array([r12.mn(in0.pins['D'])[1][0] + extension_M5_drain, r12.mn(in0.pins['D'])[0][1]])]
      r_M5_drain = dsn.route(grid=r12, mn=mn_M5_drain)

      # M1 source connect to the M5 drain
      mn_M1_M5 =  [np.array([mn_M5_drain[0][0], mn_M5_drain[0][1]]),
                                     np.array([mn_M5_drain[0][0], r12.mn(in1.pins['RAIL'])[0][1]])]
      track_M1_M5 = [mn_M5_drain[0][0], None]
      r_M1_M5 = dsn.route_via_track(grid=r12, mn=mn_M1_M5, track=track_M1_M5)
      _mn_M1_M5 = [mn_M1_M5[1], r12.mn(in1.pins['RAIL'])[0]] # in case if M1 is way smaller than M5
      _r_M1_M5 = dsn.route(grid=r12, mn=_mn_M1_M5)
      
      # M2 source connect to the M5 drain
      mn_M2_M5 =  [np.array([mn_M5_drain[1][0], mn_M5_drain[1][1]]),
                                     np.array([mn_M5_drain[1][0], r12.mn(in2.pins['RAIL'])[0][1]])]
      track_M2_M5 = [mn_M5_drain[1][0], None]
      r_M2_M5 = dsn.route_via_track(grid=r12, mn=mn_M2_M5, track=track_M2_M5)
      _mn_M2_M5 = [mn_M2_M5[1], r12.mn(in2.pins['RAIL'])[1]] # in case if M2 is way smaller than M5
      _r_M2_M5 = dsn.route(grid=r12, mn=_mn_M2_M5)
      
      # M1 drain connect to latch stage
      extension_M1_drain_h = 2
      mn_M1_drain =  [r23.mn(in1.pins['D'])[1], 
                                      np.array([r23.mn(in1.pins['D'])[1][0] + extension_M1_drain_h, r23.mn(in3.pins['D'])[0][1]  ])]
      track_M1_drain = [mn_M1_drain[1][0], None]
      r_M1_drain = dsn.route_via_track(grid=r23, mn=mn_M1_drain, track=track_M1_drain)
      
      mn_M1_drain2 =  [r23.mn(in3.pins['D'])[1], 
                                       [mn_M1_drain[1][0], r23.mn(in3.pins['D'])[1][1]]]
      r_M1_drain2 = dsn.route(grid=r12, mn=mn_M1_drain2, via_tag=[True, False])
      

      # M2 drain connect to latch stage
      extension_M2_drain_h = 2 * int(nf_M2/2) # need to shift it back, depending on how many fingers it has
      mn_M2_drain =  [r23.mn(in2.pins['D'])[0], 
                                      np.array([r23.mn(in2.pins['D'])[1][0] - extension_M2_drain_h, r23.mn(in4.pins['D'])[0][1]  ])]
      track_M2_drain = [mn_M2_drain[1][0], None]
      r_M2_drain = dsn.route_via_track(grid=r23, mn=mn_M2_drain, track=track_M2_drain)
      
      mn_M2_drain2 =  [
          [mn_M2_drain[1][0], r23.mn(in4.pins['D'])[1][1]],
          [r23.mn(in4.pins['D'])[0][0], r23.mn(in4.pins['D'])[1][1]]
                                       ]  # this one is so tricky to get right, with current template, 'D' of M3/4 is not a point but a bbox... 
                                          # possibly because 'D' is sitting in between the grid, so cannot be snap to either point
      
      r_M2_drain2 = dsn.route(grid=r12, mn=mn_M2_drain2, via_tag=[False, True])
      
      # VSS
      r_VSS = dsn.route(grid=r12_pwr, mn=[r12_pwr.mn(ntap_0.pins['RAIL'])[0], r12_pwr.mn(ntap_1.pins['RAIL'])[1]])
      
      # VDD
      r_VDD = dsn.route(grid=r12_pwr, mn=[r12_pwr.mn(in3.pins['RAIL'])[0], r12_pwr.mn(in4.pins['RAIL'])[1]])
      
      # 6. Create pins.
      pin_CLK = dsn.pin(name='CLK', grid=r12, mn=r12.mn.bbox(r_CLK1)) # CLK
      pin_Vin_p = dsn.pin(name='Vin_p', grid=r12, mn=r12.mn.bbox(r_Vin_p)) # Vin_p
      pin_Vin_n = dsn.pin(name='Vin_n', grid=r12, mn=r12.mn.bbox(r_Vin_n)) # Vin_n   
      pin_Di_n = dsn.pin(name='Di_n', grid=r23, mn=r23.mn.bbox(r_M1_drain[2])) # Di_n   
      pin_Di_p = dsn.pin(name='Di_p', grid=r23, mn=r23.mn.bbox(r_M2_drain[2])) # Di_p   

      p_VSS = dsn.pin(name='VSS', grid=r12, mn=r12.mn.bbox(r_VSS))
      p_VDD = dsn.pin(name='VDD', grid=r12, mn=r12.mn.bbox(r_VDD))
      
      # 7. Export to physical database.
      print("Export design")
      print("")
      
      # Magic TCL script export
      laygo2.interface.magic.export(lib, filename=ref_dir_MAG_exported +libname+'_'+cellname+'.tcl', cellname=None, libpath=ref_dir_layout, scale=1, reset_library=False, tech_library='sky130A')
      # 8. Export to a template database file.
      nat_temp = dsn.export_to_template()
      laygo2.interface.yaml.export_template(nat_temp, filename=ref_dir_template+libname+'_templates.yaml', mode='append')

if __name__ == "__main__":
    # convert device size from continuous to discrete to be compatible with LAYGO2
    os.system('python laygo2_size_converter.py')
    ckt_fname = 'double_tail_device_size.yaml'
    with open(ckt_fname, 'r') as stream:
        try:
            device_info = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
    
    nf_M1 = device_info['M1']['nf']
    M1 = device_info['M1']['mosfet']
    nf_M3 = device_info['M3']['nf']
    M3 = device_info['M3']['mosfet']
    nf_M5 = device_info['M5']['nf']
    M5 = device_info['M5']['mosfet']

    # diff_pair(nf_M1=12, nf_M3=2, nf_M5=10)
    diff_pair(nf_M1=nf_M1, nf_M3=nf_M3, nf_M5=nf_M5)

    
    
    
    
    
    
    
