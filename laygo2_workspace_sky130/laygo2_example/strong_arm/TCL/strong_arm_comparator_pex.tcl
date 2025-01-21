source strong_arm_comparator.tcl
select top cell
expand
flatten comparator_flat
load comparator_flat
cellname delete strong_arm_comparator
cellname rename comparator_flat strong_arm_comparator_pex
select top cell
extract all
ext2sim labels on
ext2sim
extresist tolerance 0.01
extresist
ext2spice lvs
ext2spice cthresh 0
ext2spice extresist on
ext2spice
