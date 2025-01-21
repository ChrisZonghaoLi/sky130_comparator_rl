#!/bin/bash

touch .maginit_personal

echo "addpath $PWD/magic_layout/skywater130_microtemplates_dense" | tee .maginit_personal
echo "addpath $PWD/magic_layout/logic_generated" >> .maginit_personal
echo "addpath $PWD/magic_layout/strong_arm" >> .maginit_personal
echo "addpath $PWD/magic_layout/double_tail" >> .maginit_personal
echo "source /usr/local/share/pdk/sky130A/libs.tech/magic/sky130A.magicrc" >> .maginit_personal
