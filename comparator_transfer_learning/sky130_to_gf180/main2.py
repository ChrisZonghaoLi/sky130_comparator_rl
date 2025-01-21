#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Running optimization for strong arm comparator.  Using TL from SKY130 to GF180MCU.

@author: lizongh2
"""

import torch
import numpy as np
import os
import json
from tabulate import tabulate
import gymnasium as gym
from gymnasium import spaces

import pickle

from ckt_graphs import GraphStrongArmComp
from dev_params import DeviceParams
from utils import ActionNormalizer, OutputParser
from ddpg import DDPGAgent
from models import ActorCriticRGCN, ActorCriticGCN, ActorCriticGAT, ActorCriticMLP

from strong_arm_comp import StrongArmCompEnv

from datetime import datetime
date = datetime.today().strftime('%Y-%m-%d')

PWD = os.getcwd()
SPICE_NETLIST_DIR = f'{PWD}/simulations'
NETLIST_NAME = 'strong_arm_comp_tb'
os.environ['CUDA_LAUNCH_BLOCKING'] = "1"

# """ Check if the GF180MCU environment variables are set """
# assert os.environ['PDK'] == 'gf180mcuC', 'GF180 environment variables are not set'
# assert os.environ['PDK_ROOT'] == '/usr/local/share/pdk', 'GF180 environment variables are not set'

CktGraph = GraphStrongArmComp
GNN = ActorCriticRGCN # you can select other NN
rew_eng = CktGraph().rew_eng

""" Regsiter the environemnt to gymnasium """

from gymnasium.envs.registration import register

env_id = 'gf180-strong_arm_comp_tl-v0'

env_dict = gym.envs.registration.registry.copy()

for env in env_dict:
    if env_id in env:
        print("Remove {} from registry".format(env))
        del gym.envs.registration.registry[env]

print("Register the environment")
register(
        id = env_id,
        entry_point = 'strong_arm_comp:StrongArmCompEnv',
        max_episode_steps = 50,
        )
env = gym.make(env_id)  

""" Run intial op experiment """
run_intial = False
if run_intial == True:
    env = StrongArmCompEnv()
    env._init_random_sim(100)

""" Load the actor and critic NN from sky130 StrongARM comparator """
TL = True
if TL == True:
    if GNN().__class__.__name__ == 'ActorCriticRGCN':
        print('Load RGCN')
        save_name_actor = 'Actor_GraphStrongArmComp_2023-12-07_noise=uniform_reward=11.50_ActorCriticRGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1.pth'
        save_name_critic = 'Critic_GraphStrongArmComp_2023-12-07_noise=uniform_reward=11.50_ActorCriticRGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1.pth'
        
    if GNN().__class__.__name__ == 'ActorCriticMLP':
        print('Load MLP')
        save_name_actor = 'Actor_GraphStrongArmComp_2023-12-08_noise=uniform_reward=11.32_ActorCriticMLP_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1.pth'
        save_name_critic = 'Critic_GraphStrongArmComp_2023-12-08_noise=uniform_reward=11.32_ActorCriticMLP_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1.pth'
    
    if GNN().__class__.__name__ == 'ActorCriticGCN':
        print('Load GCN')
        save_name_actor = 'Actor_GraphStrongArmComp_2023-12-08_noise=uniform_reward=11.46_ActorCriticGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1.pth'
        save_name_critic = 'Critic_GraphStrongArmComp_2023-12-08_noise=uniform_reward=11.46_ActorCriticGCN_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1.pth'
        
    if GNN().__class__.__name__ == 'ActorCriticGAT':
        print('Load GAT')
        save_name_actor = 'Actor_GraphStrongArmComp_2023-12-08_noise=uniform_reward=-0.11_ActorCriticGAT_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1.pth'
        save_name_critic = 'Critic_GraphStrongArmComp_2023-12-08_noise=uniform_reward=-0.11_ActorCriticGAT_num_steps=1000_initial_random_steps=200_noise_sigma_decay=1.pth'

    Actor = GNN().Actor(CktGraph())
    Actor.load_state_dict(torch.load(PWD + "/saved_weights_sky130/" + save_name_actor), strict=False)
    Actor.eval()
    Critic = GNN().Critic(CktGraph())
    Critic.load_state_dict(torch.load(PWD + "/saved_weights_sky130/" + save_name_critic), strict=False)
    Critic.eval()
else:
    Actor = GNN().Actor(CktGraph())
    Critic = GNN().Critic(CktGraph())  

""" Do the training """
# parameters
num_steps = 1000
memory_size = 100000
batch_size = 128
noise_sigma = 0.1 # noise volume
noise_sigma_min = 0.1
noise_sigma_decay = 1 # if 1 means no decay
initial_random_steps = 0
noise_type = 'uniform' 

agent = DDPGAgent(
    env, 
    CktGraph(),
    Actor,
    Critic,
    memory_size, 
    batch_size,
    noise_sigma,
    noise_sigma_min,
    noise_sigma_decay,
    initial_random_steps=initial_random_steps,
    noise_type=noise_type, 
)

test = True
if test == False:
    # train the agent
    agent.train(num_steps)
else:
    # test the agent
    agent.test(num_steps)
    
""" Replay the best results """
memory = agent.memory
rews_buf = memory.rews_buf[:num_steps]
info  = memory.info_buf[:num_steps]
best_design = np.argmax(rews_buf)
best_reward = np.max(rews_buf)
best_action = memory.acts_buf[best_design]
agent.env.step(best_action) # run the simulations

results = OutputParser(CktGraph())
op_results = results.dcop(f'{NETLIST_NAME}_op')

# saved agent's actor and critic network, save memory buffer and agent
save = False
if save == True and TL == True:
    model_weight_actor = agent.actor.state_dict()
    save_name_actor = f"New_Power_Spec_TL_Actor_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pth"
      
    model_weight_critic = agent.critic.state_dict()
    save_name_critic = f"New_Power_Spec_TL_Critic_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pth"
      
    torch.save(model_weight_actor, PWD + "/saved_weights/" + save_name_actor)
    torch.save(model_weight_critic, PWD + "/saved_weights/" + save_name_critic)
    print("Actor and Critic weights have been saved!")

    # save memory
    with open(f'./saved_memories/New_Power_Spec_TL_memory_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pkl', 'wb') as memory_file:
        pickle.dump(memory, memory_file)

    np.save(f'./saved_memories/New_Power_Spec_TL_rews_buf_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}', rews_buf)

    # save agent
    with open(f'./saved_agents/New_Power_Spec_TL_DDPGAgent_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pkl', 'wb') as agent_file:
        pickle.dump(agent, agent_file)

if save == True and TL == False:
    model_weight_actor = agent.actor.state_dict()
    save_name_actor = f"New_Power_Spec_TL=False_Actor_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pth"
      
    model_weight_critic = agent.critic.state_dict()
    save_name_critic = f"New_Power_Spec_TL=False_Critic_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pth"
      
    torch.save(model_weight_actor, PWD + "/saved_weights/" + save_name_actor)
    torch.save(model_weight_critic, PWD + "/saved_weights/" + save_name_critic)
    print("Actor and Critic weights have been saved!")

    # save memory
    with open(f'./saved_memories/New_Power_Spec_TL=False_memory_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pkl', 'wb') as memory_file:
        pickle.dump(memory, memory_file)

    np.save(f'./saved_memories/New_Power_Spec_TL=False_rews_buf_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}', rews_buf)

    # save agent
    with open(f'./saved_agents/New_Power_Spec_TL=False_DDPGAgent_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pkl', 'wb') as agent_file:
        pickle.dump(agent, agent_file)

