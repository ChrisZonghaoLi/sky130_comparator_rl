source double_tail_comparator.tcl
select top cell
expand
flatten comparator_flat
load comparator_flat
cellname delete double_tail_comparator
cellname rename comparator_flat double_tail_comparator_lvs
select top cell
extract all
ext2spice lvs
ext2spice
