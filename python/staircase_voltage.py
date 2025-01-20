#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This script is used to generate the staircase voltage ramp to test comparators. It will generate a PWL
source file that can be loaded by Ngspice in the netlist. 
"""

import numpy as np
import os

import matplotlib.pyplot as plt
plt.style.use(style='default')
plt.rcParams['lines.linewidth'] = 2
plt.rcParams["font.weight"] = "bold"
plt.rcParams["axes.labelweight"] = "bold"
plt.rcParams["axes.axisbelow"] = False
plt.rc('axes', axisbelow=True)

PWD = os.getcwd()
SPICE_NETLIST_DIR = f'{PWD}/simulations'

# generate the time stride. Amplitude between time points will be interpolated
# noted that the time step in the tran simulation should be larger than (say x10) the time stride here,
# otherwise the interpolation will overwrite the staircase and becomes linear ramp.
time = np.linspace(0,1e-6,100001)
time_stride =  time[1] - time[0]
Tclk = 1/1e9
Tclk_count = int(Tclk / time_stride)

# Vcm = 1.0683653097599746 
Vramp_start = -1e-3
Vramp_pk = 1e-3

rise_count = int(( 100001 / 2)  /  Tclk_count) # how many cycles within the rising time
fall_count = rise_count 

Vramp_res = (Vramp_pk - Vramp_start) / rise_count # each staircase voltage size, resolution

Vramp_rise = []
for i in range(rise_count):
    Vramp = np.ones(Tclk_count) + (i-1)*1
    Vramp_rise.append(Vramp)
    
Vramp_rise = np.array(Vramp_rise).flatten() * Vramp_res + Vramp_start
Vramp_fall = np.flip(Vramp_rise)
Vramp_fall = np.append(Vramp_fall, Vramp_start)
Vramp = np.concatenate((Vramp_rise, Vramp_fall))

data = np.column_stack([time, Vramp])

save_path = SPICE_NETLIST_DIR + '/staircase_voltage_hysteresis.txt'
np.savetxt(save_path , data, fmt=['%.8e','%.8e'])

















