v {xschem version=3.4.1 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
N 350 -350 350 -270 {
lab=#net1}
N 240 -70 240 -50 {
lab=GND}
N 240 -50 450 -50 {
lab=GND}
N 450 -70 450 -50 {
lab=GND}
N 350 -50 350 -30 {
lab=GND}
N 450 -100 470 -100 {
lab=GND}
N 470 -100 470 -50 {
lab=GND}
N 450 -50 470 -50 {
lab=GND}
N 240 -100 260 -100 {
lab=GND}
N 260 -100 260 -50 {
lab=GND}
N 240 -150 240 -130 {
lab=out}
N 240 -150 450 -150 {
lab=out}
N 450 -150 450 -130 {
lab=out}
N 350 -210 350 -150 {
lab=out}
N 350 -380 390 -380 {
lab=VDD}
N 390 -380 390 -240 {
lab=VDD}
N 350 -240 390 -240 {
lab=VDD}
N 350 -450 350 -410 {
lab=VDD}
N 350 -430 390 -430 {
lab=VDD}
N 390 -430 390 -380 {
lab=VDD}
N 170 -100 200 -100 {
lab=B}
N 170 -240 170 -100 {
lab=B}
N 170 -240 310 -240 {
lab=B}
N 410 -100 410 -60 {
lab=A}
N 100 -60 410 -60 {
lab=A}
N 100 -380 100 -60 {
lab=A}
N 100 -380 310 -380 {
lab=A}
N 70 -380 100 -380 {
lab=A}
N 70 -240 170 -240 {
lab=B}
N 350 -190 440 -190 {
lab=out}
C {sky130_fd_pr/nfet_01v8.sym} 220 -100 0 0 {name=M1
L=0.18
W=0.42
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
C {sky130_fd_pr/nfet_01v8.sym} 430 -100 0 0 {name=M2
L=0.18
W=0.42
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
C {sky130_fd_pr/pfet_01v8.sym} 330 -240 0 0 {name=M3
L=0.18
W=0.84
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
C {sky130_fd_pr/pfet_01v8.sym} 330 -380 0 0 {name=M4
L=0.18
W=0.84
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
C {devices/gnd.sym} 350 -30 0 0 {name=l1 lab=GND}
C {devices/iopin.sym} 350 -450 0 0 {name=p3 lab=VDD}
C {devices/ipin.sym} 70 -380 0 0 {name=p1 lab=A}
C {devices/ipin.sym} 70 -240 0 0 {name=p2 lab=B}
C {devices/opin.sym} 440 -190 0 0 {name=p5 lab=out}
