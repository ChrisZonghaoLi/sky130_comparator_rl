#!/usr/bin/python
########################################################################################################################
#
# Copyright (c) 2020, Nifty Chips Laboratory, Hanyang University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
# following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#   disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#    following disclaimer in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
########################################################################################################################

import numpy as np
import pprint
import laygo2
import laygo2.interface
import laygo2_tech as tech

# Parameter definitions ##############
# Templates
tpmos_name = 'pmos'
tnmos_name = 'nmos'
# Grids
pg_name = 'placement_basic'
r12_name = 'routing_12_cmos'
r23_name = 'routing_23_cmos'
# Design hierarchy
libname = 'thshin_65_to_40'
cellname = 'thshin_test'
# Design parameters
nf_a = 2
nf_b = 4
# End of parameter definitions #######

# Generation start ###################
# 1. Load templates and grids.
print("Load templates")
templates = tech.load_templates()
tpmos, tnmos = templates[tpmos_name], templates[tnmos_name]
print(templates[tpmos_name], templates[tnmos_name], sep="\n")

print("Load grids")
grids = tech.load_grids(templates=templates)
pg, r12, r23 = grids[pg_name], grids[r12_name], grids[r23_name]
print(grids[pg_name], grids[r12_name], grids[r23_name], sep="\n")

# 2. Create a design hierarchy.
lib = laygo2.object.database.Library(name=libname)
dsn = laygo2.object.database.Design(name=cellname, libname=libname)
lib.append(dsn)

# 3. Create instances.
print("Create instances")
in0 = tnmos.generate(name='MN0', params={'nf': nf_b, 'trackswap': False, 'tie': 'D', 'gbndl': True})
in1 = tnmos.generate(name='MN1', params={'nf': nf_b, 'trackswap': True, 'tie': 'D', 'gbndl': True})
in2 = tnmos.generate(name='MN2', params={'nf': nf_b, 'trackswap': True, 'tie': 'D', 'gbndl': True})
in3 = tnmos.generate(name='MN3', params={'nf': nf_b, 'trackswap': True, 'gbndl': True})
#in1 = tnmos.generate(name='MN1', params={'nf': nf_a, 'gbndr': True})
#ip0 = tpmos.generate(name='MP0', transform='MX', params={'nf': nf_b, 'tie': 'S',11gbndl': True})
#ip1 = tpmos.generate(name='MP1', transform='MX', params={'nf': nf_a, 'trackswap': True, 'tie': 'D', 'gbndr': True})

# 4. Place instances.
dsn.place(grid=pg, inst=in0, mn=pg.mn[0, 0])
dsn.place(grid=pg, inst=in1, mn=pg.mn.bottom_right(in0)+np.array([2, 0]))  # same with pg == in0.bottom_right
dsn.place(grid=pg, inst=in2, mn=pg.mn.top_left(in1)+np.array([0, 4]))  # same with pg == in0.bottom_right
dsn.place(grid=pg, inst=in3, mn=pg.mn.bottom_right(in2)+np.array([2, 0]))  # same with pg == in0.bottom_right

#dsn.place(grid=pg, inst=ip0, mn=pg.mn.top_left(in0) + pg.mn.height_vec(ip0))  # +height_vec due to MX transform
#dsn.place(grid=pg, inst=ip1, mn=pg.mn.top_right(ip0))

# 5. Create and place wires.
print("Create wires")
# A
#_mn = [r23.mn(in1.pins['G'])[0], r23.mn(ip1.pins['G'])[0]]
#va0, ra0, va1 = dsn.route(grid=r23, mn=_mn, via_tag=[True, True])
# B
#_mn = [r23.mn(in0.pins['G'])[0], r23.mn(ip0.pins['G'])[0]]
#vb0, rb0, vb1 = dsn.route(grid=r23, mn=_mn, via_tag=[True, True])
# Internal
#_mn = [r12.mn(in0.pins['S'])[0], r12.mn(in1.pins['D'])[0]]
#ri0 = dsn.route(grid=r23, mn=_mn)
#_mn = [r12.mn(ip0.pins['D'])[0], r12.mn(ip1.pins['S'])[0]]
#ri1 = dsn.route(grid=r23, mn=_mn)
# Output
#_mn = [r23.mn(in1.pins['S'])[1], r23.mn(ip1.pins['S'])[1]]
#_track = [r23.mn(ip1.pins['S'])[1, 0], None]
#_, vo0, ro0, vo1, _= dsn.route_via_track(grid=r23, mn=_mn, track=_track)
# VSS
#rvss0 = dsn.route(grid=r12, mn=[r12.mn(in0.pins['RAIL'])[0], r12.mn(in1.pins['RAIL'])[1]])
# VDD
#rvdd0 = dsn.route(grid=r12, mn=[r12.mn(ip0.pins['RAIL'])[0], r12.mn(ip1.pins['RAIL'])[1]])

# 6. Create pins.
#pa0 = dsn.pin(name='A', grid=r23, mn=r23.mn.bbox(ra0))
#pb0 = dsn.pin(name='B', grid=r23, mn=r23.mn.bbox(rb0))
#po0 = dsn.pin(name='O', grid=r23, mn=r23.mn.bbox(ro0))
#pvss0 = dsn.pin(name='VSS', grid=r12, mn=r12.mn.bbox(rvss0))
#pvdd0 = dsn.pin(name='VDD', grid=r12, mn=r12.mn.bbox(rvdd0))

# 7. Export to physical database.
print("Export design")
print(dsn)
# Uncomment for GDS export
"""
#abstract = False  # export abstract
#laygo2.interface.gds.export(lib, filename=libname+'_'+cellname+'.gds', cellname=None, scale=1e-9,
#                            layermapfile="../technology_example/technology_example.layermap", physical_unit=1e-9, logical_unit=0.001,
#                            pin_label_height=0.1, pin_annotate_layer=['text', 'drawing'], text_height=0.1,
#                            abstract_instances=abstract)
"""

# Uncomment for SKILL export
"""
#skill_str = laygo2.interface.skill.export(lib, filename=libname+'_'+cellname+'.il', cellname=None, scale=1e-3)
#print(skill_str)
"""

# Uncomment for BAG export
laygo2.interface.bag.export(lib, filename=libname+'_'+cellname+'.il', cellname=None, scale=1e-3, reset_library=False, tech_library=tech.name)

# 7-a. Import the GDS file back and display
#with open('nand_generate.gds', 'rb') as stream:
#    pprint.pprint(laygo2.interface.gds.readout(stream, scale=1e-9))

# 8. Export to a template database file.
nat_temp = dsn.export_to_template()
laygo2.interface.yaml.export_template(nat_temp, filename=libname+'_templates.yaml', mode='append')

