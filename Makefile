VIVADO  ?= vivado
PROJ    := one_stage_cpu
DEVICE  := xc7k70tfbv676-1

# OpenLane (classic) Docker image
OL_IMG := efabless/openlane:latest

# RTL source list (order matters: package first)
RTL_SRC := rtl/isa_defs.sv rtl/alu.sv rtl/regfile.sv \
           rtl/control_unit.sv rtl/instruction_memory.sv \
           rtl/data_memory.sv rtl/cpu_top.sv

.PHONY: all project sim synth impl bitstream gui reports \
        yosys-check sv2v gds-setup gds gds-view gds-clean \
        iverilog-sim lint clean

# ──────────────────────────────────────────────
#  FPGA flow  (Vivado)
# ──────────────────────────────────────────────

## Full FPGA build: synthesis -> implementation -> bitstream
all: bitstream

## Create Vivado project in batch mode
project: | reports
	$(VIVADO) -mode batch -source scripts/create_project.tcl -notrace

## Run behavioural simulation (XSim)
sim:
	$(VIVADO) -mode batch -source scripts/run_sim.tcl -notrace

## Run synthesis
synth: | reports
	$(VIVADO) -mode batch -source scripts/run_synth.tcl -notrace

## Run implementation (place & route)
impl: | reports
	$(VIVADO) -mode batch -source scripts/run_impl.tcl -notrace

## Generate bitstream
bitstream: | reports
	$(VIVADO) -mode batch -source scripts/run_bitstream.tcl -notrace

## Open the project in Vivado GUI
gui:
	$(VIVADO) $(PROJ).xpr &

## Create reports directory
reports:
	mkdir -p reports

# ──────────────────────────────────────────────
#  ASIC flow  (sv2v + OpenLane classic / Sky130)
# ──────────────────────────────────────────────

## Convert SystemVerilog to plain Verilog (sv2v)
build/cpu_top.v: $(RTL_SRC)
	mkdir -p build
	sv2v $(RTL_SRC) > $@

sv2v: build/cpu_top.v

## Copy converted Verilog into OpenLane design directory
asic/src/cpu_top.v: build/cpu_top.v
	cp $< $@

## Quick local synthesis sanity-check with Yosys (small memories)
yosys-check: build/cpu_top.v
	yosys -p 'read_verilog build/cpu_top.v; chparam -set IMEM_DEPTH 16 cpu_top; chparam -set DMEM_DEPTH 16 cpu_top; synth -top cpu_top -flatten; stat'

## Pull OpenLane Docker image and fetch Sky130 PDK (one-time)
gds-setup:
	docker pull $(OL_IMG)
	docker run --rm -v openlane_pdk:/root/.volare $(OL_IMG) \
	  volare fetch --pdk sky130 bdc9412b3e468c102d01b7cf6337be06ec6e9c9a

## Run full RTL-to-GDS flow via OpenLane classic
gds: asic/src/cpu_top.v
	docker run --rm \
	  -v openlane_pdk:/root/.volare \
	  -v $(CURDIR)/asic:/design \
	  $(OL_IMG) \
	  flow.tcl -design /design -tag run

## Open final GDS in KLayout
gds-view:
	@gds=$$(find asic/runs -path "*/results/final/gds/*.gds" 2>/dev/null | head -1); \
	if [ -z "$$gds" ]; then echo "No GDS found. Run 'make gds' first."; exit 1; fi; \
	echo "Opening $$gds"; \
	klayout "$$gds" &

# ──────────────────────────────────────────────
#  Open-source simulation & lint
# ──────────────────────────────────────────────

## Compile & run with Icarus Verilog
iverilog-sim: build/cpu_top.v
	iverilog -g2012 -s top_tb -o build/cpu_tb.vvp \
	  build/cpu_top.v tb/top_tb.sv
	vvp build/cpu_tb.vvp

## Lint with Verilator
lint:
	verilator --lint-only -Wall --top-module cpu_top $(RTL_SRC)

# ──────────────────────────────────────────────
#  Cleanup
# ──────────────────────────────────────────────

## Remove ASIC outputs
gds-clean:
	rm -rf asic/runs asic/src/cpu_top.v

## Remove all generated files
clean: gds-clean
	rm -rf $(PROJ).xpr $(PROJ).runs $(PROJ).cache $(PROJ).srcs \
	       $(PROJ).sim $(PROJ).hw $(PROJ).ip_user_files \
	       .Xil *.jou *.log *.str xsim.dir work reports build
