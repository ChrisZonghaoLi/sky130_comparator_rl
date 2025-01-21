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

# exporting logic_generated__dff_4x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_dff_4x sky130A
_laygo2_generate_instance inv0 ./magic_layout/logic_generated logic_generated_inv_4x { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object inv0 
_laygo2_generate_instance inv1 ./magic_layout/logic_generated logic_generated_inv_4x { 432.0  0.0  } R0 1 1 0 0 ; # for the Instance object inv1 
_laygo2_generate_instance tinv0 ./magic_layout/logic_generated logic_generated_tinv_4x { 864.0  0.0  } R0 1 1 0 0 ; # for the Instance object tinv0 
_laygo2_generate_instance tinv_small0 ./magic_layout/logic_generated logic_generated_tinv_small_1x { 1728.0  0.0  } R0 1 1 0 0 ; # for the Instance object tinv_small0 
_laygo2_generate_instance MNT0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense ntap_fast_boundary { 2016.0  0.0  } R0 1 1 0 0 ; # for the Instance object MNT0_IBNDL0 
_laygo2_generate_instance MNT0_IM0 ./magic_layout/skywater130_microtemplates_dense ntap_fast_center_nf2_v2 { 2088.0  0.0  } R0 1 1 504.0  144.0  ; # for the Instance object MNT0_IM0 
_laygo2_generate_instance MNT0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense ntap_fast_boundary { 2232.0  0.0  } R0 1 1 0 0 ; # for the Instance object MNT0_IBNDR0 
_laygo2_generate_rect M2 { { 2088.0  201.0  } { 2232.0  231.0  } } ; # for the Rect object MNT0_RTAP10 
_laygo2_generate_instance MNT0_IVTAP10 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 2160.0  216.0  } R0 1 1 504.0  144.0  ; # for the Instance object MNT0_IVTAP10 
_laygo2_generate_rect M2 { { 2006.0  -30.0  } { 2314.0  30.0  } } ; # for the Rect object MNT0_RRAIL0 
_laygo2_generate_rect M1 { { 2073.0  -20.0  } { 2103.0  164.0  } } ; # for the Rect object MNT0_RTIE0 
_laygo2_generate_rect M1 { { 2217.0  -20.0  } { 2247.0  164.0  } } ; # for the Rect object MNT0_RTIE1 
_laygo2_generate_instance MNT0_IVTIETAP10 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 2088.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object MNT0_IVTIETAP10 
_laygo2_generate_instance MPT0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense ptap_fast_boundary { 2016.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MPT0_IBNDL0 
_laygo2_generate_instance MPT0_IM0 ./magic_layout/skywater130_microtemplates_dense ptap_fast_center_nf2_v2 { 2088.0  1008.0  } MX 1 1 504.0  144.0  ; # for the Instance object MPT0_IM0 
_laygo2_generate_instance MPT0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense ptap_fast_boundary { 2232.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MPT0_IBNDR0 
_laygo2_generate_rect M2 { { 2088.0  807.0  } { 2232.0  777.0  } } ; # for the Rect object MPT0_RTAP10 
_laygo2_generate_instance MPT0_IVTAP10 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 2160.0  792.0  } MX 1 1 504.0  144.0  ; # for the Instance object MPT0_IVTAP10 
_laygo2_generate_rect M2 { { 2006.0  1038.0  } { 2314.0  978.0  } } ; # for the Rect object MPT0_RRAIL0 
_laygo2_generate_rect M1 { { 2073.0  1028.0  } { 2103.0  844.0  } } ; # for the Rect object MPT0_RTIE0 
_laygo2_generate_rect M1 { { 2217.0  1028.0  } { 2247.0  844.0  } } ; # for the Rect object MPT0_RTIE1 
_laygo2_generate_instance MPT0_IVTIETAP10 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 2088.0  1008.0  } MX 1 2 504.0  144.0  ; # for the Instance object MPT0_IVTIETAP10 
_laygo2_generate_instance inv2 ./magic_layout/logic_generated logic_generated_inv_4x { 2304.0  0.0  } R0 1 1 0 0 ; # for the Instance object inv2 
_laygo2_generate_instance tinv1 ./magic_layout/logic_generated logic_generated_tinv_4x { 2736.0  0.0  } R0 1 1 0 0 ; # for the Instance object tinv1 
_laygo2_generate_instance tinv_small1 ./magic_layout/logic_generated logic_generated_tinv_small_1x { 3600.0  0.0  } R0 1 1 0 0 ; # for the Instance object tinv_small1 
_laygo2_generate_instance inv3 ./magic_layout/logic_generated logic_generated_inv_4x { 4032.0  0.0  } R0 1 1 0 0 ; # for the Instance object inv3 
_laygo2_generate_rect M3 { { 705.0  57.0  } { 735.0  231.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  72.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M3 { { 1497.0  57.0  } { 1527.0  375.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1512.0  72.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 3513.0  57.0  } { 3543.0  375.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 3528.0  72.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 2001.0  57.0  } { 2031.0  375.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 2016.0  72.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M3 { { 3729.0  57.0  } { 3759.0  375.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_instance NoName_9 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 3744.0  72.0  } R0 1 1 0 0 ; # for the Instance object NoName_9 
_laygo2_generate_rect M2 { { 705.0  57.0  } { 3759.0  87.0  } } ; # for the Rect object NoName_10 
_laygo2_generate_rect M3 { { 2361.0  129.0  } { 2391.0  375.0  } } ; # for the Rect object NoName_11 
_laygo2_generate_instance NoName_12 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 2376.0  144.0  } R0 1 1 0 0 ; # for the Instance object NoName_12 
_laygo2_generate_instance NoName_13 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1584.0  144.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_instance NoName_14 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1944.0  144.0  } R0 1 1 0 0 ; # for the Instance object NoName_14 
_laygo2_generate_rect M2 { { 1569.0  129.0  } { 2391.0  159.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_rect M3 { { 4089.0  129.0  } { 4119.0  375.0  } } ; # for the Rect object NoName_16 
_laygo2_generate_instance NoName_17 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 4104.0  144.0  } R0 1 1 0 0 ; # for the Instance object NoName_17 
_laygo2_generate_instance NoName_18 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 3456.0  144.0  } R0 1 1 0 0 ; # for the Instance object NoName_18 
_laygo2_generate_instance NoName_19 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 3816.0  144.0  } R0 1 1 0 0 ; # for the Instance object NoName_19 
_laygo2_generate_rect M2 { { 3441.0  129.0  } { 4119.0  159.0  } } ; # for the Rect object NoName_20 
_laygo2_generate_instance NoName_21 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 4320.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_21 
_laygo2_generate_rect M3 { { 3657.0  201.0  } { 3687.0  375.0  } } ; # for the Rect object NoName_22 
_laygo2_generate_instance NoName_23 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 3672.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_23 
_laygo2_generate_rect M2 { { 3657.0  201.0  } { 4335.0  231.0  } } ; # for the Rect object NoName_24 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  303.0  } } ; # for the Rect object NoName_25 
_laygo2_generate_instance NoName_26 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  288.0  } R0 1 1 0 0 ; # for the Instance object NoName_26 
_laygo2_generate_rect M3 { { 489.0  273.0  } { 519.0  375.0  } } ; # for the Rect object NoName_27 
_laygo2_generate_instance NoName_28 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 504.0  288.0  } R0 1 1 0 0 ; # for the Instance object NoName_28 
_laygo2_generate_rect M3 { { 1641.0  273.0  } { 1671.0  375.0  } } ; # for the Rect object NoName_29 
_laygo2_generate_instance NoName_30 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1656.0  288.0  } R0 1 1 0 0 ; # for the Instance object NoName_30 
_laygo2_generate_rect M3 { { 3369.0  273.0  } { 3399.0  375.0  } } ; # for the Rect object NoName_31 
_laygo2_generate_instance NoName_32 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 3384.0  288.0  } R0 1 1 0 0 ; # for the Instance object NoName_32 
_laygo2_generate_rect M3 { { 1857.0  273.0  } { 1887.0  375.0  } } ; # for the Rect object NoName_33 
_laygo2_generate_instance NoName_34 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1872.0  288.0  } R0 1 1 0 0 ; # for the Instance object NoName_34 
_laygo2_generate_rect M3 { { 3873.0  273.0  } { 3903.0  375.0  } } ; # for the Rect object NoName_35 
_laygo2_generate_instance NoName_36 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 3888.0  288.0  } R0 1 1 0 0 ; # for the Instance object NoName_36 
_laygo2_generate_rect M2 { { 273.0  273.0  } { 3903.0  303.0  } } ; # for the Rect object NoName_37 
_laygo2_generate_rect M3 { { 2577.0  201.0  } { 2607.0  519.0  } } ; # for the Rect object NoName_38 
_laygo2_generate_instance NoName_39 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 2592.0  504.0  } R0 1 1 0 0 ; # for the Instance object NoName_39 
_laygo2_generate_rect M3 { { 2865.0  345.0  } { 2895.0  519.0  } } ; # for the Rect object NoName_40 
_laygo2_generate_instance NoName_41 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 2880.0  504.0  } R0 1 1 0 0 ; # for the Instance object NoName_41 
_laygo2_generate_rect M3 { { 1785.0  345.0  } { 1815.0  519.0  } } ; # for the Rect object NoName_42 
_laygo2_generate_instance NoName_43 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1800.0  504.0  } R0 1 1 0 0 ; # for the Instance object NoName_43 
_laygo2_generate_rect M2 { { 1785.0  489.0  } { 2895.0  519.0  } } ; # for the Rect object NoName_44 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 4484.0  30.0  } } ; # for the Rect object NoName_45 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 4484.0  1038.0  } } ; # for the Rect object NoName_46 
_laygo2_generate_pin CLK M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object CLK 
_laygo2_generate_pin I M3 { { 993.0  360.0  } { 1023.0  648.0  } } 2 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 4305.0  216.0  } { 4335.0  792.0  } } 3 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 4464.0  1038.0  } } 4 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 4464.0  30.0  } } 5 ; # for the Pin object VSS 
save
