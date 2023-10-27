v {xschem version=3.4.1 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
N 380 -30 380 -10 {
lab=GND}
N 380 -60 400 -60 {
lab=GND}
N 400 -60 400 -30 {
lab=GND}
N 250 -160 510 -160 {
lab=GND}
N 400 -160 400 -60 {
lab=GND}
N 250 -130 250 -110 {
lab=#net1}
N 250 -110 510 -110 {
lab=#net1}
N 510 -130 510 -110 {
lab=#net1}
N 380 -110 380 -90 {
lab=#net1}
N 510 -280 510 -190 {
lab=Di_p}
N 250 -280 250 -190 {
lab=Di_n}
N 250 -370 250 -340 {
lab=VDD}
N 250 -370 510 -370 {
lab=VDD}
N 510 -370 510 -340 {
lab=VDD}
N 310 -60 340 -60 {
lab=Vclk}
N 180 -160 210 -160 {
lab=Vin_p}
N 550 -160 580 -160 {
lab=Vin_n}
N 510 -310 530 -310 {
lab=VDD}
N 530 -370 530 -310 {
lab=VDD}
N 510 -370 530 -370 {
lab=VDD}
N 230 -310 250 -310 {
lab=VDD}
N 230 -370 230 -310 {
lab=VDD}
N 230 -370 250 -370 {
lab=VDD}
N 290 -310 470 -310 {
lab=Vclk}
N 130 -560 620 -560 {
lab=GND}
N 380 -560 380 -540 {
lab=GND}
N 230 -590 250 -590 {
lab=GND}
N 230 -590 230 -560 {
lab=GND}
N 130 -590 150 -590 {
lab=GND}
N 150 -590 150 -560 {
lab=GND}
N 500 -590 530 -590 {
lab=GND}
N 530 -590 530 -560 {
lab=GND}
N 590 -590 620 -590 {
lab=GND}
N 590 -590 590 -560 {
lab=GND}
N 60 -240 250 -240 {
lab=Di_n}
N 60 -590 60 -240 {
lab=Di_n}
N 60 -590 90 -590 {
lab=Di_n}
N 660 -590 690 -590 {
lab=Di_p}
N 690 -590 690 -240 {
lab=Di_p}
N 510 -240 690 -240 {
lab=Di_p}
N 250 -750 250 -620 {
lab=Vout_p}
N 130 -650 130 -620 {
lab=Vout_p}
N 130 -650 250 -650 {
lab=Vout_p}
N 500 -750 500 -620 {
lab=Vout_n}
N 500 -650 620 -650 {
lab=Vout_n}
N 620 -650 620 -620 {
lab=Vout_n}
N 290 -590 320 -590 {
lab=Vout_n}
N 320 -780 320 -590 {
lab=Vout_n}
N 290 -780 320 -780 {
lab=Vout_n}
N 430 -590 460 -590 {
lab=Vout_p}
N 430 -780 430 -590 {
lab=Vout_p}
N 430 -780 460 -780 {
lab=Vout_p}
N 250 -680 430 -680 {
lab=Vout_p}
N 320 -710 500 -710 {
lab=Vout_n}
N 500 -710 530 -710 {
lab=Vout_n}
N 210 -680 250 -680 {
lab=Vout_p}
N 250 -840 250 -810 {
lab=#net2}
N 250 -840 500 -840 {
lab=#net2}
N 500 -840 500 -810 {
lab=#net2}
N 380 -870 380 -840 {
lab=#net2}
N 310 -900 340 -900 {
lab=Vclk_bar}
N 380 -900 410 -900 {
lab=VDD}
N 410 -960 410 -900 {
lab=VDD}
N 380 -960 380 -930 {
lab=VDD}
N 180 -780 250 -780 {
lab=VDD}
N 180 -960 180 -780 {
lab=VDD}
N 180 -960 560 -960 {
lab=VDD}
N 500 -780 590 -780 {
lab=VDD}
N 590 -960 590 -780 {
lab=VDD}
N 560 -960 590 -960 {
lab=VDD}
N 380 -1020 380 -960 {
lab=VDD}
N 380 -10 380 -0 {
lab=GND}
N 380 60 380 70 {
lab=GND}
N 400 -30 400 60 {
lab=GND}
N 380 60 400 60 {
lab=GND}
N 380 0 380 60 {
lab=GND}
C {sky130_fd_pr/nfet_01v8.sym} 230 -160 0 0 {name=M1
L=0.18
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
C {sky130_fd_pr/nfet_01v8.sym} 530 -160 0 1 {name=M2
L=0.18
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
C {sky130_fd_pr/pfet_01v8.sym} 270 -310 0 1 {name=M3
L=0.18
W=W_M3
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
C {sky130_fd_pr/pfet_01v8.sym} 490 -310 0 0 {name=M4
L=0.18
W=W_M4
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
C {sky130_fd_pr/nfet_01v8.sym} 360 -60 0 0 {name=M5
L=0.18
W=W_M5
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
C {devices/gnd.sym} 380 70 0 0 {name=l2 lab=GND}
C {devices/iopin.sym} 380 -370 3 0 {name=p2 lab=VDD}
C {devices/ipin.sym} 380 -310 3 0 {name=p6 lab=Vclk}
C {devices/ipin.sym} 310 -60 0 0 {name=p5 lab=Vclk}
C {devices/ipin.sym} 180 -160 0 0 {name=p3 lab=Vin_p}
C {devices/ipin.sym} 580 -160 2 0 {name=p4 lab=Vin_n}
C {sky130_fd_pr/nfet_01v8.sym} 110 -590 0 0 {name=M6
L=0.18
W=W_M6
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
C {sky130_fd_pr/nfet_01v8.sym} 270 -590 0 1 {name=M7
L=0.18
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
C {sky130_fd_pr/nfet_01v8.sym} 480 -590 0 0 {name=M8
L=0.18
W=W_M8
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
C {sky130_fd_pr/nfet_01v8.sym} 640 -590 0 1 {name=M9
L=0.18
W=W_M9
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
C {devices/gnd.sym} 380 -540 0 0 {name=l1 lab=GND}
C {devices/opin.sym} 60 -410 0 1 {name=p12 lab=Di_n}
C {devices/opin.sym} 690 -410 0 0 {name=p10 lab=Di_p}
C {sky130_fd_pr/pfet_01v8.sym} 270 -780 0 1 {name=M10
L=0.18
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
C {sky130_fd_pr/pfet_01v8.sym} 480 -780 0 0 {name=M11
L=0.18
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
C {devices/opin.sym} 530 -710 0 0 {name=p8 lab=Vout_n}
C {devices/opin.sym} 210 -680 0 1 {name=p9 lab=Vout_p}
C {sky130_fd_pr/pfet_01v8.sym} 360 -900 0 0 {name=M12
L=0.18
W=W_M12
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
C {devices/ipin.sym} 310 -900 2 1 {name=p7 lab=Vclk_bar}
C {devices/iopin.sym} 380 -1020 3 0 {name=p1 lab=VDD}
