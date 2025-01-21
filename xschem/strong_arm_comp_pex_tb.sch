v {xschem version=3.4.5 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
T {This testbench is to do PEX simulation of strong arm comparator.
How to use it:
You should first click "netlist" to generate the netlist of the testbench; then go to run <reformat_netlist.py> under the same directory, which will embed the RC extracted strong arm comparator circuit netlist into the testbench. Finally, click "simulate", which will do the PEX simulations.} 10 -1410 0 0 0.4 0.4 {}
N 20 -150 20 -130 {
lab=GND}
N 20 -260 20 -210 {
lab=Vclk}
N 250 -260 390 -260 {
lab=Vclk}
N 20 -260 250 -260 {
lab=Vclk}
N 260 -150 260 -130 {
lab=GND}
N 260 -220 260 -210 {
lab=Vcm}
N 260 -300 260 -220 {
lab=Vcm}
N 260 -280 280 -280 {
lab=Vcm}
N 1390 -260 1420 -260 {
lab=Q}
N 1390 -240 1420 -240 {
lab=Q_bar}
N 1400 -140 1400 -90 {
lab=GND}
N 1400 -240 1400 -200 {
lab=Q_bar}
N 1480 -140 1480 -90 {
lab=GND}
N 1420 -240 1580 -240 {
lab=Q_bar}
N 1420 -260 1580 -260 {
lab=Q}
N 1480 -260 1480 -200 {
lab=Q}
N 920 -300 940 -300 {
lab=GND}
N 1480 -280 1490 -280 {
lab=GND}
N 1550 -280 1570 -280 {
lab=GND}
N 1490 -280 1550 -280 {
lab=GND}
N 1390 -280 1420 -280 {
lab=#net1}
N 280 -280 350 -280 {
lab=Vcm}
N 350 -280 390 -280 {
lab=Vcm}
N 260 -300 280 -300 {
lab=Vcm}
N 340 -300 390 -300 {
lab=#net2}
N 20 -460 20 -440 {
lab=GND}
N 20 -570 20 -520 {
lab=#net3}
N 250 -570 390 -570 {
lab=#net3}
N 20 -570 250 -570 {
lab=#net3}
N 350 -460 350 -440 {
lab=GND}
N 350 -530 350 -520 {
lab=#net4}
N 790 -610 800 -610 {
lab=GND}
N 800 -610 820 -610 {
lab=GND}
N 350 -590 390 -590 {
lab=#net4}
N 690 -590 740 -590 {
lab=Vout_n_mc}
N 690 -570 740 -570 {
lab=Vout_p_mc}
N 350 -590 350 -530 {
lab=#net4}
N 260 -460 260 -440 {
lab=GND}
N 260 -610 260 -520 {
lab=Vsc}
N 260 -610 390 -610 {
lab=Vsc}
N 690 -610 730 -610 {
lab=#net5}
N 20 -740 20 -720 {
lab=GND}
N 20 -850 20 -800 {
lab=#net6}
N 250 -740 250 -720 {
lab=GND}
N 250 -810 250 -800 {
lab=#net7}
N 790 -890 800 -890 {
lab=GND}
N 800 -890 820 -890 {
lab=GND}
N 690 -870 740 -870 {
lab=Vout_n_ms}
N 690 -850 740 -850 {
lab=Vout_p_ms}
N 690 -890 730 -890 {
lab=#net8}
N 250 -890 290 -890 {
lab=#net7}
N 250 -890 250 -810 {
lab=#net7}
N 20 -850 390 -850 {
lab=#net6}
N 350 -890 390 -890 {
lab=#net9}
N 250 -870 390 -870 {
lab=#net7}
N 20 -1040 20 -1020 {
lab=GND}
N 20 -1150 20 -1100 {
lab=#net10}
N 170 -1040 170 -1020 {
lab=GND}
N 170 -1110 170 -1100 {
lab=#net11}
N 790 -1190 800 -1190 {
lab=GND}
N 800 -1190 820 -1190 {
lab=GND}
N 690 -1170 740 -1170 {
lab=Vout_n_kn}
N 690 -1150 740 -1150 {
lab=Vout_p_kn}
N 690 -1190 730 -1190 {
lab=#net12}
N 20 -1150 390 -1150 {
lab=#net10}
N 270 -1190 300 -1190 {
lab=#net13}
N 360 -1190 390 -1190 {
lab=Vp_kn}
N 360 -1170 390 -1170 {
lab=Vn_kn}
N 170 -1190 210 -1190 {
lab=#net11}
N 170 -1170 300 -1170 {
lab=#net11}
N 170 -1190 170 -1110 {
lab=#net11}
N 800 -300 860 -300 {
lab=#net14}
N 690 -300 740 -300 {
lab=#net15}
N 690 -1090 710 -1090 {
lab=GND}
N 690 -790 710 -790 {
lab=GND}
N 690 -510 710 -510 {
lab=GND}
N 690 -280 780 -280 {
lab=Vout_n}
N 780 -280 820 -260 {
lab=Vout_n}
N 820 -260 1090 -260 {
lab=Vout_n}
N 690 -260 780 -260 {
lab=Vout_p}
N 780 -260 820 -280 {
lab=Vout_p}
N 820 -280 1090 -280 {
lab=Vout_p}
N 690 -200 710 -200 {
lab=GND}
N 690 -240 740 -240 {
lab=Di_p}
N 690 -220 740 -220 {
lab=Di_n}
N 690 -550 740 -550 {
lab=Di_p_mc}
N 690 -530 740 -530 {
lab=Di_n_mc}
N 690 -830 740 -830 {
lab=Di_p_ms}
N 690 -810 740 -810 {
lab=Di_n_ms}
N 690 -1130 740 -1130 {
lab=Di_p_kn}
N 690 -1110 740 -1110 {
lab=Di_n_kn}
C {devices/gnd.sym} 940 -300 3 0 {name=l1 lab=GND}
C {devices/vsource.sym} 770 -300 3 0 {name=VDD value=VDD}
C {devices/vsource.sym} 20 -180 0 0 {name=Vclk value="PULSE(0 VDD Tdelay Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 20 -130 0 0 {name=l2 lab=GND}
C {devices/vsource.sym} 260 -180 0 0 {name=Vcm value="dc Vcm"}
C {devices/gnd.sym} 260 -130 0 0 {name=l3 lab=GND}
C {devices/vsource.sym} 310 -300 1 0 {name=Vdiff value="dc Vin"}
C {devices/lab_pin.sym} 20 -230 0 0 {name=p3 sig_type=std_logic lab=Vclk}
C {devices/opin.sym} 1020 -260 1 0 {name=p8 lab=Vout_n}
C {devices/opin.sym} 1020 -280 3 0 {name=p1 lab=Vout_p}
C {devices/opin.sym} 1580 -260 0 0 {name=p6 lab=Q}
C {devices/opin.sym} 1580 -240 0 0 {name=p7 lab=Q_bar}
C {devices/lab_pin.sym} 260 -230 0 0 {name=p17 sig_type=std_logic lab=Vcm}
C {devices/capa.sym} 1400 -170 0 0 {name=C2
m=1
value=10f
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1400 -90 0 0 {name=l7 lab=GND}
C {devices/capa.sym} 1480 -170 0 0 {name=C3
m=1
value=10f
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1480 -90 0 0 {name=l9 lab=GND}
C {devices/res.sym} 890 -300 3 0 {name=Rdummy
value=0.01
footprint=1206
device=resistor
m=1}
C {devices/gnd.sym} 1570 -280 3 0 {name=l4 lab=GND}
C {devices/vsource.sym} 1450 -280 3 0 {name=VDD1 value=VDD}
C {strong_arm_comp.sym} 540 -250 0 0 {name=x1}
C {sky130_fd_pr/corner.sym} 1770 -1170 0 0 {name=CORNER only_toplevel=false corner=tt}
C {devices/code_shown.sym} 1770 -920 0 0 {name=s1 only_toplevel=false 
value="
*.OPTIONS maxord=1
*.OPTIONS itl1=200
*.OPTIONS itl2=200
*.OPTIONS itl4=200

* save all voltage and current
.save all 
.options savecurrents
.options seed=random

.control
set filetype=ascii
set units=degrees

* RC extracted comparator netlist
.include /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/netgen/strong_arm/TCL/strong_arm_comparator_pex.spice
* analyses
.include /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/xschem/simulations/strong_arm_comp_pex_tb_analyses.spice
* stimulus variables
.include /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/xschem/simulations/strong_arm_comp_pex_tb_vars.spice

.endc
"}
C {devices/gnd.sym} 820 -610 3 0 {name=l5 lab=GND}
C {devices/vsource.sym} 760 -610 3 0 {name=VDD2 value=VDD}
C {devices/vsource.sym} 20 -490 0 0 {name=Vclk1 value="PULSE(0 VDD Tdelay Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 20 -440 0 0 {name=l6 lab=GND}
C {devices/vsource.sym} 350 -490 0 0 {name=Vcm1 value="dc Vcm"}
C {devices/gnd.sym} 350 -440 0 0 {name=l8 lab=GND}
C {devices/opin.sym} 740 -590 0 0 {name=p4 lab=Vout_n_mc}
C {devices/opin.sym} 740 -570 0 0 {name=p5 lab=Vout_p_mc}
C {devices/lab_pin.sym} 260 -540 0 0 {name=p11 sig_type=std_logic lab=Vsc}
C {strong_arm_comp.sym} 540 -560 0 0 {name=x3}
C {devices/vsource.sym} 260 -490 0 0 {name=ASRC1 value=3 
format="@name \\\\%v([ @@p ]) filesrc"
device_model="
.model filesrc filesource (file=\\"staircase_voltage_hysteresis.txt\\" amploffset=[Vcm] amplscale=[1] timeoffset=0 timescale=1 timerelative=false amplstep=false)
"}
C {devices/gnd.sym} 260 -440 0 0 {name=l11 lab=GND}
C {devices/gnd.sym} 820 -890 3 0 {name=l10 lab=GND}
C {devices/vsource.sym} 760 -890 3 0 {name=VDD3 value=VDD}
C {devices/vsource.sym} 20 -770 0 0 {name=Vclk2 value="PULSE(0 VDD Tdelay Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 20 -720 0 0 {name=l12 lab=GND}
C {devices/vsource.sym} 250 -770 0 0 {name=Vcm2 value="dc Vcm"}
C {devices/gnd.sym} 250 -720 0 0 {name=l13 lab=GND}
C {devices/opin.sym} 740 -870 0 0 {name=p2 lab=Vout_n_ms}
C {devices/opin.sym} 740 -850 0 0 {name=p9 lab=Vout_p_ms}
C {strong_arm_comp.sym} 540 -840 0 0 {name=x4}
C {devices/vsource.sym} 320 -890 1 0 {name=Vdiff1 value="dc Vin_min"}
C {devices/gnd.sym} 820 -1190 3 0 {name=l14 lab=GND}
C {devices/vsource.sym} 760 -1190 3 0 {name=VDD4 value=VDD}
C {devices/vsource.sym} 20 -1070 0 0 {name=Vclk3 value="PULSE(0 VDD Tdelay Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 20 -1020 0 0 {name=l15 lab=GND}
C {devices/vsource.sym} 170 -1070 0 0 {name=Vcm3 value="dc Vcm"}
C {devices/gnd.sym} 170 -1020 0 0 {name=l16 lab=GND}
C {devices/opin.sym} 740 -1170 0 0 {name=p10 lab=Vout_n_kn}
C {devices/opin.sym} 740 -1150 0 0 {name=p12 lab=Vout_p_kn}
C {strong_arm_comp.sym} 540 -1140 0 0 {name=x5}
C {devices/vsource.sym} 240 -1190 1 0 {name=Vdiff2 value="dc Vin"}
C {devices/res.sym} 330 -1190 3 0 {name=Rdummyp
value=8k
footprint=1206
device=resistor
m=1}
C {devices/res.sym} 330 -1170 3 0 {name=Rdummyn
value=8k
footprint=1206
device=resistor
m=1}
C {RS_latch.sym} 1240 -260 0 0 {name=x2}
C {devices/lab_pin.sym} 370 -1170 3 0 {name=p23 sig_type=std_logic lab=Vn_kn}
C {devices/lab_pin.sym} 370 -1190 3 1 {name=p24 sig_type=std_logic lab=Vp_kn}
C {devices/gnd.sym} 710 -1090 3 0 {name=l21 lab=GND}
C {devices/gnd.sym} 710 -790 3 0 {name=l22 lab=GND}
C {devices/gnd.sym} 710 -510 3 0 {name=l23 lab=GND}
C {devices/gnd.sym} 710 -200 3 0 {name=l25 lab=GND}
C {devices/opin.sym} 740 -240 0 0 {name=p16 lab=Di_p}
C {devices/opin.sym} 740 -220 0 0 {name=p18 lab=Di_n}
C {devices/opin.sym} 740 -550 0 0 {name=p13 lab=Di_p_mc}
C {devices/opin.sym} 740 -530 0 0 {name=p14 lab=Di_n_mc}
C {devices/opin.sym} 740 -830 0 0 {name=p15 lab=Di_p_ms}
C {devices/opin.sym} 740 -810 0 0 {name=p19 lab=Di_n_ms}
C {devices/opin.sym} 740 -1130 0 0 {name=p20 lab=Di_p_kn}
C {devices/opin.sym} 740 -1110 0 0 {name=p21 lab=Di_n_kn}
