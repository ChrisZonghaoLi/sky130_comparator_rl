#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Nov 29 15:12:17 2023

Post-processing double-tail comparator optimization results in SKY130

@author: lizongh2
"""

from utils import OutputParser, ActionNormalizer
from ckt_graphs import GraphDoubleTailComp
from double_tail_comp import DoubleTailCompEnv

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
file_name1 = 'memory_GraphDoubleTailComp_2024-01-11_noise=uniform_reward=11.04_ActorCriticRGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
file_name2 = 'memory_GraphDoubleTailComp_2024-01-11_noise=uniform_reward=11.05_ActorCriticRGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
file_name3 = 'memory_GraphDoubleTailComp_2024-01-10_noise=uniform_reward=10.88_ActorCriticRGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
# GCN
file_name4 = 'memory_GraphDoubleTailComp_2024-01-12_noise=uniform_reward=10.67_ActorCriticGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
file_name5 = 'memory_GraphDoubleTailComp_2024-01-12_noise=uniform_reward=11.11_ActorCriticGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
file_name6 = 'memory_GraphDoubleTailComp_2024-01-11_noise=uniform_reward=-0.06_ActorCriticGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
# GAT
file_name7 = 'memory_GraphDoubleTailComp_2024-01-11_noise=uniform_reward=11.21_ActorCriticGAT_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
file_name8 = 'memory_GraphDoubleTailComp_2024-01-11_noise=uniform_reward=11.27_ActorCriticGAT_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
file_name9 = 'memory_GraphDoubleTailComp_2024-01-11_noise=uniform_reward=10.47_ActorCriticGAT_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
# MLP
file_name10 = 'memory_GraphDoubleTailComp_2024-01-13_noise=uniform_reward=11.08_ActorCriticMLP_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
file_name11 = 'memory_GraphDoubleTailComp_2024-01-12_noise=uniform_reward=10.97_ActorCriticMLP_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
file_name12 = 'memory_GraphDoubleTailComp_2024-01-12_noise=uniform_reward=10.75_ActorCriticMLP_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1'
# Random
file_name13 = 'memory_GraphDoubleTailComp_2023-12-04_noise=uniform_reward=10.46_random'
file_name14 = 'memory_GraphDoubleTailComp_2023-12-05_noise=uniform_reward=-0.00_random'
file_name15 = 'memory_GraphDoubleTailComp_2023-12-05_noise=uniform_reward=-0.01_random'

num_steps = 1000
num_random = 200

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
    
    return avg_rewards

""" Result visualizations and save these as pictures """
# plot average reward
rgcn_mean = average_window(np.mean([rews_buf1, rews_buf2, rews_buf3], axis=0))
rgcn_std =  np.std([rews_buf1, rews_buf2, rews_buf3], axis=0)
gcn_mean = average_window(np.mean([rews_buf4, rews_buf5, rews_buf6], axis=0))
gcn_std =  np.std([rews_buf4, rews_buf5, rews_buf6], axis=0)
gat_mean = average_window(np.mean([rews_buf7, rews_buf8, rews_buf9], axis=0))
gat_std =  np.std([rews_buf7, rews_buf8], axis=0)
mlp_mean = average_window(np.mean([rews_buf10, rews_buf11, rews_buf12], axis=0))
mlp_std =  np.std([rews_buf10, rews_buf11, rews_buf12], axis=0)
random_mean = average_window(np.mean([rews_buf13, rews_buf14, rews_buf15], axis=0))
random_std =  np.std([rews_buf13, rews_buf14, rews_buf15], axis=0)

plt.figure('Reward')
plt.plot(rgcn_mean, 'b', label='RGCN') # RGCN
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf1, rews_buf2, rews_buf3], axis=0), np.max([rews_buf1, rews_buf2, rews_buf3], axis=0), alpha=0.3, color='b') 
plt.plot(gcn_mean, 'r', label='GCN') # GCN
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf4, rews_buf5, rews_buf6], axis=0), np.max([rews_buf4, rews_buf5, rews_buf6], axis=0), alpha=0.3, color='r') 
plt.plot(gat_mean, 'lime', label='GAT') # GAT
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf7, rews_buf8, rews_buf9], axis=0), np.max([rews_buf7, rews_buf8, rews_buf9], axis=0), alpha=0.3, color='lime') 
plt.plot(mlp_mean, 'yellow', label='MLP') # MLP 
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf10, rews_buf11, rews_buf12], axis=0), np.max([rews_buf10, rews_buf11, rews_buf12], axis=0), alpha=0.3, color='yellow') 
plt.plot(random_mean, 'grey', label='Random') # Random 
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf13, rews_buf14, rews_buf15], axis=0), np.max([rews_buf10, rews_buf11, rews_buf12], axis=0), alpha=0.2, color='grey') 
plt.xlabel('Number of Simulations', fontweight='bold', fontsize=20)
plt.xticks(fontsize=20, weight='bold')
plt.xticks(np.arange(0, num_steps+1, 200))
plt.ylabel('Reward', fontweight='bold', fontsize=20)
plt.yticks(fontsize=20, fontweight='bold')
plt.legend(loc='upper left', fontsize=14)
plt.grid(linewidth=2)
ax = plt.gca()
ax.spines['bottom'].set_linewidth(2)
ax.spines['left'].set_linewidth(2)
ax.spines['right'].set_linewidth(2)
ax.spines['top'].set_linewidth(2)
# ax.spines['top'].set_linewidth(2)
# axins = zoomed_inset_axes(ax, 6, loc=7) # zoom = 10
# axins.plot(rgcn_mean, color='b')
# axins.plot(gcn_mean, color='r')
# axins.plot(gat_mean, color='lime')
# axins.plot(mlp_mean, color='yellow')
# axins.plot(random_mean, color='grey')
# axins.set_xlim(9900, 10000) # Limit the region for zoom
# axins.set_ylim(-1.2, -0.7)
# axins.set_xticks([])
# mark_inset(ax, axins, loc1=1, loc2=2, fc="none", ec="0.5")
# plt.savefig(f'./pics/reward_double_tail_comp_small.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/reward_double_tail_comp_small.png', format='png', bbox_inches='tight')

# plot how the best result evolve with simulation run
rgcn_best = np.array([np.max(np.mean([rews_buf1, rews_buf2, rews_buf3], axis=0)[200:i+1]) for i in range(200,len(rgcn_mean))])
gcn_best = np.array([np.max(np.mean([rews_buf4, rews_buf5, rews_buf6], axis=0)[200:i+1]) for i in range(200,len(gcn_mean))])
gat_best = np.array([np.max(np.mean([rews_buf7, rews_buf8, rews_buf9], axis=0)[200:i+1]) for i in range(200,len(gat_mean))])
mlp_best = np.array([np.max(np.mean([rews_buf10, rews_buf11, rews_buf12], axis=0)[200:i+1]) for i in range(200,len(mlp_mean))])
random_best = np.array([np.max(np.mean([rews_buf13, rews_buf14, rews_buf15], axis=0)[200:i+1]) for i in range(200,len(mlp_mean))])
x = np.linspace(num_random,num_steps,int(num_steps-num_random),dtype=np.int16)

plt.figure('Reward Improvement')
plt.plot(x,rgcn_best, 'b', label='RGCN') # RGCN
plt.plot(x,gcn_best, 'r', label='GCN') # GCN
plt.plot(x,gat_best, 'lime', label='GAT') # GAT
plt.plot(x,mlp_best, 'yellow', label='MLP') # MLP 
plt.plot(x,random_best, 'grey', label='Random') # Random
plt.xlabel('Number of Simulations', fontweight='bold', fontsize=14)
plt.xticks(fontsize=14, weight='bold')
plt.ylabel('Reward', fontweight='bold', fontsize=14)
plt.xticks(np.array([200,400,600,800,1000]))
plt.yticks(fontsize=14, fontweight='bold')
plt.legend(loc='upper left')
plt.grid(linewidth=2)
ax = plt.gca()
ax.spines['bottom'].set_linewidth(2)
ax.spines['left'].set_linewidth(2)
ax.spines['right'].set_linewidth(2)
ax.spines['top'].set_linewidth(2)
# plt.savefig(f'./pics/reward_best_double_tail_comp.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/reward_best_double_tail_comp.png', format='png', bbox_inches='tight')

''' plot optimal simulation results '''
# transient response clk-2-q
sim_results = OutputParser(GraphDoubleTailComp(), SPICE_NETLIST_DIR='/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/xschem/simulations')
time, Vclk = np.array(sim_results.tran(file_name='double_tail_comp_tb_Vclk_opt_final'))
_, Voutp = np.array(sim_results.tran(file_name='double_tail_comp_tb_Voutp_opt_final'))
_, Voutn = np.array(sim_results.tran(file_name='double_tail_comp_tb_Voutn_opt_final'))

fig, axs = plt.subplots(2)
axs[0].plot(time*1e9, Vclk, 'b', label='$\mathbf{V_{CLK}}$')
axs[0].plot(time*1e9, Vclk*-1+1.8, 'b--', label='$\mathbf{\overline{V_{CLK}}}$ ')
axs[0].set_ylabel('$\mathbf{V_{CLK}}$ (V)', fontweight='bold', fontsize=14)
axs[0].xaxis.set_tick_params(labelsize='14')
axs[0].yaxis.set_tick_params(labelsize='14')
axs[0].spines['bottom'].set_linewidth(2)
axs[0].spines['left'].set_linewidth(2)
axs[0].spines['right'].set_linewidth(2)
axs[0].spines['top'].set_linewidth(2)
axs[0].grid(linewidth=2)
axs[0].legend(loc='upper right', fontsize=14)

axs[1].plot(time*1e9, Voutp, 'b', label='$\mathbf{V_{outp}}$')
axs[1].plot(time*1e9, Voutn, 'r--', label='$\mathbf{V_{outn}}$')
axs[1].set_ylabel('$\mathbf{V_{out}}$ (V)', fontweight='bold', fontsize=14)
axs[1].xaxis.set_tick_params(labelsize='14')
axs[1].yaxis.set_tick_params(labelsize='14')
axs[1].spines['bottom'].set_linewidth(2)
axs[1].spines['left'].set_linewidth(2)
axs[1].spines['right'].set_linewidth(2)
axs[1].spines['top'].set_linewidth(2)
axs[1].grid(linewidth=2)
axs[1].set_yticks(np.array([0, 0.6, 1.2, 1.8]))
axs[1].set_xlabel('Time ($\mathbf{ns}$)', fontweight='bold', fontsize=14)
axs[1].legend(loc='upper right', fontsize=14)

# plt.savefig(f'./pics/clk2q_double_tail_comp.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/clk2q_double_tail_comp.png', format='png', bbox_inches='tight')

# peramp output Vdi
_, Vdip = np.array(sim_results.tran(file_name='double_tail_comp_tb_Vdip_opt_final'))
_, Vdin = np.array(sim_results.tran(file_name='double_tail_comp_tb_Vdin_opt_final'))

fig, axs = plt.subplots(2)
axs[0].plot(time*1e9, Vclk, 'b', label='$\mathbf{V_{CLK}}$')
axs[0].plot(time*1e9, Vclk*-1+1.8, 'b--', label='$\mathbf{\overline{V_{CLK}}}$ ')
axs[0].set_ylabel('$\mathbf{V_{CLK}}$ (V)', fontweight='bold', fontsize=14)
axs[0].xaxis.set_tick_params(labelsize='14')
axs[0].yaxis.set_tick_params(labelsize='14')
axs[0].spines['bottom'].set_linewidth(2)
axs[0].spines['left'].set_linewidth(2)
axs[0].spines['right'].set_linewidth(2)
axs[0].spines['top'].set_linewidth(2)
axs[0].grid(linewidth=2)
axs[0].legend(loc='upper right', fontsize=14)

axs[1].plot(time*1e9, Vdip, 'b', label='$\mathbf{V_{Dip}}$')
axs[1].plot(time*1e9, Vdin, 'r--', label='$\mathbf{V_{Din}}$')
axs[1].set_ylabel('$\mathbf{V_{Di}}$ (V)', fontweight='bold', fontsize=14)
axs[1].xaxis.set_tick_params(labelsize='14')
axs[1].yaxis.set_tick_params(labelsize='14')
axs[1].spines['bottom'].set_linewidth(2)
axs[1].spines['left'].set_linewidth(2)
axs[1].spines['right'].set_linewidth(2)
axs[1].spines['top'].set_linewidth(2)
axs[1].grid(linewidth=2)
axs[1].set_yticks(np.array([0, 0.6, 1.2, 1.8]))
axs[1].set_xlabel('Time ($\mathbf{ns}$)', fontweight='bold', fontsize=14)
axs[1].legend(loc='upper right', fontsize=14)

# plt.savefig(f'./pics/VDi_double_tail_comp.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/VDi_double_tail_comp.png', format='png', bbox_inches='tight')

# monte-carlo simulations on offset
# See <mc.py>

# kickback noise
_, Vknp = np.array(sim_results.tran(file_name='double_tail_comp_tb_Vp_kn_opt_final'))
_, Vknn = np.array(sim_results.tran(file_name='double_tail_comp_tb_Vn_kn_opt_final'))

fig, axs = plt.subplots(2)
axs[0].plot(time*1e9, Vclk, 'b', label='$\mathbf{V_{CLK}}$')
axs[0].plot(time*1e9, Vclk*-1+1.8, 'b--', label='$\mathbf{\overline{V_{CLK}}}$ ')
axs[0].set_ylabel('$\mathbf{V_{CLK}}$ (V)', fontweight='bold', fontsize=14)
axs[0].xaxis.set_tick_params(labelsize='14')
axs[0].yaxis.set_tick_params(labelsize='14')
axs[0].spines['bottom'].set_linewidth(2)
axs[0].spines['left'].set_linewidth(2)
axs[0].spines['right'].set_linewidth(2)
axs[0].spines['top'].set_linewidth(2)
axs[0].grid(linewidth=2)
axs[0].legend(loc='upper right', fontsize=14)

axs[1].plot(time*1e9,  (Vknp-Vknn-0.05)*1e3, 'b', label='$\mathbf{V_{kn}}$')
axs[1].set_ylabel('Kickback Noise (mV)', fontweight='bold', fontsize=14)
axs[1].xaxis.set_tick_params(labelsize='14')
axs[1].yaxis.set_tick_params(labelsize='14')
axs[1].spines['bottom'].set_linewidth(2)
axs[1].spines['left'].set_linewidth(2)
axs[1].spines['right'].set_linewidth(2)
axs[1].spines['top'].set_linewidth(2)
axs[1].grid(linewidth=2)
axs[1].set_yticks(np.array([-30, -20, -10, 0, 10, 20, 30]))
axs[1].set_xlabel('Time ($\mathbf{ns}$)', fontweight='bold', fontsize=14)

# plt.savefig(f'./pics/kickback_noise_double_tail_comp.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/kickback_noise_double_tail_comp.png', format='png', bbox_inches='tight')

""" Plot how each spec improve w.r.t. simulation run """
info1 = memory1.info_buf[:num_steps]
info2 = memory2.info_buf[:num_steps]
info3 = memory3.info_buf[:num_steps]

# Clock2Q,  offset, energy
clk2q_1 = np.array([info1[i]['Clock-to-Q delay (ns)'] for i in range(num_steps)])
clk2q_2 = np.array([info2[i]['Clock-to-Q delay (ns)'] for i in range(num_steps)])
clk2q_3 = np.array([info3[i]['Clock-to-Q delay (ns)'] for i in range(num_steps)])
clk2q_mean = np.mean([clk2q_1, clk2q_2, clk2q_3], axis=0)
clk2q_min = np.min([clk2q_1, clk2q_2, clk2q_3], axis=0)
clk2q_max = np.max([clk2q_1, clk2q_2, clk2q_3], axis=0)

offset_1 = np.array([info1[i]['Vos (V)'] for i in range(num_steps)])
offset_2 = np.array([info2[i]['Vos (V)'] for i in range(num_steps)])
offset_3 = np.array([info3[i]['Vos (V)'] for i in range(num_steps)])
offset_mean = np.mean([offset_1, offset_2, offset_3], axis=0)
offset_min = np.min([offset_1, offset_2, offset_3], axis=0)
offset_max = np.max([offset_1, offset_2, offset_3], axis=0)

energy_1 = np.array([info1[i]['Energy consumption (fJ/conversion)'] for i in range(num_steps)])
energy_2 = np.array([info2[i]['Vos (V)'] for i in range(num_steps)])
energy_3 = np.array([info3[i]['Vos (V)'] for i in range(num_steps)])
energy_mean = np.mean([energy_1, energy_2, energy_3], axis=0)
energy_min = np.min([energy_1, energy_2, energy_3], axis=0)
energy_max = np.max([energy_1, energy_2, energy_3], axis=0)

fig, axs = plt.subplots(3)
axs[0].plot(1e3*clk2q_mean, 'b') # RGCN
axs[0].fill_between(np.linspace(0, num_steps, num_steps), 1e3*clk2q_min, 1e3*clk2q_max, alpha=0.3, color='b') 
axs[0].set_ylabel('$\mathbf{Clk2Q}$\n(ps)', fontweight='bold', fontsize=14)
axs[0].axhline(y=230, color='r', linestyle='--', alpha=0.5)
axs[0].xaxis.set_ticklabels([])
axs[0].yaxis.set_tick_params(labelsize='14')
axs[0].spines['bottom'].set_linewidth(2)
axs[0].spines['left'].set_linewidth(2)
axs[0].spines['right'].set_linewidth(2)
axs[0].spines['top'].set_linewidth(2)
axs[0].grid(linewidth=2)
axs[0].set_yticks(np.array([100, 200, 300, 400]))

axs[1].plot(1e3*offset_mean, 'b') # RGCN
axs[1].fill_between(np.linspace(0, num_steps, num_steps), 1e3*offset_min, 1e3*offset_max, alpha=0.3, color='b')
axs[1].set_ylabel('$\mathbf{V_{os}}$\n(mV)', fontweight='bold', fontsize=14)
axs[1].axhline(y=10, color='r', linestyle='--', alpha=0.5)
axs[1].xaxis.set_ticklabels([])
axs[1].yaxis.set_tick_params(labelsize='14')
axs[1].spines['bottom'].set_linewidth(2)
axs[1].spines['left'].set_linewidth(2)
axs[1].spines['right'].set_linewidth(2)
axs[1].spines['top'].set_linewidth(2)
axs[1].grid(linewidth=2)

axs[2].plot(energy_mean, 'b') # RGCN
axs[2].fill_between(np.linspace(0, num_steps, num_steps), energy_min, energy_max, alpha=0.3, color='b')
axs[2].set_ylabel('Energy/Conv.\n(fJ/Conv.)', fontweight='bold', fontsize=14)
axs[2].axhline(y=200, color='r', linestyle='--', alpha=0.5)
axs[2].xaxis.set_tick_params(labelsize='14')
axs[2].yaxis.set_tick_params(labelsize='12')
axs[2].spines['bottom'].set_linewidth(2)
axs[2].spines['left'].set_linewidth(2)
axs[2].spines['right'].set_linewidth(2)
axs[2].spines['top'].set_linewidth(2)
axs[2].grid(linewidth=2)
axs[2].set_xlabel('Number of Simulations', fontweight='bold', fontsize=14)
axs[2].set_yticks(np.array([100, 200, 300, 400, 500, 600]))

# plt.savefig(f'./pics/specs_double_tail_comp.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/specs_double_tail_comp.png', format='png', bbox_inches='tight')

""" Plot how Vcm and M1/M2's W change w.r.t. simulation run """
action1 = memory1.acts_buf[:num_steps]
action2 = memory2.acts_buf[:num_steps]
action3 = memory3.acts_buf[:num_steps]
# M1 and M2
W_M1_mean = np.mean([action1[:num_steps,0], action2[:num_steps,0], action3[:num_steps,0]], axis=0)
W_M1_min = np.min([action1[:num_steps,0], action2[:num_steps,0], action3[:num_steps,0]], axis=0)
W_M1_max = np.max([action1[:num_steps,0], action2[:num_steps,0], action3[:num_steps,0]], axis=0)
W_M1_mean = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[0], action_space_high = \
                               GraphDoubleTailComp().action_space_high[0]).action(W_M1_mean) # convert [-1.1] range back to normal range
