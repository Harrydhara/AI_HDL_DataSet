# AI-ASSISTED DESIGN LOG
## Design Phase 4: Netlist to Chip Tapeout
**Team:** Acona-Tech
**Competition:** AI-HDL 2026 Hardware Design Competition
**Institution:** Arizona State University / PRISM Lab
**Date:** April 27, 2026
**AI Tool Used:** Claude (Anthropic) — Opus 4
**Target PDK:** SkyWater Sky130 (sky130_fd_sc_hd)

---

## 1. Executive Summary
This document provides a comprehensive record of all AI-assisted interactions during Design Phase 4 (DP4) of the AI-HDL 2026 competition. Our team used Claude (Anthropic) as an AI co-pilot to integrate our DP3-hardened AES-128 accelerator into the TinyQV RISC-V peripheral harness, debug RTL compatibility issues, and execute the complete RTL-to-GDSII physical design flow. The AI-assisted workflow spanned multiple iterative sessions covering: RTL peripheral integration, SystemVerilog-to-Verilog conversion, cloud-based tapeout attempts (Autotapeout), debugging synthesis and LVS failures, and ultimately a successful local OpenLane tapeout achieving timing closure at 64 MHz with zero DRC/LVS violations.

### 1.1 Key Achievements

| Metric | Target | Achieved |
|---|---|---|
| Clock Frequency | 64 MHz | 64 MHz (✓) |
| Setup Slack (WNS) | ≥ 0 ns | +3.73 ns |
| Hold Slack | ≥ 0 ns | +0.07 ns |
| DRC Violations | 0 | 0 (✓) |
| LVS | Clean | Clean — Circuits match uniquely (✓) |
| Total Cells | — | 45,702 devices |
| Die Size | ≤ 1500 µm | 1488.56 × 1476.96 µm |
| Security Features | All retained | Masked S-Box, LFSR, Fault Detection (✓) |

---

## 2. Design Context
Our AES-128 secure accelerator was developed over DP1–DP3 with progressive enhancements. By DP3, the design included: a security-hardened AES core with masked S-Boxes (anti-DPA countermeasure), a 32-bit LFSR for random mask generation, a fault detection module with shadow round counters, unrolled key expansion for timing optimization, and a secure register interface with lock/zeroize capabilities.

### 2.1 RTL Module Hierarchy

| Module | Function |
|---|---|
| `tt_um_tqv_peripheral_harness` | Chip top module (TinyQV SPI interface) |
| `tqvp_aes128_secure` | AES peripheral top wrapper |
| `aes_core_secure` | Security-hardened AES-128 encryption core |
| `aes_reg_interface_secure` | Register interface with key lock and zeroization |
| `aes_sbox_masked` | Boolean-masked S-Box (anti-DPA) |
| `aes_sbox` | Standard AES S-Box (fwd + inv) |
| `aes_mixcolumns_fast` | Optimized MixColumns (reduced logic depth) |
| `aes_key_expansion_unrolled` | Pre-computed round key generation |
| `aes_masking_lfsr` | 32-bit LFSR for mask randomness |
| `aes_fault_detector` | Shadow round counter for fault injection detection |
| `aes_clock_gate` | ICG cell for power optimization |
| `spi_reg` | SPI slave to register bridge (TinyQV infra) |
| `synchronizer` | Multi-stage FF synchronizer (CDC) |

---

## 3. AI Interaction Log
Below is a chronological record of all significant AI-assisted interactions, organized by task category. Each entry includes the user prompt (paraphrased), Claude’s response summary, and the outcome.

### 3.1 Peripheral Integration (TinyQV Harness)
The first challenge was integrating our DP3 AES RTL into the TinyQV peripheral harness template provided by the competition organizers.

#### Interaction 3.1.1 — Understanding the Template
* **Prompt:** Here is the `tt_wrapper.v` file. Where do I integrate my peripheral?
* **Claude Response:** Claude identified the instantiation point marked with the comment '// **** Change the module name from tqvp_example to match your peripheral ****' and explained the peripheral interface: `clk`, `rst_n`, `ui_in`, `uo_out`, `address[5:0]`, `data_in[31:0]`, `data_write_n[1:0]`, `data_read_n[1:0]`, `data_out[31:0]`, `data_ready`, `user_interrupt`.
* **Action Taken:** Identified exact integration point in `tt_wrapper.v`.

