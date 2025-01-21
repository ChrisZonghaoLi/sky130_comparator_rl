#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Nov 29 15:12:17 2023

Post-processing StrongARM comparator optimization results in GF180MCU

@author: lizongh2
"""

from utils import OutputParser, ActionNormalizer
from ckt_graphs import GraphStrongArmComp
from strong_arm_comp import StrongArmCompEnv

import matplotlib.pyplot as plt
import matplotlib.animation as animation
plt.style.use(style='default')
plt.rcParams['lines.linewidth'] = 2
plt.rcParams["font.weight"] = "bold"
plt.rcParams["axes.labelweight"] = "bold"
plt.rcParams["axes.axisbelow"] = False
plt.rc('axes', axisbelow=True)


from mpl_toolkits.axes_grid1.inset_locator import zoomed_inset_axes
from mpl_toolkits.axes_grid1.inset_locator import mark_inset

import pickle

import numpy as np

from datetime import datetime
date = datetime.today().strftime('%Y-%m-%d')

""" Load memory to plot reward vs simulations """
# RGCN
#file_name1 = 'TL_memory_GraphStrongArmComp_2023-12-08_noise=uniform_reward=10.625_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
#file_name2 = 'TL_memory_GraphStrongArmComp_2023-12-08_noise=uniform_reward=10.537_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
#file_name3 = 'TL_memory_GraphStrongArmComp_2023-12-08_noise=uniform_reward=10.542_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
# GCN
#file_name4 = 'TL_memory_GraphStrongArmComp_2023-12-08_noise=uniform_reward=-0.06_ActorCriticGCN_initial_random_steps=0_noise_sigma_decay=1'
#file_name5 = 'TL_memory_GraphStrongArmComp_2023-12-08_noise=uniform_reward=-0.03_ActorCriticGCN_initial_random_steps=0_noise_sigma_decay=1'
#file_name6 = 'TL_memory_GraphStrongArmComp_2023-12-08_noise=uniform_reward=-0.01_ActorCriticGCN_initial_random_steps=0_noise_sigma_decay=1'
# GAT
#file_name7 = 'TL_memory_GraphStrongArmComp_2023-12-09_noise=uniform_reward=-0.45_ActorCriticGAT_initial_random_steps=0_noise_sigma_decay=1'
#file_name8 = 'TL_memory_GraphStrongArmComp_2023-12-09_noise=uniform_reward=-0.44_ActorCriticGAT_initial_random_steps=0_noise_sigma_decay=1'
#file_name9 = 'TL_memory_GraphStrongArmComp_2023-12-09_noise=uniform_reward=-0.42_ActorCriticGAT_initial_random_steps=0_noise_sigma_decay=1'
# MLP
#file_name10 = 'TL_memory_GraphStrongArmComp_2023-12-11_noise=uniform_reward=-0.175_ActorCriticMLP_initial_random_steps=0_noise_sigma_decay=1'
#file_name11 = 'TL_memory_GraphStrongArmComp_2023-12-11_noise=uniform_reward=-0.157_ActorCriticMLP_initial_random_steps=0_noise_sigma_decay=1'
#file_name12 = 'TL_memory_GraphStrongArmComp_2023-12-11_noise=uniform_reward=-0.162_ActorCriticMLP_initial_random_steps=0_noise_sigma_decay=1'
# No TL
#file_name13 = 'TL=False_memory_GraphStrongArmComp_2023-12-11_noise=uniform_reward=-0.113_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
#file_name14 = 'TL=False_memory_GraphStrongArmComp_2023-12-11_noise=uniform_reward=-0.265_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
#file_name15 = 'TL=False_memory_GraphStrongArmComp_2023-12-11_noise=uniform_reward=-0.165_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'

# new power spec
# RGCN
file_name1 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-11_noise=uniform_reward=11.017_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
file_name2 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-13_noise=uniform_reward=11.035_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
file_name3 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-13_noise=uniform_reward=11.034_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
# # GCN
file_name4 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-13_noise=uniform_reward=-0.041_ActorCriticGCN_initial_random_steps=0_noise_sigma_decay=1'
file_name5 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-13_noise=uniform_reward=-0.048_ActorCriticGCN_initial_random_steps=0_noise_sigma_decay=1'
file_name6 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-13_noise=uniform_reward=-0.027_ActorCriticGCN_initial_random_steps=0_noise_sigma_decay=1'
# # GAT
file_name7 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-13_noise=uniform_reward=-0.223_ActorCriticGAT_initial_random_steps=0_noise_sigma_decay=1'
file_name8 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-14_noise=uniform_reward=-0.003_ActorCriticGAT_initial_random_steps=0_noise_sigma_decay=1'
file_name9 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-14_noise=uniform_reward=-0.225_ActorCriticGAT_initial_random_steps=0_noise_sigma_decay=1'
# # MLP
file_name10 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-13_noise=uniform_reward=-0.053_ActorCriticMLP_initial_random_steps=0_noise_sigma_decay=1'
file_name11 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-13_noise=uniform_reward=-0.109_ActorCriticMLP_initial_random_steps=0_noise_sigma_decay=1'
file_name12 = 'New_Power_Spec_TL_memory_GraphStrongArmComp_2024-06-13_noise=uniform_reward=-0.111_ActorCriticMLP_initial_random_steps=0_noise_sigma_decay=1'
# # No TL
file_name13 = 'New_Power_Spec_TL=False_memory_GraphStrongArmComp_2024-06-14_noise=uniform_reward=-0.176_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
file_name14 = 'New_Power_Spec_TL=False_memory_GraphStrongArmComp_2024-06-14_noise=uniform_reward=-0.096_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
file_name15 = 'New_Power_Spec_TL=False_memory_GraphStrongArmComp_2024-06-15_noise=uniform_reward=-0.087_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'

num_steps = 1000
num_random = 0

with open(f'./saved_memories/{file_name1}.pkl', 'rb') as memory_file:
    memory1 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name2}.pkl', 'rb') as memory_file:
    memory2 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name3}.pkl', 'rb') as memory_file:
    memory3 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name4}.pkl', 'rb') as memory_file:
    memory4 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name5}.pkl', 'rb') as memory_file:
    memory5 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name6}.pkl', 'rb') as memory_file:
    memory6 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name7}.pkl', 'rb') as memory_file:
    memory7 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name8}.pkl', 'rb') as memory_file:
    memory8 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name9}.pkl', 'rb') as memory_file:
    memory9 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name10}.pkl', 'rb') as memory_file:
    memory10 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name11}.pkl', 'rb') as memory_file:
    memory11 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name12}.pkl', 'rb') as memory_file:
    memory12 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name13}.pkl', 'rb') as memory_file:
    memory13 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name14}.pkl', 'rb') as memory_file:
    memory14 = pickle.load(memory_file)
with open(f'./saved_memories/{file_name15}.pkl', 'rb') as memory_file:
    memory15 = pickle.load(memory_file)

rews_buf1 = memory1.rews_buf[:num_steps]
rews_buf2 = memory2.rews_buf[:num_steps]
rews_buf3 = memory3.rews_buf[:num_steps]
rews_buf4 = memory4.rews_buf[:num_steps]
rews_buf5 = memory5.rews_buf[:num_steps]
rews_buf6 = memory6.rews_buf[:num_steps]
rews_buf7 = memory7.rews_buf[:num_steps]
rews_buf8 = memory8.rews_buf[:num_steps]
rews_buf9 = memory9.rews_buf[:num_steps]
rews_buf10 = memory10.rews_buf[:num_steps]
rews_buf11 = memory11.rews_buf[:num_steps]
rews_buf12 = memory12.rews_buf[:num_steps]
rews_buf13 = memory13.rews_buf[:num_steps]
rews_buf14 = memory14.rews_buf[:num_steps]
rews_buf15 = memory15.rews_buf[:num_steps]

def average_window(rews_buf, window=10):
    avg_rewards=[]
    for k in range(len(rews_buf)):
        if k >= window:
            avg_reward = np.mean(rews_buf[k-window:k])
        else:
            avg_reward = np.inf
        avg_rewards.append(avg_reward)
    
    return np.array(avg_rewards)

""" Result visualizations and save these as pictures """
# plot average reward
rgcn_mean = average_window(np.mean([rews_buf1, rews_buf2, rews_buf3], axis=0))
rgcn_std =  np.std([rews_buf1, rews_buf2, rews_buf3], axis=0)
gcn_mean = average_window(np.mean([rews_buf4, rews_buf5, rews_buf6], axis=0))
gcn_std =  np.std([rews_buf4, rews_buf5, rews_buf6], axis=0)
gat_mean = average_window(np.mean([rews_buf7, rews_buf8, rews_buf9], axis=0))
gat_std =  np.std([rews_buf7, rews_buf8, rews_buf9], axis=0)
mlp_mean = average_window(np.mean([rews_buf10, rews_buf11, rews_buf12], axis=0))
mlp_std =  np.std([rews_buf10, rews_buf11, rews_buf12], axis=0)
no_tl_mean = average_window(np.mean([rews_buf13, rews_buf14, rews_buf15], axis=0))
no_tl_std =  np.std([rews_buf13, rews_buf14, rews_buf15], axis=0)

plt.figure('Reward')
plt.plot(rgcn_mean, 'b', label='RGCN') # RGCN
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf1, rews_buf2, rews_buf3], axis=0), np.max([rews_buf1, rews_buf2, rews_buf3], axis=0), alpha=0.3, color='b') 
plt.plot(gcn_mean, 'r', label='GCN') # GCN
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf4, rews_buf5, rews_buf6], axis=0), np.max([rews_buf4, rews_buf5, rews_buf6], axis=0), alpha=0.3, color='r') 
plt.plot(gat_mean, 'lime', label='GAT') # GAT
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf7, rews_buf8, rews_buf9], axis=0), np.max([rews_buf7, rews_buf8, rews_buf9], axis=0), alpha=0.3, color='lime') 
plt.plot(mlp_mean, 'yellow', label='MLP') # MLP 
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf10, rews_buf11, rews_buf12], axis=0), np.max([rews_buf10, rews_buf11, rews_buf12], axis=0), alpha=0.3, color='yellow') 
plt.plot(no_tl_mean, 'grey', label='No TL (RGCN)') # No TL 
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf13, rews_buf14, rews_buf15], axis=0), np.max([rews_buf10, rews_buf11, rews_buf12], axis=0), alpha=0.2, color='grey') 
plt.xlabel('Number of Simulations', fontweight='bold', fontsize=20)
plt.xticks(fontsize=20, weight='bold')
# plt.xticks(np.arange(0, num_steps+1, 200))
plt.ylabel('Reward', fontweight='bold', fontsize=20)
plt.yticks(fontsize=20, fontweight='bold')
plt.legend(loc='upper left', fontsize=16)
plt.grid(linewidth=2)
ax = plt.gca()
ax.spines['bottom'].set_linewidth(2)
ax.spines['left'].set_linewidth(2)
ax.spines['right'].set_linewidth(2)
ax.spines['top'].set_linewidth(2)
# axins = zoomed_inset_axes(ax, 2, loc=1) # zoom = 10
# axins.plot(rgcn_mean, color='b')
# axins.plot(gcn_mean, color='r')
# axins.plot(gat_mean, color='lime')
# axins.plot(mlp_mean, color='yellow')
# axins.plot(no_tl_mean, color='grey')
# axins.set_xlim(900, 1000) # Limit the region for zoom
# axins.set_ylim(-2.5, 0.5)
# axins.set_xticks([])
# patch, pp1,pp2 = mark_inset(ax, axins, loc1=1, loc2=3, fc="none", ec="0.5")
# pp1.loc1, pp1.loc2 = 4, 1
# pp2.loc1, pp2.loc2 = 3, 2  
plt.savefig(f'./pics/tl_reward_new_specs_sky130_to_gf180_strong_arm_comp_small.pdf', format='pdf', bbox_inches='tight')
plt.savefig(f'./pics/tl_reward_new_specs_sky130_to_gf180_strong_arm_comp_small.png', format='png', bbox_inches='tight')

# plot how the best result evolve with simulation run
rgcn_best = np.array([np.max(np.mean([rews_buf1, rews_buf2, rews_buf3], axis=0)[num_random:i+1]) for i in range(num_random,len(rgcn_mean))])
gcn_best = np.array([np.max(np.mean([rews_buf4, rews_buf5, rews_buf6], axis=0)[num_random:i+1]) for i in range(num_random,len(gcn_mean))])
gat_best = np.array([np.max(np.mean([rews_buf7, rews_buf8, rews_buf9], axis=0)[num_random:i+1]) for i in range(num_random,len(gat_mean))])
mlp_best = np.array([np.max(np.mean([rews_buf10, rews_buf11, rews_buf12], axis=0)[num_random:i+1]) for i in range(num_random,len(mlp_mean))])
no_tl_best = np.array([np.max(np.mean([rews_buf13, rews_buf14, rews_buf15], axis=0)[num_random:i+1]) for i in range(num_random,len(mlp_mean))])
x = np.linspace(num_random,num_steps,int(num_steps-num_random),dtype=np.int16)

plt.figure('Reward Improvement')
plt.plot(x,rgcn_best, 'b', label='RGCN') # RGCN
plt.plot(x,gcn_best, 'r', label='GCN') # GCN
plt.plot(x,gat_best, 'lime', label='GAT') # GAT
plt.plot(x,mlp_best, 'yellow', label='MLP') # MLP 
plt.plot(x,no_tl_best, 'grey', label='No TL (RGCN)') # no TL (RGCN) 
plt.xlabel('Number of Simulations', fontweight='bold', fontsize=20)
plt.xticks(fontsize=20, weight='bold')
plt.ylabel('Reward', fontweight='bold', fontsize=20)
# plt.ylim(-2,0)
plt.yticks(fontsize=20, fontweight='bold')
plt.legend(loc='lower right', fontsize=14)
plt.grid(linewidth=2)
ax = plt.gca()
ax.spines['bottom'].set_linewidth(2)
ax.spines['left'].set_linewidth(2)
ax.spines['right'].set_linewidth(2)
ax.spines['top'].set_linewidth(2)
plt.savefig(f'./pics/tl_reward_new_specs_best_sky130_to_gf180_strong_arm_comp.pdf', format='pdf', bbox_inches='tight')
plt.savefig(f'./pics/tl_reward_new_specs_best_sky130_to_gf180_strong_arm_comp.png', format='png', bbox_inches='tight')


