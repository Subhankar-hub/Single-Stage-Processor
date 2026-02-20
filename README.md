# Single-Stage (Single-Cycle) Processor

A 32-bit single-cycle CPU written in SystemVerilog, targeting both **FPGA** (Xilinx Vivado / Kintex-7) and **ASIC** (Sky130 via OpenLane) flows.

## CPU Microarchitecture

```mermaid
graph LR
    subgraph Fetch
        PC["PC<br/>(+1 each cycle)"] -->|addr| IMEM["Instruction<br/>Memory"]
    end

    IMEM -->|instr| CU["Control<br/>Unit"]
    IMEM -->|instr| DECODE((" "))

    subgraph Decode / Execute
        CU -->|alu_op| ALU
        CU -->|reg_write_en| RF["Register File<br/>r0-r7 (r0=0)"]
        CU -->|mem_read / mem_write| DMEM["Data<br/>Memory"]
        CU -->|rs1, rs2, rd| RF

        RF -->|rs1_val| ALU
        RF -->|rs2_val / imm16| MUX_B{{"MUX<br/>(R/I)"}}
        MUX_B --> ALU
    end

    subgraph Memory / Writeback
        ALU -->|eff_addr| DMEM
        RF -->|rs2_val| DMEM
        ALU -->|result| MUX_WB{{"MUX<br/>(WB)"}}
        DMEM -->|rdata| MUX_WB
        MUX_WB -->|write_back| RF
    end
```

## Datapath Detail

```mermaid
flowchart TD
    CLK([clk]) --> PC["PC Register"]
    RST([rst_n]) --> PC

    PC -->|"addr_word"| IMEM["instruction_memory<br/>DEPTH words"]
    IMEM -->|"instr [31:0]"| CU["control_unit"]

    CU -->|"opcode, rd, rs1, rs2, imm16"| RF["regfile<br/>8 x 32-bit"]
    CU -->|"alu_op"| ALU["alu<br/>ADD / SUB / NOP"]
    CU -->|"is_itype"| BMUX{{"ALU-B MUX"}}
    CU -->|"mem_read"| WBMUX{{"Write-back MUX"}}
    CU -->|"mem_write"| DMEM["data_memory<br/>DEPTH words"]

    RF -->|"rs1_val"| ALU
    RF -->|"rs2_val"| BMUX
    CU -->|"sign_ext(imm16)"| BMUX
    BMUX -->|"b"| ALU

    ALU -->|"result (addr)"| DMEM
    RF -->|"rs2_val (wdata)"| DMEM
    ALU -->|"result"| WBMUX
    DMEM -->|"rdata"| WBMUX
    WBMUX -->|"rd_data"| RF

    PC -->|"pc + 1"| PC
```

## ISA Encoding

```mermaid
packet-beta
  0-5: "opcode [31:26]"
  6-8: "rd [25:23]"
  9-11: "rs1 [22:20]"
  12-14: "rs2 [19:17]"
  15-31: "unused [16:0]"
```

**R-type** (ADD, SUB): `[31:26] opcode | [25:23] rd | [22:20] rs1 | [19:17] rs2`

**I-type** (ADDI, LOAD, STORE): `[31:26] opcode | [25:23] rd/rs2 | [22:20] rs1 | [19:4] imm16`

| Opcode | Encoding | Description |
|--------|----------|-------------|
| NOP    | `000000` | No operation |
| ADD    | `000001` | `rd = rs1 + rs2` |
| SUB    | `000010` | `rd = rs1 - rs2` |
| ADDI   | `000011` | `rd = rs1 + sign_ext(imm16)` |
| LOAD   | `000100` | `rd = dmem[rs1 + sign_ext(imm16)]` |
| STORE  | `000101` | `dmem[rs1 + sign_ext(imm16)] = rs2` |

## Design Flows

### FPGA Flow

```mermaid
flowchart LR
    RTL["RTL<br/>(SystemVerilog)"] --> SYNTH["Vivado<br/>Synthesis"]
    SYNTH --> IMPL["Place &<br/>Route"]
    IMPL --> BIT["Bitstream<br/>(.bit)"]
    BIT --> FPGA["Kintex-7<br/>FPGA"]

    RTL --> SIM["XSim + UVM<br/>Simulation"]
    SIM --> WAVE["Waveforms"]

    style RTL fill:#4a90d9,color:#fff
    style BIT fill:#2ecc71,color:#fff
    style SIM fill:#9b59b6,color:#fff
```

### ASIC Flow (RTL-to-GDS)