W_M1_min = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[0], action_space_high = \
                               GraphDoubleTailComp().action_space_high[0]).action(W_M1_min) # convert [-1.1] range back to normal range
W_M1_max = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[0], action_space_high = \
                               GraphDoubleTailComp().action_space_high[0]).action(W_M1_max) # convert [-1.1] range back to normal range

# M6 and M9
W_M6_mean = np.mean([action1[:num_steps,3], action2[:num_steps,3], action3[:num_steps,3]], axis=0)
W_M6_min = np.min([action1[:num_steps,3], action2[:num_steps,3], action3[:num_steps,3]], axis=0)
W_M6_max = np.max([action1[:num_steps,3], action2[:num_steps,3], action3[:num_steps,3]], axis=0)
W_M6_mean = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[3], action_space_high = \
                               GraphDoubleTailComp().action_space_high[3]).action(W_M6_mean) # convert [-1.1] range back to normal range
W_M6_min = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[3], action_space_high = \
                               GraphDoubleTailComp().action_space_high[3]).action(W_M6_min) # convert [-1.1] range back to normal range
W_M6_max = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[3], action_space_high = \
                               GraphDoubleTailComp().action_space_high[3]).action(W_M6_max) # convert [-1.1] range back to normal range

# M5
W_M5_mean = np.mean([action1[:num_steps,2], action2[:num_steps,2], action3[:num_steps,2]], axis=0)
W_M5_min = np.min([action1[:num_steps,2], action2[:num_steps,2], action3[:num_steps,2]], axis=0)
W_M5_max = np.max([action1[:num_steps,2], action2[:num_steps,2], action3[:num_steps,2]], axis=0)
W_M5_mean = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[2], action_space_high = \
                               GraphDoubleTailComp().action_space_high[2]).action(W_M5_mean) # convert [-1.1] range back to normal range
