v {xschem version=3.4.5 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
N 590 -290 850 -290 {
lab=VSS}
N 590 -260 590 -240 {
lab=#net1}
N 590 -240 850 -240 {
lab=#net1}
N 850 -260 850 -240 {
lab=#net1}
N 720 -240 720 -220 {
lab=#net1}
N 520 -290 550 -290 {
lab=Vin_p}
N 890 -290 920 -290 {
lab=Vin_n}
N 590 -440 590 -320 {
lab=Di_n}
N 850 -440 850 -320 {
lab=Di_p}
N 590 -640 590 -500 {
lab=Vout_n}
N 850 -640 850 -500 {
lab=Vout_p}
N 630 -470 670 -470 {
lab=Vout_p}
N 590 -530 670 -530 {
lab=Vout_n}
N 590 -610 670 -610 {
lab=Vout_n}
N 630 -670 670 -670 {
lab=Vout_p}
N 420 -640 590 -640 {
lab=Vout_n}
N 850 -640 1020 -640 {
lab=Vout_p}
N 420 -700 1020 -700 {
lab=VDD}
N 420 -670 590 -670 {
lab=VDD}
N 500 -700 500 -670 {
lab=VDD}
N 850 -670 1020 -670 {
lab=VDD}
N 940 -700 940 -670 {
lab=VDD}
N 720 -190 740 -190 {
lab=VSS}
N 740 -190 740 -160 {
lab=VSS}
N 650 -190 680 -190 {
lab=CLK}
N 260 -640 260 -390 {
lab=Di_n}
N 260 -390 590 -390 {
lab=Di_n}
N 260 -670 280 -670 {
lab=VDD}
N 280 -700 280 -670 {
lab=VDD}
N 260 -700 420 -700 {
lab=VDD}
N 1020 -700 1160 -700 {
lab=VDD}
N 850 -390 1160 -390 {
lab=Di_p}
N 1160 -640 1160 -390 {
lab=Di_p}
N 720 -730 720 -700 {
lab=VDD}
N 1130 -670 1160 -670 {
lab=VDD}
N 1130 -700 1130 -670 {
lab=VDD}
N 380 -670 380 -620 {
lab=CLK}
N 380 -620 380 -610 {
lab=CLK}
N 220 -610 380 -610 {
lab=CLK}
N 130 -190 650 -190 {
lab=CLK}
N 770 -610 850 -610 {
lab=Vout_p}
N 670 -670 770 -610 {
lab=Vout_p}
N 770 -670 810 -670 {
lab=Vout_n}
N 670 -610 770 -670 {
lab=Vout_n}
N 670 -470 770 -530 {
lab=Vout_p}
N 770 -530 850 -530 {
lab=Vout_p}
N 770 -470 810 -470 {
lab=Vout_n}
N 670 -530 770 -470 {
lab=Vout_n}
N 540 -570 590 -570 {
lab=Vout_n}
N 850 -570 920 -570 {
lab=Vout_p}
N 740 -290 740 -190 {
lab=VSS}
N 220 -670 220 -610 {
lab=CLK}
N 1060 -670 1060 -610 {
lab=CLK}
N 1200 -670 1200 -610 {
lab=CLK}
N 720 -160 740 -160 {
lab=VSS}
N 740 -160 740 -100 {
lab=VSS}
N 550 -470 590 -470 {
lab=VSS}
N 550 -470 550 -340 {
lab=VSS}
N 550 -340 890 -340 {
lab=VSS}
N 890 -470 890 -340 {
lab=VSS}
N 850 -470 890 -470 {
lab=VSS}
N 740 -340 740 -290 {
lab=VSS}
N 220 -610 220 -190 {
lab=CLK}
N 1060 -610 1200 -610 {
lab=CLK}
N 560 -190 560 -130 {
lab=CLK}
N 560 -130 1060 -130 {
lab=CLK}
N 1060 -610 1060 -130 {
lab=CLK}
N 530 -360 590 -360 {
lab=Di_n}
N 520 -360 530 -360 {
lab=Di_n}
N 850 -360 920 -360 {
lab=Di_p}
C {sky130_fd_pr/nfet_01v8.sym} 570 -290 0 0 {name=M1
L=0.15
W=W_M1
nf=1 
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/nfet_01v8.sym} 870 -290 0 1 {name=M2
L=0.15
W=W_M2
nf=1 
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {devices/ipin.sym} 520 -290 0 0 {name=p3 lab=Vin_p}
C {devices/ipin.sym} 920 -290 2 0 {name=p4 lab=Vin_n}
C {sky130_fd_pr/nfet_01v8.sym} 610 -470 0 1 {name=M3
L=0.15
W=W_M3
nf=1
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/nfet_01v8.sym} 830 -470 0 0 {name=M4
L=0.15
W=W_M4
nf=1 
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/pfet_01v8.sym} 610 -670 0 1 {name=M5
L=0.15
W=W_M5
nf=1
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/pfet_01v8.sym} 830 -670 0 0 {name=M6
L=0.15
W=W_M6
nf=1
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/pfet_01v8.sym} 1040 -670 0 1 {name=M9
L=0.15
W=W_M9
nf=1
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/pfet_01v8.sym} 400 -670 0 0 {name=M8
L=0.15
W=W_M8
nf=1
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/nfet_01v8.sym} 700 -190 0 0 {name=M7
L=0.15
W=W_M7
nf=1 
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {devices/ipin.sym} 130 -190 0 0 {name=p5 lab=CLK}
C {sky130_fd_pr/pfet_01v8.sym} 240 -670 0 0 {name=M10
L=0.15
W=W_M10
nf=1
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/pfet_01v8.sym} 1180 -670 0 1 {name=M11
L=0.15
W=W_M11
nf=1
mult=1
ad="'int((nf+1)/2) * W/nf * 0.29'" 
pd="'2*int((nf+1)/2) * (W/nf + 0.29)'"
as="'int((nf+2)/2) * W/nf * 0.29'" 
ps="'2*int((nf+2)/2) * (W/nf + 0.29)'"
nrd="'0.29 / W'" nrs="'0.29 / W'"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {devices/iopin.sym} 720 -730 3 0 {name=p1 lab=VDD}
C {devices/opin.sym} 540 -570 0 1 {name=p9 lab=Vout_n}
C {devices/opin.sym} 920 -570 0 0 {name=p8 lab=Vout_p}
C {devices/iopin.sym} 740 -100 1 0 {name=p10 lab=VSS}
C {devices/opin.sym} 520 -360 0 1 {name=p6 lab=Di_n}
C {devices/opin.sym} 920 -360 2 1 {name=p7 lab=Di_p}
