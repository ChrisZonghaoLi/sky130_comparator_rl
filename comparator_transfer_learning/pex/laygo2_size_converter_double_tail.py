#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Feb  1 16:51:03 2024

@author: lizongh2

This is used to convert the optimal consinuous transistor size of double-tail comparator to discretized
LAYGO2 size, so that when doing Netgen, it wont complain about the size difference.
"""

import numpy as np
import re
import shutil 
import yaml

# extrac the transistor dimension parameters
with open(f'/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/comparator_transfer_learning/pex/simulations/double_tail_comp_tb_vars.spice', "r") as variables:
    params = variables.readlines()

W = []

for param in params:
    for i in range(0,len(param)):
        if param[i:i+5] == 'W_M1=':
            W_M1 = float(re.findall("\d+\.\d+", param)[0])
            W_M2 = W_M1
            W.append(['M1', W_M1, 'NMOS'])
        if param[i:i+5] == 'W_M3=':
            W_M3 = float(re.findall("\d+\.\d+", param)[0])
            W_M4 = W_M3
            W.append(['M3', W_M3, 'PMOS'])
        if param[i:i+5] == 'W_M5=':
            W_M5 = float(re.findall("\d+\.\d+", param)[0])
            W.append(['M5', W_M5, 'NMOS'])
        if param[i:i+5] == 'W_M6=':
            if float(re.findall(r'\b\d+\b', param)[0]) == 10: # in case if W6 is exceed the size limit
                W_M6 = 10
            else:
                W_M6 = float(re.findall("\d+\.\d+", param)[0])
            W_M9 = W_M6
            W.append(['M6', W_M6, 'NMOS'])
        if param[i:i+5] == 'W_M7=':
            W_M7 = float(re.findall("\d+\.\d+", param)[0])
            W_M8 = W_M7
            W.append(['M7', W_M7, 'NMOS'])
        if param[i:i+6] == 'W_M10=':
            W_M10 = float(re.findall("\d+\.\d+", param)[0])
            W_M11 = W_M10
            W.append(['M10', W_M10, 'PMOS'])
        if param[i:i+6] == 'W_M12=':
            W_M12 = float(re.findall("\d+\.\d+", param)[0])
            W.append(['M12', W_M12, 'PMOS'])
            
device_dict = {}
device_dict['circuit'] = 'double_tail'

for w in W:
    if w[1] >= 5.04:
        if w[2] == 'NMOS':
            mosfet = 'nfet_01v8_0p84_nf2'
        else:
            mosfet = 'pfet_01v8_0p84_nf2'
        w_discrete = round(w[1]/(0.84*2)) * (0.84*2) 
        nf = round(w[1]/(0.84*2)) * 2
    else:
        if w[2] == 'NMOS':
            mosfet = 'nfet_01v8_0p42_nf2'
        else:
            mosfet = 'pfet_01v8_0p42_nf2'
        w_discrete = round(w[1]/(0.42*2)) * (0.42*2) 
        nf = round(w[1]/(0.42*2)) * 2

    device_dict[w[0]] = {}
    device_dict[w[0]]['mosfet'] = mosfet
    device_dict[w[0]]['nf'] = nf
    device_dict[w[0]]['W_discrete'] = w_discrete
    device_dict[w[0]]['W_continuous'] = w[1]

# double-check if W6 is two times of W7
M6_nf = device_dict['M6']['nf']
M7_nf = device_dict['M7']['nf']
if M6_nf <= 2*M7_nf:
    M6_nf = 2 * M7_nf
    device_dict['M6']['nf'] = M6_nf

# generate a yaml file that contain the strong arm size info
with open('/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/comparator_transfer_learning/pex/laygo2_example/double_tail/double_tail_device_size.yaml', 'w') as outfile:
    yaml.dump(device_dict, outfile, default_flow_style=False)





