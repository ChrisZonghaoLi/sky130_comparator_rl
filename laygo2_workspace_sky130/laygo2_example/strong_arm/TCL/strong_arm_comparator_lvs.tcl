source strong_arm_comparator.tcl
select top cell
expand
flatten comparator_flat
load comparator_flat
cellname delete strong_arm_comparator
cellname rename comparator_flat strong_arm_comparator_lvs
select top cell
extract all
ext2spice lvs
ext2spice
