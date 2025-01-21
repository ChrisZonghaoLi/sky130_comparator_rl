# Optimizing Latched Comparator in SKY130 and GF180MCU Using Reinforcement Learning and Transfer Learning

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![CI](https://github.com/efabless/caravel_user_project_analog/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_user_project_analog/actions/workflows/user_project_ci.yml) [![Caravan Build](https://github.com/efabless/caravel_user_project_analog/actions/workflows/caravan_build.yml/badge.svg)](https://github.com/efabless/caravel_user_project_analog/actions/workflows/caravan_build.yml)

---
This repo contains the code used to run the StrongARM and double-tail comparator optimization in SKY130 using Reinforcement Learning. For more details please read our paper here at IEEE Access: https://ieeexplore.ieee.org/abstract/document/10714341.

What makes this work special? The following are some of the contributions from this work:
1. We propose using a heterogeneous GNN as the function approximator for RL. Our optimization results show it achieves higher reward values with fewer iterations than the homogeneous GNN.
2. Our AMS circuit optimization framework provides insights into the correlation between circuit design parameters and target specifications. By looking into the optimization trajectories of particular design parameters and simulation results, designers can discover useful design trade-offs that may guide future manual design.
3. Our framework enables a specification-to-layout closed-loop optimization cycle.
4. Here might be an interesting one. We propose a simple yet effective method to predict the input-offset voltage Vos of the latched comparator with reasonable accuracy. This method allows our framework to optimize Vos for both StrongARM and double-tail comparators in the optimization loop, obviating the need for time-consuming Monte Carlo (MC) simulations.
5. Finally, our entire framework is fully open-sourced (I will make the source code available soon here: https://lnkd.in/eHnEWHhG), enabling researchers to reuse the code and reproduce similar results. We hope this effort spurs research progress in this area.
