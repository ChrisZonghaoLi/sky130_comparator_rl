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
# file_name1 = 'TL_memory_GraphStrongArmComp_2024-03-05_noise=uniform_reward=11.293_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
# file_name2 = 'TL_memory_GraphStrongArmComp_2024-03-05_noise=uniform_reward=11.296_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
# file_name3 = 'TL_memory_GraphStrongArmComp_2024-03-06_noise=uniform_reward=11.295_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
file_name1 = 'TL_memory_GraphStrongArmComp_2024-03-09_noise=uniform_reward=11.0904_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1_test=True'
file_name2 = 'TL_memory_GraphStrongArmComp_2024-03-09_noise=uniform_reward=11.090_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1_test=True'
file_name3 = 'TL_memory_GraphStrongArmComp_2024-03-09_noise=uniform_reward=11.089_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1_test=True'

# No TL
file_name4 = 'TL=False_memory_GraphStrongArmComp_2024-03-07_noise=uniform_reward=-0.167_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
file_name5 = 'TL=False_memory_GraphStrongArmComp_2024-03-07_noise=uniform_reward=-0.234_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'
file_name6 = 'TL=False_memory_GraphStrongArmComp_2024-03-07_noise=uniform_reward=-1.267_ActorCriticRGCN_initial_random_steps=0_noise_sigma_decay=1'

num_steps = 100
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

rews_buf1 = memory1.rews_buf[:num_steps]
rews_buf2 = memory2.rews_buf[:num_steps]
rews_buf3 = memory3.rews_buf[:num_steps]

rews_buf4 = memory4.rews_buf[:num_steps]
rews_buf5 = memory5.rews_buf[:num_steps]
rews_buf6 = memory6.rews_buf[:num_steps]

def average_window(rews_buf, window=1):
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
no_tl_mean = average_window(np.mean([rews_buf4, rews_buf5, rews_buf6], axis=0))
no_tl_std =  np.std([rews_buf4, rews_buf5, rews_buf6], axis=0)

plt.figure('Reward')
plt.plot(rgcn_mean, 'b', label='RGCN') # RGCN
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf1, rews_buf2, rews_buf3], axis=0), np.max([rews_buf1, rews_buf2, rews_buf3], axis=0), alpha=0.3, color='b') 
plt.plot(no_tl_mean, 'grey', label='No TL (RGCN)') # No TL
plt.fill_between(np.linspace(0, num_steps, num_steps), np.min([rews_buf4, rews_buf5, rews_buf6], axis=0), np.max([rews_buf4, rews_buf5, rews_buf6], axis=0), alpha=0.3, color='grey') 
plt.xlabel('Number of Simulations', fontweight='bold', fontsize=20)
plt.xticks(fontsize=20, weight='bold')
# plt.xticks(np.arange(0, num_steps+1, 200))
plt.ylabel('Reward', fontweight='bold', fontsize=20)
plt.yticks(fontsize=20, fontweight='bold')
plt.legend(loc='lower left', fontsize=14)
plt.grid(linewidth=2)
ax = plt.gca()
ax.spines['bottom'].set_linewidth(2)
ax.spines['left'].set_linewidth(2)
ax.spines['right'].set_linewidth(2)
ax.spines['top'].set_linewidth(2)
# plt.savefig(f'./pics/tl_reward_sky130_pex_strong_arm_comp_small.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/tl_reward_sky130_pex_strong_arm_comp_small.png', format='png', bbox_inches='tight')

''' plot optimal simulation results '''
# transient response clk-2-q
sim_results = OutputParser(GraphStrongArmComp(), SPICE_NETLIST_DIR= '/autofs/fs1.ece/fs1.eecg.tcc/lizongh2/comparator_transfer_learning/pex/simulations')
time, Vclk = np.array(sim_results.tran(file_name='strong_arm_comp_pex_tb_Vclk'))
_, Voutp = np.array(sim_results.tran(file_name='strong_arm_comp_pex_tb_Voutp'))
_, Voutn = np.array(sim_results.tran(file_name='strong_arm_comp_pex_tb_Voutn'))

