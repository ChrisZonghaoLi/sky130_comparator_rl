#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jul 10 17:21:48 2023

@author: lizongh2
"""

import torch
import numpy as np

class GraphDoubleTailComp:
    def __init__(self):
        self.device = torch.device(
           "cpu"
        )

        # we do not include R and C here since, it is not straght forward to get them from device attributes in GF180MCU
        self.ckt_hierarchy = (('M1','x1.XM1','nfet_03v3','m'),
                      ('M2','x1.XM2','nfet_03v3','m'),
                      ('M3','x1.XM3','pfet_03v3','m'),
                      ('M4','x1.XM4','pfet_03v3','m'),
                      ('M5','x1.XM5','nfet_03v3','m'),
                      
                      ('M6','x1.XM6','nfet_03v3','m'),
                      ('M7','x1.XM7','nfet_03v3','m'),
                      ('M8','x1.XM8','nfet_03v3','m'),
                      ('M9','x1.XM9','nfet_03v3','m'),

                      ('M10','x1.XM10','pfet_03v3','m'),
                      ('M11','x1.XM11','pfet_03v3','m'),
                      
                      ('M12','x1.XM12','pfet_03v3','m')

                     )    

        self.op = {'M1':{},
                'M2':{},
                'M3':{},
                'M4':{},
                'M5':{},
                'M6':{},
                'M7':{},
                'M8':{},
                'M9':{},
                'M10':{},
                'M11':{},
                'M12':{}
                 }

        self.edge_index = torch.tensor([
            [0,1], [1,0], [0,2], [2,0], [0,4], [4,0], [0,5], [5,0],    
            [1,3], [3,1], [1,4], [4,1], [1,8], [8,1],
            [2,3], [3,2], [2,5], [5,2], 
            [3,8], [8,3],
            [5,6], [6,5],
            [6,7], [7,6], [6,9], [9,6],[6,10], [10,6],
            [7,8], [8,7], [7,9], [9,7], [7,10],[10,7],
            [9,10], [10,9], [9,11], [11,9],
            [10,11], [11,10]
            ], dtype=torch.long).t().to(self.device)
        
        # sorted based on if it is the small signal path
        # small signal path: 0; biasing path: 1
        self.edge_type = torch.tensor([
            0, 0, 0, 0, 0, 0, 0, 0,    
            0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 
            0, 0,
            1, 1,
            1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1
            ]).to(self.device)
        
        self.num_relations = 2
        self.num_nodes = 12
        self.num_node_features = 7
        self.obs_shape = (self.num_nodes, self.num_node_features)
        
        """Select an action from the input state."""
        self.action_space_low = np.array([ 0.22e-6, # M1 & M2's W
                                                                     0.22e-6, # M3 & M4's W
                                                                     0.22e-6, # M6 and M9 W
                                                                     0.22e-6, # M5's W
                                                                     0.22e-6, # M7 & M8's W
                                                                     0.22e-6, # M10 & M11's W
                                                                     0.22e-6, # M12's W
                                                                     0.9 #Vcm
                                                                     ]) 
        
        self.action_space_high = np.array([ 10e-6, # M1 & M2's W
                                                                    10e-6, # M3 & M4's W
                                                                    10e-6, # M6 & M9's W
                                                                    10e-6, # M5's W
                                                                    10e-6, # M7 & M8's W, we will enforce that M6's W will be at least 10 times larger than M7's W
                                                                    10e-6, # M10 & M11's W
                                                                    10e-6, # M12's W
                                                                    1.6 # Vcm, In Wicht JSSC'04 shows Vcm has big impact on speed and offset, suggest Vcm = 70% VDD gives best compromise between offset and speed 
                                                                     ]) 
        
        self.action_dim =len(self.action_space_low)
        self.action_shape = (self.action_dim,)    
        
        self.L = 0.28e-6
        self.CL = 20e-15 # load capacitance, 20 fF
        self.Tclk = 1e-9 # clock speed, 1GHz, reported in Nauta's ISSCC paper
        self.Tr = 0.05 * self.Tclk
        self.Tf = 0.05 * self.Tclk
        self.Tclk_pk = (self.Tclk - self.Tr - self.Tf) / 2
        self.Tdelay = 0.2e-9
        self.Tdelay_bar =  self.Tclk_pk + self.Tdelay + self.Tr
        self.VDD = 3.3
        self.Vin = 50e-3 # input differential voltage, from Nauta's ISSCC paper
        
        """Some target specifications for the final design"""
        self.Voffset_spec = 13e-3 # offset voltage, from Nauta's ISSCC paper
        self.Clk2Q_spec = 230e-12 # clock-to-output delay, from Nikolic's JSSC paper
        self.Vos_spec = 11e-3 # input offset voltage, should be smaller than 10mV
        self.E_cycle_spec = 680e-15 # energy consumption per conversion, Bindra JSSC'18, Nauta's ISSCC paper, Lotfi's T-VLSI paper
        self.V_kn_pk_spec = 40e-3 # peak input voltage error due to kickback noise
        self.Vin_min_spec = 100e-6 # minimum input voltage without being metastable

        """If you want to apply the reward engineering"""
        self.rew_eng = True


class GraphStrongArmComp:
    def __init__(self):
        self.device = torch.device(
           "cpu"
        )

        # we do not include R and C here since, it is not straght forward to get them from device attributes in GF180MCU
        self.ckt_hierarchy = (('M1','x1.XM1','nfet_03v3','m'),
                      ('M2','x1.XM2','nfet_03v3','m'),
                      ('M3','x1.XM3','nfet_03v3','m'),
                      ('M4','x1.XM4','nfet_03v3','m'),
                      
                      ('M5','x1.XM5','pfet_03v3','m'),
                      ('M6','x1.XM6','pfet_03v3','m'),
                      
                      ('M7','x1.XM7','nfet_03v3','m'),
                      
                      ('M8','x1.XM8','pfet_03v3','m'),
                      ('M9','x1.XM9','pfet_03v3','m'),
                      ('M10','x1.XM10','pfet_03v3','m'),
                      ('M11','x1.XM11','pfet_03v3','m')
                      
                     )    

        self.op = {'M1':{},
                'M2':{},
                'M3':{},
                'M4':{},
                'M5':{},
                'M6':{},
                'M7':{},
                'M8':{},
                'M9':{},
                'M10':{},
                'M11':{}
                 }

        self.edge_index = torch.tensor([
            [0,1], [1,0], [0,2], [2,0], [0,6], [6,0], [0,9], [9,0],    
            [1,3], [3,1], [1,6], [6,1], [1,10], [10,1],
            [2,3], [3,2], [2,4], [4,2], [2,5], [5,2], [2,7], [7,2], [2,8], [8,2], [2,9], [9,2],
            [3,4], [4,3], [3,5], [5,3], [3,7], [7,3], [3,8], [8,3], [3,10], [10,3],
            [4,5], [5,4], [4,7], [7,4], [4,8], [8,4],
            [5,7], [7,5], [5,8], [8,5]
            ], dtype=torch.long).t().to(self.device)
        
        # sorted based on if it is the small signal path
        # small signal path: 0; biasing path: 1
        self.edge_type = torch.tensor([
            0, 0, 0, 0, 0, 0, 0, 0,    
            0, 0, 0, 0, 0, 0,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1,
            1, 1, 1, 1
            ]).to(self.device)
        
        self.num_relations = 2
        self.num_nodes = 11
        self.num_node_features = 7
        self.obs_shape = (self.num_nodes, self.num_node_features)
        
        """Select an action from the input state."""
        self.action_space_low = np.array([ 0.22e-6, # M1 & M2's W
                                                                    0.22e-6, # M3 & M4's W
                                                                    0.22e-6, # M5 & M6 W
                                                                    0.22e-6, # M7 W
                                                                    0.22e-6, # M8 & M9's W
                                                                    0.22e-6, # M10 & M11's W
                                                                    0.9 #Vcm
                                                                    ]) 
        
        self.action_space_high = np.array([ 10e-6, # M1 & M2's W
                                                                    10e-6, # M3 & M4's W
                                                                    10e-6,  # M5 & M6 W
                                                                    10e-6, # M7 W
                                                                    10e-6, # M8 & M9's W
                                                                    10e-6, # M10 & M11's W
                                                                    1.6 # Vcm, In Wicht JSSC'04 shows Vcm has big impact on speed and offset, suggest Vcm = 70% VDD gives best compromise between offset and speed 
                                                                     ]) 
        
        self.action_dim =len(self.action_space_low)
        self.action_shape = (self.action_dim,)    
        
        self.L = 0.28e-6
        self.CL = 20e-15 # load capacitance, 20 fF
        self.Tclk = 1e-9 # clock speed, 1GHz, reported in Nauta's ISSCC paper
        self.Tr = 0.05 * self.Tclk
        self.Tf = 0.05 * self.Tclk
        self.Tclk_pk = (self.Tclk - self.Tr - self.Tf) / 2
        self.Tdelay = 0.2e-9
        self.Tdelay_bar =  self.Tclk_pk + self.Tdelay + self.Tr
        self.VDD = 3.3
        self.Vin = 50e-3 # input differential voltage, from Nauta's ISSCC paper
        
        """Some target specifications for the final design"""
        self.Voffset_spec = 13e-3 # offset voltage, from Nauta's ISSCC paper
        self.Clk2Q_spec = 230e-12 # clock-to-output delay, from Nikolic's JSSC paper
        self.Vos_spec = 10e-3 # input offset voltage, should be smaller than 10mV
        self.E_cycle_spec = 680e-15 # energy consumption per conversion, Bindra JSSC'18, Nauta's ISSCC paper, Lotfi's T-VLSI paper
        self.V_kn_pk_spec = 40e-3 # peak input voltage error due to kickback noise
        self.Vin_min_spec = 100e-6 # minimum input voltage without being metastable

        """If you want to apply the reward engineering"""
        self.rew_eng = True