W_M5_min = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[2], action_space_high = \
                               GraphDoubleTailComp().action_space_high[2]).action(W_M5_min) # convert [-1.1] range back to normal range
W_M5_max = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[2], action_space_high = \
                               GraphDoubleTailComp().action_space_high[2]).action(W_M5_max) # convert [-1.1] range back to normal range

# M12
W_M12_mean = np.mean([action1[:num_steps,-2], action2[:num_steps,-2], action3[:num_steps,-2]], axis=0)
W_M12_min = np.min([action1[:num_steps,-2], action2[:num_steps,-2], action3[:num_steps,-2]], axis=0)
W_M12_max = np.max([action1[:num_steps,-2], action2[:num_steps,-2], action3[:num_steps,-2]], axis=0)
W_M12_mean = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[-2], action_space_high = \
                               GraphDoubleTailComp().action_space_high[-2]).action(W_M12_mean) # convert [-1.1] range back to normal range
W_M12_min = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[-2], action_space_high = \
                               GraphDoubleTailComp().action_space_high[-2]).action(W_M12_min) # convert [-1.1] range back to normal range
W_M12_max = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[-2], action_space_high = \
                               GraphDoubleTailComp().action_space_high[-2]).action(W_M12_max) # convert [-1.1] range back to normal range
    
