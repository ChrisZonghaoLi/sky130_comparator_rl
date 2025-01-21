# laygo2 layout export magic(tcl) script.

# _laygo2_create_layout:
# parameters:
#  - libpath: path of folder for cellfile
#  - _cellname: name of cellfile (without .mag)
#  - techname: [name of tech file[.tech]] in the system tech folder 
# flow:
# 1. create cell (if _cellname already loaded on db, just load it to layout window -> need to clear before run script but I don't know how to clear yet. So you need to shutdown and run magic again to reset db before run script)
# 2. load tech: tk_path tech load techname(include path, no need a suffix .tech)
# 3. load cell: 
# 4. select layout and turn into editmode
# 5. return cv

proc _laygo2_create_layout {libpath _cellname techname} {
    cellname create $_cellname
#    set techFileName_full [tech filename]
#    set nameidx [expr [string last / $techFileName_full] + 1 ]
#    set techFileName [string range $techFileName_full $nameidx [string length $techFileName_full] ]
#    if { $techFileName != $techname } {
#        tech load $techname
#    }
    if { [tech name] != $techname } {
        tech load $techname
    }
    cellname filepath $_cellname $libpath
    load $_cellname
    select top cell
    edit
# if same named cell already exist, erase it.
    set ilist [cellname list childinst]
    set len [llength $ilist]
    for { set idx 0 } { $idx < $len } { incr idx 1 } {
        set bracket [string first \\ [lindex $ilist $idx]]
        if { $bracket != -1 } {
            set instname [string range [lindex $ilist $idx] 0 [expr $bracket - 1] ]
        } else {
            set instname [lindex $ilist $idx]
        }
        select cell $instname
        delete
    }
    select top cell    
    select area
    delete
}; # create new edit cell

proc _laygo2_open_layout {libpath _cellname techname} {
    if { [tech filename] != $techname } {
        tech load $techname
    }
    load ${libpath}/${_cellname}
    select
    edit
}; # open layout file

proc _laygo2_clear_layout {} {
    select top cell
    select area
    delete
}; # we can't delete subcells with this -> must get children instance name list 
proc _laygo2_save_and_close_layout {cv} {
    $cv save
    set frameName [string range $cv 0 [expr [string first . $cv 1] - 1]]
    closewrapper $frameName
}; # save layout and close window
#don't use now
# TODO: should find way to unload cell from layout

#more metal layers may added
proc _laygo2_generate_rect {layer bbox} { 
    box values [lindex [lindex $bbox 0] 0] [lindex [lindex $bbox 0] 1] [lindex [lindex $bbox 1] 0] [lindex [lindex $bbox 1] 1]
    switch -exact -- $layer {
        M1 { paint metal1 }
        M2 { paint metal2 }
        M3 { paint metal3 }
        M4 { paint metal4 }
        M5 { paint metal5 }
        default { paint $layer }
    }
}; #create a rectangle

proc _laygo2_generate_pin {name layer bbox port_num} {
    set pin_w [ expr [lindex [lindex $bbox 1] 0] - [lindex [lindex $bbox 0] 0] ]
    set pin_cx [expr [expr [lindex [lindex $bbox 1] 0] + [lindex [lindex $bbox 0] 0]] / 2]
    set pin_cy [expr [expr [lindex [lindex $bbox 1] 1] + [lindex [lindex $bbox 0] 1]] / 2]
    set pin_h [ expr [lindex [lindex $bbox 1] 1] - [lindex [lindex $bbox 0] 1] ]
    switch -exact -- $layer {
        M1 { set layer_real metal1 }
        M2 { set layer_real metal2 }
        M3 { set layer_real metal3 }
        M4 { set layer_real metal4 }
        M5 { set layer_real metal5 }
        default { set layer_real $layer }
    }
    box values [lindex [lindex $bbox 0] 0] [lindex [lindex $bbox 0] 1] [lindex [lindex $bbox 1] 0] [lindex [lindex $bbox 1] 1]
    paint $layer_real
    if {$pin_w >= $pin_h} {
        box values $pin_cx $pin_cy $pin_cx $pin_cy
        label $name FreeSans $pin_h 0 0 0 center $layer_real
    } else {
        box values $pin_cx $pin_cy $pin_cx $pin_cy
        label $name FreeSans $pin_w 90 0 0 center $layer_real
    }
    box values $pin_cx $pin_cy $pin_cx $pin_cy
    select area label
    setlabel layer $layer_real
    port make $port_num
}; #print label on layer bbox

