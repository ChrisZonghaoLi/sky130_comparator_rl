#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Sep 29 17:12:55 2023

@author: lizongh2
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

from scipy.optimize import curve_fit

from ckt_graphs import GraphDoubleTailComp, GraphStrongArmComp
from dev_params import DeviceParams

PWD = os.getcwd()
SPICE_NETLIST_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/xschem/simulations'

NETLIST_NAME = 'strong_arm_comp_tb'
CktGraph = GraphStrongArmComp

class OutputParser(DeviceParams):
    
    def __init__(self, CktGraph):
        self.ckt_hierarchy = CktGraph.ckt_hierarchy
        self.op = CktGraph.op
        super().__init__(self.ckt_hierarchy)

    def ac(self, file_name):
        # AC analysis result parser
        try:
            ldo_tb_ac = open(f'{SPICE_NETLIST_DIR}/{file_name}', 'r')
            lines_ac = ldo_tb_ac.readlines()
            freq = []
            Vout_mag = []
            Vout_ph = []
            for line in lines_ac:
                Vac = line.split(' ')
                Vac = [i for i in Vac if i != '']
                freq.append(float(Vac[0]))
                Vout_mag.append(float(Vac[1]))
                Vout_ph.append(float(Vac[3]))
            return freq, Vout_mag, Vout_ph
        except:
            print("Simulation errors, no .AC simulation results.")
            
    def dc(self, file_name):
        # DC analysis result parser
        try:
            ldo_tb_dc = open(f'{SPICE_NETLIST_DIR}/{file_name}', 'r')
            lines_dc = ldo_tb_dc.readlines()
            Vin_dc = []
            Vout_dc = []
            for line in lines_dc:
                Vdc = line.split(' ')
                Vdc = [i for i in Vdc if i != '']
                Vin_dc.append(float(Vdc[0]))
                Vout_dc.append(float(Vdc[1])) 
    
            dx = Vin_dc[1] - Vin_dc[0]
            dydx = np.gradient(Vout_dc, dx)
            
            return Vin_dc, Vout_dc
        except:
            print("Simulation errors, no .OP simulation results.")
      
    def tran(self, file_name):
        # Transient analysis result parser
        try:
            ldo_tb_tran = open(f'{SPICE_NETLIST_DIR}/{file_name}', 'r')
            lines_tran = ldo_tb_tran.readlines()
            time = []
            Vout_tran = []
            for line in lines_tran:
                line = line.split(' ')
                line = [i for i in line if i != '']
                time.append(float(line[0]))
                Vout_tran.append(float(line[1])) 
            
            return time, Vout_tran
        except:
                print("Simulation errors, no .TRAN simulation results.")

            
    def dcop(self, file_name):
        # DCOP analysis result parser
        try:
            ldo_tb_op = open(f'{SPICE_NETLIST_DIR}/{file_name}', 'r')
            # ldo_tb_op = open(f'{file_dir}', 'r')
            lines_op = ldo_tb_op.readlines()
            for index, line in enumerate(lines_op):
                if line == "Values:\n":
                    # print(f"{index}") # catch the index where the dcop values start
                    start_idx = index
            _lines_op = lines_op[start_idx+2:-1] 
            lines_op = []
            for _line in _lines_op:
                lines_op.append(float(_line.split('\n')[0].split('\t')[1]))
            
            num_dev = len(self.ckt_hierarchy)
            num_dev_params_mos = len(self.params_mos)
            num_dev_params_r = len(self.params_r)
            num_dev_params_c = len(self.params_c)
            num_dev_params_i = len(self.params_i)
            num_dev_params_v = len(self.params_v)
            
            idx = 0
            for i in range(num_dev):
                dev_type = self.ckt_hierarchy[i][3]
                if dev_type == 'm' or dev_type == 'M':
                    for j in range(num_dev_params_mos):
                        param = self.params_mos[j]
                        self.op[list(self.op)[i]][param] = lines_op[idx+j]
                    idx = idx + num_dev_params_mos
                elif dev_type == 'r' or dev_type == 'R':
                    for j in range(num_dev_params_r):
                        param = self.params_r[j]
                        self.op[list(self.op)[i]][param] = lines_op[idx+j]
                    idx = idx + num_dev_params_r
                elif dev_type == 'c' or dev_type == 'C':
                    for j in range(num_dev_params_c):
                        param = self.params_c[j]
                        self.op[list(self.op)[i]][param] = lines_op[idx+j]
                    idx = idx + num_dev_params_c
                elif dev_type == 'i' or dev_type == 'I':
                    for j in range(num_dev_params_i):
                        param = self.params_i[j]
                        self.op[list(self.op)[i]][param] = lines_op[idx+j]
                    idx = idx + num_dev_params_i
                elif dev_type == 'v' or dev_type == 'V':
                    for j in range(num_dev_params_v):
                        param = self.params_v[j]
                        self.op[list(self.op)[i]][param] = lines_op[idx+j]
                    idx = idx + num_dev_params_v
                else:
                    None
            
            return self.op
        except:
            print("Simulation errors, no .OP simulation results.")

Vcm = 1.0683653097599746
time, Vsc_hy = np.array(OutputParser(CktGraph()).tran(f'{NETLIST_NAME}_Vsc_hy_opt_final'))
_, Voutn_hy = np.array(OutputParser(CktGraph()).tran(f'{NETLIST_NAME}_Voutn_hy_opt_final'))
_, Voutp_hy = np.array(OutputParser(CktGraph()).tran(f'{NETLIST_NAME}_Voutp_hy_opt_final'))

'''' find hysteresis '''

Vout = Voutp_hy - Voutn_hy
if NETLIST_NAME == 'double_tail_comp_tb':
    eps = 0.1 # +/- 0.1V as the sign discriminator
    sign = Vout > eps
if NETLIST_NAME == 'strong_arm_comp_tb':
    eps = 0.1 # +/- 0.1V as the sign discriminator
    sign = Vout > eps

try:
    idx_r = np.where(sign == True)[0][0]
    idx_f = np.where(sign == True)[0][-1]
    V_hy_r = Vsc_hy[idx_r]
    V_hy_f = Vsc_hy[idx_f]
except:
    pass

V_hy = abs(V_hy_r) - abs(V_hy_f)