# Vcm
Vcm_mean = np.mean([action2[:num_steps,-1], action3[:num_steps,-1]], axis=0)
Vcm_min = np.min([ action2[:num_steps,-1], action3[:num_steps,-1]], axis=0)
Vcm_max = np.max([action2[:num_steps,-1], action3[:num_steps,-1]], axis=0)
Vcm_mean = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[-1], action_space_high = \
                                GraphDoubleTailComp().action_space_high[-1]).action(Vcm_mean) # convert [-1.1] range back to normal range
Vcm_min = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[-1], action_space_high = \
                                GraphDoubleTailComp().action_space_high[-1]).action(Vcm_min) # convert [-1.1] range back to normal range
Vcm_max = ActionNormalizer(action_space_low=GraphDoubleTailComp().action_space_low[-1], action_space_high = \
                                GraphDoubleTailComp().action_space_high[-1]).action(Vcm_max) # convert [-1.1] range back to normal range

plt.figure('Transistor dimensions M1')
fig, axs = plt.subplots(3)
axs[0].plot(W_M1_mean, 'b', label='RGCN') # RGCN
axs[0].fill_between(np.linspace(0, num_steps, num_steps), W_M1_min, W_M1_max, alpha=0.3, color='b') 
axs[0].xaxis.set_ticklabels([])
axs[0].yaxis.set_tick_params(labelsize='14')
axs[0].set_ylabel('$\mathbf{W_{1}}$ $(\mathbf{\mu m})$', fontweight='bold', fontsize=14)
axs[0].spines['bottom'].set_linewidth(2)
axs[0].spines['left'].set_linewidth(2)
axs[0].spines['right'].set_linewidth(2)
axs[0].spines['top'].set_linewidth(2)
axs[0].grid(linewidth=2)
axs[0].set_yticks(np.array([0, 2, 4, 6, 8, 10]))

