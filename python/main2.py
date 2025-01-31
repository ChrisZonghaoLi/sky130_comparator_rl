#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Running optimization for strong arm comparator

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

CktGraph = GraphStrongArmComp
GNN = ActorCriticRGCN # you can select other NN
rew_eng = CktGraph().rew_eng

""" Regsiter the environemnt to gymnasium """

from gymnasium.envs.registration import register

env_id = 'sky130-strong_arm_comp-v0'

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

""" Do the training """
# parameters
num_steps = 1000
memory_size = 100000
batch_size = 128
noise_sigma = 0.1 # noise volume
noise_sigma_min = 0.1
noise_sigma_decay = 1 # if 1 means no decay
initial_random_steps = 200
noise_type = 'uniform' 

random = False
if random == True:
    initial_random_steps = num_steps
    print("=== Warning: Random sampling is used instead of DDPG ===")

agent = DDPGAgent(
    env, 
    CktGraph(),
    GNN().Actor(CktGraph()),
    GNN().Critic(CktGraph()),
    memory_size, 
    batch_size,
    noise_sigma,
    noise_sigma_min,
    noise_sigma_decay,
    initial_random_steps=initial_random_steps,
    noise_type=noise_type, 
)

# train the agent
agent.train(num_steps)

""" Replay the best results """
memory = agent.memory
rews_buf = memory.rews_buf[:num_steps]
info  = memory.info_buf[:num_steps]
best_design = np.argmax(rews_buf)
best_reward = np.max(rews_buf)
best_action = memory.acts_buf[best_design]
agent.env.step(best_action) # run the simulations
acts_buf = memory.acts_buf[:num_steps]

results = OutputParser(CktGraph())
op_results = results.dcop(f'{NETLIST_NAME}_op')

# saved agent's actor and critic network, save memory buffer and agent
save = False
if save == True and random == False:
    model_weight_actor = agent.actor.state_dict()
    save_name_actor = f"Actor_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_num_steps={num_steps}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pth"
      
    model_weight_critic = agent.critic.state_dict()
    save_name_critic = f"Critic_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_num_steps={num_steps}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pth"
      
    torch.save(model_weight_actor, PWD + "/saved_weights/" + save_name_actor)
    torch.save(model_weight_critic, PWD + "/saved_weights/" + save_name_critic)
    print("Actor and Critic weights have been saved!")

    # save memory
    with open(f'./saved_memories/memory_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_num_steps={num_steps}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pkl', 'wb') as memory_file:
        pickle.dump(memory, memory_file)

    np.save(f'./saved_memories/rews_buf_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_num_steps={num_steps}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}', rews_buf)

    # save agent
    with open(f'./saved_agents/DDPGAgent_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_{GNN().__class__.__name__}_num_steps={num_steps}_initial_random_steps={initial_random_steps}_noise_sigma_decay={noise_sigma_decay}.pkl', 'wb') as agent_file:
        pickle.dump(agent, agent_file)

if save == True and random == True:
    # no need to save weights as no training is done
    # save memory
    with open(f'./saved_memories/memory_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_random.pkl', 'wb') as memory_file:
        pickle.dump(memory, memory_file)

    np.save(f'./saved_memories/rews_buf_{CktGraph().__class__.__name__}_{date}_noise={noise_type}_reward={best_reward:.3f}_random', rews_buf)
