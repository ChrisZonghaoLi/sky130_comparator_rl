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

# exporting logic_generated__inv_2x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_2x sky130A
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
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 288.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 288.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_4x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_4x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 360.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 326.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 2 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 326.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 2 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 442.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 3 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 2 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 360.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 326.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 2 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 326.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 2 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 442.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 3 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 452.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 452.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 273.0  216.0  } { 303.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 432.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 432.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_6x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_6x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 3 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 504.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 470.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 3 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 470.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 3 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 586.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 4 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 3 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 504.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 470.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 3 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 470.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 3 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 586.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 4 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 417.0  201.0  } { 447.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 596.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 596.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 417.0  216.0  } { 447.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 576.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 576.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_8x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_8x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 4 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 648.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 614.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 4 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 614.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 4 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 730.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 5 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 4 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 648.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 614.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 4 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 614.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 4 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 730.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 5 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 561.0  201.0  } { 591.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 740.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 740.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 561.0  216.0  } { 591.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 720.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 720.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_10x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_10x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 5 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 792.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 758.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 5 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 758.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 5 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 874.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 6 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 5 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 792.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 758.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 5 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 758.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 5 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 874.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 6 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 705.0  201.0  } { 735.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 884.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 884.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 705.0  216.0  } { 735.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 864.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 864.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_12x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_12x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 6 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 936.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 902.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 6 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 902.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 6 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1018.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 7 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 6 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 936.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 902.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 6 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 902.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 6 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1018.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 7 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 849.0  201.0  } { 879.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1028.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1028.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 849.0  216.0  } { 879.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1008.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1008.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_14x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_14x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 7 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 1080.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 1046.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 7 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 1046.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 7 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1162.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 8 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 7 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 1080.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 1046.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 7 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 1046.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 7 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1162.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 8 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 993.0  201.0  } { 1023.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1172.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1172.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 993.0  216.0  } { 1023.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1152.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1152.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_16x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_16x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 8 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 1224.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 1190.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 8 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 1190.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 8 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1306.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object MN0_RTIE8 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 9 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 8 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 1224.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 1190.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 8 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 1190.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 8 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1306.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  1028.0  } { 1239.0  844.0  } } ; # for the Rect object MP0_RTIE8 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 9 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 1137.0  201.0  } { 1167.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1316.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1316.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 1137.0  216.0  } { 1167.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1296.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1296.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_18x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_18x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 9 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 1368.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 1334.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 9 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 1334.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 9 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1450.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object MN0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  -20.0  } { 1383.0  164.0  } } ; # for the Rect object MN0_RTIE9 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 10 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 9 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 1368.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 1334.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 9 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 1334.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 9 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1450.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  1028.0  } { 1239.0  844.0  } } ; # for the Rect object MP0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  1028.0  } { 1383.0  844.0  } } ; # for the Rect object MP0_RTIE9 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 10 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1296.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 1281.0  201.0  } { 1311.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1296.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1460.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1460.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 1281.0  216.0  } { 1311.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1440.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1440.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_24x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_24x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 12 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 1800.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 1766.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 12 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 1766.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 12 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1882.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object MN0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  -20.0  } { 1383.0  164.0  } } ; # for the Rect object MN0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  -20.0  } { 1527.0  164.0  } } ; # for the Rect object MN0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  -20.0  } { 1671.0  164.0  } } ; # for the Rect object MN0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  -20.0  } { 1815.0  164.0  } } ; # for the Rect object MN0_RTIE12 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 13 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 12 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 1800.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 1766.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 12 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 1766.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 12 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1882.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  1028.0  } { 1239.0  844.0  } } ; # for the Rect object MP0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  1028.0  } { 1383.0  844.0  } } ; # for the Rect object MP0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  1028.0  } { 1527.0  844.0  } } ; # for the Rect object MP0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  1028.0  } { 1671.0  844.0  } } ; # for the Rect object MP0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  1028.0  } { 1815.0  844.0  } } ; # for the Rect object MP0_RTIE12 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 13 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1728.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 1713.0  201.0  } { 1743.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1728.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1892.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1892.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 1713.0  216.0  } { 1743.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1872.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1872.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_32x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_32x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 16 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 2376.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 2342.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 16 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 2342.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 16 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 2458.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object MN0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  -20.0  } { 1383.0  164.0  } } ; # for the Rect object MN0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  -20.0  } { 1527.0  164.0  } } ; # for the Rect object MN0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  -20.0  } { 1671.0  164.0  } } ; # for the Rect object MN0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  -20.0  } { 1815.0  164.0  } } ; # for the Rect object MN0_RTIE12 
_laygo2_generate_rect M1 { { 1929.0  -20.0  } { 1959.0  164.0  } } ; # for the Rect object MN0_RTIE13 
_laygo2_generate_rect M1 { { 2073.0  -20.0  } { 2103.0  164.0  } } ; # for the Rect object MN0_RTIE14 
_laygo2_generate_rect M1 { { 2217.0  -20.0  } { 2247.0  164.0  } } ; # for the Rect object MN0_RTIE15 
_laygo2_generate_rect M1 { { 2361.0  -20.0  } { 2391.0  164.0  } } ; # for the Rect object MN0_RTIE16 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 17 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 16 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 2376.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 2342.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 16 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 2342.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 16 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 2458.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  1028.0  } { 1239.0  844.0  } } ; # for the Rect object MP0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  1028.0  } { 1383.0  844.0  } } ; # for the Rect object MP0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  1028.0  } { 1527.0  844.0  } } ; # for the Rect object MP0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  1028.0  } { 1671.0  844.0  } } ; # for the Rect object MP0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  1028.0  } { 1815.0  844.0  } } ; # for the Rect object MP0_RTIE12 
_laygo2_generate_rect M1 { { 1929.0  1028.0  } { 1959.0  844.0  } } ; # for the Rect object MP0_RTIE13 
_laygo2_generate_rect M1 { { 2073.0  1028.0  } { 2103.0  844.0  } } ; # for the Rect object MP0_RTIE14 
_laygo2_generate_rect M1 { { 2217.0  1028.0  } { 2247.0  844.0  } } ; # for the Rect object MP0_RTIE15 
_laygo2_generate_rect M1 { { 2361.0  1028.0  } { 2391.0  844.0  } } ; # for the Rect object MP0_RTIE16 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 17 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 2304.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 2289.0  201.0  } { 2319.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 2304.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 2468.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 2468.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 2289.0  216.0  } { 2319.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 2448.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 2448.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_36x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_36x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 18 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 2664.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 2630.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 18 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 2630.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 18 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 2746.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object MN0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  -20.0  } { 1383.0  164.0  } } ; # for the Rect object MN0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  -20.0  } { 1527.0  164.0  } } ; # for the Rect object MN0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  -20.0  } { 1671.0  164.0  } } ; # for the Rect object MN0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  -20.0  } { 1815.0  164.0  } } ; # for the Rect object MN0_RTIE12 
_laygo2_generate_rect M1 { { 1929.0  -20.0  } { 1959.0  164.0  } } ; # for the Rect object MN0_RTIE13 
_laygo2_generate_rect M1 { { 2073.0  -20.0  } { 2103.0  164.0  } } ; # for the Rect object MN0_RTIE14 
_laygo2_generate_rect M1 { { 2217.0  -20.0  } { 2247.0  164.0  } } ; # for the Rect object MN0_RTIE15 
_laygo2_generate_rect M1 { { 2361.0  -20.0  } { 2391.0  164.0  } } ; # for the Rect object MN0_RTIE16 
_laygo2_generate_rect M1 { { 2505.0  -20.0  } { 2535.0  164.0  } } ; # for the Rect object MN0_RTIE17 
_laygo2_generate_rect M1 { { 2649.0  -20.0  } { 2679.0  164.0  } } ; # for the Rect object MN0_RTIE18 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 19 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 18 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 2664.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 2630.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 18 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 2630.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 18 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 2746.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  1028.0  } { 1239.0  844.0  } } ; # for the Rect object MP0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  1028.0  } { 1383.0  844.0  } } ; # for the Rect object MP0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  1028.0  } { 1527.0  844.0  } } ; # for the Rect object MP0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  1028.0  } { 1671.0  844.0  } } ; # for the Rect object MP0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  1028.0  } { 1815.0  844.0  } } ; # for the Rect object MP0_RTIE12 
_laygo2_generate_rect M1 { { 1929.0  1028.0  } { 1959.0  844.0  } } ; # for the Rect object MP0_RTIE13 
_laygo2_generate_rect M1 { { 2073.0  1028.0  } { 2103.0  844.0  } } ; # for the Rect object MP0_RTIE14 
_laygo2_generate_rect M1 { { 2217.0  1028.0  } { 2247.0  844.0  } } ; # for the Rect object MP0_RTIE15 
_laygo2_generate_rect M1 { { 2361.0  1028.0  } { 2391.0  844.0  } } ; # for the Rect object MP0_RTIE16 
_laygo2_generate_rect M1 { { 2505.0  1028.0  } { 2535.0  844.0  } } ; # for the Rect object MP0_RTIE17 
_laygo2_generate_rect M1 { { 2649.0  1028.0  } { 2679.0  844.0  } } ; # for the Rect object MP0_RTIE18 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 19 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 2592.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 2577.0  201.0  } { 2607.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 2592.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 2756.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 2756.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 2577.0  216.0  } { 2607.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 2736.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 2736.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_64x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_64x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 32 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 4680.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 4646.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 32 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 4646.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 32 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 4762.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object MN0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  -20.0  } { 1383.0  164.0  } } ; # for the Rect object MN0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  -20.0  } { 1527.0  164.0  } } ; # for the Rect object MN0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  -20.0  } { 1671.0  164.0  } } ; # for the Rect object MN0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  -20.0  } { 1815.0  164.0  } } ; # for the Rect object MN0_RTIE12 
_laygo2_generate_rect M1 { { 1929.0  -20.0  } { 1959.0  164.0  } } ; # for the Rect object MN0_RTIE13 
_laygo2_generate_rect M1 { { 2073.0  -20.0  } { 2103.0  164.0  } } ; # for the Rect object MN0_RTIE14 
_laygo2_generate_rect M1 { { 2217.0  -20.0  } { 2247.0  164.0  } } ; # for the Rect object MN0_RTIE15 
_laygo2_generate_rect M1 { { 2361.0  -20.0  } { 2391.0  164.0  } } ; # for the Rect object MN0_RTIE16 
_laygo2_generate_rect M1 { { 2505.0  -20.0  } { 2535.0  164.0  } } ; # for the Rect object MN0_RTIE17 
_laygo2_generate_rect M1 { { 2649.0  -20.0  } { 2679.0  164.0  } } ; # for the Rect object MN0_RTIE18 
_laygo2_generate_rect M1 { { 2793.0  -20.0  } { 2823.0  164.0  } } ; # for the Rect object MN0_RTIE19 
_laygo2_generate_rect M1 { { 2937.0  -20.0  } { 2967.0  164.0  } } ; # for the Rect object MN0_RTIE20 
_laygo2_generate_rect M1 { { 3081.0  -20.0  } { 3111.0  164.0  } } ; # for the Rect object MN0_RTIE21 
_laygo2_generate_rect M1 { { 3225.0  -20.0  } { 3255.0  164.0  } } ; # for the Rect object MN0_RTIE22 
_laygo2_generate_rect M1 { { 3369.0  -20.0  } { 3399.0  164.0  } } ; # for the Rect object MN0_RTIE23 
_laygo2_generate_rect M1 { { 3513.0  -20.0  } { 3543.0  164.0  } } ; # for the Rect object MN0_RTIE24 
_laygo2_generate_rect M1 { { 3657.0  -20.0  } { 3687.0  164.0  } } ; # for the Rect object MN0_RTIE25 
_laygo2_generate_rect M1 { { 3801.0  -20.0  } { 3831.0  164.0  } } ; # for the Rect object MN0_RTIE26 
_laygo2_generate_rect M1 { { 3945.0  -20.0  } { 3975.0  164.0  } } ; # for the Rect object MN0_RTIE27 
_laygo2_generate_rect M1 { { 4089.0  -20.0  } { 4119.0  164.0  } } ; # for the Rect object MN0_RTIE28 
_laygo2_generate_rect M1 { { 4233.0  -20.0  } { 4263.0  164.0  } } ; # for the Rect object MN0_RTIE29 
_laygo2_generate_rect M1 { { 4377.0  -20.0  } { 4407.0  164.0  } } ; # for the Rect object MN0_RTIE30 
_laygo2_generate_rect M1 { { 4521.0  -20.0  } { 4551.0  164.0  } } ; # for the Rect object MN0_RTIE31 
_laygo2_generate_rect M1 { { 4665.0  -20.0  } { 4695.0  164.0  } } ; # for the Rect object MN0_RTIE32 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 33 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 32 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 4680.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 4646.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 32 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 4646.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 32 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 4762.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  1028.0  } { 1239.0  844.0  } } ; # for the Rect object MP0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  1028.0  } { 1383.0  844.0  } } ; # for the Rect object MP0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  1028.0  } { 1527.0  844.0  } } ; # for the Rect object MP0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  1028.0  } { 1671.0  844.0  } } ; # for the Rect object MP0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  1028.0  } { 1815.0  844.0  } } ; # for the Rect object MP0_RTIE12 
_laygo2_generate_rect M1 { { 1929.0  1028.0  } { 1959.0  844.0  } } ; # for the Rect object MP0_RTIE13 
_laygo2_generate_rect M1 { { 2073.0  1028.0  } { 2103.0  844.0  } } ; # for the Rect object MP0_RTIE14 
_laygo2_generate_rect M1 { { 2217.0  1028.0  } { 2247.0  844.0  } } ; # for the Rect object MP0_RTIE15 
_laygo2_generate_rect M1 { { 2361.0  1028.0  } { 2391.0  844.0  } } ; # for the Rect object MP0_RTIE16 
_laygo2_generate_rect M1 { { 2505.0  1028.0  } { 2535.0  844.0  } } ; # for the Rect object MP0_RTIE17 
_laygo2_generate_rect M1 { { 2649.0  1028.0  } { 2679.0  844.0  } } ; # for the Rect object MP0_RTIE18 
_laygo2_generate_rect M1 { { 2793.0  1028.0  } { 2823.0  844.0  } } ; # for the Rect object MP0_RTIE19 
_laygo2_generate_rect M1 { { 2937.0  1028.0  } { 2967.0  844.0  } } ; # for the Rect object MP0_RTIE20 
_laygo2_generate_rect M1 { { 3081.0  1028.0  } { 3111.0  844.0  } } ; # for the Rect object MP0_RTIE21 
_laygo2_generate_rect M1 { { 3225.0  1028.0  } { 3255.0  844.0  } } ; # for the Rect object MP0_RTIE22 
_laygo2_generate_rect M1 { { 3369.0  1028.0  } { 3399.0  844.0  } } ; # for the Rect object MP0_RTIE23 
_laygo2_generate_rect M1 { { 3513.0  1028.0  } { 3543.0  844.0  } } ; # for the Rect object MP0_RTIE24 
_laygo2_generate_rect M1 { { 3657.0  1028.0  } { 3687.0  844.0  } } ; # for the Rect object MP0_RTIE25 
_laygo2_generate_rect M1 { { 3801.0  1028.0  } { 3831.0  844.0  } } ; # for the Rect object MP0_RTIE26 
_laygo2_generate_rect M1 { { 3945.0  1028.0  } { 3975.0  844.0  } } ; # for the Rect object MP0_RTIE27 
_laygo2_generate_rect M1 { { 4089.0  1028.0  } { 4119.0  844.0  } } ; # for the Rect object MP0_RTIE28 
_laygo2_generate_rect M1 { { 4233.0  1028.0  } { 4263.0  844.0  } } ; # for the Rect object MP0_RTIE29 
_laygo2_generate_rect M1 { { 4377.0  1028.0  } { 4407.0  844.0  } } ; # for the Rect object MP0_RTIE30 
_laygo2_generate_rect M1 { { 4521.0  1028.0  } { 4551.0  844.0  } } ; # for the Rect object MP0_RTIE31 
_laygo2_generate_rect M1 { { 4665.0  1028.0  } { 4695.0  844.0  } } ; # for the Rect object MP0_RTIE32 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 33 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 4608.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 4593.0  201.0  } { 4623.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 4608.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 4772.0  30.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 4772.0  1038.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O M3 { { 4593.0  216.0  } { 4623.0  792.0  } } 2 ; # for the Pin object O 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 4752.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 4752.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_2x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_2x sky130A
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
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 288.0  1038.0  } } 3 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 288.0  30.0  } } 4 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_4x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_4x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 360.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 326.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 2 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 326.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 2 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 442.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 3 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 2 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 360.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 326.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 2 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 326.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 2 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 442.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 3 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_instance NoName_8 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_instance NoName_10 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 452.0  30.0  } } ; # for the Rect object NoName_11 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 452.0  1038.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin O: M3 { { 273.0  216.0  } { 303.0  792.0  } } 3 ; # for the Pin object O1 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 432.0  1038.0  } } 4 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 432.0  30.0  } } 5 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_6x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_6x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 3 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 504.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 470.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 3 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 470.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 3 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 586.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 4 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 3 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 504.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 470.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 3 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 470.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 3 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 586.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 4 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_instance NoName_8 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_instance NoName_10 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_instance NoName_11 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_rect M3 { { 417.0  201.0  } { 447.0  807.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_instance NoName_13 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 596.0  30.0  } } ; # for the Rect object NoName_14 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 596.0  1038.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin O: M3 { { 273.0  216.0  } { 303.0  792.0  } } 3 ; # for the Pin object O1 
_laygo2_generate_pin O: M3 { { 417.0  216.0  } { 447.0  792.0  } } 4 ; # for the Pin object O2 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 576.0  1038.0  } } 5 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 576.0  30.0  } } 6 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_8x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_8x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 4 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 648.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 614.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 4 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 614.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 4 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 730.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 5 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 4 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 648.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 614.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 4 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 614.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 4 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 730.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 5 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_instance NoName_8 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_instance NoName_10 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_instance NoName_11 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_rect M3 { { 417.0  201.0  } { 447.0  807.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_instance NoName_13 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_instance NoName_14 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_14 
_laygo2_generate_rect M3 { { 561.0  201.0  } { 591.0  807.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_instance NoName_16 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_16 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 740.0  30.0  } } ; # for the Rect object NoName_17 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 740.0  1038.0  } } ; # for the Rect object NoName_18 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin O: M3 { { 273.0  216.0  } { 303.0  792.0  } } 3 ; # for the Pin object O1 
_laygo2_generate_pin O: M3 { { 417.0  216.0  } { 447.0  792.0  } } 4 ; # for the Pin object O2 
_laygo2_generate_pin O: M3 { { 561.0  216.0  } { 591.0  792.0  } } 5 ; # for the Pin object O3 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 720.0  1038.0  } } 6 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 720.0  30.0  } } 7 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_10x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_10x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 5 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 792.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 758.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 5 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 758.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 5 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 874.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 6 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 5 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 792.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 758.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 5 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 758.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 5 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 874.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 6 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_instance NoName_8 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_instance NoName_10 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_instance NoName_11 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_rect M3 { { 417.0  201.0  } { 447.0  807.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_instance NoName_13 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_instance NoName_14 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_14 
_laygo2_generate_rect M3 { { 561.0  201.0  } { 591.0  807.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_instance NoName_16 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_16 
_laygo2_generate_instance NoName_17 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_17 
_laygo2_generate_rect M3 { { 705.0  201.0  } { 735.0  807.0  } } ; # for the Rect object NoName_18 
_laygo2_generate_instance NoName_19 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_19 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 884.0  30.0  } } ; # for the Rect object NoName_20 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 884.0  1038.0  } } ; # for the Rect object NoName_21 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin O: M3 { { 273.0  216.0  } { 303.0  792.0  } } 3 ; # for the Pin object O1 
_laygo2_generate_pin O: M3 { { 417.0  216.0  } { 447.0  792.0  } } 4 ; # for the Pin object O2 
_laygo2_generate_pin O: M3 { { 561.0  216.0  } { 591.0  792.0  } } 5 ; # for the Pin object O3 
_laygo2_generate_pin O: M3 { { 705.0  216.0  } { 735.0  792.0  } } 6 ; # for the Pin object O4 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 864.0  1038.0  } } 7 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 864.0  30.0  } } 8 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_12x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_12x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 6 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 936.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 902.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 6 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 902.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 6 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1018.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 7 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 6 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 936.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 902.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 6 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 902.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 6 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1018.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 7 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_instance NoName_8 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_instance NoName_10 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_instance NoName_11 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_rect M3 { { 417.0  201.0  } { 447.0  807.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_instance NoName_13 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_instance NoName_14 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_14 
_laygo2_generate_rect M3 { { 561.0  201.0  } { 591.0  807.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_instance NoName_16 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_16 
_laygo2_generate_instance NoName_17 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_17 
_laygo2_generate_rect M3 { { 705.0  201.0  } { 735.0  807.0  } } ; # for the Rect object NoName_18 
_laygo2_generate_instance NoName_19 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_19 
_laygo2_generate_instance NoName_20 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_20 
_laygo2_generate_rect M3 { { 849.0  201.0  } { 879.0  807.0  } } ; # for the Rect object NoName_21 
_laygo2_generate_instance NoName_22 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_22 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1028.0  30.0  } } ; # for the Rect object NoName_23 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1028.0  1038.0  } } ; # for the Rect object NoName_24 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin O: M3 { { 273.0  216.0  } { 303.0  792.0  } } 3 ; # for the Pin object O1 
_laygo2_generate_pin O: M3 { { 417.0  216.0  } { 447.0  792.0  } } 4 ; # for the Pin object O2 
_laygo2_generate_pin O: M3 { { 561.0  216.0  } { 591.0  792.0  } } 5 ; # for the Pin object O3 
_laygo2_generate_pin O: M3 { { 705.0  216.0  } { 735.0  792.0  } } 6 ; # for the Pin object O4 
_laygo2_generate_pin O: M3 { { 849.0  216.0  } { 879.0  792.0  } } 7 ; # for the Pin object O5 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1008.0  1038.0  } } 8 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1008.0  30.0  } } 9 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_14x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_14x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 7 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 1080.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 1046.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 7 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 1046.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 7 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1162.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 8 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 7 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 1080.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 1046.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 7 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 1046.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 7 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1162.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 8 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_instance NoName_8 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_instance NoName_10 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_instance NoName_11 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_rect M3 { { 417.0  201.0  } { 447.0  807.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_instance NoName_13 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_instance NoName_14 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_14 
_laygo2_generate_rect M3 { { 561.0  201.0  } { 591.0  807.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_instance NoName_16 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_16 
_laygo2_generate_instance NoName_17 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_17 
_laygo2_generate_rect M3 { { 705.0  201.0  } { 735.0  807.0  } } ; # for the Rect object NoName_18 
_laygo2_generate_instance NoName_19 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_19 
_laygo2_generate_instance NoName_20 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_20 
_laygo2_generate_rect M3 { { 849.0  201.0  } { 879.0  807.0  } } ; # for the Rect object NoName_21 
_laygo2_generate_instance NoName_22 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_22 
_laygo2_generate_instance NoName_23 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_23 
_laygo2_generate_rect M3 { { 993.0  201.0  } { 1023.0  807.0  } } ; # for the Rect object NoName_24 
_laygo2_generate_instance NoName_25 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_25 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1172.0  30.0  } } ; # for the Rect object NoName_26 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1172.0  1038.0  } } ; # for the Rect object NoName_27 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin O: M3 { { 273.0  216.0  } { 303.0  792.0  } } 3 ; # for the Pin object O1 
_laygo2_generate_pin O: M3 { { 417.0  216.0  } { 447.0  792.0  } } 4 ; # for the Pin object O2 
_laygo2_generate_pin O: M3 { { 561.0  216.0  } { 591.0  792.0  } } 5 ; # for the Pin object O3 
_laygo2_generate_pin O: M3 { { 705.0  216.0  } { 735.0  792.0  } } 6 ; # for the Pin object O4 
_laygo2_generate_pin O: M3 { { 849.0  216.0  } { 879.0  792.0  } } 7 ; # for the Pin object O5 
_laygo2_generate_pin O: M3 { { 993.0  216.0  } { 1023.0  792.0  } } 8 ; # for the Pin object O6 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1152.0  1038.0  } } 9 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1152.0  30.0  } } 10 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_16x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_16x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 8 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 1224.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 1190.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 8 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 1190.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 8 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1306.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object MN0_RTIE8 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 9 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 8 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 1224.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 1190.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 8 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 1190.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 8 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1306.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  1028.0  } { 1239.0  844.0  } } ; # for the Rect object MP0_RTIE8 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 9 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_instance NoName_8 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_instance NoName_10 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_instance NoName_11 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_rect M3 { { 417.0  201.0  } { 447.0  807.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_instance NoName_13 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_instance NoName_14 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_14 
_laygo2_generate_rect M3 { { 561.0  201.0  } { 591.0  807.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_instance NoName_16 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_16 
_laygo2_generate_instance NoName_17 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_17 
_laygo2_generate_rect M3 { { 705.0  201.0  } { 735.0  807.0  } } ; # for the Rect object NoName_18 
_laygo2_generate_instance NoName_19 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_19 
_laygo2_generate_instance NoName_20 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_20 
_laygo2_generate_rect M3 { { 849.0  201.0  } { 879.0  807.0  } } ; # for the Rect object NoName_21 
_laygo2_generate_instance NoName_22 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_22 
_laygo2_generate_instance NoName_23 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_23 
_laygo2_generate_rect M3 { { 993.0  201.0  } { 1023.0  807.0  } } ; # for the Rect object NoName_24 
_laygo2_generate_instance NoName_25 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_25 
_laygo2_generate_instance NoName_26 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_26 
_laygo2_generate_rect M3 { { 1137.0  201.0  } { 1167.0  807.0  } } ; # for the Rect object NoName_27 
_laygo2_generate_instance NoName_28 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_28 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1316.0  30.0  } } ; # for the Rect object NoName_29 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1316.0  1038.0  } } ; # for the Rect object NoName_30 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin O: M3 { { 273.0  216.0  } { 303.0  792.0  } } 3 ; # for the Pin object O1 
_laygo2_generate_pin O: M3 { { 417.0  216.0  } { 447.0  792.0  } } 4 ; # for the Pin object O2 
_laygo2_generate_pin O: M3 { { 561.0  216.0  } { 591.0  792.0  } } 5 ; # for the Pin object O3 
_laygo2_generate_pin O: M3 { { 705.0  216.0  } { 735.0  792.0  } } 6 ; # for the Pin object O4 
_laygo2_generate_pin O: M3 { { 849.0  216.0  } { 879.0  792.0  } } 7 ; # for the Pin object O5 
_laygo2_generate_pin O: M3 { { 993.0  216.0  } { 1023.0  792.0  } } 8 ; # for the Pin object O6 
_laygo2_generate_pin O: M3 { { 1137.0  216.0  } { 1167.0  792.0  } } 9 ; # for the Pin object O7 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1296.0  1038.0  } } 10 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1296.0  30.0  } } 11 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_18x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_18x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 9 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 1368.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 1334.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 9 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 1334.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 9 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1450.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object MN0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  -20.0  } { 1383.0  164.0  } } ; # for the Rect object MN0_RTIE9 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 10 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 9 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 1368.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 1334.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 9 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 1334.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 9 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1450.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  1028.0  } { 1239.0  844.0  } } ; # for the Rect object MP0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  1028.0  } { 1383.0  844.0  } } ; # for the Rect object MP0_RTIE9 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 10 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_instance NoName_8 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_instance NoName_10 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_instance NoName_11 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_rect M3 { { 417.0  201.0  } { 447.0  807.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_instance NoName_13 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_instance NoName_14 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_14 
_laygo2_generate_rect M3 { { 561.0  201.0  } { 591.0  807.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_instance NoName_16 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_16 
_laygo2_generate_instance NoName_17 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_17 
_laygo2_generate_rect M3 { { 705.0  201.0  } { 735.0  807.0  } } ; # for the Rect object NoName_18 
_laygo2_generate_instance NoName_19 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_19 
_laygo2_generate_instance NoName_20 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_20 
_laygo2_generate_rect M3 { { 849.0  201.0  } { 879.0  807.0  } } ; # for the Rect object NoName_21 
_laygo2_generate_instance NoName_22 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_22 
_laygo2_generate_instance NoName_23 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_23 
_laygo2_generate_rect M3 { { 993.0  201.0  } { 1023.0  807.0  } } ; # for the Rect object NoName_24 
_laygo2_generate_instance NoName_25 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_25 
_laygo2_generate_instance NoName_26 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_26 
_laygo2_generate_rect M3 { { 1137.0  201.0  } { 1167.0  807.0  } } ; # for the Rect object NoName_27 
_laygo2_generate_instance NoName_28 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_28 
_laygo2_generate_instance NoName_29 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1296.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_29 
_laygo2_generate_rect M3 { { 1281.0  201.0  } { 1311.0  807.0  } } ; # for the Rect object NoName_30 
_laygo2_generate_instance NoName_31 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1296.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_31 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1460.0  30.0  } } ; # for the Rect object NoName_32 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1460.0  1038.0  } } ; # for the Rect object NoName_33 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin O: M3 { { 273.0  216.0  } { 303.0  792.0  } } 3 ; # for the Pin object O1 
_laygo2_generate_pin O: M3 { { 417.0  216.0  } { 447.0  792.0  } } 4 ; # for the Pin object O2 
_laygo2_generate_pin O: M3 { { 561.0  216.0  } { 591.0  792.0  } } 5 ; # for the Pin object O3 
_laygo2_generate_pin O: M3 { { 705.0  216.0  } { 735.0  792.0  } } 6 ; # for the Pin object O4 
_laygo2_generate_pin O: M3 { { 849.0  216.0  } { 879.0  792.0  } } 7 ; # for the Pin object O5 
_laygo2_generate_pin O: M3 { { 993.0  216.0  } { 1023.0  792.0  } } 8 ; # for the Pin object O6 
_laygo2_generate_pin O: M3 { { 1137.0  216.0  } { 1167.0  792.0  } } 9 ; # for the Pin object O7 
_laygo2_generate_pin O: M3 { { 1281.0  216.0  } { 1311.0  792.0  } } 10 ; # for the Pin object O8 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1440.0  1038.0  } } 11 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1440.0  30.0  } } 12 ; # for the Pin object VSS 
save