# notice: filename must have form of path/cellname.mag otherwise, segmentation fault occur when import one cellfile twice
# param: 
#     -name: instanceName
#     -loc: xy location of lower-left
#     -orient: R0(default), MX(v), MY(h), R90(90), R180(180), MXY(270)
#     -num_rows: (mosaic) number of instances for y direction
#     -num_cols: (mosaic) number of instances for x direction
#     -sp_rows: (mosaic) y_pitch between adjacent instance
#     -sp_cols: (mosaic) x_pitch between adjacent instance
# TODO:
#     - make routine for checking if cellfile exist
# flow:
#     check if array or single
#     1.case_single -> getcell
#     2.case_array -> getcell -> select -> box size sp_cols sp_rows -> array num_cols num_rows

proc _laygo2_generate_instance { name libpath _cellname loc orient num_rows num_cols sp_rows sp_cols} {
        switch -exact -- $orient {
            R0 { set orientation 0 }
            MX { set orientation v }
            MY { set orientation h }
            R90 { set orientation 90 }
            R180 { set orientation 180 }
            MXY { set orientation 270 }
            default { set orientation 0 }
        }
        box position [lindex $loc 0] [lindex $loc 1]
        if { $orientation == 0 } {
#            set instName [ getcell ${libpath}/${_cellname}.mag child 0 0 parent ll ]
            set instName [ getcell ${_cellname}.mag child 0 0 parent ll ]
        } else {
#            set instName [ getcell ${libpath}/${_cellname}.mag child 0 0 parent ll $orientation 0 0 ]
            set instName [ getcell ${_cellname}.mag child 0 0 parent ll $orientation 0 0 ]
        }
        select cell $instName
        identify $name
        if { ($num_cols != 1) || ($num_rows != 1) } { ; # array command to make mosaic
            box size $sp_cols $sp_rows
            array $num_cols $num_rows
        }
};

proc _laygo2_test {libpath _cellname techname} {
# create layout file
_laygo2_create_layout ./magic_layout laygo2_test_inv_2x sky130A
#generate rects&instance.
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 1 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 216.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 54.0  345.0  } { 234.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 1 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 54.0  201.0  } { 234.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 1 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 298.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 1 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 216.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 54.0  663.0  } { 234.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 1 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 54.0  807.0  } { 234.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 1 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 298.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 2 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 308.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 308.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } }  ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 129.0  216.0  } { 159.0  792.0  } }  ; # for the Pin object O 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 288.0  30.0  } }  ; # for the Pin object VSS 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 288.0  1038.0  } }  ; # for the Pin object VDD 
#save and close
save
}

