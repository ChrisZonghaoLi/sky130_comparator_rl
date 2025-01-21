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

# exporting double_tail__latch
_laygo2_create_layout /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/double_tail double_tail_latch sky130A
_laygo2_generate_instance inv0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/double_tail double_tail_inverter { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object inv0 
_laygo2_generate_instance inv1 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/double_tail double_tail_inverter { 0.0  0.0  } MY 1 1 0 0 ; # for the Instance object inv1 
_laygo2_generate_instance M9_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 288.0  0.0  } R0 1 1 0 0 ; # for the Instance object M9_IBNDL0 
_laygo2_generate_instance M9_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nfet_01v8_0p42_nf2 { 360.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object M9_IM0 
_laygo2_generate_instance M9_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 648.0  0.0  } R0 1 1 0 0 ; # for the Instance object M9_IBNDR0 
_laygo2_generate_rect M2 { { 394.0  345.0  } { 614.0  375.0  } } ; # for the Rect object M9_RG0 
_laygo2_generate_instance M9_IVG0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 432.0  360.0  } R0 1 2 504.0  144.0  ; # for the Instance object M9_IVG0 
_laygo2_generate_rect M2 { { 394.0  201.0  } { 614.0  231.0  } } ; # for the Rect object M9_RD0 
_laygo2_generate_instance M9_IVD0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 432.0  216.0  } R0 1 2 504.0  144.0  ; # for the Instance object M9_IVD0 
_laygo2_generate_rect M2 { { 278.0  -30.0  } { 730.0  30.0  } } ; # for the Rect object M9_RRAIL0 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object M9_RTIE0 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object M9_RTIE1 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object M9_RTIE2 
_laygo2_generate_instance M9_IVTIED0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 360.0  0.0  } R0 1 3 504.0  144.0  ; # for the Instance object M9_IVTIED0 
_laygo2_generate_instance M6_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { -720.0  0.0  } R0 1 1 0 0 ; # for the Instance object M6_IBNDL0 
_laygo2_generate_instance M6_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nfet_01v8_0p42_nf2 { -648.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object M6_IM0 
_laygo2_generate_instance M6_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { -360.0  0.0  } R0 1 1 0 0 ; # for the Instance object M6_IBNDR0 
_laygo2_generate_rect M2 { { -614.0  345.0  } { -394.0  375.0  } } ; # for the Rect object M6_RG0 
_laygo2_generate_instance M6_IVG0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { -576.0  360.0  } R0 1 2 504.0  144.0  ; # for the Instance object M6_IVG0 
_laygo2_generate_rect M2 { { -614.0  201.0  } { -394.0  231.0  } } ; # for the Rect object M6_RD0 
_laygo2_generate_instance M6_IVD0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { -576.0  216.0  } R0 1 2 504.0  144.0  ; # for the Instance object M6_IVD0 
_laygo2_generate_rect M2 { { -730.0  -30.0  } { -278.0  30.0  } } ; # for the Rect object M6_RRAIL0 
_laygo2_generate_rect M1 { { -663.0  -20.0  } { -633.0  164.0  } } ; # for the Rect object M6_RTIE0 
_laygo2_generate_rect M1 { { -519.0  -20.0  } { -489.0  164.0  } } ; # for the Rect object M6_RTIE1 
_laygo2_generate_rect M1 { { -375.0  -20.0  } { -345.0  164.0  } } ; # for the Rect object M6_RTIE2 
_laygo2_generate_instance M6_IVTIED0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { -648.0  0.0  } R0 1 3 504.0  144.0  ; # for the Instance object M6_IVTIED0 
_laygo2_generate_instance M12_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { -504.0  1512.0  } MX 1 1 0 0 ; # for the Instance object M12_IBNDL0 
_laygo2_generate_instance M12_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pfet_01v8_0p84_nf2 { -432.0  1512.0  } MX 1 6 504.0  144.0  ; # for the Instance object M12_IM0 
_laygo2_generate_instance M12_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 432.0  1512.0  } MX 1 1 0 0 ; # for the Instance object M12_IBNDR0 
_laygo2_generate_rect M2 { { -398.0  1167.0  } { 398.0  1137.0  } } ; # for the Rect object M12_RG0 
_laygo2_generate_instance M12_IVG0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { -360.0  1152.0  } MX 1 6 504.0  144.0  ; # for the Instance object M12_IVG0 
_laygo2_generate_rect M2 { { -398.0  1311.0  } { 398.0  1281.0  } } ; # for the Rect object M12_RD0 
_laygo2_generate_instance M12_IVD0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { -360.0  1296.0  } MX 1 6 504.0  144.0  ; # for the Instance object M12_IVD0 
_laygo2_generate_rect M2 { { -514.0  1542.0  } { 514.0  1482.0  } } ; # for the Rect object M12_RRAIL0 
_laygo2_generate_rect M1 { { -447.0  1532.0  } { -417.0  1348.0  } } ; # for the Rect object M12_RTIE0 
_laygo2_generate_rect M1 { { -303.0  1532.0  } { -273.0  1348.0  } } ; # for the Rect object M12_RTIE1 
_laygo2_generate_rect M1 { { -159.0  1532.0  } { -129.0  1348.0  } } ; # for the Rect object M12_RTIE2 
_laygo2_generate_rect M1 { { -15.0  1532.0  } { 15.0  1348.0  } } ; # for the Rect object M12_RTIE3 
_laygo2_generate_rect M1 { { 129.0  1532.0  } { 159.0  1348.0  } } ; # for the Rect object M12_RTIE4 
_laygo2_generate_rect M1 { { 273.0  1532.0  } { 303.0  1348.0  } } ; # for the Rect object M12_RTIE5 
_laygo2_generate_rect M1 { { 417.0  1532.0  } { 447.0  1348.0  } } ; # for the Rect object M12_RTIE6 
_laygo2_generate_instance M12_IVTIED0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { -432.0  1512.0  } MX 1 7 504.0  144.0  ; # for the Instance object M12_IVTIED0 
_laygo2_generate_instance Ntap_0_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 720.0  0.0  } R0 1 1 0 0 ; # for the Instance object Ntap_0_IBNDL0 
_laygo2_generate_instance Ntap_0_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense ntap_nf2 { 792.0  0.0  } R0 1 1 504.0  144.0  ; # for the Instance object Ntap_0_IM0 
_laygo2_generate_instance Ntap_0_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 936.0  0.0  } R0 1 1 0 0 ; # for the Instance object Ntap_0_IBNDR0 
_laygo2_generate_rect M2 { { 835.0  201.0  } { 835.0  231.0  } } ; # for the Rect object Ntap_0_RTAP10 
_laygo2_generate_rect M2 { { 710.0  -30.0  } { 1018.0  30.0  } } ; # for the Rect object Ntap_0_RRAIL0 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object Ntap_0_RTIE0 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object Ntap_0_RTIE1 
_laygo2_generate_instance Ntap_0_IVTIETAP10 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 792.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object Ntap_0_IVTIETAP10 
_laygo2_generate_instance Ntap_1_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { -1008.0  0.0  } R0 1 1 0 0 ; # for the Instance object Ntap_1_IBNDL0 
_laygo2_generate_instance Ntap_1_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense ntap_nf2 { -936.0  0.0  } R0 1 1 504.0  144.0  ; # for the Instance object Ntap_1_IM0 
_laygo2_generate_instance Ntap_1_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { -792.0  0.0  } R0 1 1 0 0 ; # for the Instance object Ntap_1_IBNDR0 
_laygo2_generate_rect M2 { { -893.0  201.0  } { -893.0  231.0  } } ; # for the Rect object Ntap_1_RTAP10 
_laygo2_generate_rect M2 { { -1018.0  -30.0  } { -710.0  30.0  } } ; # for the Rect object Ntap_1_RRAIL0 
_laygo2_generate_rect M1 { { -951.0  -20.0  } { -921.0  164.0  } } ; # for the Rect object Ntap_1_RTIE0 
_laygo2_generate_rect M1 { { -807.0  -20.0  } { -777.0  164.0  } } ; # for the Rect object Ntap_1_RTIE1 
_laygo2_generate_instance Ntap_1_IVTIETAP10 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { -936.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object Ntap_1_IVTIETAP10 
_laygo2_generate_instance Ptap_0_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 504.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Ptap_0_IBNDL0 
_laygo2_generate_instance Ptap_0_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense ptap_nf2 { 576.0  1512.0  } MX 1 1 504.0  144.0  ; # for the Instance object Ptap_0_IM0 
_laygo2_generate_instance Ptap_0_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 720.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Ptap_0_IBNDR0 
_laygo2_generate_rect M2 { { 619.0  1311.0  } { 619.0  1281.0  } } ; # for the Rect object Ptap_0_RTAP10 
_laygo2_generate_rect M2 { { 494.0  1542.0  } { 802.0  1482.0  } } ; # for the Rect object Ptap_0_RRAIL0 
_laygo2_generate_rect M1 { { 561.0  1532.0  } { 591.0  1348.0  } } ; # for the Rect object Ptap_0_RTIE0 
_laygo2_generate_rect M1 { { 705.0  1532.0  } { 735.0  1348.0  } } ; # for the Rect object Ptap_0_RTIE1 
_laygo2_generate_instance Ptap_0_IVTIETAP10 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 576.0  1512.0  } MX 1 2 504.0  144.0  ; # for the Instance object Ptap_0_IVTIETAP10 
_laygo2_generate_instance Ptap_1_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { -792.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Ptap_1_IBNDL0 
_laygo2_generate_instance Ptap_1_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense ptap_nf2 { -720.0  1512.0  } MX 1 1 504.0  144.0  ; # for the Instance object Ptap_1_IM0 
_laygo2_generate_instance Ptap_1_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { -576.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Ptap_1_IBNDR0 
_laygo2_generate_rect M2 { { -677.0  1311.0  } { -677.0  1281.0  } } ; # for the Rect object Ptap_1_RTAP10 
_laygo2_generate_rect M2 { { -802.0  1542.0  } { -494.0  1482.0  } } ; # for the Rect object Ptap_1_RRAIL0 
_laygo2_generate_rect M1 { { -735.0  1532.0  } { -705.0  1348.0  } } ; # for the Rect object Ptap_1_RTIE0 
_laygo2_generate_rect M1 { { -591.0  1532.0  } { -561.0  1348.0  } } ; # for the Rect object Ptap_1_RTIE1 
_laygo2_generate_instance Ptap_1_IVTIETAP10 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { -720.0  1512.0  } MX 1 2 504.0  144.0  ; # for the Instance object Ptap_1_IVTIETAP10 
_laygo2_generate_instance Pwell_fill0_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { -1008.0  0.0  } R0 1 1 0 0 ; # for the Instance object Pwell_fill0_IBNDL0 
_laygo2_generate_instance Pwell_fill0_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_1p44_5p04 { -936.0  0.0  } R0 1 12 504.0  144.0  ; # for the Instance object Pwell_fill0_IM0 
_laygo2_generate_instance Pwell_fill0_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 792.0  0.0  } R0 1 1 0 0 ; # for the Instance object Pwell_fill0_IBNDR0 
_laygo2_generate_instance Nwell_fill0_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { -288.0  504.0  } R0 1 1 0 0 ; # for the Instance object Nwell_fill0_IBNDL0 
_laygo2_generate_instance Nwell_fill0_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_1p44_5p04 { -216.0  504.0  } R0 1 3 504.0  144.0  ; # for the Instance object Nwell_fill0_IM0 
_laygo2_generate_instance Nwell_fill0_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 216.0  504.0  } R0 1 1 0 0 ; # for the Instance object Nwell_fill0_IBNDR0 
_laygo2_generate_instance Nwell_fill1_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { -792.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Nwell_fill1_IBNDL0 
_laygo2_generate_instance Nwell_fill1_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_1p44_5p04 { -720.0  1512.0  } MX 1 9 504.0  144.0  ; # for the Instance object Nwell_fill1_IM0 
_laygo2_generate_instance Nwell_fill1_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 576.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Nwell_fill1_IBNDR0 
_laygo2_generate_instance NoName_0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { -72.0  576.0  } R0 1 1 0 0 ; # for the Instance object NoName_0 
_laygo2_generate_rect M2 { { -87.0  561.0  } { 159.0  591.0  } } ; # for the Rect object NoName_1 
_laygo2_generate_instance NoName_2 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 144.0  576.0  } R0 1 1 0 0 ; # for the Instance object NoName_2 
_laygo2_generate_instance NoName_3 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { -144.0  432.0  } R0 1 1 0 0 ; # for the Instance object NoName_3 
_laygo2_generate_rect M2 { { -159.0  417.0  } { 87.0  447.0  } } ; # for the Rect object NoName_4 
_laygo2_generate_instance NoName_5 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 72.0  432.0  } R0 1 1 0 0 ; # for the Instance object NoName_5 
_laygo2_generate_rect M2 { { 129.0  201.0  } { 447.0  231.0  } } ; # for the Rect object NoName_6 
_laygo2_generate_rect M2 { { -591.0  201.0  } { -129.0  231.0  } } ; # for the Rect object NoName_7 
_laygo2_generate_rect M2 { { -303.0  993.0  } { 303.0  1023.0  } } ; # for the Rect object NoName_8 
_laygo2_generate_instance NoName_9 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 0.0  1296.0  } R0 1 1 0 0 ; # for the Instance object NoName_9 
_laygo2_generate_rect M3 { { -15.0  993.0  } { 15.0  1311.0  } } ; # for the Rect object NoName_10 
_laygo2_generate_instance NoName_11 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 0.0  1008.0  } R0 1 1 0 0 ; # for the Instance object NoName_11 
_laygo2_generate_rect M2 { { -1038.0  -30.0  } { 1038.0  30.0  } } ; # for the Rect object NoName_12 
_laygo2_generate_rect M2 { { -822.0  1482.0  } { 822.0  1542.0  } } ; # for the Rect object NoName_13 
_laygo2_generate_pin CLK_bar M2 { { -360.0  1137.0  } { 360.0  1167.0  } } 1 ; # for the Pin object CLK_bar 
_laygo2_generate_pin Di_n M2 { { -576.0  345.0  } { -432.0  375.0  } } 2 ; # for the Pin object Di_n 
_laygo2_generate_pin Di_p M2 { { 432.0  345.0  } { 576.0  375.0  } } 3 ; # for the Pin object Di_p 
_laygo2_generate_pin VDD M2 { { -792.0  1497.0  } { 792.0  1527.0  } } 4 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { -288.0  -15.0  } { 288.0  15.0  } } 5 ; # for the Pin object VSS 
_laygo2_generate_pin Vout_n M2 { { -72.0  561.0  } { 144.0  591.0  } } 6 ; # for the Pin object Vout_n 
_laygo2_generate_pin Vout_p M2 { { -144.0  417.0  } { 72.0  447.0  } } 7 ; # for the Pin object Vout_p 
save
