v {xschem version=3.4.5 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
T {This testbench is to do PEX simulation of strong arm comparator.
How to use it:
You should first click "netlist" to generate the netlist of the testbench; then go to run <reformat_netlist.py> under the same directory, which will embed the RC extracted strong arm comparator circuit netlist into the testbench. Finally, click "simulate", which will do the PEX simulations.} 130 -1830 0 0 0.4 0.4 {}
N 1160 -290 1160 -270 {
lab=GND}
N 590 -290 590 -270 {
lab=GND}
N 140 -290 140 -270 {
lab=GND}
N 440 -290 440 -270 {
lab=GND}
N 440 -360 440 -350 {
lab=Vcm}
N 440 -470 440 -360 {
lab=Vcm}
N 440 -510 440 -490 {
lab=Vcm}
N 140 -530 140 -350 {
lab=Vclk_bar}
N 940 -470 990 -470 {
lab=Di_n}
N 940 -450 990 -450 {
lab=Di_p}
N 940 -530 1160 -530 {
lab=#net1}
N 940 -490 950 -490 {
lab=Vout_p}
N 940 -510 1200 -510 {
lab=Vout_n}
N 1190 -530 1190 -510 {
lab=Vout_n}
N 1190 -530 1440 -530 {
lab=Vout_n}
N 1440 -530 1440 -510 {
lab=Vout_n}
N 950 -490 1200 -490 {
lab=Vout_p}
N 1190 -490 1190 -470 {
lab=Vout_p}
N 1190 -470 1400 -470 {
lab=Vout_p}
N 1850 -490 1930 -490 {
lab=Q}
N 1850 -470 1930 -470 {
lab=Q_bar}
N 1870 -320 1870 -270 {
lab=GND}
N 1920 -320 1920 -270 {
lab=GND}
N 1870 -470 1870 -380 {
lab=Q_bar}
N 1920 -490 1920 -380 {
lab=Q}
N 1160 -670 1160 -650 {
lab=GND}
N 630 -670 630 -650 {
lab=GND}
N 140 -670 140 -650 {
lab=GND}
N 440 -670 440 -650 {
lab=GND}
N 440 -740 440 -730 {
lab=#net2}
N 440 -850 440 -740 {
lab=#net2}
N 440 -870 440 -850 {
lab=#net2}
N 140 -910 140 -730 {
lab=#net3}
N 940 -850 990 -850 {
lab=Di_n_mc}
N 940 -830 990 -830 {
lab=Di_p_mc}
N 1160 -910 1160 -730 {
lab=#net4}
N 940 -910 1160 -910 {
lab=#net4}
N 940 -870 950 -870 {
lab=Vout_p_mc}
N 940 -890 1200 -890 {
lab=Vout_n_mc}
N 950 -870 1200 -870 {
lab=Vout_p_mc}
N 560 -670 560 -650 {
lab=GND}
N 560 -780 560 -730 {
lab=Vsc}
N 1160 -1060 1160 -1040 {
lab=GND}
N 550 -1060 550 -1040 {
lab=GND}
N 140 -1060 140 -1040 {
lab=GND}
N 440 -1060 440 -1040 {
lab=GND}
N 440 -1130 440 -1120 {
lab=#net5}
N 580 -1260 640 -1260 {
lab=#net6}
N 440 -1240 440 -1130 {
lab=#net5}
N 440 -1280 640 -1280 {
lab=#net5}
N 440 -1280 440 -1260 {
lab=#net5}
N 140 -1300 140 -1120 {
lab=#net7}
N 940 -1240 990 -1240 {
lab=Di_n_ms}
N 940 -1220 990 -1220 {
lab=Di_p_ms}
N 1160 -1300 1160 -1120 {
lab=#net8}
N 940 -1300 1160 -1300 {
lab=#net8}
N 940 -1260 950 -1260 {
lab=Vout_p_ms}
N 940 -1280 1200 -1280 {
lab=Vout_n_ms}
N 950 -1260 1200 -1260 {
lab=Vout_p_ms}
N 560 -1260 580 -1260 {
lab=#net6}
N 440 -1260 470 -1260 {
lab=#net5}
N 530 -1260 560 -1260 {
lab=#net6}
N 560 -850 560 -780 {
lab=Vsc}
N 1940 -510 1960 -510 {
lab=GND}
N 1160 -360 1160 -350 {
lab=#net9}
N 1160 -530 1160 -420 {
lab=#net1}
N 1440 -510 1550 -510 {
lab=Vout_n}
N 1400 -470 1440 -470 {
lab=Vout_p}
N 1440 -490 1440 -470 {
lab=Vout_p}
N 1440 -490 1550 -490 {
lab=Vout_p}
N 440 -490 470 -490 {
lab=Vcm}
N 440 -510 540 -510 {
lab=Vcm}
N 530 -490 550 -490 {
lab=#net10}
N 540 -510 550 -510 {
lab=Vcm}
N 610 -490 640 -490 {
lab=#net10}
N 550 -510 640 -510 {
lab=Vcm}
N 550 -490 610 -490 {
lab=#net10}
N 1160 -1440 1160 -1420 {
lab=GND}
N 600 -1440 600 -1420 {
lab=GND}
N 140 -1440 140 -1420 {
lab=GND}
N 440 -1440 440 -1420 {
lab=GND}
N 440 -1510 440 -1500 {
lab=#net11}
N 440 -1620 440 -1510 {
lab=#net11}
N 440 -1660 440 -1640 {
lab=#net11}
N 140 -1680 140 -1500 {
lab=#net12}
N 940 -1620 990 -1620 {
lab=Di_n_kn}
N 940 -1600 990 -1600 {
lab=Di_p_kn}
N 1160 -1680 1160 -1500 {
lab=#net13}
N 940 -1680 1160 -1680 {
lab=#net13}
N 940 -1640 950 -1640 {
lab=Vout_p_kn}
N 940 -1660 1200 -1660 {
lab=Vout_n_kn}
N 950 -1640 1200 -1640 {
lab=Vout_p_kn}
N 440 -1640 470 -1640 {
lab=#net11}
N 610 -1660 640 -1660 {
lab=Vn_kn}
N 530 -1640 550 -1640 {
lab=#net14}
N 610 -1640 640 -1640 {
lab=Vp_kn}
N 530 -1660 550 -1660 {
lab=#net11}
N 440 -1660 470 -1660 {
lab=#net11}
N 470 -1660 530 -1660 {
lab=#net11}
N 440 -490 440 -470 {
lab=Vcm}
N 590 -470 590 -350 {
lab=Vclk}
N 560 -870 560 -850 {
lab=Vsc}
N 560 -870 640 -870 {
lab=Vsc}
N 440 -890 440 -870 {
lab=#net2}
N 440 -890 640 -890 {
lab=#net2}
N 630 -850 630 -730 {
lab=#net15}
N 630 -850 640 -850 {
lab=#net15}
N 140 -910 640 -910 {
lab=#net3}
N 940 -810 960 -810 {
lab=GND}
N 940 -430 960 -430 {
lab=GND}
N 940 -1200 960 -1200 {
lab=GND}
N 440 -1260 440 -1240 {
lab=#net5}
N 550 -1240 550 -1120 {
lab=#net16}
N 550 -1240 640 -1240 {
lab=#net16}
N 140 -1300 640 -1300 {
lab=#net7}
N 590 -470 640 -470 {
lab=Vclk}
N 1850 -510 1880 -510 {
lab=#net17}
N 140 -530 640 -530 {
lab=Vclk_bar}
N 440 -1640 440 -1620 {
lab=#net11}
N 600 -1620 600 -1500 {
lab=#net18}
N 600 -1620 640 -1620 {
lab=#net18}
N 140 -1680 640 -1680 {
lab=#net12}
N 940 -1580 960 -1580 {
lab=GND}
C {double_tail_comp.sym} 790 -480 0 0 {name=x1}
C {devices/gnd.sym} 1160 -270 0 0 {name=l1 lab=GND}
C {devices/vsource.sym} 1160 -390 0 0 {name=VDD value=VDD}
C {devices/vsource.sym} 590 -320 0 0 {name=Vclk value="PULSE(0 VDD Tdelay Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 590 -270 0 0 {name=l2 lab=GND}
C {devices/vsource.sym} 140 -320 0 0 {name=Vclk_bar value="PULSE(0 VDD Tdelay_bar Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 140 -270 0 0 {name=Vclk_bar1 lab=GND
value="PULSE(3.3 0 0 10p 10p 100ns 400ns 0)"}
C {devices/vsource.sym} 440 -320 0 0 {name=Vcm value="dc Vcm"}
C {devices/gnd.sym} 440 -270 0 0 {name=l3 lab=GND}
C {devices/vsource.sym} 500 -490 1 0 {name=Vdiff value="dc Vin"}
C {devices/lab_pin.sym} 140 -390 0 0 {name=p2 sig_type=std_logic lab=Vclk_bar}
C {devices/lab_pin.sym} 590 -390 0 0 {name=p3 sig_type=std_logic lab=Vclk}
C {devices/lab_pin.sym} 440 -390 0 0 {name=p17 sig_type=std_logic lab=Vcm}
C {devices/opin.sym} 990 -470 0 0 {name=p5 lab=Di_n}
C {devices/opin.sym} 990 -450 0 0 {name=p4 lab=Di_p}
C {devices/opin.sym} 1200 -510 0 0 {name=p8 lab=Vout_n}
C {devices/opin.sym} 1200 -490 0 0 {name=p1 lab=Vout_p}
C {devices/opin.sym} 1930 -490 0 0 {name=p6 lab=Q}
C {devices/opin.sym} 1930 -470 0 0 {name=p7 lab=Q_bar}
C {devices/capa.sym} 1870 -350 0 0 {name=C2
m=1
value=10f
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1870 -270 0 0 {name=l7 lab=GND}
C {devices/capa.sym} 1920 -350 0 0 {name=C3
m=1
value=10f
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1920 -270 0 0 {name=l9 lab=GND}
C {sky130_fd_pr/corner.sym} 2290 -1680 0 0 {name=CORNER only_toplevel=false corner=tt}
C {RS_latch.sym} 1700 -490 0 0 {name=x2}
C {double_tail_comp.sym} 790 -860 0 0 {name=x3}
C {devices/gnd.sym} 1160 -650 0 0 {name=l4 lab=GND}
C {devices/vsource.sym} 1160 -700 0 0 {name=VDD2 value=VDD}
C {devices/vsource.sym} 630 -700 0 0 {name=Vclk2 value="PULSE(0 VDD 0 Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 630 -650 0 0 {name=l5 lab=GND}
C {devices/vsource.sym} 140 -700 0 0 {name=Vclk_bar2 value="PULSE(0 VDD Tclk_pk Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 140 -650 0 0 {name=Vclk_bar4 lab=GND
value="PULSE(3.3 0 0 10p 10p 100ns 400ns 0)"}
C {devices/vsource.sym} 440 -700 0 0 {name=Vcm2 value="dc Vcm"}
C {devices/gnd.sym} 440 -650 0 0 {name=l6 lab=GND}
C {devices/opin.sym} 990 -850 0 0 {name=p12 lab=Di_n_mc}
C {devices/opin.sym} 990 -830 0 0 {name=p13 lab=Di_p_mc}
C {devices/opin.sym} 1200 -890 0 0 {name=p14 lab=Vout_n_mc}
C {devices/opin.sym} 1200 -870 0 0 {name=p15 lab=Vout_p_mc}
C {devices/vsource.sym} 560 -700 0 0 {name=ASRC1 value=3 
format="@name \\\\%v([ @@p ]) filesrc"
device_model="
.model filesrc filesource (file=\\"staircase_voltage.txt\\" amploffset=[Vcm] amplscale=[1] timeoffset=0 timescale=1 timerelative=false amplstep=false)
"}
C {devices/gnd.sym} 560 -650 0 0 {name=l11 lab=GND}
C {devices/lab_pin.sym} 560 -780 0 1 {name=p19 sig_type=std_logic lab=Vsc}
C {double_tail_comp.sym} 790 -1250 0 0 {name=x4}
C {devices/gnd.sym} 1160 -1040 0 0 {name=l8 lab=GND}
C {devices/vsource.sym} 1160 -1090 0 0 {name=VDD3 value=VDD}
C {devices/vsource.sym} 550 -1090 0 0 {name=Vclk3 value="PULSE(0 VDD Tdelay Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 550 -1040 0 0 {name=l10 lab=GND}
C {devices/vsource.sym} 140 -1090 0 0 {name=Vclk_bar3 value="PULSE(0 VDD Tdelay_bar Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 140 -1040 0 0 {name=Vclk_bar6 lab=GND
value="PULSE(3.3 0 0 10p 10p 100ns 400ns 0)"}
C {devices/vsource.sym} 440 -1090 0 0 {name=Vcm3 value="dc Vcm"}
C {devices/gnd.sym} 440 -1040 0 0 {name=l12 lab=GND}
C {devices/opin.sym} 990 -1240 0 0 {name=p9 lab=Di_n_ms}
C {devices/opin.sym} 990 -1220 0 0 {name=p10 lab=Di_p_ms}
C {devices/opin.sym} 1200 -1280 0 0 {name=p11 lab=Vout_n_ms}
C {devices/opin.sym} 1200 -1260 0 0 {name=p16 lab=Vout_p_ms}
C {devices/vsource.sym} 500 -1260 1 0 {name=Vdiff2 value="dc Vin_min"}
C {devices/gnd.sym} 1960 -510 3 0 {name=l13 lab=GND}
C {devices/vsource.sym} 1910 -510 3 0 {name=VDD_latch value=VDD}
C {devices/res.sym} 1160 -320 0 0 {name=Rdummy
value=1
footprint=1206
device=resistor
m=1}
C {double_tail_comp.sym} 790 -1630 0 0 {name=x5}
C {devices/gnd.sym} 1160 -1420 0 0 {name=l14 lab=GND}
C {devices/vsource.sym} 1160 -1470 0 0 {name=VDD4 value=VDD}
C {devices/vsource.sym} 600 -1470 0 0 {name=Vclk4 value="PULSE(0 VDD Tdelay Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 600 -1420 0 0 {name=l15 lab=GND}
C {devices/vsource.sym} 140 -1470 0 0 {name=Vclk_bar5 value="PULSE(0 VDD Tdelay_bar Tr Tf Tclk_pk Tclk 0)"}
C {devices/gnd.sym} 140 -1420 0 0 {name=Vclk_bar7 lab=GND
value="PULSE(3.3 0 0 10p 10p 100ns 400ns 0)"}
C {devices/vsource.sym} 440 -1470 0 0 {name=Vcm4 value="dc Vcm"}
C {devices/gnd.sym} 440 -1420 0 0 {name=l16 lab=GND}
C {devices/opin.sym} 990 -1620 0 0 {name=p18 lab=Di_n_kn}
C {devices/opin.sym} 990 -1600 0 0 {name=p20 lab=Di_p_kn}
C {devices/opin.sym} 1200 -1660 0 0 {name=p21 lab=Vout_n_kn}
C {devices/opin.sym} 1200 -1640 0 0 {name=p22 lab=Vout_p_kn}
C {devices/vsource.sym} 500 -1640 1 0 {name=Vdiff4 value="dc Vin"}
C {devices/res.sym} 580 -1660 3 0 {name=Rdummyn
value=8k
footprint=1206
device=resistor
m=1}
C {devices/res.sym} 580 -1640 3 0 {name=Rdummyp
value=8k
footprint=1206
device=resistor
m=1}
C {devices/lab_pin.sym} 620 -1660 3 1 {name=p23 sig_type=std_logic lab=Vn_kn}
C {devices/lab_pin.sym} 620 -1640 1 1 {name=p24 sig_type=std_logic lab=Vp_kn}
C {devices/gnd.sym} 960 -810 3 0 {name=l17 lab=GND}
C {devices/gnd.sym} 960 -430 3 0 {name=l18 lab=GND}
C {devices/gnd.sym} 960 -1200 3 0 {name=l19 lab=GND}
C {devices/gnd.sym} 960 -1580 3 0 {name=l20 lab=GND}
C {devices/code_shown.sym} 2290 -1380 0 0 {name=s2 only_toplevel=false 
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
.include /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/netgen/double_tail/TCL/double_tail_comparator_pex.spice
* analyses
.include /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/xschem/simulations/double_tail_comp_pex_tb_analyses.spice
* stimulus variables
.include /autofs/fs1.ece/fs1.eecg.tcc/lizongh2/sky130_comparator/xschem/simulations/double_tail_comp_pex_tb_vars.spice

.endc
"}
