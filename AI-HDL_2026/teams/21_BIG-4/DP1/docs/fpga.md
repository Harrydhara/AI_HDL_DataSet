# FPGA & Hardware Implementation Report

**Project:** Tensorbolt AI Accelerator (TinyQV Peripheral)
**Competition:** AI-HDL Design Phase 1
**Date:** 2026-01-30

## 1. Implementation Overview
The design targets a constrained area budget (< 2000 standard cells) and is implemented as a memory-mapped peripheral within the TinyQV system. While the primary target is the SkyWater 130nm ASIC node (via OpenLane), the design features strictly synthesizable Verilog-2005 logic compatible with standard FPGA flows (Xilinx Vivado / Intel Quartus).

## 2. Resource Utilization (Synthesis Results)
Based on the Yosys synthesis results performed during the OpenLane flow (Generic Gate Level):

| Resource Category | Count / Est. Value | Notes |
|:--- |:--- |:--- |
| **Total Standard Cells** | **~771 - 980** | Well within the 2,000 cell budget (< 50% utilization). |
| **Combinational Logic** | ~570 cells | dominated by MUXes and Logic Gates (AND/OR). |
| **Sequential Logic (FFs)**| ~130 - 150 cells | Registers for State Machine, Input Buffers, and Accumulator. |
| **Multiplexers** | ~237 - 290 | High usage due to time-multiplexed SIMD architecture. |
| **Macros / DSPs** | 0 | Design uses flattened logic for arithmetic (no hard macros). |

**Analysis:**
The design utilizes a **"Time-Multiplexed"** architecture. Instead of instantiating large parallel arrays of multipliers (which would consume excessive FPGA LUTs or DSP slices), the design reuses a single pipelined datapath over multiple clock cycles. This results in a very compact footprint suitable for low-cost FPGAs (e.g., Artix-7, Cyclone V) or tiny ASIC tiles.

## 3. FPGA Compatibility Notes
* **Clocking:** Single clock domain (`clk`), positive-edge triggered. No internal PLLs or generated clocks.
* **Reset:** Synchronous/Asynchronous active-low reset (`rst_n`) handled via standard cell mapping.
* **Portability:** No vendor-specific primitives (IP Cores) were used. The `tensorbolt_ai_accelerator.v` module is pure Verilog-2005.
* **Safety:** The design avoids latches and combinatorial loops (verified via Verilator linting and simulation), ensuring stable Place & Route on FPGA fabrics.

## 4. Build Environment
* **Synthesis Tool:** Yosys (part of OpenLane Flow)
* **Target Library:** SkyWater 130nm (ASIC) / Generic (FPGA equivalent logic)
* **Optimization Strategy:** Area-Optimized (`AREA 2` strategy in OpenLane).
