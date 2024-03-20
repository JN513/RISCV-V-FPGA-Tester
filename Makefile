# read_verilog Risco-5/src/core/*.v;
# read_verilog riscv-steel/hardware/core/rvsteel_core.v;

all: ./build/out.bit

./build/out.bit: ./build/out.config
	ecppack --compress --input ./build/out.config  --bit ./build/out.bit

./build/out.config: ./build/out.json
	nextpnr-ecp5 --json ./build/out.json --write ./build/out_pnr.json --45k \
		--lpf pinout.lpf --textcfg ./build/out.config --package CABGA381 \
		--speed 6 --lpf-allow-unconstrained

./build/out.json: pinout.lpf buildFolder
	yosys -p " \
		read_verilog Risco-5/src/core/*.v; \
		read_verilog src/*.v; \
		synth_ecp5 -json ./build/out.json -abc9 \
	"

buildFolder:
	mkdir -p build

clean:
	rm -rf build

flash:
	openFPGALoader -b colorlight-i9 ./build/out.bit

run_all: ./build/out.bit flash