#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 11 15:29:20 2023

@author: lizongh2
"""

import numpy as np
import os
import json
from tabulate import tabulate
import gymnasium as gym
from gymnasium import spaces

from ckt_graphs import GraphStrongArmComp 
from dev_params import DeviceParams
from utils import ActionNormalizer, OutputParser

from datetime import datetime

date = datetime.today().strftime('%Y-%m-%d')

PWD = os.getcwd()
SPICE_NETLIST_DIR = f'{PWD}/simulations'
NETLIST_NAME = 'strong_arm_comp_tb'
NETLIST_PEX_NAME = 'strong_arm_comp_pex_tb'
os.environ['CUDA_LAUNCH_BLOCKING'] = "1"

CktGraph = GraphStrongArmComp

class StrongArmCompEnv(gym.Env, CktGraph, DeviceParams):

    def __init__(self):
        gym.Env.__init__(self)
        CktGraph.__init__(self)
        DeviceParams.__init__(self, self.ckt_hierarchy)

        self.CktGraph = CktGraph()
        self.observation_space = spaces.Box(low=-np.inf, high=np.inf, shape=self.obs_shape, dtype=np.float64)
        self.action_space = spaces.Box(low=-1, high=1, shape=self.action_shape, dtype=np.float64)
        
    def _initialize_simulation(self):
        self.W_M1, self.W_M3, self.W_M5, self.W_M7, self.W_M8, self.W_M10, self.Vcm= \
        np.array([1, 1, 1, 1, 1, 1, 1.1]) 
        # self.Vcm: initial input common-mode voltage

        """Run the initial simulations."""  
        action = np.array([self.W_M1, self.W_M3, self.W_M5, self.W_M7, self.W_M8, self.W_M10, self.Vcm])
        
        self.do_simulation(action)
        
    def _do_simulation(self, action: np.array):
        """
         W_M1 = W_M2, 
         W_M3 = W_M4,
         W_M6 = W_M5,
         W_M9 = W_M8,
         W_M10 = W_M11
        """ 
        W_M1, W_M3, W_M5, W_M7, W_M8, W_M10, Vcm = action 
            
        CL = self.CktGraph.CL
        Vin = self.CktGraph.Vin
        Tclk = self.CktGraph.Tclk
        Tclk_pk = self.CktGraph.Tclk_pk
        Tdelay = self.CktGraph.Tdelay
        Tr = self.CktGraph.Tr
        Tf = self.CktGraph.Tf
        VDD = self.CktGraph.VDD
        Vin_min = self.Vin_min_spec

        # update netlist
        try:
            # open the netlist of the testbench
            comp_tb_vars = open(f'{SPICE_NETLIST_DIR}/{NETLIST_NAME}_vars.spice', 'r')
            lines = comp_tb_vars.readlines()
            
            lines[0] = f'.param W_M1={W_M1}\n'
            lines[1] = f'.param W_M3={W_M3}\n'
            lines[2] = f'.param W_M5={W_M5}\n'
            lines[3] = f'.param W_M7={W_M7}\n'
            lines[4] = f'.param W_M8={W_M8}\n'
            lines[5] = f'.param W_M10={W_M10}\n'
            lines[11] = f'.param Vcm={Vcm}\n'
            lines[12] = f'.param VDD={VDD}\n'
            lines[13] = f'.param Vin={Vin}\n'
            lines[14] = f'.param Vin_min={Vin_min}\n'
            lines[15] = f'.param CL={CL}\n'
            lines[16] = f'.param Tclk={Tclk}\n'
            lines[17] = f'.param Tclk_pk={Tclk_pk}\n'
            lines[18] = f'.param Tdelay={Tdelay}\n'
            lines[19] = f'.param Tr={Tr}\n'
            lines[20] = f'.param Tf={Tf}\n'            

            comp_tb_vars = open(f'{SPICE_NETLIST_DIR}/{NETLIST_NAME}_vars.spice', 'w')
            comp_tb_vars.writelines(lines)
            comp_tb_vars.close()
            
            print('*** Simulations for Comparator, run DCOP analysis only***')
            os.system(f'cd {SPICE_NETLIST_DIR}; ngspice -b -o {NETLIST_NAME}.log {NETLIST_NAME}.spice')
            
            print('*** Run LAYGO2 to generate layout, then do LVS and DRC check and extract PEX layout ***')
            os.system(f'cd {PWD}/laygo2_example/double_tail; ipython double_tail.py')
            
            print(('*** Run ngspice for the PEX netlist ***'))
            os.system(f'cd {SPICE_NETLIST_DIR}; ngspice -b -o {NETLIST_PEX_NAME}.log {NETLIST_PEX_NAME}.spice')
        except:
            print('ERROR')

    def do_simulation(self, action):
        self._do_simulation(action)
        self.sim_results = OutputParser(self.CktGraph)
        self.op_results = self.sim_results.dcop(file_name=f'{NETLIST_NAME}_op')

    def reset(self, seed=None, options=None):
        super().reset(seed=seed)
        self._initialize_simulation()
        observation = self._get_obs()
        info = self._get_info()

        return observation, info
    
    def close(self):
        return None
    
    def step(self, action):
        action = ActionNormalizer(action_space_low=self.action_space_low, action_space_high = \
                                       self.action_space_high).action(action) # convert [-1.1] range back to normal range
        action = action.astype(object)
        
        print(f"action: {action}")
        
        self.W_M1, self.W_M3, self.W_M5, self.W_M7, self.W_M8, self.W_M10, self.Vcm = action
        
        ''' run simulations '''
        self.do_simulation(action)
        
        ''' get observation '''
        observation = self._get_obs()
        info = self._get_info()
        
        reward = self.reward
        
        if reward >= 0:
            terminated = True
        else:
            terminated = False
            
        print(tabulate(
            [
                ['Clock-2-Q delay (ns)', self.Clk2Q*1e9, f'<={self.Clk2Q_spec*1e9}'],
                ['Max |Vout| (V)', np.max(np.abs(self.Vout)), f'>={0.5*self.VDD}'],
                ['Input offset voltage Vos (mV)', 1e3*self.Vos, f'<={1e3*self.Vos_spec}'],
                ['Energy consumption (fJ/conversion)', self.E_cycle*1e15, f'<={1e15*self.E_cycle_spec}'],
                ['Peak input voltage error due to kickback noise (mV)', self.V_kn_pk*1e3, f'<={1e3*self.V_kn_pk_spec}'],
                ['Decision time at Vin_min without being metastable (ps)', self.t_decision*1e12, f'<={1e12*self.Tclk/2}'],
                ['-----', '-----', '-----'],
                ['Vout reset score (Vout should be reset during reset phase)', self.Vout_reset_score, '=0'],
                ['Vdi reset score (Vdi should be reset during reset phase)', self.Vdi_reset_score, '=0'],
                ['Vout score (needs to be larger than VDD/2)', self.Vout_score,'=0'],
                ['-----', '-----', '-----'],
                ['Clock-2-Q delay score', self.Clk2Q_score,'>=0'],
                ['Vos score', self.Vos_score,'>=0'],
                ['Energy consumption score', self.E_cycle_score,'>=0'],
                ['Kickback noise score', self.kn_score,'>=0'],
                ['Metastability score', self.ms_score,'>=0'],
                ['-----', '-----', '-----'],
                ['Reward', reward, '>=0']
                ],
            headers=['param', 'num', 'target'], tablefmt='orgtbl', numalign='right', floatfmt=".2f"
            ))

        return observation, reward, terminated, False, info
        
    def _get_obs(self):
        # pick some .OP params from the dict:
        try:
            f = open(f'{SPICE_NETLIST_DIR}/{NETLIST_NAME}_op_mean_std.json')
            self.op_mean_std = json.load(f)
            self.op_mean = self.op_mean_std['OP_M_mean']
            self.op_std = self.op_mean_std['OP_M_std']
            self.op_mean = np.array([self.op_mean['id'], self.op_mean['gm'], self.op_mean['gds'], self.op_mean['vth'], self.op_mean['vdsat'], self.op_mean['vds'], self.op_mean['vgs']])
            self.op_std = np.array([self.op_std['id'], self.op_std['gm'], self.op_std['gds'], self.op_std['vth'], self.op_std['vdsat'], self.op_std['vds'], self.op_std['vgs']])
        except:
            print('You need to run <_random_op_sims> to generate mean and std for transistor .OP parameters')
        
        self.OP_M1 = self.op_results['M1']
        self.OP_M1_norm = (np.array([self.OP_M1['id'],
                                self.OP_M1['gm'],
                                self.OP_M1['gds'],
                                self.OP_M1['vth'],
                                self.OP_M1['vdsat'],
                                self.OP_M1['vds'],
                                self.OP_M1['vgs']
                                ]) - self.op_mean)/self.op_std
        
        self.OP_M3 = self.op_results['M3']
        self.OP_M3_norm = (np.array([self.OP_M3['id'],
                                self.OP_M3['gm'],
                                self.OP_M3['gds'],
                                self.OP_M3['vth'],
                                self.OP_M3['vdsat'],
                                self.OP_M3['vds'],
                                self.OP_M3['vgs']
                                ]) - self.op_mean)/self.op_std
        
        self.OP_M5 = self.op_results['M5']
        self.OP_M5_norm = (np.abs([self.OP_M5['id'],
                                self.OP_M5['gm'],
                                self.OP_M5['gds'],
                                self.OP_M5['vth'],
                                self.OP_M5['vdsat'],
                                self.OP_M5['vds'],
                                self.OP_M5['vgs']
                                ]) - self.op_mean)/self.op_std
        
        self.OP_M7 = self.op_results['M7']
        self.OP_M7_norm = (np.abs([self.OP_M7['id'],
                                self.OP_M7['gm'],
                                self.OP_M7['gds'],
                                self.OP_M7['vth'],
                                self.OP_M7['vdsat'],
                                self.OP_M7['vds'],
                                self.OP_M7['vgs']
                                ]) - self.op_mean)/self.op_std
        
        self.OP_M8 = self.op_results['M8']
        self.OP_M8_norm = (np.array([self.OP_M8['id'],
                                self.OP_M8['gm'],
                                self.OP_M8['gds'],
                                self.OP_M8['vth'],
                                self.OP_M8['vdsat'],
                                self.OP_M8['vds'],
                                self.OP_M8['vgs']
                                ]) - self.op_mean)/self.op_std
        
        self.OP_M10 = self.op_results['M10']
        self.OP_M10_norm = (np.array([self.OP_M10['id'],
                                self.OP_M10['gm'],
                                self.OP_M10['gds'],
                                self.OP_M10['vth'],
                                self.OP_M10['vdsat'],
                                self.OP_M10['vds'],
                                self.OP_M10['vgs']
                                ]) - self.op_mean)/self.op_std
        
        # state shall be in the order of node (M1,M2,M3,M4,M5,M6,M7,M8,M9,M10,M11)
        # it is a symmatric circuits: M1 and M2, M3 and M4, M6 and M5, M9 and M8, M10 and M11
        observation = np.array([
                               [self.OP_M1_norm[0],self.OP_M1_norm[1],self.OP_M1_norm[2],self.OP_M1_norm[3],self.OP_M1_norm[4],self.OP_M1_norm[5],self.OP_M1_norm[6]],
                               [self.OP_M1_norm[0],self.OP_M1_norm[1],self.OP_M1_norm[2],self.OP_M1_norm[3],self.OP_M1_norm[4],self.OP_M1_norm[5],self.OP_M1_norm[6]],
                               [self.OP_M3_norm[0],self.OP_M3_norm[1],self.OP_M3_norm[2],self.OP_M3_norm[3],self.OP_M3_norm[4],self.OP_M3_norm[5],self.OP_M3_norm[6]],
                               [self.OP_M3_norm[0],self.OP_M3_norm[1],self.OP_M3_norm[2],self.OP_M3_norm[3],self.OP_M3_norm[4],self.OP_M3_norm[5],self.OP_M3_norm[6]],
                               [self.OP_M5_norm[0],self.OP_M5_norm[1],self.OP_M5_norm[2],self.OP_M5_norm[3],self.OP_M5_norm[4],self.OP_M5_norm[5],self.OP_M5_norm[6]],
                               [self.OP_M5_norm[0],self.OP_M5_norm[1],self.OP_M5_norm[2],self.OP_M5_norm[3],self.OP_M5_norm[4],self.OP_M5_norm[5],self.OP_M5_norm[6]],
                               [self.OP_M7_norm[0],self.OP_M7_norm[1],self.OP_M7_norm[2],self.OP_M7_norm[3],self.OP_M7_norm[4],self.OP_M7_norm[5],self.OP_M7_norm[6]],
                               [self.OP_M8_norm[0],self.OP_M8_norm[1],self.OP_M8_norm[2],self.OP_M8_norm[3],self.OP_M8_norm[4],self.OP_M8_norm[5],self.OP_M8_norm[6]],
                               [self.OP_M8_norm[0],self.OP_M8_norm[1],self.OP_M8_norm[2],self.OP_M8_norm[3],self.OP_M8_norm[4],self.OP_M8_norm[5],self.OP_M8_norm[6]],
                               [self.OP_M10_norm[0],self.OP_M10_norm[1],self.OP_M10_norm[2],self.OP_M10_norm[3],self.OP_M10_norm[4],self.OP_M10_norm[5],self.OP_M10_norm[6]],
                               [self.OP_M10_norm[0],self.OP_M10_norm[1],self.OP_M10_norm[2],self.OP_M10_norm[3],self.OP_M10_norm[4],self.OP_M10_norm[5],self.OP_M10_norm[6]],
                               ])
        # clip the obs for better regularization
        observation = np.clip(observation, -5, 5)
        
        return observation
        
    def _get_info(self):
        '''Evaluate the performance'''   
        VDD = self.VDD
        Vin = self.Vin # input differential voltage for comparing
        Tdelay = self.Tdelay # initial delay time for the clock (=0V)
        Tr = self.Tr # clock rising time
        Tclk_pk = self.Tclk_pk # clock positive/negative peak duration
        Tdelay_Tr_Tclkpk = Tdelay + Tr + Tclk_pk # __/--
        
        time, Vclk = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Vclk')        
        _, Voutp = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Voutp')
        _, Voutn = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Voutn')
        _, Vdip = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Vdip')
        _, Vdin = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Vdin')
        time = np.array(time)
        self.Vclk = np.array(Vclk)
        self.Voutp = np.array(Voutp)
        self.Voutn = np.array(Voutn)
        self.Vdip = np.array(Vdip)
        self.Vdin = np.array(Vdin)
        self.Vout = self.Voutp - self.Voutn
        
        # introduce a score that defines how big Vout is compared to VDD/2, 
        # this score will be come zero once np.max(self.Vout) >= 0.5*VDD
        idx_Tdelay_Tr_Tclkpk = np.argmin(np.abs(time - Tdelay_Tr_Tclkpk))
        # self.Vout_score = np.min([(np.max(np.abs(self.Vout[:idx_Tdelay_Tr_Tclkpk])) - 0.5*VDD) / (np.max(np.abs(self.Vout[:idx_Tdelay_Tr_Tclkpk])) + 0.5*VDD), 0])
        if (np.max(np.abs(self.Vout[:idx_Tdelay_Tr_Tclkpk])) - 0.5*VDD) <= 0:
            self.Vout_score = -1 # the voltage difference does not exceed half of VDD within half clock period
        else:
            self.Vout_score = 0
        
        # introduce a score that defines if Vout+ and Vout- node get reset when Vclk = 0
        eps1 = 0.9 # margin for the descriminator
        Tclk = self.Tclk # clock period
        Tdelay_Tclk = Tdelay + Tclk #  __/--\__, delay time plus the first clock cycle
        idx_Tdelay_Tclk = np.argmin(np.abs(time - Tdelay_Tclk))
        if np.max(self.Voutp[idx_Tdelay_Tr_Tclkpk:idx_Tdelay_Tclk]) <= VDD * eps1 or np.max(self.Voutn[idx_Tdelay_Tr_Tclkpk:idx_Tdelay_Tclk]) <= VDD * eps1:
            self.Vout_reset_score = -1
        else:
            self.Vout_reset_score = 0 # Vout+ and Vout- node get reset when Vclk = 0

        # introduce a score that defines if Vdi+ and Vdi- node get reset when Vclk = 0
        eps2 = 0.9
        if np.max(self.Vdip[idx_Tdelay_Tr_Tclkpk:idx_Tdelay_Tclk]) <= VDD * eps2 or np.max(self.Vdin[idx_Tdelay_Tr_Tclkpk:idx_Tdelay_Tclk]) <= VDD * eps2:
            self.Vdi_reset_score = -1
        else:
            self.Vdi_reset_score = 0 # Vout+ and Vout- node get reset when Vclk = 0

        """ Clk-to-Q delay """
        idx_Vclk = np.argmin(np.abs(self.Vclk - 0.5*VDD)[:idx_Tdelay_Tr_Tclkpk]) # time index at which Vclk rises to the half of VDD 
        time_Vclk = time[idx_Vclk]
        
        if self.Vout_score < 0 or self.Vout_reset_score < 0 or self.Vdi_reset_score < 0: 
            self.Clk2Q_score = -1
            self.Clk2Q = np.inf # Clk2Q definition become pointless
        else:
            idx_Vout = np.argmin(np.abs(np.abs(self.Vout[:idx_Tdelay_Tr_Tclkpk]) - 0.5*VDD)) # time index at which the value of Vout rises to the half of VDD
            time_Vout = time[idx_Vout]
            self.Clk2Q = time_Vout - time_Vclk
            if self.Clk2Q > self.Tclk/2: # if delay is longer than half of clock cycle
                self.Clk2Q_score = -1 + np.min([(self.Clk2Q_spec - self.Clk2Q ) / (self.Clk2Q_spec + self.Clk2Q), 0])
            else:
                self.Clk2Q_score = np.min([(self.Clk2Q_spec - self.Clk2Q ) / (self.Clk2Q_spec + self.Clk2Q), 0])
            
        ''' Offset performance '''
        L = self.L
        Vgs_M1 = self.op_results['M1']['vgs']
        Vds_M1 = self.op_results['M1']['vds']
        Vgs_M2 = self.op_results['M2']['vgs']
        Vds_M2 = self.op_results['M2']['vds']
        Vth_M1 = self.op_results['M1']['vth']
        Vth_M2 = self.op_results['M2']['vth']

        self.total_offset, self.Vth_offset, self.tox_offset = self.input_offset(self.W_M1, L,
                                                                                self.W_M1, L,
                                                                                Vgs_M1, Vds_M1, Vth_M1,
                                                                                Vgs_M2, Vds_M2, Vth_M2)
        
        # 2 is just a scaling factor to compensate the error between the prediction model and MC simulation results, 
        # it is emperical.
        self.Vos = 2 * self.total_offset
        if self.Vout_score < 0 or self.Vout_reset_score or self.Vdi_reset_score < 0: 
            self.Vos_score = -1
        else:
            self.Vos_score = np.min([(self.Vos_spec - self.Vos) / (self.Vos_spec + self.Vos) ,0])

        ''' Energy consumption '''
        _, self.Ibias = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Ibias')
        Tdelay_Tclk_Tclk = Tdelay_Tclk + Tclk # Tdelay + Tclk + Tclk = Ttot + Tclk 
        idx_Tdelay_Tclk_Tclk = np.argmin(np.abs(time - Tdelay_Tclk_Tclk)) 
        self.I_cycle = self.Ibias[idx_Tdelay_Tclk:idx_Tdelay_Tclk_Tclk] # current per cycle
        Itot = np.trapz(np.abs(self.I_cycle), time[idx_Tdelay_Tclk:idx_Tdelay_Tclk_Tclk]) # total current, integral
        Iavg = Itot / Tclk 
        self.E_cycle = VDD * Iavg * Tclk # energy consumption per conversion
        if self.Vout_score < 0 or self.Vout_reset_score < 0 or self.Vdi_reset_score < 0: 
            self.E_cycle_score = -1
        else:
            self.E_cycle_score = np.min([(self.E_cycle_spec - self.E_cycle) / (self.E_cycle_spec + self.E_cycle) ,0])
        
        ''' Kickback noise '''
        _, Vn_kn = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Vn_kn')
        _, Vp_kn = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Vp_kn')
        Vn_kn = np.array(Vn_kn)
        Vp_kn = np.array(Vp_kn)
        self.V_kn = Vp_kn - Vn_kn - Vin # the input voltage error due to kickback noise (actual Vin removed)
        self.V_kn_pk = np.max(np.abs(self.V_kn))
        if self.Vout_score < 0 or self.Vout_reset_score < 0 or self.Vdi_reset_score < 0: 
            self.kn_score = -1
        else:
            self.kn_score = np.min([(self.V_kn_pk_spec - self.V_kn_pk) / (self.V_kn_pk_spec + self.V_kn_pk) ,0])
        
        ''' Metastability '''
        # these are generated when the test Vin=Vin_min to the positive input terminal
        _, Vout_n_ms = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Voutn_ms')
        _, Vout_p_ms = self.sim_results.tran(file_name=f'{NETLIST_PEX_NAME}_Voutp_ms')
        Vout_n_ms = np.array(Vout_n_ms)
        Vout_p_ms = np.array(Vout_p_ms)
        Vout_ms = Vout_p_ms - Vout_n_ms
        idx_Tdelay = np.argmin(np.abs(time - Tdelay))
        self.Vout_ms = np.abs(Vout_ms[:idx_Tdelay_Tclk])

        eps_ms = 1e-3 # margin for descrimination where all the output logic should be the same sign
        
        if self.Vout_score < 0 or self.Vout_reset_score < 0 or self.Vdi_reset_score < 0: 
            self.tau = np.inf # time of the regeneration becomes pointless
            self.ms_score = -1
            self.t_decision = np.inf
        elif np.all(Vout_ms > -eps_ms) or np.all(Vout_ms < eps_ms): # no metastable, transient sim should be at least 3-4 clock cycles
            idx_Vout_ms = np.argmin(np.abs(np.abs(self.Vout_ms[:idx_Tdelay_Tr_Tclkpk]) - 0.5*VDD)) # time index at which the value of Vout rises to the half of VDD
            time_Vout_ms = time[idx_Vout_ms]
            self.tau = time_Vout_ms - time_Vclk # delay
            alpha = 1 #Vin_min / self.Vin_min_spec
            self.t_shift = self.tau * np.log(alpha)
            self.t_decision = self.t_shift + self.tau
            # using time to define the score
            self.ms_score = np.min([(Tclk/2 - self.t_decision) / (Tclk/2 + self.t_decision) ,0])
            # using voltage to define
            # self.ms_score = np.min([(0.5*VDD - np.max(self.Vout_ms)) / (0.5*VDD + np.max(self.Vout_ms)) ,0])
        else:
            self.tau = np.inf # time of the regeneration becomes pointless
            self.ms_score = -1
            self.t_decision = np.inf
            
        """ Total reward """
        self.reward = self.Clk2Q_score + self.Vout_score + self.Vout_reset_score + self.E_cycle_score + self.kn_score + self.ms_score + self.Vos_score
                
        if self.reward >= 0:
            # restore the actual score, remove zero-clipping
            self.Clk2Q_score = (self.Clk2Q_spec - self.Clk2Q) / (self.Clk2Q_spec + self.Clk2Q)
            self.Vos_score = (self.Vos_spec - self.Vos) / (self.Vos_spec + self.Vos) 
            self.E_cycle_score = (self.E_cycle_spec - self.E_cycle) / (self.E_cycle_spec + self.E_cycle)
            self.kn_score = (self.V_kn_pk_spec - self.V_kn_pk) / (self.V_kn_pk_spec + self.V_kn_pk)
            self.ms_score = (Tclk/2 - self.t_decision) / (Tclk/2 + self.t_decision)

            self.reward = self.Clk2Q_score + self.Vout_score + self.Vout_reset_score + self.E_cycle_score + self.kn_score + self.ms_score + 10 + self.Vos_score 
            
        return {
                'Clock-to-Q delay (ns)': self.Clk2Q*1e9,
                'Vout (V)': self.Vout,
                'Vos (V)': self.Vos,
                'Energy consumption (fJ/conversion)': self.E_cycle * 1e15,
                'Peak input voltage error due to kickback noise (mV)': self.V_kn_pk * 1e3,
                'Decision time at Vin_min without being metastable (ps)': self.t_decision*1e12
            }

    def input_offset(self, W_M1, L_M1,
                    W_M2, L_M2,
                    Vgs_M1, Vds_M1, Vth_M1,
                    Vgs_M2, Vds_M2, Vth_M2):
        
        '''
        Calculate the input offset voltage, M1 and M2 are a pair
        '''
        
        W_M1 = W_M1 * 1e-6
        L_M1 = L_M1 * 1e-6
        W_M2 = W_M2 * 1e-6
        L_M2 = L_M2 * 1e-6

        def random_mismatch(W, L):
            if L >= 4e-6 and L <= 8e-6 and W >= 3.6e-7 and W <= 0.0001:
                    A_th = 7.356e-03 
            else: # others
                A_th = 3.356e-03
        
            A_tox = 3.443e-03
            tox = 4.148e-009 # meter
            
            sigma_Vth = A_th / (W*1e6 * L*1e6)**0.5
            sigma_tox = A_tox * tox / (W*1e6 * L*1e6)**0.5
        
            return sigma_Vth, sigma_tox        

        sigma_Vth_M1, sigma_tox_M1 = random_mismatch(W_M1, L_M1)
        sigma_Vth_M2 = sigma_Vth_M1
        sigma_tox_M2 = sigma_tox_M1
        
        tox = 4.148e-009 # meter, oxide thickness
        
        Vth = Vth_M1
            
        KVth_M1 = -1
        KVth_M2 = -Vds_M2 / Vds_M1
        
        Kz = (Vds_M2 / Vds_M1) * (Vgs_M2 - Vth - Vds_M2/2)
        sigma_z = np.sqrt(sigma_tox_M1**2 + sigma_tox_M2**2) / tox
        
        total_offset = (KVth_M1**2 * sigma_Vth_M1**2 + KVth_M2**2 * sigma_Vth_M2**2 + Kz**2 * sigma_z**2)**0.5
        Vth_offset = (KVth_M1**2 * sigma_Vth_M1**2 + KVth_M2**2 * sigma_Vth_M2**2)**0.5
        tox_offset = (Kz**2 * sigma_z**2)**0.5

        return total_offset, Vth_offset, tox_offset

    def _init_random_sim(self, max_sims=100):
        '''
        
        This is NOT the same as the random step in the agent, here is basically 
        doing some completely random design variables selection for generating
        some device parameters for calculating the mean and variance for each
        .OP device parameters (getting a statistical idea of, how each ckt parameter's range is like'), 
        so that you can do the normalization for the state representations later.
    
        '''

        random_op_count = 0
        OP_M_lists = []
        OP_R_lists = []
        OP_C_lists = []
        OP_V_lists = []
        
        while random_op_count <= max_sims :
            print(f'* simulation #{random_op_count} *')
            action = np.random.uniform(self.action_space_low, self.action_space_high, self.action_dim) 
            print(f'action: {action}')
            self._do_simulation(action)
    
            sim_results = OutputParser(self.CktGraph)
            op_results = sim_results.dcop(file_name=f'{NETLIST_NAME}_op') 
            
            OP_M_list = []
            OP_R_list = []
            OP_C_list = []
            OP_V_list = []

            for key in list(op_results):
                if key[0] == 'M' or key[0] == 'm':
                    OP_M = np.array([op_results[key][f'{item}'] for item in list(op_results[key])])    
                    OP_M_list.append(OP_M)
                elif key[0] == 'R' or key[0] == 'r':
                    OP_R = np.array([op_results[key][f'{item}'] for item in list(op_results[key])])    
                    OP_R_list.append(OP_R)
                elif key[0] == 'C' or key[0] == 'c':
                    OP_C = np.array([op_results[key][f'{item}'] for item in list(op_results[key])])    
                    OP_C_list.append(OP_C)   
                elif key[0] == 'V' or key[0] == 'v':
                    OP_V = np.array([op_results[key][f'{item}'] for item in list(op_results[key])])    
                    OP_V_list.append(OP_V)   
                else:
                    None
                    
            OP_M_list = np.array(OP_M_list)
            OP_R_list = np.array(OP_R_list)
            OP_C_list = np.array(OP_C_list)
            OP_V_list = np.array(OP_V_list)
                        
            OP_M_lists.append(OP_M_list)
            OP_R_lists.append(OP_R_list)
            OP_C_lists.append(OP_C_list)
            OP_V_lists.append(OP_V_list)
            
            random_op_count = random_op_count + 1

        OP_M_lists = np.array(OP_M_lists)
        OP_R_lists = np.array(OP_R_lists)
        OP_C_lists = np.array(OP_C_lists)
        OP_V_lists = np.array(OP_V_lists)
        
        if OP_M_lists.size != 0:
            OP_M_mean = np.mean(OP_M_lists.reshape(-1, OP_M_lists.shape[-1]), axis=0)
            OP_M_std = np.std(OP_M_lists.reshape(-1, OP_M_lists.shape[-1]),axis=0)
            OP_M_mean_dict = {}
            OP_M_std_dict = {}
            for idx, key in enumerate(self.params_mos):
                OP_M_mean_dict[key] = OP_M_mean[idx]
                OP_M_std_dict[key] = OP_M_std[idx]
        
        if OP_R_lists.size != 0:
            OP_R_mean = np.mean(OP_R_lists.reshape(-1, OP_R_lists.shape[-1]), axis=0)
            OP_R_std = np.std(OP_R_lists.reshape(-1, OP_R_lists.shape[-1]),axis=0)
            OP_R_mean_dict = {}
            OP_R_std_dict = {}
            for idx, key in enumerate(self. params_r):
                OP_R_mean_dict[key] = OP_R_mean[idx]
                OP_R_std_dict[key] = OP_R_std[idx]
                
        if OP_C_lists.size != 0:
            OP_C_mean = np.mean(OP_C_lists.reshape(-1, OP_C_lists.shape[-1]), axis=0)
            OP_C_std = np.std(OP_C_lists.reshape(-1, OP_C_lists.shape[-1]),axis=0)
            OP_C_mean_dict = {}
            OP_C_std_dict = {}
            for idx, key in enumerate(self.params_c):
                OP_C_mean_dict[key] = OP_C_mean[idx]
                OP_C_std_dict[key] = OP_C_std[idx]     
                
        if OP_V_lists.size != 0:
            OP_V_mean = np.mean(OP_V_lists.reshape(-1, OP_V_lists.shape[-1]), axis=0)
            OP_V_std = np.std(OP_V_lists.reshape(-1, OP_V_lists.shape[-1]),axis=0)
            OP_V_mean_dict = {}
            OP_V_std_dict = {}
            for idx, key in enumerate(self.params_v):
                OP_V_mean_dict[key] = OP_V_mean[idx]
                OP_V_std_dict[key] = OP_V_std[idx]

        self.OP_M_mean_std = {
            'OP_M_mean': OP_M_mean_dict,         
            'OP_M_std': OP_M_std_dict
            }

        with open(f'{SPICE_NETLIST_DIR}/{NETLIST_NAME}_op_mean_std.json','w') as file:
            json.dump(self.OP_M_mean_std, file)

if __name__ == "__main__":
        W_M1 = 10.08
        W_M3 = 0.84
        W_M5 = 0.84
        W_M7 = 10.08
        W_M8 = 0.84
        W_M10 = 1.68
        Vcm = 0.91
        env = StrongArmCompEnv()
        action_space_low = env.action_space_low
        action_space_high = env.action_space_high
        
        action = [W_M1, W_M3, W_M5, W_M7, W_M8, W_M10, Vcm]

        action_normalized = ActionNormalizer(action_space_low=action_space_low, action_space_high = \
                                       action_space_high).reverse_action(action) # convert to [-1,1]
        
        env.step(action_normalized)
        
        
        
        