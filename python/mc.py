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

from ckt_graphs import GraphDoubleTailComp
from dev_params import DeviceParams

PWD = os.getcwd()
SPICE_NETLIST_DIR = '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/xschem/simulations'

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

Vcm = 1.197699210047722
time, Vsc_mc = OutputParser(GraphDoubleTailComp()).tran('double_tail_comp_tb_Vsc_mc_opt3')
_, Voutn_mc = OutputParser(GraphDoubleTailComp()).tran('double_tail_comp_tb_Voutn_mc_opt3')
_, Voutp_mc = OutputParser(GraphDoubleTailComp()).tran('double_tail_comp_tb_Voutp_mc_opt3')

W_M1 = 9.73683432996273e-06
L_M1 = 0.18e-6
W_M2 = W_M1
L_M2 = L_M1

results = OutputParser(GraphDoubleTailComp())
op_results = results.dcop('double_tail_comp_tb_op_opt3') # no mismatch variation, no process vatiation

Vgs_M1 = op_results['M1']['vgs']
Vds_M1 = op_results['M1']['vds']
Vgs_M2 = op_results['M2']['vgs']
Vds_M2 = op_results['M2']['vds']
Vth_M1 = op_results['M1']['vth']
Vth_M2 = op_results['M2']['vth']

time = np.array(time)
Vsc_mc = np.array(Vsc_mc)
Voutn_mc = np.array(Voutn_mc)
Voutp_mc = np.array(Voutp_mc)

time_idx = [i for i in range(len(time)) if time[i]==0]
mc_run = len(time_idx)
Voffset_r_mc = []
Voffset_f_mc = []

'''' find offset '''
for i in range(mc_run-1):
    a = Vsc_mc[time_idx[i] : time_idx[i+1]]

    Vout = Voutp_mc[time_idx[i] : time_idx[i+1]] - Voutn_mc[time_idx[i] : time_idx[i+1]]
    eps = 0.1 # +/- 0.1V as the sign discriminator
    sign = Vout > eps

    try:
        idx_r = np.where(sign == True)[0][0]
        idx_f = np.where(sign == True)[0][-1]
        Voffset_r = a[idx_r] - Vcm
        Voffset_f = a[idx_f] - Vcm
    except:
        pass

    Voffset_r_mc.append(Voffset_r)
    Voffset_f_mc.append(Voffset_f)

Voffset_r_mc = np.array(Voffset_r_mc)    
Voffset_f_mc = np.array(Voffset_f_mc)

bins = np.linspace(-60, 60, 60)
bins_centers = (bins[:-1] + bins[1:]) / 2
Voffset_r_count, _ , _ = plt.hist(Voffset_r_mc*1e3, bins)
Voffset_f_count, _ , _ = plt.hist(Voffset_f_mc*1e3, bins)

def Gauss(x, A, mu, sigma):
    return A * np.exp(-(x - mu) ** 2 / (2 * sigma ** 2))

popt_Voffset_r, pcov = curve_fit(Gauss, bins_centers, Voffset_r_count) #popt returns the best fit values for parameters of the given model (func)
ym_r = Gauss(bins_centers, popt_Voffset_r[0], popt_Voffset_r[1], popt_Voffset_r[2])
mean_Voffset_r_fit, Voffset_r_fit = popt_Voffset_r[1], popt_Voffset_r[2]

plt.figure('Voffset rising')
plt.plot(bins_centers, ym_r, c='r', label='Best fit')
plt.hist(Voffset_r_mc*1e3, bins)
plt.xlabel('$V_{offset}$ (mV)')
plt.ylabel('Count (out=high)')
plt.grid(True)

popt_Voffset_f, pcov = curve_fit(Gauss, bins_centers, Voffset_f_count) #popt returns the best fit values for parameters of the given model (func)
ym_f = Gauss(bins_centers, popt_Voffset_f[0], popt_Voffset_f[1], popt_Voffset_f[2])
mean_Voffset_f_fit, Voffset_f_fit = popt_Voffset_f[1], popt_Voffset_f[2]

plt.figure('Voffset falling')
plt.plot(bins_centers, ym_f, c='r', label='Best fit')
plt.hist(Voffset_f_mc*1e3, bins)
plt.xlabel('$V_{offset}$ (mV)')
plt.ylabel('Count (out=low)')
plt.grid(True)

Voffset_fit = (Voffset_r_fit + Voffset_f_fit) / 2 # in mV

''' Calculate mismatch analytically in SKY130 '''

def random_mismatch(W, L, par=1):
    if L == 0.15e-6: # bin31
        if W == 7e-6:
            A_th = 7.356e-03 
    elif L == 4e-6: # bin29
        if W == 7e-6:
            A_th = 7.356e-03
    elif L == 4e-6: # bin38
        if W == 0.42e-6:
            A_th = 7.356e-03
    else: # others
        A_th = 3.356e-03

    A_tox = 3.443e-03
    tox = 4.148e-009 # meter
    
    sigma_Vth = A_th / (W*1e6 * L*1e6)**0.5
    sigma_tox = A_tox * tox / (W*1e6 * L*1e6)**0.5

    return sigma_Vth, sigma_tox

par = 1
sigma_Vth_M1, sigma_tox_M1 = random_mismatch(W_M1, L_M1)
sigma_Vth_M2 = sigma_Vth_M1
sigma_tox_M2 = sigma_tox_M1

def random_mismatch_M1M2(W_M1, L_M1,
                        W_M2, L_M2,
                        Vgs_M1, Vds_M1, Vth_M1,
                        Vgs_M2, Vds_M2, Vth_M2,
                        sigma_Vth_M1, sigma_tox_M1,  
                        sigma_Vth_M2, sigma_tox_M2):

    tox = 4.148e-009 # meter
    epsilon_SiO2 = 3.9
    epsilon_0 = 8.854e-12 # permitivity of free space, F/m
    Cox = epsilon_0 * epsilon_SiO2 / tox
    
    Vth = Vth_M1
        
    KVth_1 = -Vds_M2 / Vds_M1
    KVth_2 = -1
    
    Kz = (Vds_M2 / Vds_M1) * (Vgs_M2 - Vth - Vds_M2/2)
    sigma_z = np.sqrt(sigma_tox_M1**2 + sigma_tox_M2**2) / tox
    
    total_offset = (KVth_1**2 * sigma_Vth_M1**2 + KVth_2**2 * sigma_Vth_M2**2 + Kz**2 * sigma_z**2)**0.5
    Vth_offset = (KVth_1**2 * sigma_Vth_M1**2 + KVth_2**2 * sigma_Vth_M2**2)**0.5
    tox_offset = (Kz**2 * sigma_z**2)**0.5

    return total_offset, Vth_offset, tox_offset

total_offset, Vth_offset, tox_offset = random_mismatch_M1M2(W_M1, L_M1,
                                                            W_M2, L_M2,
                                                            Vgs_M1, Vds_M1, Vth_M1,
                                                            Vgs_M2, Vds_M2, Vth_M2,
                                                            sigma_Vth_M1, sigma_tox_M1,  
                                                            sigma_Vth_M2, sigma_tox_M2)