fig, axs = plt.subplots(2)
axs[0].plot(time*1e9, Vclk, 'b', label='$\mathbf{V_{CLK}}$')
axs[0].set_ylabel('$\mathbf{V_{CLK}}$ (V)', fontweight='bold', fontsize=20)
axs[0].xaxis.set_tick_params(labelsize='20')
axs[0].yaxis.set_tick_params(labelsize='20')
axs[0].spines['bottom'].set_linewidth(2)
axs[0].spines['left'].set_linewidth(2)
axs[0].spines['right'].set_linewidth(2)
axs[0].spines['top'].set_linewidth(2)
axs[0].grid(linewidth=2)
axs[0].set_yticks(np.array([0, 0.6, 1.2, 1.8]))
axs[0].set_xticks(np.array([0, 0.5, 1, 1.5, 2, 2.5, 3]))
axs[0].xaxis.set_ticklabels([])

axs[1].plot(time*1e9, Voutp, 'b', label='$\mathbf{V_{outp}}$')
axs[1].plot(time*1e9, Voutn, 'r--', label='$\mathbf{V_{outn}}$')
axs[1].set_ylabel('$\mathbf{V_{out}}$ (V)', fontweight='bold', fontsize=20)
axs[1].xaxis.set_tick_params(labelsize='20')
axs[1].yaxis.set_tick_params(labelsize='20')
axs[1].spines['bottom'].set_linewidth(2)
axs[1].spines['left'].set_linewidth(2)
axs[1].spines['right'].set_linewidth(2)
axs[1].spines['top'].set_linewidth(2)
axs[1].grid(linewidth=2)
axs[1].set_yticks(np.array([0, 0.6, 1.2, 1.8]))
axs[1].set_xticks(np.array([0, 0.5, 1, 1.5, 2, 2.5, 3]))
axs[1].set_xlabel('Time ($\mathbf{ns}$)', fontweight='bold', fontsize=20)
axs[1].legend(loc='upper right', fontsize=16)

# plt.savefig(f'./pics/clk2q_strong_arm_comp_pex_small.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/clk2q_strong_arm_comp_pex_small.png', format='png', bbox_inches='tight')


# peramp output Vdi
_, Vdip = np.array(sim_results.tran(file_name='strong_arm_comp_pex_tb_Vdip'))
_, Vdin = np.array(sim_results.tran(file_name='strong_arm_comp_pex_tb_Vdin'))

fig, axs = plt.subplots(2)
axs[0].plot(time*1e9, Vclk, 'b', label='$\mathbf{V_{CLK}}$')
axs[0].set_ylabel('$\mathbf{V_{CLK}}$ (V)', fontweight='bold', fontsize=14)
axs[0].xaxis.set_tick_params(labelsize='14')
axs[0].yaxis.set_tick_params(labelsize='14')
axs[0].spines['bottom'].set_linewidth(2)
axs[0].spines['left'].set_linewidth(2)
axs[0].spines['right'].set_linewidth(2)
axs[0].spines['top'].set_linewidth(2)
axs[0].grid(linewidth=2)

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

# plt.savefig(f'./pics/VDi_strong_arm_comp_pex.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/VDi_strong_arm_comp_pex.png', format='png', bbox_inches='tight')


# kickback noise
_, Vknp = np.array(sim_results.tran(file_name='strong_arm_comp_pex_tb_Vp_kn'))
_, Vknn = np.array(sim_results.tran(file_name='strong_arm_comp_pex_tb_Vn_kn'))

fig, axs = plt.subplots(2)
axs[0].plot(time*1e9, Vclk, 'b', label='$\mathbf{V_{CLK}}$')
axs[0].set_ylabel('$\mathbf{V_{CLK}}$ (V)', fontweight='bold', fontsize=14)
axs[0].xaxis.set_tick_params(labelsize='14')
axs[0].yaxis.set_tick_params(labelsize='14')
axs[0].spines['bottom'].set_linewidth(2)
axs[0].spines['left'].set_linewidth(2)
axs[0].spines['right'].set_linewidth(2)
axs[0].spines['top'].set_linewidth(2)
axs[0].grid(linewidth=2)

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

# plt.savefig(f'./pics/kickback_noise_strong_arm_comp_pex.pdf', format='pdf', bbox_inches='tight')
# plt.savefig(f'./pics/kickback_noise_strong_arm_comp_pex.png', format='png', bbox_inches='tight')