# exporting double_tail__comparator
_laygo2_create_layout /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/double_tail double_tail_comparator sky130A
_laygo2_generate_instance diff_pair /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/double_tail double_tail_diff_pair { 432.0  0.0  } MX 1 1 0 0 ; # for the Instance object diff_pair 
_laygo2_generate_instance latch /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/double_tail double_tail_latch { 936.0  0.0  } R0 1 1 0 0 ; # for the Instance object latch 
_laygo2_generate_rect M2 { { 993.0  -735.0  } { 1527.0  -705.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1512.0  -720.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_instance NoName_2 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1512.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_2 
_laygo2_generate_rect M3 { { 1497.0  -735.0  } { 1527.0  375.0  } } ; # for the Rect object NoName_3 
_laygo2_generate_rect M2 { { 345.0  -735.0  } { 879.0  -705.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 360.0  -720.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_instance NoName_6 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 360.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_6 
_laygo2_generate_rect M3 { { 345.0  -735.0  } { 375.0  375.0  } } ; # for the Rect object NoName_7 
_laygo2_generate_instance NoName_8 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_instance NoName_9 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 216.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_9 
_laygo2_generate_instance NoName_10 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_instance NoName_11 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 360.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_instance NoName_12 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_12 
_laygo2_generate_instance NoName_13 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 504.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_instance NoName_14 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_14 
_laygo2_generate_instance NoName_15 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 648.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_15 
_laygo2_generate_instance NoName_16 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_16 
_laygo2_generate_instance NoName_17 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 792.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_17 
_laygo2_generate_instance NoName_18 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_18 
_laygo2_generate_instance NoName_19 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 936.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_19 
_laygo2_generate_instance NoName_20 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_20 
_laygo2_generate_instance NoName_21 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1080.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_21 
_laygo2_generate_instance NoName_22 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_22 
_laygo2_generate_instance NoName_23 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1224.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_23 
_laygo2_generate_instance NoName_24 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1296.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_24 
_laygo2_generate_instance NoName_25 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1368.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_25 
_laygo2_generate_instance NoName_26 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1440.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_26 
_laygo2_generate_instance NoName_27 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1512.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_27 
_laygo2_generate_instance NoName_28 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1584.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_28 
_laygo2_generate_instance NoName_29 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1656.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_29 
_laygo2_generate_instance NoName_30 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1728.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_30 
_laygo2_generate_rect M3 { { 114.0  1482.0  } { 1758.0  1542.0  } } ; # for the Rect object NoName_31 
_laygo2_generate_instance NoName_32 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 144.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_32 
_laygo2_generate_instance NoName_33 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 216.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_33 
_laygo2_generate_instance NoName_34 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 288.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_34 
_laygo2_generate_instance NoName_35 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 360.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_35 
_laygo2_generate_instance NoName_36 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 432.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_36 
_laygo2_generate_instance NoName_37 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 504.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_37 
_laygo2_generate_instance NoName_38 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 576.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_38 
_laygo2_generate_instance NoName_39 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 648.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_39 
_laygo2_generate_instance NoName_40 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 720.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_40 
_laygo2_generate_instance NoName_41 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 792.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_41 
_laygo2_generate_instance NoName_42 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 864.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_42 
_laygo2_generate_instance NoName_43 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 936.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_43 
_laygo2_generate_instance NoName_44 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1008.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_44 
_laygo2_generate_instance NoName_45 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1080.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_45 
_laygo2_generate_instance NoName_46 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1152.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_46 
_laygo2_generate_instance NoName_47 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1224.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_47 
_laygo2_generate_instance NoName_48 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1296.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_48 
_laygo2_generate_instance NoName_49 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1368.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_49 
_laygo2_generate_instance NoName_50 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1440.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_50 
_laygo2_generate_instance NoName_51 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1512.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_51 
_laygo2_generate_instance NoName_52 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1584.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_52 
_laygo2_generate_instance NoName_53 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1656.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_53 
_laygo2_generate_instance NoName_54 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1728.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_54 
_laygo2_generate_rect M4 { { 114.0  1462.0  } { 1758.0  1562.0  } } ; # for the Rect object NoName_55 
_laygo2_generate_instance NoName_56 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_56 
_laygo2_generate_instance NoName_57 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 648.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_57 
_laygo2_generate_instance NoName_58 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_58 
_laygo2_generate_instance NoName_59 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 792.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_59 
_laygo2_generate_instance NoName_60 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_60 
_laygo2_generate_instance NoName_61 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 936.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_61 
_laygo2_generate_instance NoName_62 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_62 
_laygo2_generate_instance NoName_63 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1080.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_63 
_laygo2_generate_instance NoName_64 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_64 
_laygo2_generate_instance NoName_65 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1224.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_65 
_laygo2_generate_instance NoName_66 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1296.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_66 
_laygo2_generate_rect M3 { { 546.0  -1542.0  } { 1326.0  -1482.0  } } ; # for the Rect object NoName_67 
_laygo2_generate_instance NoName_68 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 576.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_68 
_laygo2_generate_instance NoName_69 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 648.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_69 
_laygo2_generate_instance NoName_70 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 720.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_70 
_laygo2_generate_instance NoName_71 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 792.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_71 
_laygo2_generate_instance NoName_72 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 864.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_72 
_laygo2_generate_instance NoName_73 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 936.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_73 
_laygo2_generate_instance NoName_74 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1008.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_74 
_laygo2_generate_instance NoName_75 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1080.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_75 
_laygo2_generate_instance NoName_76 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1152.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_76 
_laygo2_generate_instance NoName_77 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1224.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_77 
_laygo2_generate_instance NoName_78 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1296.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_78 
_laygo2_generate_rect M4 { { 546.0  -1562.0  } { 1326.0  -1462.0  } } ; # for the Rect object NoName_79 
_laygo2_generate_rect M4 { { -204.0  -1562.0  } { 996.0  -1462.0  } } ; # for the Rect object NoName_80 
_laygo2_generate_instance NoName_81 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M4_M5_0 { -144.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_81 
_laygo2_generate_rect M4 { { -204.0  1462.0  } { 996.0  1562.0  } } ; # for the Rect object NoName_82 
_laygo2_generate_instance NoName_83 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M4_M5_0 { -144.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_83 
_laygo2_generate_rect M5 { { -224.0  -1572.0  } { -64.0  1572.0  } } ; # for the Rect object NoName_84 
_laygo2_generate_rect M4 { { 876.0  -1562.0  } { 2076.0  -1462.0  } } ; # for the Rect object NoName_85 
_laygo2_generate_instance NoName_86 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M4_M5_0 { 2016.0  -1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_86 
_laygo2_generate_rect M4 { { 876.0  1462.0  } { 2076.0  1562.0  } } ; # for the Rect object NoName_87 
_laygo2_generate_instance NoName_88 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M4_M5_0 { 2016.0  1512.0  } R0 1 1 0 0 ; # for the Instance object NoName_88 
_laygo2_generate_rect M5 { { 1936.0  -1572.0  } { 2096.0  1572.0  } } ; # for the Rect object NoName_89 
_laygo2_generate_instance NoName_90 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 648.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_90 
_laygo2_generate_instance NoName_91 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_91 
_laygo2_generate_instance NoName_92 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 792.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_92 
_laygo2_generate_instance NoName_93 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_93 
_laygo2_generate_instance NoName_94 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 936.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_94 
_laygo2_generate_instance NoName_95 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_95 
_laygo2_generate_instance NoName_96 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1080.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_96 
_laygo2_generate_instance NoName_97 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_97 
_laygo2_generate_instance NoName_98 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1224.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_98 
_laygo2_generate_rect M3 { { 618.0  -30.0  } { 1254.0  30.0  } } ; # for the Rect object NoName_99 
_laygo2_generate_instance NoName_100 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 648.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_100 
_laygo2_generate_instance NoName_101 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 720.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_101 
_laygo2_generate_instance NoName_102 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 792.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_102 
_laygo2_generate_instance NoName_103 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 864.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_103 
_laygo2_generate_instance NoName_104 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 936.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_104 
_laygo2_generate_instance NoName_105 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1008.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_105 
_laygo2_generate_instance NoName_106 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1080.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_106 
_laygo2_generate_instance NoName_107 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1152.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_107 
_laygo2_generate_instance NoName_108 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M3_M4_0 { 1224.0  0.0  } R0 1 1 0 0 ; # for the Instance object NoName_108 
_laygo2_generate_rect M4 { { 618.0  -50.0  } { 1254.0  50.0  } } ; # for the Rect object NoName_109 
_laygo2_generate_pin CLK M2 { { 576.0  -375.0  } { 1296.0  -345.0  } } 1 ; # for the Pin object CLK 
_laygo2_generate_pin CLK_bar M2 { { 576.0  1137.0  } { 1296.0  1167.0  } } 2 ; # for the Pin object CLK_bar 
_laygo2_generate_pin Di_n M3 { { 849.0  -1296.0  } { 879.0  -720.0  } } 3 ; # for the Pin object Di_n 
_laygo2_generate_pin Di_p M3 { { 993.0  -1296.0  } { 1023.0  -720.0  } } 4 ; # for the Pin object Di_p 
_laygo2_generate_pin VDD M4 { { 144.0  1462.0  } { 1728.0  1562.0  } } 5 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M4 { { 648.0  -50.0  } { 1224.0  50.0  } } 6 ; # for the Pin object VSS 
_laygo2_generate_pin Vin_n M2 { { 1152.0  -879.0  } { 1728.0  -849.0  } } 7 ; # for the Pin object Vin_n 
_laygo2_generate_pin Vin_p M2 { { 144.0  -879.0  } { 720.0  -849.0  } } 8 ; # for the Pin object Vin_p 
_laygo2_generate_pin Vout_n M2 { { 864.0  561.0  } { 1080.0  591.0  } } 9 ; # for the Pin object Vout_n 
_laygo2_generate_pin Vout_p M2 { { 792.0  417.0  } { 1008.0  447.0  } } 10 ; # for the Pin object Vout_p 
save