# exporting logic_generated__inv_hs_24x
_laygo2_create_layout ./magic_layout/logic_generated logic_generated_inv_hs_24x sky130A
_laygo2_generate_instance MN0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDL0 
_laygo2_generate_instance MN0_IM0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_center_nf2 { 72.0  0.0  } R0 1 12 504.0  144.0  ; # for the Instance object MN0_IM0 
_laygo2_generate_instance MN0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 1800.0  0.0  } R0 1 1 0 0 ; # for the Instance object MN0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 1766.0  375.0  } } ; # for the Rect object MN0_RG0 
_laygo2_generate_instance MN0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 12 504.0  144.0  ; # for the Instance object MN0_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 1766.0  231.0  } } ; # for the Rect object MN0_RD0 
_laygo2_generate_instance MN0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 12 504.0  144.0  ; # for the Instance object MN0_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1882.0  30.0  } } ; # for the Rect object MN0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object MN0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object MN0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object MN0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object MN0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object MN0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object MN0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object MN0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  -20.0  } { 1095.0  164.0  } } ; # for the Rect object MN0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object MN0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  -20.0  } { 1383.0  164.0  } } ; # for the Rect object MN0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  -20.0  } { 1527.0  164.0  } } ; # for the Rect object MN0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  -20.0  } { 1671.0  164.0  } } ; # for the Rect object MN0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  -20.0  } { 1815.0  164.0  } } ; # for the Rect object MN0_RTIE12 
_laygo2_generate_instance MN0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 13 504.0  144.0  ; # for the Instance object MN0_IVTIED0 
_laygo2_generate_instance MP0_IBNDL0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 0.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDL0 
_laygo2_generate_instance MP0_IM0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_center_nf2 { 72.0  1008.0  } MX 1 12 504.0  144.0  ; # for the Instance object MP0_IM0 
_laygo2_generate_instance MP0_IBNDR0 ./magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 1800.0  1008.0  } MX 1 1 0 0 ; # for the Instance object MP0_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  663.0  } { 1766.0  633.0  } } ; # for the Rect object MP0_RG0 
_laygo2_generate_instance MP0_IVG0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  648.0  } MX 1 12 504.0  144.0  ; # for the Instance object MP0_IVG0 
_laygo2_generate_rect M2 { { 106.0  807.0  } { 1766.0  777.0  } } ; # for the Rect object MP0_RD0 
_laygo2_generate_instance MP0_IVD0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  792.0  } MX 1 12 504.0  144.0  ; # for the Instance object MP0_IVD0 
_laygo2_generate_rect M2 { { -10.0  1038.0  } { 1882.0  978.0  } } ; # for the Rect object MP0_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  1028.0  } { 87.0  844.0  } } ; # for the Rect object MP0_RTIE0 
_laygo2_generate_rect M1 { { 201.0  1028.0  } { 231.0  844.0  } } ; # for the Rect object MP0_RTIE1 
_laygo2_generate_rect M1 { { 345.0  1028.0  } { 375.0  844.0  } } ; # for the Rect object MP0_RTIE2 
_laygo2_generate_rect M1 { { 489.0  1028.0  } { 519.0  844.0  } } ; # for the Rect object MP0_RTIE3 
_laygo2_generate_rect M1 { { 633.0  1028.0  } { 663.0  844.0  } } ; # for the Rect object MP0_RTIE4 
_laygo2_generate_rect M1 { { 777.0  1028.0  } { 807.0  844.0  } } ; # for the Rect object MP0_RTIE5 
_laygo2_generate_rect M1 { { 921.0  1028.0  } { 951.0  844.0  } } ; # for the Rect object MP0_RTIE6 
_laygo2_generate_rect M1 { { 1065.0  1028.0  } { 1095.0  844.0  } } ; # for the Rect object MP0_RTIE7 
_laygo2_generate_rect M1 { { 1209.0  1028.0  } { 1239.0  844.0  } } ; # for the Rect object MP0_RTIE8 
_laygo2_generate_rect M1 { { 1353.0  1028.0  } { 1383.0  844.0  } } ; # for the Rect object MP0_RTIE9 
_laygo2_generate_rect M1 { { 1497.0  1028.0  } { 1527.0  844.0  } } ; # for the Rect object MP0_RTIE10 
_laygo2_generate_rect M1 { { 1641.0  1028.0  } { 1671.0  844.0  } } ; # for the Rect object MP0_RTIE11 
_laygo2_generate_rect M1 { { 1785.0  1028.0  } { 1815.0  844.0  } } ; # for the Rect object MP0_RTIE12 
_laygo2_generate_instance MP0_IVTIED0 ./magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  1008.0  } MX 1 13 504.0  144.0  ; # for the Instance object MP0_IVTIED0 
_laygo2_generate_rect M2 { { 62.0  345.0  } { 154.0  375.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_instance NoName_1 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_1 
_laygo2_generate_rect M2 { { 62.0  633.0  } { 154.0  663.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_instance NoName_3 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  648.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M3 { { 57.0  345.0  } { 87.0  663.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M3 { { 129.0  201.0  } { 159.0  807.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_instance NoName_7 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_7 
_laygo2_generate_instance NoName_8 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_rect M3 { { 273.0  201.0  } { 303.0  807.0  } } ; # for the Rect object NoName_9 
_laygo2_generate_instance NoName_10 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 288.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_10 
_laygo2_generate_instance NoName_11 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_rect M3 { { 417.0  201.0  } { 447.0  807.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_instance NoName_13 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_instance NoName_14 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_14 
_laygo2_generate_rect M3 { { 561.0  201.0  } { 591.0  807.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_instance NoName_16 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_16 
_laygo2_generate_instance NoName_17 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_17 
_laygo2_generate_rect M3 { { 705.0  201.0  } { 735.0  807.0  } } ; # for the Rect object NoName_18 
_laygo2_generate_instance NoName_19 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 720.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_19 
_laygo2_generate_instance NoName_20 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_20 
_laygo2_generate_rect M3 { { 849.0  201.0  } { 879.0  807.0  } } ; # for the Rect object NoName_21 
_laygo2_generate_instance NoName_22 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 864.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_22 
_laygo2_generate_instance NoName_23 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_23 
_laygo2_generate_rect M3 { { 993.0  201.0  } { 1023.0  807.0  } } ; # for the Rect object NoName_24 
_laygo2_generate_instance NoName_25 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1008.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_25 
_laygo2_generate_instance NoName_26 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_26 
_laygo2_generate_rect M3 { { 1137.0  201.0  } { 1167.0  807.0  } } ; # for the Rect object NoName_27 
_laygo2_generate_instance NoName_28 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1152.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_28 
_laygo2_generate_instance NoName_29 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1296.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_29 
_laygo2_generate_rect M3 { { 1281.0  201.0  } { 1311.0  807.0  } } ; # for the Rect object NoName_30 
_laygo2_generate_instance NoName_31 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1296.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_31 
_laygo2_generate_instance NoName_32 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1440.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_32 
_laygo2_generate_rect M3 { { 1425.0  201.0  } { 1455.0  807.0  } } ; # for the Rect object NoName_33 
_laygo2_generate_instance NoName_34 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1440.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_34 
_laygo2_generate_instance NoName_35 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1584.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_35 
_laygo2_generate_rect M3 { { 1569.0  201.0  } { 1599.0  807.0  } } ; # for the Rect object NoName_36 
_laygo2_generate_instance NoName_37 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1584.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_37 
_laygo2_generate_instance NoName_38 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1728.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_38 
_laygo2_generate_rect M3 { { 1713.0  201.0  } { 1743.0  807.0  } } ; # for the Rect object NoName_39 
_laygo2_generate_instance NoName_40 ./magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 1728.0  792.0  } R0 1 1 0 0 ; # for the Instance object NoName_40 
_laygo2_generate_rect M2 { { -20.0  -30.0  } { 1892.0  30.0  } } ; # for the Rect object NoName_41 
_laygo2_generate_rect M2 { { -20.0  978.0  } { 1892.0  1038.0  } } ; # for the Rect object NoName_42 
_laygo2_generate_pin I M3 { { 57.0  360.0  } { 87.0  648.0  } } 1 ; # for the Pin object I 
_laygo2_generate_pin O: M3 { { 129.0  216.0  } { 159.0  792.0  } } 2 ; # for the Pin object O0 
_laygo2_generate_pin O: M3 { { 273.0  216.0  } { 303.0  792.0  } } 3 ; # for the Pin object O1 
_laygo2_generate_pin O: M3 { { 417.0  216.0  } { 447.0  792.0  } } 4 ; # for the Pin object O2 
_laygo2_generate_pin O: M3 { { 561.0  216.0  } { 591.0  792.0  } } 5 ; # for the Pin object O3 
_laygo2_generate_pin O: M3 { { 705.0  216.0  } { 735.0  792.0  } } 6 ; # for the Pin object O4 
_laygo2_generate_pin O: M3 { { 849.0  216.0  } { 879.0  792.0  } } 7 ; # for the Pin object O5 
_laygo2_generate_pin O: M3 { { 993.0  216.0  } { 1023.0  792.0  } } 8 ; # for the Pin object O6 
_laygo2_generate_pin O: M3 { { 1137.0  216.0  } { 1167.0  792.0  } } 9 ; # for the Pin object O7 
_laygo2_generate_pin O: M3 { { 1281.0  216.0  } { 1311.0  792.0  } } 10 ; # for the Pin object O8 
_laygo2_generate_pin O: M3 { { 1425.0  216.0  } { 1455.0  792.0  } } 11 ; # for the Pin object O9 
_laygo2_generate_pin O: M3 { { 1569.0  216.0  } { 1599.0  792.0  } } 12 ; # for the Pin object O10 
_laygo2_generate_pin O: M3 { { 1713.0  216.0  } { 1743.0  792.0  } } 13 ; # for the Pin object O11 
_laygo2_generate_pin VDD M2 { { 0.0  978.0  } { 1872.0  1038.0  } } 14 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { 0.0  -30.0  } { 1872.0  30.0  } } 15 ; # for the Pin object VSS 
save
