# DP1 — TinyQV RISC-V CPU with DMA Integration

**Design Name:** `tt_um_tt_tinyQV`

**Platform:** Tiny Tapeout (TT)

**Technology:** SkyWater SKY130 (130 nm)

**Affiliation:** ICLabHUST, Hanoi University of Science and Technology (HUST)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Design Specification](#2-design-specification)
3. [Module Hierarchy](#3-module-hierarchy)
4. [DMA Peripheral — Register Map](#4-dma-peripheral--register-map)
5. [Simulation Environment Setup](#5-simulation-environment-setup)
6. [Running Simulations](#6-running-simulations)
7. [Logic Synthesis](#7-logic-synthesis)
8. [Physical Design — OpenLane2 Flow](#8-physical-design--openlane2-flow)
9. [Project Directory Structure](#9-project-directory-structure)
10. [Tools and AI Assistance](#10-tools-and-ai-assistance)
11. [Project Documentation](#11-project-documentation)
12. [References](#12-references)

---

## 1. Project Overview

This project integrates a **Direct Memory Access (DMA) peripheral** into the **TinyQV** RISC-V processor and submits the combined design to the **Tiny Tapeout** shuttle program for fabrication on the SkyWater SKY130 130 nm process.

TinyQV is a minimal-area RISC-V CPU designed for resource-constrained silicon tiles. The base architecture implements the **RV32I** instruction set with hardware multiply support and interfaces with external QSPI Flash/RAM through a Quad-SPI memory controller.

The DMA block (`tqvp_dma`) is implemented as a memory-mapped peripheral in the TinyQV peripheral bus. It provides autonomous streaming transfer between the CPU data buffer and the Tiny Tapeout I/O ports (`ui_in` / `uo_out`), offloading the CPU from byte-by-byte polling loops.

---

## 2. Design Specification

| Parameter                    | Value                                          |
|------------------------------|------------------------------------------------|
| Top-level module             | `tt_um_tt_tinyQV`                              |
| ISA                          | RV32I + M-extension (hardware multiply)        |
| Register file                | 16 × 32-bit general-purpose registers          |
| Instruction memory interface | 16-bit fetch over QSPI Flash                   |
| Data memory interface        | QSPI Flash + QSPI RAM (28-bit address space)   |
| Peripheral bus               | Memory-mapped I/O, 28-bit address              |
| Clock frequency              | 50 MHz target (20 ns period) / 64 MHz nominal  |
| Reset polarity               | Active-low, synchronous to negative clock edge |                                |
| PDK                          | SkyWater SKY130                              |                                 |

<!-- ### I/O Pin Mapping

| Signal         | Width | Direction | Function                                          |
|----------------|-------|-----------|---------------------------------------------------|
| `ui_in[7:0]`   | 8     | Input     | General-purpose inputs; [1:0] = interrupt source  |
| `uo_out[7:0]`  | 8     | Output    | General-purpose outputs; [6] = debug UART TX      |
| `uio_oe[7:0]`  | 8     | Output    | Bidir direction control (active-high = output)    |
| `clk`          | 1     | Input     | System clock                                      |
| `rst_n`        | 1     | Input     | Asynchronous reset, active-low                    |
| `ena`          | 1     | Input     | Tile enable (not used internally)                 | -->

---

## 3. Module Hierarchy

```
tt_um_tt_tinyQV                   [top-level Tiny Tapeout wrapper]
├── tinyQV                        [CPU + memory controller integration]
│   ├── tinyqv_cpu                [RISC-V CPU pipeline]
│   │   ├── tinyqv_core           [execution core]
│   │   │   ├── tinyqv_alu        [arithmetic & logic unit]
│   │   │   ├── tinyqv_shifter    [barrel shifter]
│   │   │   ├── tinyqv_registers  [16 × 32-bit register file]
│   │   │   ├── tinyqv_counter    [program counter]
│   │   │   └── tinyqv_mul        [16×32 hardware multiplier]
│   │   └── tinyqv_decoder        [RISC-V instruction decoder]
│   └── tinyqv_mem_ctrl           [instruction/data memory arbiter]
│       └── qspi_controller       [Quad-SPI protocol engine]
├── tinyQV_peripherals            [peripheral bus fabric]
│   └── tqvp_dma                  [streaming DMA peripheral]
└── uart_tx                       [4 Mbps debug UART transmitter]
```

### Key Sub-modules

| Module              | Description                                                                       |
|---------------------|-----------------------------------------------------------------------------------|
| `tinyqv_alu`        | Combinational ALU; supports ADD, SUB, SLT/SLTU, AND, OR, XOR, compare-zero ops   |
| `tinyqv_decoder`    | Single-cycle RISC-V instruction decode; generates control signals for the core    |
| `tinyqv_mem_ctrl`   | Arbitrates between instruction fetch and data load/store over the QSPI interface  |
| `qspi_controller`   | Quad-SPI (x4) protocol engine supporting Flash and two SRAM devices               |
| `tqvp_dma`          | Streaming DMA; 32-byte internal buffer, configurable rate, IRQ on completion      |
| `uart_tx`           | UART transmitter instantiated at 4 Mbps for in-circuit debug output               |

---

## 4. DMA Peripheral — Register Map

The `tqvp_dma` module is addressed within the TinyQV peripheral address space. All registers are word-aligned (32-bit accesses).

| Offset | Name      | R/W | Bit-field Description                                                     |
|--------|-----------|-----|---------------------------------------------------------------------------|
| `0x00` | `CTRL`    | W   | [0] `start` — self-clearing; [1] `mode` (0=RX, 1=TX); [2] `irq_enable`  |
| `0x04` | `COUNT`   | RW  | Number of bytes to transfer (valid range: 1–32)                           |
| `0x08` | `DIVISOR` | RW  | Output/sample clock divisor; period = (DIVISOR+1) cycles. Default: 63    |
| `0x0C` | `STATUS`  | R   | [0] `busy`; [1] `done`                                                    |
| `0x10` | `CLR_IRQ` | W   | Write any value to clear `done` flag and deassert the interrupt line      |
| `0x14` | `DATA0`   | RW  | Data buffer bytes  3:0                                                    |
| `0x18` | `DATA1`   | RW  | Data buffer bytes  7:4                                                    |
| `0x1C` | `DATA2`   | RW  | Data buffer bytes 11:8                                                    |
| `0x20` | `DATA3`   | RW  | Data buffer bytes 15:12                                                   |
| `0x24` | `DATA4`   | RW  | Data buffer bytes 19:16                                                   |
| `0x28` | `DATA5`   | RW  | Data buffer bytes 23:20                                                   |
| `0x2C` | `DATA6`   | RW  | Data buffer bytes 27:24                                                   |
| `0x30` | `DATA7`   | RW  | Data buffer bytes 31:28                                                   |

### Operating Modes

**TX mode** (`CTRL[1] = 1`): The CPU fills `DATA[0..N/4]`, sets `COUNT`, optionally configures `DIVISOR`, then writes `1` to `CTRL[start]`. The DMA controller clocks each byte out on `uo_out[7:0]` at the configured rate and asserts `STATUS[done]` after the last byte.

**RX mode** (`CTRL[1] = 0`): The CPU sets `COUNT` and `DIVISOR`, then writes `1` to `CTRL[start]`. The DMA samples `ui_in[7:0]` at the configured rate, fills `DATA[0..N/4]`, and asserts `STATUS[done]` after `COUNT` bytes have been captured.

In both modes, the interrupt line is asserted on completion when `CTRL[irq_enable]` is set. Write any value to `CLR_IRQ` to deassert.

---

## 5. Simulation Environment Setup

Functional verification uses **cocotb** (Python coroutine testbench framework) compiled against **Verilator** as the simulator backend.

### Prerequisites

| Tool        | Version  | Notes                                       |
|-------------|----------|---------------------------------------------|
| Python      | ≥ 3.10   | Required for cocotb and test scripts        |
| Verilator   | ≥ 5.0    | RTL simulator backend                       |
| GNU Make    | ≥ 4.0    | Test orchestration                          |
| GCC / Clang | any      | C++ compilation for Verilator-generated code|

### Step-by-step Installation

**1. Create and activate a Python virtual environment**

```bash
cd test/
python3 -m venv venv
source venv/bin/activate       # Linux / macOS
# venv\Scripts\activate        # Windows (PowerShell)
```

**2. Install all required Python packages**

```bash
pip install -r requirements.txt
```

The `requirements.txt` file installs the following packages:

| Package       | Purpose                                                        |
|---------------|----------------------------------------------------------------|
| `cocotb`      | Coroutine-based HDL testbench framework                        |
| `pytest`      | Test runner and result reporting (JUnit XML output)            |
| `riscv-model` | RISC-V instruction set model used by CPU-level testbenches     |
| `pyelftools`  | ELF binary parser for loading firmware images in system tests  |
| `bitstring`   | Bit-accurate data manipulation in testbench scripts            |

Alternatively, packages can be installed individually:

```bash
pip install cocotb pytest riscv-model pyelftools bitstring
```

**3. Verify the cocotb installation**

```bash
cocotb-config --version
```

Expected output example:
```
1.9.2
```

---

## 6. Running Simulations

All tests are managed by per-module Makefiles located in `test/`. The master `Makefile` orchestrates the full suite.

### Test Suite

| Target              | Makefile             | DUT module            |
|---------------------|----------------------|-----------------------|
| `test_alu`          | `test_alu.mk`        | `tinyqv_alu`          |
| `test_core`         | `test_core.mk`       | `tinyqv_core`         |
| `test_counter`      | `test_counter.mk`    | `tinyqv_counter`      |
| `test_cpu`          | `test_cpu.mk`        | `tinyqv_cpu`          |
| `test_decode`       | `test_decode.mk`     | `tinyqv_decoder`      |
| `test_latch_reg`    | `test_latch_reg.mk`  | `tinyqv_registers`    |
| `test_mem_ctrl`     | `test_mem_ctrl.mk`   | `tinyqv_mem_ctrl`     |
| `test_qspi_ctrl`    | `test_qspi_ctrl.mk`  | `qspi_controller`     |
| `test_qspi_flash`   | `test_qspi_flash.mk` | QSPI Flash model      |
| `test_register`     | `test_register.mk`   | `tinyqv_registers`    |
| `test_time`         | `test_time.mk`       | timer logic           |
| `test_uart_tx`      | `test_uart_tx.mk`    | `uart_tx`             |
| `test_peripherals`  | `test_peripherals.mk`| `tinyQV_peripherals`  |
| `test_tinyqv`       | `test_tinyqv.mk`     | `tinyQV`              |
| `test_dma`          | `test_dma.mk`        | `tqvp_dma`            |
| `test_system`       | `test_system.mk`     | `tt_um_tt_tinyQV`     |

### Commands

```bash
# Activate the virtual environment first (if not already active)
source venv/bin/activate

# Run the complete test suite (all 16 modules)
make all

# Run a specific module test
make test_alu
make test_dma
make test_system

# Remove all simulation build artifacts
make clean
```

Test results are written to `test/results.xml` in JUnit XML format, compatible with CI/CD pipelines and pytest reporting tools.

---

## 7. Logic Synthesis

Synthesis maps the RTL to the **SkyWater SKY130HD** standard cell library using **Yosys**.

### Synthesis Flow

```bash
cd yosys/
yosys synth.ys
```

Output artifacts are written to `output/`:

| File                  | Description                               |
|-----------------------|-------------------------------------------|
| `synth_netlist.v`     | Gate-level netlist (Verilog)              |
| `synth_netlist.json`  | Gate-level netlist (JSON)                 |
| `synth_stats.txt`     | Cell count and area statistics per module |
| `synth.log`           | Full Yosys synthesis log                  |

<!-- ### Synthesis Configuration

| Parameter         | Value                     |
|-------------------|---------------------------|
| Tool              | Yosys 0.46                |
| Strategy          | `AREA 0` (area-optimised) |
| Technology        | SKY130HD liberty model    |
| Clock gating      | Disabled (`USE_LIGHTER 0`)| -->

---

## 8. Physical Design — OpenLane2 Flow

The complete RTL-to-GDS implementation uses **OpenLane2** with the default Tiny Tapeout base flow configuration.

### Configuration

- **Config file:** `openlane/config.json`
- **SDC file:** `openlane/tt_um_tt_tinyQV.sdc`
- **Run directory:** `openlane/runs/Base_PPA_DP1/`

<!-- ### Key Configuration Parameters

| Parameter                      | Value       | Description                                      |
|--------------------------------|-------------|--------------------------------------------------|
| `CLOCK_PERIOD`                 | 20 ns       | 50 MHz target frequency                          |
| `PL_TARGET_DENSITY_PCT`        | 50 %        | Cell placement density                           |
| `SYNTH_STRATEGY`               | `AREA 0`    | Area-optimised synthesis                         |
| `MAX_TRANSITION_CONSTRAINT`    | 1.5 ns      | Maximum signal transition time constraint        |
| `DESIGN_REPAIR_MAX_SLEW_PCT`   | 75 %        | Fraction of slew violations repaired by resizer  |
| `DESIGN_REPAIR_MAX_CAP_PCT`    | 75 %        | Fraction of cap violations repaired by resizer   |
| `PL_RESIZER_SETUP_SLACK_MARGIN`| 0.17 ns     | Setup timing margin for placement resizer        |
| `GRT_RESIZER_SETUP_SLACK_MARGIN`| 0.12 ns    | Setup timing margin for global routing resizer   |
| `PL_RESIZER_HOLD_SLACK_MARGIN` | 0.15 ns     | Hold timing margin for placement resizer         |
| `RT_MAX_LAYER`                 | `met4`      | Maximum metal routing layer                      |
| `FP_SIZING`                    | `absolute`  | Fixed die area                                   |
| `DIE_AREA`                     | 0 0 668 432 | Die boundary in µm                               |
| `RUN_CTS`                      | 1           | Clock tree synthesis enabled                     |
| `RUN_POST_GRT_DESIGN_REPAIR`   | true        | Post-routing design repair pass enabled          |
| `RUN_HEURISTIC_DIODE_INSERTION`| 1           | Antenna violation mitigation                     |

### SDC Timing Constraints -->

<!-- The SDC file (`openlane/tt_um_tt_tinyQV.sdc`) defines:

- **Clock period:** `CLOCK_PERIOD` ns with ±2.5 ns duty-cycle uncertainty (accounting for the Tiny Tapeout mux capacitance)
- **Input delays:** 65% of clock period for `ui_in`, `uio_in` (worst-case setup); 24% for hold
- **Output delays:** 65% setup / 1 ns hold for bidirectional SPI ports; 1 ns for `uo_out`
- **SPI clock output:** relaxed to 18% clock period (driven on negative edge)
- **Max fanout:** 12 (reduced to force earlier buffer insertion on high-fanout nets)
- **Max transition:** 1.5 ns (aligned with `MAX_TRANSITION_CONSTRAINT`)

### Flow Steps

```
01  verilator-lint              → RTL lint check
02  checker-linttimingconstructs
03  checker-linterrors
04  checker-lintwarnings
05  yosys-jsonheader            → Module header extraction
06  yosys-synthesis             → Gate-level synthesis (SKY130HD)
07  checker-yosysunmappedcells
08  checker-yosyssynthchecks
...                             → Floorplan, placement, CTS, routing, signoff
```

--- -->

## 9. Project Directory Structure

```
DP1/
│
├── src/                        # RTL source files (Verilog)
│   ├── project.v               # Top-level Tiny Tapeout wrapper (tt_um_tt_tinyQV)
│   ├── tinyqv.v                # TinyQV integration (CPU + memory controller)
│   ├── cpu.v                   # RISC-V CPU (tinyqv_cpu)
│   ├── core.v                  # Execution core (tinyqv_core)
│   ├── decode.v                # Instruction decoder (tinyqv_decoder)
│   ├── alu.v                   # ALU (tinyqv_alu)
│   ├── register.v              # Register file (tinyqv_registers)
│   ├── latch_reg.v             # Latch-based register variant
│   ├── counter.v               # Program counter (tinyqv_counter)
│   ├── mem_ctrl.v              # Memory controller (tinyqv_mem_ctrl)
│   ├── qspi_ctrl.v             # QSPI controller (qspi_controller)
│   ├── qspi_flash.v            # QSPI flash interface
│   ├── peripherals.v           # Peripheral bus (tinyQV_peripherals)
│   ├── tqvp_dma.v              # DMA peripheral (tqvp_dma)
│   ├── uart_tx.v               # Debug UART transmitter (uart_tx)
│   └── time.v                  # Timer module
│
├── test/                       # Verification environment
│   ├── Makefile                # Master test runner (all modules)
│   ├── requirements.txt        # Python package dependencies
│   ├── test_*.mk               # Per-module cocotb Makefiles
│   ├── test_*.py               # cocotb Python testbenches
│   ├── tb_*.v                  # Verilog testbench wrappers
│   ├── flash_model.v           # QSPI Flash behavioral model
│   ├── peripherals_stub.v      # Peripheral bus stub for CPU-level tests
│   ├── tt_wrapper.v            # Tiny Tapeout test harness wrapper
│   ├── tqv.py / tqv_reg.py     # TinyQV software model (Python)
│   ├── core_instr.py           # RISC-V instruction generator helpers
│   ├── test_harness/           # Synchronizer and edge-detector primitives (SV)
│   ├── test_program.hex        # Firmware hex image for system-level tests
│   ├── results.xml             # JUnit test result output
│   └── venv/                   # Python virtual environment (not tracked by git)
│
├── yosys/                      # Yosys synthesis scripts
│   ├── synth.ys                # Yosys script (read → synth → write)
│   └── synth.tcl               # TCL wrapper (optional)
│
├── output/                     # Yosys synthesis outputs
│   ├── synth_netlist.v         # Gate-level netlist (Verilog)
│   ├── synth_netlist.json      # Gate-level netlist (JSON)
│   ├── synth_stats.txt         # Cell count and area report per module
│   └── synth.log               # Full Yosys synthesis log
│
├── openlane/                   # OpenLane2 physical design
│   ├── config.json             # OpenLane2 run configuration
│   └── tt_um_tt_tinyQV.sdc     # Timing constraints (SDC)
│
├── metrics.csv                 # OpenLane2 run metrics summary
│
├── docs/                       # Project documentation
│   └── SPEC.docx               # Full design specification (architecture, modules, signal tables)
│
├── prompt/                     # AI-assisted development log
│   └── prompt.docx             # Complete Claude Code session transcript
│
└── README.md                   # This document
```

---

## 10. Tools and AI Assistance

| Category            | Tool / Resource                                        |
|---------------------|--------------------------------------------------------|
| RTL Simulation      | Verilator 5.x                                          |
| Testbench Framework | cocotb 1.9.2 (Python coroutines)                       |
| Logic Synthesis     | Yosys 0.46                                             |
| Physical Design     | OpenLane2 (base flow)                                  |
| PDK                 | SkyWater SKY130HD                                      |
| Version Control     | Git                                                    |
| AI Assistance       | Claude (Anthropic) — Claude Code extension for VS Code |
|                     | ChatGPT (OpenAI)                                       |

AI tools were employed to accelerate RTL code generation and verification scripting. The **Claude Code** extension was used both within the **VS Code IDE** and via the **web interface**. Descriptions and code generated by AI were reviewed, adapted, and verified by the design team before integration.

The OpenLane2 physical design flow was executed independently by the team; AI tools were not used for guidance in this stage.

---

## 11. Project Documentation

### `docs/SPEC.docx` — Design Specification

`docs/SPEC.docx` is the official technical specification document for the project, covering all design information from system architecture down to per-module signal-level detail.

**Contents:**

| Section | Description |
|---------|-------------|
| I. System Architecture | TinyQV Core architecture (RV32E + C + Zcb + Zicond extensions); 28-bit memory model; Flash / PSRAM / MMIO address partitioning; address decoding logic |
| II. Modules | Functional description and complete signal table for all 18 modules: `tqvp_dma`, `tinyQV` (top), `tinyqv_cpu`, `tinyqv_mem_ctrl`, `tinyqv_core`, `tinyqv_decoder`, `qspi_controller`, `tinyqv_registers`, `tinyqv_alu`, `tinyqv_mul`, `tinyqv_shifter`, `i_cycles`, `i_instrret`, `tinyqv_time`, `latch_reg_p`, `peripheral` |
| III. Design Implementation | Data bus flows between CPU–Peripheral–mem_ctrl; DMA configuration mechanism via MMIO; interrupt handling and feedback bus |

**Highlights:**
- The 28-bit address space is partitioned into Flash (`0x0000000–0x0FFFFFF`), PSRAM A/B (`0x1000000–0x1FFFFFF`), and Peripherals (`0x8000000+`)
- Each module includes a detailed signal table listing name, direction (I/O), bit width, and functional description
- The `tqvp_dma` specification covers the request/grant arbitration mechanism, autonomous data transfer, and completion interrupt

---

### `prompt/prompt.docx` — AI Session Transcript

`prompt/prompt.docx` records the complete interactive session between the design team and the AI tool (Claude Code — VS Code extension) throughout the development of DP1.

**Overview:**

| Property | Value |
|----------|-------|
| Content lines | ~4,972 |
| AI tool | Claude Code (Anthropic) — VS Code extension |
| Format | Conversational log (User / Claude turns) interleaved with shell command output |

**Topics covered:**
- Debugging a fully-failing DMA testbench (`PASS=0 FAIL=12`) and analysing detailed Verilator / cocotb logs
- RTL code generation for `tqvp_dma.v` and integration into `peripherals.v`
- Writing the cocotb testbench (`test_dma.py`, `tb_dma.v`) and the corresponding Makefile
- Project directory structure and source file organisation
- Python virtual environment setup and simulation workflow
- Step-by-step design decisions and architectural explanations

This file serves as a development journal, providing context for every significant change made to the codebase.

---

## 12. References

<!-- ### TinyQV CPU

- Original design by **Michael Bell**, released under Apache-2.0 licence.
  Copyright (c) 2024 Michael Bell.

### Tiny Tapeout Platform

- Tiny Tapeout documentation: https://tinytapeout.com
- OpenLane configuration reference: https://openlane.readthedocs.io/en/latest/reference/configuration.html
- Tiny Tapeout FAQ (clock mapping): https://tinytapeout.com/faq/ -->

### DMA Architecture

- *Direct Memory Access (DMA) Controller in Computer Architecture* — GeeksforGeeks
  https://www.geeksforgeeks.org/computer-organization-architecture/direct-memory-access-dma-controller-in-computer-architecture/

- *Direct Memory Access (DMA) in Embedded Systems* — Open4Tech
  https://open4tech.com/direct-memory-access-dma-in-embedded-systems/