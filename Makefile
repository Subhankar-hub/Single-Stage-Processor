# ══════════════════════════════════════════════════
#  Single-Stage RISC-V Processor — ASIC Makefile
# ══════════════════════════════════════════════════
#
#  Usage:
#    make gds                        # full RTL-to-GDS (sky130A default)
#    make gds PDK=gf180mcuD          # full flow with GF180
#    make synth PDK=sky130A          # synthesis only
#    make floorplan                  # up to floorplan + PDN
#    make help                       # show all targets
#
#  Valid PDK values:
#    sky130A  sky130B
#    gf180mcuA  gf180mcuB  gf180mcuC  gf180mcuD

# ── User-configurable variables ──────────────────
PDK        ?= sky130A
PDK_ROOT   ?= /home/smith/asic/pdks
TAG        ?= run

# ── Nix / OpenLane invocation ───────────────────────
OL2_FLAKE  ?= /home/smith/Desktop/project/openlane2
NIX_FLAGS  ?= --extra-experimental-features "nix-command flakes"

# In local development, use Nix by default. In CI, fall back to a
# plain OpenLane binary unless NIX_RUN is explicitly provided.
ifeq ($(origin NIX_RUN), undefined)
  ifeq ($(CI),true)
    NIX_RUN :=
  else
    NIX_RUN := nix $(NIX_FLAGS) develop $(OL2_FLAKE) --command
  endif
endif

OPENLANE_BIN ?= openlane
OL_RUN       := $(NIX_RUN) $(OPENLANE_BIN)

# ── Project paths ────────────────────────────────
DESIGN_DIR := asic
CONFIG     := $(DESIGN_DIR)/config.json

# ── RTL sources (order matters: package first) ───
RTL_SRC := rtl/isa_defs_pkg.sv rtl/alu.sv rtl/regfile.sv \
           rtl/control_unit.sv rtl/instruction_memory.sv \
           rtl/data_memory.sv rtl/cpu_top.sv

# ── OpenLane flags ───────────────────────────────
OL_FLAGS := --pdk-root $(PDK_ROOT) -p $(PDK) --run-tag $(TAG)

.PHONY: all help sv2v synth floorplan placement cts routing gds \
        gds-view yosys-check iverilog-sim lint \
        report-synth report-floorplan report-cts report-routing report-timing \
        clean gds-clean

all: gds

# ══════════════════════════════════════════════════
#  Help
# ══════════════════════════════════════════════════

help:
	@echo ""
	@echo "  ASIC flow targets (OpenLane 2 + local PDKs)"
	@echo "  ────────────────────────────────────────────"
	@echo "  Current PDK : $(PDK)  (override with PDK=<variant>)"
	@echo "  PDK_ROOT    : $(PDK_ROOT)"
	@echo "  Toolchain   : nix develop $(OL2_FLAKE)"
	@echo ""
	@echo "  Preparation:"
	@echo "    sv2v            Convert SystemVerilog to Verilog (sv2v)"
	@echo "    yosys-check     Quick Yosys synthesis sanity check"
	@echo "    lint            Lint with Verilator"
	@echo ""
	@echo "  ASIC flow (cumulative — each target runs all prior stages):"
	@echo "    synth           Synthesis + STA pre-PNR"
	@echo "    floorplan       Synthesis → Floorplan + PDN generation"
	@echo "    placement       Synthesis → Detailed placement"
	@echo "    cts             Synthesis → Clock tree synthesis"
	@echo "    routing         Synthesis → Detailed routing"
	@echo "    gds             Full RTL-to-GDS (default target)"
	@echo ""
	@echo "  Viewing & reports:"
	@echo "    gds-view        Open final GDS in KLayout"
	@echo "    report-synth    Show synthesis timing report"
	@echo "    report-cts      Show CTS timing report"
	@echo "    report-routing  Show routing timing report"
	@echo "    report-timing   Show signoff STA report"
	@echo ""
	@echo "  Simulation (open-source):"
	@echo "    iverilog-sim     Compile & run with Icarus Verilog"
	@echo ""
	@echo "  Cleanup:"
	@echo "    gds-clean       Remove ASIC run outputs"
	@echo "    clean           Remove all generated files"
	@echo ""
	@echo "  Examples:"
	@echo "    make gds PDK=sky130A"
	@echo "    make synth PDK=gf180mcuD"
	@echo "    make cts PDK=sky130A TAG=experiment1"
	@echo ""

# ══════════════════════════════════════════════════
#  Preparation
# ══════════════════════════════════════════════════

build/cpu_top.v: $(RTL_SRC)
	mkdir -p build
	sv2v $(RTL_SRC) > $@

