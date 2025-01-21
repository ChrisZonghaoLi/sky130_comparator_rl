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

# exporting double_tail__diff_pair
_laygo2_create_layout /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/double_tail double_tail_diff_pair sky130A
_laygo2_generate_instance M5_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object M5_IBNDL0 
_laygo2_generate_instance M5_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nfet_01v8_0p42_nf2 { 72.0  0.0  } R0 1 6 504.0  144.0  ; # for the Instance object M5_IM0 
_laygo2_generate_instance M5_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 936.0  0.0  } R0 1 1 0 0 ; # for the Instance object M5_IBNDR0 
_laygo2_generate_rect M2 { { 106.0  345.0  } { 902.0  375.0  } } ; # for the Rect object M5_RG0 
_laygo2_generate_instance M5_IVG0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  360.0  } R0 1 6 504.0  144.0  ; # for the Instance object M5_IVG0 
_laygo2_generate_rect M2 { { 106.0  201.0  } { 902.0  231.0  } } ; # for the Rect object M5_RD0 
_laygo2_generate_instance M5_IVD0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 144.0  216.0  } R0 1 6 504.0  144.0  ; # for the Instance object M5_IVD0 
_laygo2_generate_rect M2 { { -10.0  -30.0  } { 1018.0  30.0  } } ; # for the Rect object M5_RRAIL0 
_laygo2_generate_rect M1 { { 57.0  -20.0  } { 87.0  164.0  } } ; # for the Rect object M5_RTIE0 
_laygo2_generate_rect M1 { { 201.0  -20.0  } { 231.0  164.0  } } ; # for the Rect object M5_RTIE1 
_laygo2_generate_rect M1 { { 345.0  -20.0  } { 375.0  164.0  } } ; # for the Rect object M5_RTIE2 
_laygo2_generate_rect M1 { { 489.0  -20.0  } { 519.0  164.0  } } ; # for the Rect object M5_RTIE3 
_laygo2_generate_rect M1 { { 633.0  -20.0  } { 663.0  164.0  } } ; # for the Rect object M5_RTIE4 
_laygo2_generate_rect M1 { { 777.0  -20.0  } { 807.0  164.0  } } ; # for the Rect object M5_RTIE5 
_laygo2_generate_rect M1 { { 921.0  -20.0  } { 951.0  164.0  } } ; # for the Rect object M5_RTIE6 
_laygo2_generate_instance M5_IVTIED0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 72.0  0.0  } R0 1 7 504.0  144.0  ; # for the Instance object M5_IVTIED0 
_laygo2_generate_instance M1_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { -432.0  504.0  } R0 1 1 0 0 ; # for the Instance object M1_IBNDL0 
_laygo2_generate_instance M1_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nfet_01v8_0p84_nf2 { -360.0  504.0  } R0 1 5 504.0  144.0  ; # for the Instance object M1_IM0 
_laygo2_generate_instance M1_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 360.0  504.0  } R0 1 1 0 0 ; # for the Instance object M1_IBNDR0 
_laygo2_generate_rect M2 { { -326.0  849.0  } { 326.0  879.0  } } ; # for the Rect object M1_RG0 
_laygo2_generate_instance M1_IVG0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { -288.0  864.0  } R0 1 5 504.0  144.0  ; # for the Instance object M1_IVG0 
_laygo2_generate_rect M2 { { -326.0  705.0  } { 326.0  735.0  } } ; # for the Rect object M1_RD0 
_laygo2_generate_instance M1_IVD0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { -288.0  720.0  } R0 1 5 504.0  144.0  ; # for the Instance object M1_IVD0 
_laygo2_generate_rect M2 { { -442.0  474.0  } { 442.0  534.0  } } ; # for the Rect object M1_RRAIL0 
_laygo2_generate_rect M1 { { -375.0  484.0  } { -345.0  668.0  } } ; # for the Rect object M1_RTIE0 
_laygo2_generate_rect M1 { { -231.0  484.0  } { -201.0  668.0  } } ; # for the Rect object M1_RTIE1 
_laygo2_generate_rect M1 { { -87.0  484.0  } { -57.0  668.0  } } ; # for the Rect object M1_RTIE2 
_laygo2_generate_rect M1 { { 57.0  484.0  } { 87.0  668.0  } } ; # for the Rect object M1_RTIE3 
_laygo2_generate_rect M1 { { 201.0  484.0  } { 231.0  668.0  } } ; # for the Rect object M1_RTIE4 
_laygo2_generate_rect M1 { { 345.0  484.0  } { 375.0  668.0  } } ; # for the Rect object M1_RTIE5 
_laygo2_generate_instance M1_IVTIED0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { -360.0  504.0  } R0 1 6 504.0  144.0  ; # for the Instance object M1_IVTIED0 
_laygo2_generate_instance M2_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 576.0  504.0  } R0 1 1 0 0 ; # for the Instance object M2_IBNDL0 
_laygo2_generate_instance M2_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nfet_01v8_0p84_nf2 { 648.0  504.0  } R0 1 5 504.0  144.0  ; # for the Instance object M2_IM0 
_laygo2_generate_instance M2_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nmos13_fast_boundary { 1368.0  504.0  } R0 1 1 0 0 ; # for the Instance object M2_IBNDR0 
_laygo2_generate_rect M2 { { 682.0  849.0  } { 1334.0  879.0  } } ; # for the Rect object M2_RG0 
_laygo2_generate_instance M2_IVG0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 720.0  864.0  } R0 1 5 504.0  144.0  ; # for the Instance object M2_IVG0 
_laygo2_generate_rect M2 { { 682.0  705.0  } { 1334.0  735.0  } } ; # for the Rect object M2_RD0 
_laygo2_generate_instance M2_IVD0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 720.0  720.0  } R0 1 5 504.0  144.0  ; # for the Instance object M2_IVD0 
_laygo2_generate_rect M2 { { 566.0  474.0  } { 1450.0  534.0  } } ; # for the Rect object M2_RRAIL0 
_laygo2_generate_rect M1 { { 633.0  484.0  } { 663.0  668.0  } } ; # for the Rect object M2_RTIE0 
_laygo2_generate_rect M1 { { 777.0  484.0  } { 807.0  668.0  } } ; # for the Rect object M2_RTIE1 
_laygo2_generate_rect M1 { { 921.0  484.0  } { 951.0  668.0  } } ; # for the Rect object M2_RTIE2 
_laygo2_generate_rect M1 { { 1065.0  484.0  } { 1095.0  668.0  } } ; # for the Rect object M2_RTIE3 
_laygo2_generate_rect M1 { { 1209.0  484.0  } { 1239.0  668.0  } } ; # for the Rect object M2_RTIE4 
_laygo2_generate_rect M1 { { 1353.0  484.0  } { 1383.0  668.0  } } ; # for the Rect object M2_RTIE5 
_laygo2_generate_instance M2_IVTIED0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 648.0  504.0  } R0 1 6 504.0  144.0  ; # for the Instance object M2_IVTIED0 
_laygo2_generate_instance Pwell_M5_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 0.0  0.0  } R0 1 1 0 0 ; # for the Instance object Pwell_M5_IBNDL0 
_laygo2_generate_instance Pwell_M5_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_1p44_5p04 { 72.0  0.0  } R0 1 6 504.0  144.0  ; # for the Instance object Pwell_M5_IM0 
_laygo2_generate_instance Pwell_M5_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 936.0  0.0  } R0 1 1 0 0 ; # for the Instance object Pwell_M5_IBNDR0 
_laygo2_generate_instance Pwell_M1_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { -432.0  504.0  } R0 1 1 0 0 ; # for the Instance object Pwell_M1_IBNDL0 
_laygo2_generate_instance Pwell_M1_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_1p44_5p04 { -360.0  504.0  } R0 1 5 504.0  144.0  ; # for the Instance object Pwell_M1_IM0 
_laygo2_generate_instance Pwell_M1_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 360.0  504.0  } R0 1 1 0 0 ; # for the Instance object Pwell_M1_IBNDR0 
_laygo2_generate_instance Pwell_M2_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 576.0  504.0  } R0 1 1 0 0 ; # for the Instance object Pwell_M2_IBNDL0 
_laygo2_generate_instance Pwell_M2_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_1p44_5p04 { 648.0  504.0  } R0 1 5 504.0  144.0  ; # for the Instance object Pwell_M2_IM0 
_laygo2_generate_instance Pwell_M2_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 1368.0  504.0  } R0 1 1 0 0 ; # for the Instance object Pwell_M2_IBNDR0 
_laygo2_generate_instance Pwell_fill1_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 432.0  504.0  } R0 1 1 0 0 ; # for the Instance object Pwell_fill1_IBNDL0 
_laygo2_generate_instance Pwell_fill1_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_1p44_5p04 { 504.0  504.0  } R0 1 1 504.0  144.0  ; # for the Instance object Pwell_fill1_IM0 
_laygo2_generate_instance Pwell_fill1_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 648.0  504.0  } R0 1 1 0 0 ; # for the Instance object Pwell_fill1_IBNDR0 
_laygo2_generate_instance M3_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 144.0  1512.0  } MX 1 1 0 0 ; # for the Instance object M3_IBNDL0 
_laygo2_generate_instance M3_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pfet_01v8_0p42_nf2 { 216.0  1512.0  } MX 1 1 504.0  144.0  ; # for the Instance object M3_IM0 
_laygo2_generate_instance M3_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 360.0  1512.0  } MX 1 1 0 0 ; # for the Instance object M3_IBNDR0 
_laygo2_generate_rect M2 { { 198.0  1167.0  } { 378.0  1137.0  } } ; # for the Rect object M3_RG0 
_laygo2_generate_instance M3_IVG0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 288.0  1152.0  } MX 1 1 504.0  144.0  ; # for the Instance object M3_IVG0 
_laygo2_generate_rect M2 { { 198.0  1311.0  } { 378.0  1281.0  } } ; # for the Rect object M3_RD0 
_laygo2_generate_instance M3_IVD0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 288.0  1296.0  } MX 1 1 504.0  144.0  ; # for the Instance object M3_IVD0 
_laygo2_generate_rect M2 { { 134.0  1542.0  } { 442.0  1482.0  } } ; # for the Rect object M3_RRAIL0 
_laygo2_generate_rect M1 { { 201.0  1532.0  } { 231.0  1348.0  } } ; # for the Rect object M3_RTIE0 
_laygo2_generate_rect M1 { { 345.0  1532.0  } { 375.0  1348.0  } } ; # for the Rect object M3_RTIE1 
_laygo2_generate_instance M3_IVTIED0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 216.0  1512.0  } MX 1 2 504.0  144.0  ; # for the Instance object M3_IVTIED0 
_laygo2_generate_instance M4_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 576.0  1512.0  } MX 1 1 0 0 ; # for the Instance object M4_IBNDL0 
_laygo2_generate_instance M4_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pfet_01v8_0p42_nf2 { 648.0  1512.0  } MX 1 1 504.0  144.0  ; # for the Instance object M4_IM0 
_laygo2_generate_instance M4_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pmos13_fast_boundary { 792.0  1512.0  } MX 1 1 0 0 ; # for the Instance object M4_IBNDR0 
_laygo2_generate_rect M2 { { 630.0  1167.0  } { 810.0  1137.0  } } ; # for the Rect object M4_RG0 
_laygo2_generate_instance M4_IVG0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 720.0  1152.0  } MX 1 1 504.0  144.0  ; # for the Instance object M4_IVG0 
_laygo2_generate_rect M2 { { 630.0  1311.0  } { 810.0  1281.0  } } ; # for the Rect object M4_RD0 
_laygo2_generate_instance M4_IVD0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 720.0  1296.0  } MX 1 1 504.0  144.0  ; # for the Instance object M4_IVD0 
_laygo2_generate_rect M2 { { 566.0  1542.0  } { 874.0  1482.0  } } ; # for the Rect object M4_RRAIL0 
_laygo2_generate_rect M1 { { 633.0  1532.0  } { 663.0  1348.0  } } ; # for the Rect object M4_RTIE0 
_laygo2_generate_rect M1 { { 777.0  1532.0  } { 807.0  1348.0  } } ; # for the Rect object M4_RTIE1 
_laygo2_generate_instance M4_IVTIED0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 648.0  1512.0  } MX 1 2 504.0  144.0  ; # for the Instance object M4_IVTIED0 
_laygo2_generate_instance Nwell_M3_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 144.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Nwell_M3_IBNDL0 
_laygo2_generate_instance Nwell_M3_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_1p44_5p04 { 216.0  1512.0  } MX 1 1 504.0  144.0  ; # for the Instance object Nwell_M3_IM0 
_laygo2_generate_instance Nwell_M3_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 360.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Nwell_M3_IBNDR0 
_laygo2_generate_instance Nwell_M4_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 576.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Nwell_M4_IBNDL0 
_laygo2_generate_instance Nwell_M4_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_1p44_5p04 { 648.0  1512.0  } MX 1 1 504.0  144.0  ; # for the Instance object Nwell_M4_IM0 
_laygo2_generate_instance Nwell_M4_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 792.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Nwell_M4_IBNDR0 
_laygo2_generate_instance Nwell_fill_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 432.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Nwell_fill_IBNDL0 
_laygo2_generate_instance Nwell_fill_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_1p44_5p04 { 504.0  1512.0  } MX 1 1 504.0  144.0  ; # for the Instance object Nwell_fill_IM0 
_laygo2_generate_instance Nwell_fill_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 648.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Nwell_fill_IBNDR0 
_laygo2_generate_instance Ptap_0_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 360.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Ptap_0_IBNDL0 
_laygo2_generate_instance Ptap_0_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense ptap_nf2 { 432.0  1512.0  } MX 1 1 504.0  144.0  ; # for the Instance object Ptap_0_IM0 
_laygo2_generate_instance Ptap_0_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense nwell_boundary_0p72_5p04 { 576.0  1512.0  } MX 1 1 0 0 ; # for the Instance object Ptap_0_IBNDR0 
_laygo2_generate_rect M2 { { 475.0  1311.0  } { 475.0  1281.0  } } ; # for the Rect object Ptap_0_RTAP10 
_laygo2_generate_rect M2 { { 350.0  1542.0  } { 658.0  1482.0  } } ; # for the Rect object Ptap_0_RRAIL0 
_laygo2_generate_rect M1 { { 417.0  1532.0  } { 447.0  1348.0  } } ; # for the Rect object Ptap_0_RTIE0 
_laygo2_generate_rect M1 { { 561.0  1532.0  } { 591.0  1348.0  } } ; # for the Rect object Ptap_0_RTIE1 
_laygo2_generate_instance Ptap_0_IVTIETAP10 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 432.0  1512.0  } MX 1 2 504.0  144.0  ; # for the Instance object Ptap_0_IVTIETAP10 
_laygo2_generate_instance Ntap_0_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { -432.0  0.0  } R0 1 1 0 0 ; # for the Instance object Ntap_0_IBNDL0 
_laygo2_generate_instance Ntap_0_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense ntap_nf2 { -360.0  0.0  } R0 1 1 504.0  144.0  ; # for the Instance object Ntap_0_IM0 
_laygo2_generate_instance Ntap_0_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { -216.0  0.0  } R0 1 1 0 0 ; # for the Instance object Ntap_0_IBNDR0 
_laygo2_generate_rect M2 { { -317.0  201.0  } { -317.0  231.0  } } ; # for the Rect object Ntap_0_RTAP10 
_laygo2_generate_rect M2 { { -442.0  -30.0  } { -134.0  30.0  } } ; # for the Rect object Ntap_0_RRAIL0 
_laygo2_generate_rect M1 { { -375.0  -20.0  } { -345.0  164.0  } } ; # for the Rect object Ntap_0_RTIE0 
_laygo2_generate_rect M1 { { -231.0  -20.0  } { -201.0  164.0  } } ; # for the Rect object Ntap_0_RTIE1 
_laygo2_generate_instance Ntap_0_IVTIETAP10 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { -360.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object Ntap_0_IVTIETAP10 
_laygo2_generate_instance Ntap_1_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 1152.0  0.0  } R0 1 1 0 0 ; # for the Instance object Ntap_1_IBNDL0 
_laygo2_generate_instance Ntap_1_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense ntap_nf2 { 1224.0  0.0  } R0 1 1 504.0  144.0  ; # for the Instance object Ntap_1_IM0 
_laygo2_generate_instance Ntap_1_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 1368.0  0.0  } R0 1 1 0 0 ; # for the Instance object Ntap_1_IBNDR0 
_laygo2_generate_rect M2 { { 1267.0  201.0  } { 1267.0  231.0  } } ; # for the Rect object Ntap_1_RTAP10 
_laygo2_generate_rect M2 { { 1142.0  -30.0  } { 1450.0  30.0  } } ; # for the Rect object Ntap_1_RRAIL0 
_laygo2_generate_rect M1 { { 1209.0  -20.0  } { 1239.0  164.0  } } ; # for the Rect object Ntap_1_RTIE0 
_laygo2_generate_rect M1 { { 1353.0  -20.0  } { 1383.0  164.0  } } ; # for the Rect object Ntap_1_RTIE1 
_laygo2_generate_instance Ntap_1_IVTIETAP10 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_1 { 1224.0  0.0  } R0 1 2 504.0  144.0  ; # for the Instance object Ntap_1_IVTIETAP10 
_laygo2_generate_instance Pwell_fill2_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { -144.0  0.0  } R0 1 1 0 0 ; # for the Instance object Pwell_fill2_IBNDL0 
_laygo2_generate_instance Pwell_fill2_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_1p44_5p04 { -72.0  0.0  } R0 1 1 504.0  144.0  ; # for the Instance object Pwell_fill2_IM0 
_laygo2_generate_instance Pwell_fill2_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 72.0  0.0  } R0 1 1 0 0 ; # for the Instance object Pwell_fill2_IBNDR0 
_laygo2_generate_instance Pwell_fill3_IBNDL0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 1008.0  0.0  } R0 1 1 0 0 ; # for the Instance object Pwell_fill3_IBNDL0 
_laygo2_generate_instance Pwell_fill3_IM0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_1p44_5p04 { 1080.0  0.0  } R0 1 1 504.0  144.0  ; # for the Instance object Pwell_fill3_IM0 
_laygo2_generate_instance Pwell_fill3_IBNDR0 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense pwell_boundary_0p72_5p04 { 1224.0  0.0  } R0 1 1 0 0 ; # for the Instance object Pwell_fill3_IBNDR0 
_laygo2_generate_rect M2 { { -303.0  849.0  } { 303.0  879.0  } } ; # for the Rect object NoName_0 
_laygo2_generate_rect M2 { { 705.0  849.0  } { 1311.0  879.0  } } ; # for the Rect object NoName_1 
_laygo2_generate_rect M2 { { 129.0  345.0  } { 879.0  375.0  } } ; # for the Rect object NoName_2 
_laygo2_generate_rect M2 { { 273.0  1137.0  } { 735.0  1167.0  } } ; # for the Rect object NoName_3 
_laygo2_generate_instance NoName_4 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 504.0  360.0  } R0 1 1 0 0 ; # for the Instance object NoName_4 
_laygo2_generate_rect M3 { { 489.0  345.0  } { 519.0  1167.0  } } ; # for the Rect object NoName_5 
_laygo2_generate_instance NoName_6 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 504.0  1152.0  } R0 1 1 0 0 ; # for the Instance object NoName_6 
_laygo2_generate_rect M2 { { -87.0  201.0  } { 1095.0  231.0  } } ; # for the Rect object NoName_7 
_laygo2_generate_instance NoName_8 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { -72.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_8 
_laygo2_generate_instance NoName_9 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { -72.0  504.0  } R0 1 1 0 0 ; # for the Instance object NoName_9 
_laygo2_generate_rect M1 { { -87.0  201.0  } { -57.0  519.0  } } ; # for the Rect object NoName_10 
_laygo2_generate_rect M2 { { -447.0  489.0  } { -57.0  519.0  } } ; # for the Rect object NoName_11 
_laygo2_generate_instance NoName_12 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 1080.0  216.0  } R0 1 1 0 0 ; # for the Instance object NoName_12 
_laygo2_generate_instance NoName_13 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 1080.0  504.0  } R0 1 1 0 0 ; # for the Instance object NoName_13 
_laygo2_generate_rect M1 { { 1065.0  201.0  } { 1095.0  519.0  } } ; # for the Rect object NoName_14 
_laygo2_generate_rect M2 { { 1065.0  489.0  } { 1455.0  519.0  } } ; # for the Rect object NoName_15 
_laygo2_generate_rect M2 { { 273.0  705.0  } { 447.0  735.0  } } ; # for the Rect object NoName_16 
_laygo2_generate_instance NoName_17 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  720.0  } R0 1 1 0 0 ; # for the Instance object NoName_17 
_laygo2_generate_instance NoName_18 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 432.0  1296.0  } R0 1 1 0 0 ; # for the Instance object NoName_18 
_laygo2_generate_rect M3 { { 417.0  705.0  } { 447.0  1311.0  } } ; # for the Rect object NoName_19 
_laygo2_generate_instance NoName_20 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 288.0  1296.0  } R0 1 1 0 0 ; # for the Instance object NoName_20 
_laygo2_generate_rect M2 { { 273.0  1281.0  } { 447.0  1311.0  } } ; # for the Rect object NoName_21 
_laygo2_generate_rect M2 { { 561.0  705.0  } { 735.0  735.0  } } ; # for the Rect object NoName_22 
_laygo2_generate_instance NoName_23 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  720.0  } R0 1 1 0 0 ; # for the Instance object NoName_23 
_laygo2_generate_instance NoName_24 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M2_M3_0 { 576.0  1296.0  } R0 1 1 0 0 ; # for the Instance object NoName_24 
_laygo2_generate_rect M3 { { 561.0  705.0  } { 591.0  1311.0  } } ; # for the Rect object NoName_25 
_laygo2_generate_rect M2 { { 561.0  1281.0  } { 735.0  1311.0  } } ; # for the Rect object NoName_26 
_laygo2_generate_instance NoName_27 /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/laygo2_workspace_sky130/magic_layout/skywater130_microtemplates_dense via_M1_M2_0 { 720.0  1296.0  } R0 1 1 0 0 ; # for the Instance object NoName_27 
_laygo2_generate_rect M2 { { -462.0  -30.0  } { 1470.0  30.0  } } ; # for the Rect object NoName_28 
_laygo2_generate_rect M2 { { 114.0  1482.0  } { 894.0  1542.0  } } ; # for the Rect object NoName_29 
_laygo2_generate_pin CLK M2 { { 144.0  345.0  } { 864.0  375.0  } } 1 ; # for the Pin object CLK 
_laygo2_generate_pin Di_n M3 { { 417.0  720.0  } { 447.0  1296.0  } } 2 ; # for the Pin object Di_n 
_laygo2_generate_pin Di_p M3 { { 561.0  720.0  } { 591.0  1296.0  } } 3 ; # for the Pin object Di_p 
_laygo2_generate_pin VDD M2 { { 144.0  1497.0  } { 864.0  1527.0  } } 4 ; # for the Pin object VDD 
_laygo2_generate_pin VSS M2 { { -432.0  -15.0  } { 1440.0  15.0  } } 5 ; # for the Pin object VSS 
_laygo2_generate_pin Vin_n M2 { { 720.0  849.0  } { 1296.0  879.0  } } 6 ; # for the Pin object Vin_n 
_laygo2_generate_pin Vin_p M2 { { -288.0  849.0  } { 288.0  879.0  } } 7 ; # for the Pin object Vin_p 
save