#### Interaction 3.1.2 — Port Width Mismatch
* **Prompt:** [Uploaded all 10 AES RTL files] These are our all RTLs from DP3.
* **Claude Response:** Claude analyzed `tqvp_aes128_secure.sv` and discovered the address port is 7-bit `[6:0]` while the template uses 6-bit `[5:0]`. Three changes were needed: (1) address bus widened to `[6:0]`, (2) module name changed to `tqvp_aes128_secure`, (3) SPI ADDR_W parameter changed from 6 to 7.
* **Files Modified:** `tt_um_tqv_peripheral_harness.v` — 3 lines changed.

#### Interaction 3.1.3 — Missing Infrastructure Modules
* **Prompt:** We cannot find `spi_reg.v` and `synchronizer.v` in the template repo. Can you write them?
* **Claude Response:** Claude wrote both modules from scratch based on the port interface visible in `tt_wrapper.v`. The synchronizer is a parameterizable multi-stage flip-flop chain. The spi_reg is a full SPI slave-to-register bridge with configurable address/data widths, supporting 8/16/32-bit transactions.
* **Files Created:** `spi_reg.v` (270 lines), `synchronizer.v` (35 lines).

#### Interaction 3.1.4 — Single-File Consolidation
* **Prompt:** Can you merge all RTL and templates into a single file for tapeout?
* **Claude Response:** Claude concatenated all 13 modules into a single `aes128_secure_tapeout.v` (2544 lines) in correct dependency order: leaf modules first, top module last. Removed the redundant `tqvp_aes128_top_secure` wrapper and deduplicated `\`default_nettype` directives. Verified with iverilog — zero errors.
* **Output:** `aes128_secure_tapeout.v` — 13 modules, 2544 lines, syntax clean.

### 3.2 RTL Debugging — Synthesis Failures
Multiple iterations were required to achieve a clean synthesis. Each failure was diagnosed through log analysis and AI-assisted debugging.

#### Interaction 3.2.1 — First Autotapeout Attempt: RTL Validation Failed
* **Prompt:** [Screenshot: Autotapeout showing 'Synthesis failed: RTL validation failed after retries']
* **Claude Response:** Claude identified that Yosys (used by Autotapeout) runs in Verilog-2005 mode and does not support SystemVerilog keywords. The `aes_masking_lfsr` module used `logic` declarations and `always_ff` constructs. Claude wrote a Python script to automatically convert all SV keywords: logic → wire/reg, always_ff → always.
* **Root Cause:** SystemVerilog keywords incompatible with Yosys Verilog-2005 frontend.
* **Fix Applied:** Automated SV→Verilog conversion, verified with iverilog.

#### Interaction 3.2.2 — Clock Gate LVS Failure
* **Prompt:** [Autotapeout result: DRC=0, LVS=FAIL, WNS=-92.92ns]
* **Claude Response:** Claude analyzed that the `aes_clock_gate` module used a latch-based ICG (`always @(*) if(!clk)`) which Yosys synthesizes poorly, causing a netlist mismatch at LVS. First attempt: replaced with negedge flip-flop — still failed RTL validation. Second attempt: replaced with direct passthrough (`assign gated_clk = clk`), trading power optimization for LVS compatibility.
* **Iterations:** 3 versions of `aes_clock_gate` tested.
* **Final Fix:** Clock gate bypassed with direct wire assignment.

#### Interaction 3.2.3 — Output Reg/Assign Conflict
* **Prompt:** [Uploaded LVS log file showing persistent LVS FAIL]
* **Claude Response:** Claude performed deep log analysis and found Yosys warnings: 'reg rand_out is assigned in a continuous assignment.' The `aes_masking_lfsr` declared outputs as `output reg` but drove them with `assign` statements. This caused Yosys to generate a different netlist structure than the layout expected.