sv2v: build/cpu_top.v

$(DESIGN_DIR)/src/cpu_top.v: build/cpu_top.v
	mkdir -p $(DESIGN_DIR)/src
	cp $< $@

yosys-check: build/cpu_top.v
	yosys -p 'read_verilog build/cpu_top.v; \
	  chparam -set IMEM_DEPTH 16 cpu_top; \
	  chparam -set DMEM_DEPTH 16 cpu_top; \
	  synth -top cpu_top -flatten; stat'

# ══════════════════════════════════════════════════
#  ASIC flow stages (OpenLane 2 — Classic flow)
# ══════════════════════════════════════════════════

synth: $(DESIGN_DIR)/src/cpu_top.v
	@echo "═══ Synthesis (PDK=$(PDK)) ═══"
	$(OL_RUN) $(OL_FLAGS) --to OpenROAD.STAPrePNR $(CONFIG)

floorplan: $(DESIGN_DIR)/src/cpu_top.v
	@echo "═══ Floorplan + PDN (PDK=$(PDK)) ═══"
	$(OL_RUN) $(OL_FLAGS) --to OpenROAD.GeneratePDN $(CONFIG)

placement: $(DESIGN_DIR)/src/cpu_top.v
	@echo "═══ Placement (PDK=$(PDK)) ═══"
	$(OL_RUN) $(OL_FLAGS) --to OpenROAD.DetailedPlacement $(CONFIG)

cts: $(DESIGN_DIR)/src/cpu_top.v
	@echo "═══ Clock Tree Synthesis (PDK=$(PDK)) ═══"
	$(OL_RUN) $(OL_FLAGS) --to OpenROAD.ResizerTimingPostCTS $(CONFIG)

routing: $(DESIGN_DIR)/src/cpu_top.v
	@echo "═══ Routing (PDK=$(PDK)) ═══"
	$(OL_RUN) $(OL_FLAGS) --to OpenROAD.DetailedRouting $(CONFIG)

gds: $(DESIGN_DIR)/src/cpu_top.v
	@echo "═══ Full RTL-to-GDS (PDK=$(PDK)) ═══"
	$(OL_RUN) $(OL_FLAGS) $(CONFIG)

# ══════════════════════════════════════════════════
#  Viewing & reports
# ══════════════════════════════════════════════════

gds-view:
	@gds=$$(find $(DESIGN_DIR)/runs/$(TAG) -path "*/results/final/gds/*.gds" 2>/dev/null | head -1); \
	if [ -z "$$gds" ]; then \
		echo "No GDS found for tag '$(TAG)'. Run 'make gds' first."; exit 1; \
	fi; \
	echo "Opening $$gds in KLayout"; \
	klayout "$$gds" &

report-synth:
	@find $(DESIGN_DIR)/runs/$(TAG)/reports/synthesis -name "*.rpt" 2>/dev/null | sort | \
	while read f; do echo "\n═══ $$f ═══"; cat "$$f"; done || \
	echo "No synthesis reports found. Run 'make synth' first."

report-cts:
	@find $(DESIGN_DIR)/runs/$(TAG)/reports/cts -name "*.rpt" 2>/dev/null | sort | \
	while read f; do echo "\n═══ $$f ═══"; cat "$$f"; done || \
	echo "No CTS reports found. Run 'make cts' first."

report-routing:
	@find $(DESIGN_DIR)/runs/$(TAG)/reports/routing -name "*.rpt" 2>/dev/null | sort | \
	while read f; do echo "\n═══ $$f ═══"; cat "$$f"; done || \
	echo "No routing reports found. Run 'make routing' first."

report-timing:
	@find $(DESIGN_DIR)/runs/$(TAG)/reports/signoff -name "*.rpt" 2>/dev/null | sort | \
	while read f; do echo "\n═══ $$f ═══"; cat "$$f"; done || \
	echo "No signoff reports found. Run 'make gds' first."

# ══════════════════════════════════════════════════
#  Open-source simulation & lint
# ══════════════════════════════════════════════════

iverilog-sim: build/cpu_top.v
	iverilog -g2012 -s top_tb -o build/cpu_tb.vvp \
	  build/cpu_top.v tb/top_tb.sv
	vvp build/cpu_tb.vvp

lint:
	verilator --lint-only -Wall --top-module cpu_top $(RTL_SRC)

# ══════════════════════════════════════════════════
#  Cleanup
# ══════════════════════════════════════════════════

gds-clean:
	rm -rf $(DESIGN_DIR)/runs $(DESIGN_DIR)/src/cpu_top.v

clean: gds-clean
	rm -rf build reports .Xil *.jou *.log *.str