axs[1].plot(Vcm_mean, 'b', label='RGCN') # RGCN
axs[1].fill_between(np.linspace(0, num_steps, num_steps), Vcm_min, Vcm_max, alpha=0.3, color='b') 
axs[1].xaxis.set_ticklabels([])
axs[1].yaxis.set_tick_params(labelsize='14')
axs[1].set_ylabel('$\mathbf{V_{cm}}$ $(\mathbf{V})$', fontweight='bold', fontsize=14)
axs[1].spines['bottom'].set_linewidth(2)
axs[1].spines['left'].set_linewidth(2)
axs[1].spines['right'].set_linewidth(2)
axs[1].spines['top'].set_linewidth(2)
axs[1].grid(linewidth=2)
axs[1].set_yticks(np.array([0.9, 1.0, 1.1, 1.2]))

axs[2].plot(W_M12_mean, 'b', label='RGCN') # RGCN
axs[2].fill_between(np.linspace(0, num_steps, num_steps), W_M12_min, W_M12_max, alpha=0.3, color='b') 
axs[2].xaxis.set_tick_params(labelsize='14')
axs[2].yaxis.set_tick_params(labelsize='14')
axs[2].set_ylabel('$\mathbf{W_{12}}$ $(\mathbf{\mu m})$', fontweight='bold', fontsize=14)
axs[2].spines['bottom'].set_linewidth(2)
axs[2].spines['left'].set_linewidth(2)
axs[2].spines['right'].set_linewidth(2)
axs[2].spines['top'].set_linewidth(2)
axs[2].grid(linewidth=2)
axs[2].set_yticks(np.array([0, 2, 4, 6, 8, 10]))
axs[2].set_xlabel('Number of Simulations', fontweight='bold', fontsize=14)

# plt.savefig(f'./pics/W1_Vcm_double_tail_comp.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/W1_Vcm_double_tail_comp.png', format='png', bbox_inches='tight')