```mermaid
flowchart LR
    SV["RTL<br/>(SystemVerilog)"] --> SV2V["sv2v"]
    SV2V --> V["Verilog<br/>(.v)"]
    V --> OL["OpenLane (Docker)"]

    subgraph OL["OpenLane Flow"]
        direction TB
        YS["Yosys<br/>Synthesis"] --> FP["Floorplan"]
        FP --> GPL["Global<br/>Placement"]
        GPL --> DPL["Detailed<br/>Placement"]
        DPL --> CTS["Clock Tree<br/>Synthesis"]
        CTS --> GRT["Global<br/>Routing"]
        GRT --> DRT["Detailed<br/>Routing"]
        DRT --> SIGN["Signoff<br/>(DRC/LVS/STA)"]
        SIGN --> GDS["GDS-II"]
    end

    GDS --> KL["KLayout<br/>Viewer"]

    style SV fill:#4a90d9,color:#fff
    style GDS fill:#2ecc71,color:#fff
```

### UVM Testbench Architecture

```mermaid
flowchart TB
    subgraph TEST["UVM Test (directed / random)"]
        direction TB
        TB_TEST["cpu_test_base"]
    end

    subgraph ENV["cpu_env"]
        direction TB
        subgraph AGENT["cpu_agent"]
            DRV["cpu_driver"] --- MON["cpu_monitor"]
        end
        SB["cpu_scoreboard<br/>(reference model)"]
    end

    TEST --> ENV
    MON -->|"cpu_trans<br/>(analysis port)"| SB
    DRV <-->|"cpu_if<br/>(virtual interface)"| DUT["cpu_top<br/>(DUT)"]
    MON <-->|"cpu_if"| DUT

    style DUT fill:#e74c3c,color:#fff
    style SB fill:#f39c12,color:#fff
    style TEST fill:#9b59b6,color:#fff
```

## Project Structure

```
.
├── Makefile                  # All build/sim/ASIC targets
├── rtl/
│   ├── isa_defs.sv           # ISA package (opcodes, field extraction)
│   ├── alu.sv                # ALU (ADD/SUB)
│   ├── regfile.sv            # 8x32 register file
│   ├── control_unit.sv       # Instruction decoder
│   ├── instruction_memory.sv # IMEM (with TB write port)
│   ├── data_memory.sv        # DMEM (with TB read/write ports)
│   └── cpu_top.sv            # Top-level CPU
├── tb/
│   ├── top_tb.sv             # Top testbench (clock, reset, UVM entry)
│   └── uvm/                  # UVM verification environment
├── scripts/                  # Vivado TCL scripts
├── asic/
│   ├── config.json           # OpenLane configuration (Sky130)
│   ├── src/                  # sv2v-converted Verilog (generated)
│   └── runs/                 # OpenLane run outputs
│       └── run/results/final/
│           └── gds/cpu_top.gds
└── sim/
    └── program.hex           # Optional preload program
```

## Prerequisites

| Tool | Used for |
|------|----------|
| **Vivado 2025.2** | FPGA synthesis, implementation, simulation (XSim) |
| **Yosys** | Local synthesis sanity check |
| **sv2v** | SystemVerilog-to-Verilog conversion for ASIC tools |
| **Verilator** | RTL linting |
| **Icarus Verilog** | Open-source simulation |
| **GTKWave** | Waveform viewing |
| **Docker** | Runs OpenLane for RTL-to-GDS |

## Quick Start

### FPGA Flow (Vivado)

```bash
make project          # Create Vivado project (Kintex-7 xc7k70tfbv676-1)
make sim              # Run behavioural simulation (XSim + UVM)
make synth            # Run synthesis (reports in reports/)
make impl             # Run implementation / place & route
make bitstream        # Generate bitstream
make gui              # Open project in Vivado GUI
```

### ASIC Flow (OpenLane + Sky130)

```bash
make gds-setup        # One-time: pull Docker image + fetch Sky130 PDK
make yosys-check      # Quick local synthesis sanity check
make gds              # Full RTL-to-GDS (synthesis -> floorplan -> PnR -> DRC -> GDS)
make gds-view         # Open GDS in KLayout
```

The ASIC flow uses 64-entry memories (parameterised down from 1024) so they synthesise as flip-flop arrays. A production design would replace these with SRAM macros (e.g. via OpenRAM).

### Open-Source Simulation & Lint

```bash
make lint             # Verilator lint check
make iverilog-sim     # Compile & run with Icarus Verilog
```

### Cleanup

```bash
make clean            # Remove all generated files
make gds-clean        # Remove only ASIC run outputs
```

## Target Platforms

### FPGA

- **Device**: Xilinx Kintex-7 `xc7k70tfbv676-1`
- **Clock**: 100 MHz (10 ns period)

### ASIC

- **PDK**: SkyWater Sky130A (130 nm, open-source)
- **Clock**: 40 MHz (25 ns period)
- **Standard cell library**: `sky130_fd_sc_hd`
- **Flow**: OpenLane v1.1.1 (classic) via Docker
- **Output**: `asic/runs/run/results/final/gds/cpu_top.gds`

## License

Licensed under the [Apache License 2.0](LICENSE). The Sky130 PDK is separately licensed under Apache 2.0 by Google/SkyWater.
