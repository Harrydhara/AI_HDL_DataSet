# Final Project Report: TinyQV RISC-V SoC with Secure DMA Peripheral

**Team:** ICLab_HUST — Hanoi University of Science and Technology (HUST)

**Program:** AI-HDL 2026 — Tiny Tapeout Shuttle

**Technology:** SkyWater SKY130 (130 nm)

**Design Name:** `tt_um_tt_tinyQV`

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Design Phase 1: Base Architecture and DMA Integration](#2-design-phase-1-base-architecture-and-dma-integration)
3. [Design Phase 2: PPA Optimization](#3-design-phase-2-ppa-optimization)
4. [Design Phase 3: Hardware Security Hardening](#4-design-phase-3-hardware-security-hardening)
5. [Design Phase 4: Physical Design and Tapeout](#5-design-phase-4-physical-design-and-tapeout)
6. [Final PPA Metrics](#6-final-ppa-metrics)
7. [Security Features Summary](#7-security-features-summary)
8. [Reflections on the Process](#8-reflections-on-the-process)
9. [References](#9-references)

---

## 1. Executive Summary

This report documents the complete 16-week journey of designing, optimizing, securing, and taping out a RISC-V System-on-Chip for the AI-HDL 2026 program. Starting from an open-source minimal RISC-V core (TinyQV), we integrated a custom DMA peripheral, systematically optimized the design for Power, Performance, and Area (PPA), hardened it against four identified hardware vulnerabilities, and produced a manufacturable GDSII layout on the SkyWater SKY130 130 nm process.

The final submitted design achieves **zero DRC errors, zero LVS errors, and zero timing violations** across all process-voltage-temperature corners — meeting the requirements of a manufacturable chip.

### Key Results at a Glance

| Metric | DP1 (Baseline) | DP4 (Final) | Total Change |
|--------|---------------|-------------|-------------|
| Standard cell count | 13,981 | 12,713 | **−9.1 %** |
| Standard cell area | 87,735 µm² | 81,645 µm² | **−6.9 %** |
| Total power | 6.432 mW | 6.413 mW | **−0.3 %** |
| Setup slack (worst corner) | 1.684 ns | 1.380 ns | — |
| Wire length | 257,132 µm | 219,602 µm | **−14.6 %** |
| DRC / LVS errors | 0 / 0 | **0 / 0** | Clean |
| Security vulnerabilities | 4 | **0** | All mitigated |

Despite adding four security countermeasures, the final design is **smaller, more power-efficient, and more manufacturable** than the original baseline — a result of disciplined RTL optimization performed alongside the security work.

---

## 2. Design Phase 1: Base Architecture and DMA Integration

**Duration:** Weeks 1–4 · **Goal:** Establish a working RTL baseline

### 2.1 Overview

Design Phase 1 established the core system architecture by integrating a custom **Direct Memory Access (DMA) peripheral** (`tqvp_dma`) into the open-source **TinyQV** RISC-V processor. The combined design was targeted for submission to the Tiny Tapeout (TT) shuttle program for fabrication on the SkyWater SKY130 130 nm process.

TinyQV is a minimal-area RISC-V CPU implementing the **RV32I + M-extension** instruction set with a Quad-SPI memory interface. The architecture is designed for resource-constrained silicon tiles.

### 2.2 Design Specification

| Parameter | Value |
|-----------|-------|
| Top-level module | `tt_um_tt_tinyQV` |
| ISA | RV32I + M-extension (hardware multiply) |
| Register file | 16 × 32-bit general-purpose registers |
| Instruction memory | 16-bit fetch over QSPI Flash |
| Data memory | QSPI Flash + QSPI RAM (28-bit address space) |
| Peripheral bus | Memory-mapped I/O, 28-bit address |
| Clock target | 50 MHz (20 ns period) |
| PDK | SkyWater SKY130 HD |
| Die area | 432 × 432 µm (186,624 µm²) |

### 2.3 Module Hierarchy

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

### 2.4 DMA Peripheral Design

The `tqvp_dma` module implements autonomous streaming transfers between the CPU memory buffer and the physical I/O ports (`ui_in` / `uo_out`), eliminating CPU polling overhead. It exposes a 32-byte buffer with configurable transfer count and rate control.

**Register Map:**

| Offset | Name | Description |
|--------|------|-------------|
| `0x00` | `CTRL` | `[0]` start (self-clearing), `[1]` mode (RX/TX), `[2]` irq_enable |
| `0x04` | `COUNT` | Number of bytes to transfer (1–32) |
| `0x08` | `DIVISOR` | Clock divisor; period = (DIVISOR+1) cycles |
| `0x0C` | `STATUS` | `[0]` busy, `[1]` done |
| `0x10` | `CLR_IRQ` | Write any value to clear interrupt |
| `0x14–0x30` | `DATA0–DATA7` | 32-byte data buffer |

### 2.5 Verification

The design was verified using **cocotb** (coroutine-based testbenches) compiled against **Verilator** v5.x. A suite of 16 test targets covered every module from individual ALU operation up to full-system simulation with RISC-V firmware.

| Test suite coverage | Modules verified |
|---------------------|-----------------|
| Unit tests | ALU, decoder, registers, counter, shifter, QSPI, UART, timer |
| Integration tests | CPU pipeline, peripheral bus, DMA |
| System test | Full SoC (CPU + Flash + DMA) |

### 2.6 Physical Design — DP1 Baseline PPA

The initial OpenLane2 run established the baseline metrics:

| Metric | Value |
|--------|-------|
| Standard cell count | 13,981 |
| Standard cell area | 87,735 µm² |
| Core utilization | 48.49 % |
| Timing-repair buffers | 170 |
| Total power | 6.432 mW |
| Setup slack (SS 100°C 1.60V) | 1.684 ns |
| Wire length | 257,132 µm |
| Routing iterations to clean | 22 |
| DRC errors | 0 |
| LVS errors | 0 |

The router required **22 iterations** before clearing all DRC errors, indicating moderate routing congestion driven by the wide case/MUX trees in the original DMA RTL. The 170 timing-repair buffers inserted by the placer indicated over-deep logic paths — a clear target for Phase 2.

### 2.7 AI Assistance in Phase 1

Claude Code (Anthropic, VS Code extension) was the primary AI tool, used for RTL code generation, testbench scripting, and debugging. A complete session transcript (~4,972 lines) was preserved as a development journal. Key AI-assisted tasks included:

- Debugging a fully-failing DMA testbench (PASS=0, FAIL=12) to 12/12 passing
- RTL generation for `tqvp_dma.v` and `peripherals.v` integration
- Writing the full cocotb testbench suite
- Project directory organization and simulation workflow

---

## 3. Design Phase 2: PPA Optimization

**Duration:** Weeks 5–8 · **Goal:** Reduce area and improve timing without changing functionality

### 3.1 Overview

Design Phase 2 applied seven RTL-level optimizations to `tqvp_dma.v` and `peripherals.v`. No module ports were changed; all modifications are strictly internal logic. The goal was to reduce cell count, shrink area, and improve routing quality.

### 3.2 Optimizations Applied

| ID | File | Technique | Primary Gain |
|----|------|-----------|-------------|
| OPT-1 | `tqvp_dma.v` | Computed write index (`address[4:2] − 5`) replacing 8-case decoder | Area: collapses 8-way MUX |
| OPT-2 | `tqvp_dma.v` | Variable part-select for RX byte write replacing 32-case nested decoder | Area: collapses 32 explicit assignments |
| OPT-3 | `tqvp_dma.v` | Variable part-select for TX byte read | Area/Performance: shorter combinational path |
| OPT-4 | `tqvp_dma.v` | Computed read index in `default` branch — case from 14 to 6 entries | Area: narrower MUX tree |
| OPT-5 | `tqvp_dma.v` | Down-counter with zero-detect replacing 8-bit magnitude comparator | Area/Power: NOR gate replaces subtractor |
| OPT-6 | `tqvp_dma.v` | Eliminated `dma_done` register — `state == ST_DONE` carries same info | Area: saves 1 FF + logic |
| OPT-P1 | `peripherals.v` | Removed always-true `data_ready_from_peri` wire | Performance: removes AND gates on handshake path |

**Core insight:** The original DMA RTL used flat, explicit `case` trees for buffer access — 8 × 4 = 32 nested assignments for both read and write paths. Replacing these with computed indices and variable part-selects allowed the synthesizer to infer compact MUX structures, directly reducing logic cone depth.

### 3.3 DP2 vs DP1 — PPA Comparison

| Metric | DP1 Baseline | DP2 Optimized | Change |
|--------|-------------|--------------|--------|
| Standard cell count | 13,981 | 13,165 | **−5.84 %** |
| Standard cell area (µm²) | 87,735 | 84,074 | **−4.17 %** |
| Timing-repair buffers | 170 | 136 | **−20.0 %** |
| Multi-input combinational cells | 4,230 | 4,065 | **−3.90 %** |
| Total power (mW) | 6.432 | 6.543 | +1.72 % |
| Setup slack SS corner (ns) | 1.684 | 0.916 | −0.768 ns |
| Wire length (µm) | 257,132 | 225,599 | **−12.3 %** |
| Routing iterations | 22 | 7 | **−68.2 %** |
| Worst IR drop (µV) | 130.7 | 114.8 | **−12.2 %** |

### 3.4 Notable Trade-offs

**Power slight increase (+1.72 %):** Although cell count fell by 5.84 %, total power increased marginally. The root cause is a cell-type migration: replacing wide flat MUX trees with subtractors and array-index multiplexers causes the synthesizer to select different, higher drive-strength cells. The leakage component correctly decreased (−2.47 %), confirming the cell selection is lighter. This is a routing artifact, not a fundamental RTL regression.

**Setup slack reduction at SS corner:** The worst-case SS setup slack decreased from 1.684 ns to 0.916 ns (still positive — no violations). Fewer timing-repair buffers in the optimized design removed implicit timing padding. Both designs meet 50 MHz with zero violations.

**Routing iteration reduction (22 → 7):** The most visible sign of reduced congestion — the original dense MUX trees required many re-route attempts; the optimized version clears in 7 passes.

---

## 4. Design Phase 3: Hardware Security Hardening

**Duration:** Weeks 9–12 · **Goal:** Identify, analyze, and mitigate hardware vulnerabilities in the DMA peripheral

### 4.1 Overview

Design Phase 3 conducted a systematic security evaluation of the TinyQV DMA peripheral using three combined threat modeling frameworks:

- **CIA Triad** — defines Confidentiality, Integrity, and Availability protection goals
- **STRIDE** — classifies attack types (Spoofing, Tampering, Information Disclosure, DoS, Elevation of Privilege)
- **DREAD** — scores each vulnerability on a 1–10 risk scale across five dimensions

### 4.2 Vulnerabilities Identified

A static RTL review of `tqvp_dma.v` uncovered four structural vulnerabilities:

| ID | Vulnerability | CWE | STRIDE | DREAD | Severity |
|----|-------------|-----|--------|-------|----------|
| SEC-1 | TOCTOU race condition — config registers writable during active transfer | CWE-362, CWE-787 | Tampering | 8/10 | Critical |
| SEC-2 | Missing start authentication — any bus write launches DMA without verification | CWE-284 | EoP, Tampering | 7/10 | High |
| SEC-3 | TX residual data leakage — last byte lingers on output pins after transfer ends | CWE-226 | Info Disclosure | 5/10 | Medium |
| SEC-4 | RX stale buffer data — old capture data bleeds into shorter new transfers | CWE-212 | Info Disclosure | 6/10 | High |

#### SEC-1: TOCTOU Race Condition (DREAD 8/10)

Configuration registers (`COUNT`, `DIVISOR`, `mode`, `irq_enable`) were unprotected during active transfers. A malicious or buggy concurrent software thread could overwrite `COUNT` mid-transfer, causing the DMA to advance `byte_idx` past the end of the 32-byte buffer — a classic Time-Of-Check/Time-Of-Use race condition leading to out-of-bounds memory writes (CWE-787).

#### SEC-2: Missing Start Authentication (DREAD 7/10)

Any write to `CTRL[start]` immediately launched the DMA with no handshake or authentication. This allowed both rogue writes (any entity on the bus can trigger unintended transfers) and replay attacks (a recorded valid `CTRL` write can be replayed at an attacker-chosen moment).

#### SEC-3: TX Residual Data Leakage (DREAD 5/10)

After a TX transfer, `uo_out` retained the logic voltage of the last transmitted byte indefinitely. Any passive observer on the GPIO pins could sample the final byte of the payload — a CWE-226 violation of Confidentiality.

#### SEC-4: RX Stale Data in Buffer (DREAD 6/10)

The 32-byte buffer `dbuf` was never cleared between transfers. A new shorter capture left stale data from the prior session in the tail words — accessible to any process reading the full buffer. This CWE-212 cross-context memory aliasing violated both Confidentiality and Integrity.

### 4.3 Security Countermeasures Implemented

All four countermeasures were implemented directly in RTL, following the **Security by Design** principle — security properties are part of the hardware logic itself, not enforced by software conventions that can be bypassed.

#### SEC-1 Fix: Transfer-Active Write Lock (`cfg_write_ok`)

A single combinational wire gates every configuration write path:

```verilog
wire cfg_write_ok = (state != ST_RUN);
```

Any write attempt to `COUNT`, `DIVISOR`, `mode`, or `dbuf` while the DMA is running is silently ignored. No error signal is needed; no software change is required. Configuration is frozen at the exact moment the FSM enters `ST_RUN`.

**PPA cost:** 1 combinational wire + fewer than 5 AND gates — negligible.

#### SEC-2 Fix: Start-Unlock Key (`sec_key_valid`)

A new write-only register `SEC_KEY` at address `0x34` and a 1-bit status flip-flop implement a hardware handshake:

```verilog
6'h34: begin
    if (wr_byte0)
        sec_key_valid <= (data_in[7:0] == 8'hA5);
end
```

The key is **always consumed** on every `CTRL` write, giving it one-time-use semantics. Replay attacks fail because the replayed `CTRL` write finds `sec_key_valid = 0`. Rogue writes to `CTRL` without a preceding valid `SEC_KEY` write are silently ignored.

**Required software sequence:**
1. Write `0xA5` to `SEC_KEY` → arms the key
2. Write start bits to `CTRL` → DMA launches (key consumed)
3. Must re-arm for each subsequent transfer

**PPA cost:** 1 FF + 1 eight-bit comparator + 1 AND gate ≈ +2–3 standard cells.

#### SEC-3 Fix: TX Output Zeroization

The combinational block driving `uo_out` uses an explicit safe default:

```verilog
always @(*) begin
    tx_byte = 8'd0;  // Safe default in all non-TX-active states
    if (state == ST_RUN && dma_mode == 1'b1)
        tx_byte = dbuf[word_idx][byte_lane*8 +: 8];
end
```

`uo_out` is forced to `0x00` in the same clock cycle the FSM leaves `ST_RUN`. No sensitive byte can linger on the physical GPIO pins.

**PPA cost:** Zero — a default-zero assignment already existed; this makes the security intent architecturally explicit.

#### SEC-4 Fix: RX Buffer Zeroization at Transfer Start

When a valid RX transfer starts, all 8 words of `dbuf` are cleared in a single clock cycle:

```verilog
if (data_in[1] == 1'b0)  // RX mode
    for (i = 0; i < 8; i = i + 1) dbuf[i] <= 32'd0;
```

The synthesizer unrolls this into 8 parallel flip-flop resets. By the time the first byte arrives from `ui_in`, the buffer is guaranteed to be all zeros. Cross-context memory aliasing is completely eliminated.

**PPA cost:** Reset fanout on existing `dbuf` FFs — no new logic cells, < 0.5 % area from driver resizing.

### 4.4 DP3 vs DP2 — PPA Comparison

The counterintuitive result: despite adding security logic, DP3 is **smaller and faster** than DP2.

| Metric | DP2 | DP3 | Change |
|--------|-----|-----|--------|
| Standard cell count | 13,165 | 12,713 | **−3.43 %** |
| Standard cell area (µm²) | 84,074 | 81,645 | **−2.89 %** |
| Total power (mW) | 6.543 | 6.413 | **−1.99 %** |
| Setup slack (TT 25°C) | 2.972 ns | 4.467 ns | **+50.3 %** |
| Setup slack (worst, max_ss) | 0.748 ns | 1.380 ns | **+84.5 %** |
| Setup R2R slack (max_ss) | 0.748 ns | 3.379 ns | **+351 %** |
| Wire length (µm) | 225,599 | 219,602 | **−2.66 %** |
| Vias | 59,968 | 57,044 | **−4.87 %** |
| Max fanout violations | 212 | 165 | **−22.2 %** |

**Root causes of improvement:** The security features added only ≈ +3 cells. Simultaneously applied RTL optimizations (OPT-1..6) removed ≈ 54–68 cells. An SDC correction (`set_false_path` for the reset-synchronizer negedge FF) removed 26 auxiliary timing-repair and clock-tree cells. Routing improvements reduced 290 antenna cells. Net result: −452 cells, −2.89 % area.

### 4.5 Timing Violation Encountered and Resolved

The first DP3 OpenLane run produced a setup timing violation of −0.139 ns in the `max_ss_100C_1v60` corner on a fall→rise inter-clock path. The only negedge-clocked FF in the design is `rst_reg_n` in `project.v` — a reset synchronizer, not a data path. The violation arose because the new netlist placement positioned this FF further from its driven posedge FFs, increasing RC wire delay.

**Fix:** Added `set_false_path -fall_from [get_clocks clk] -rise_to [get_clocks clk]` to the SDC. This is architecturally correct: `rst_n` transitions exactly once per power cycle during initialization and does not require single-cycle timing. The fix eliminated the violation and increased the next-tightest path's margin to +1.380 ns.

### 4.6 Validation

**12/12 unit tests passed** — including direct security proof tests:
- Test 10: Writes to `COUNT`/`mode` during `ST_RUN` are silently ignored (SEC-1 proof)
- Test 11: `CTRL[start]` without prior `SEC_KEY = 0xA5` does not launch DMA (SEC-2 proof)
- Test 12: `sec_key_valid` cleared after every `CTRL` write — key cannot be reused (SEC-2 consumed key proof)

**Full-system SoC integration test passed:** A 52-byte hand-assembled RISC-V binary driven through the full TinyQV SoC (CPU + QSPI Flash + DMA) executed the SEC-2 authentication sequence and produced the expected byte stream on `uo_out`:

```
Captured:  [0x78, 0x56, 0x34, 0x12]
Expected:  [0x78, 0x56, 0x34, 0x12]
Result: PASS — Full SoC DMA integration test
```

---

## 5. Design Phase 4: Physical Design and Tapeout

**Duration:** Weeks 13–16 (April 9–22, 2026) · **Goal:** Netlist to manufacturable GDSII

### 5.1 Overview

Design Phase 4 took the security-hardened, PPA-optimized DP3 RTL through the complete physical design flow using **OpenLane2** on the SkyWater SKY130 HD standard cell library. The objective was a "DRC/LVS Clean" design — the bar for a manufacturable chip.

### 5.2 Synthesis Results

Yosys synthesis (technology mapping to SKY130HD liberty models) produced the following gate-level netlist statistics:

| Module | Cells (pre-PnR) | Role |
|--------|----------------|------|
| `tqvp_dma` | 1,598 | DMA peripheral (largest module) |
| `tinyqv_cpu` | 1,245 | RISC-V CPU |
| `tinyqv_decoder` | 725 | Instruction decoder |
| `tinyqv_registers` | 802 | 16 × 32-bit register file |
| `tinyqv_mul` | 462 | Hardware multiplier |
| `qspi_controller` | 329 | Quad-SPI engine |
| `tinyqv_mem_ctrl` | 370 | Memory arbiter |
| `tinyqv_core` | 624 | Execution core |
| `tinyqv_shifter` | 149 | Barrel shifter |
| `tinyqv_alu` | 92 | ALU |
| **Total design** | **6,918** | Pre-mapping cells |

### 5.3 Physical Design Flow

The OpenLane2 flow executed the following stages sequentially:

| Stage | Tool | Key Result |
|-------|------|-----------|
| Synthesis | Yosys | 6,918 pre-map cells → gate-level netlist |
| Floorplanning | OpenROAD | Die: 432 × 432 µm, Core: 426 × 424 µm |
| Placement | OpenROAD | 45.12 % core utilization |
| Clock Tree Synthesis (CTS) | OpenROAD | 149 clock buffers, 91 clock inverters |
| Routing | OpenROAD | 31 iterations to DRC-clean |
| Timing repair (post-route) | OpenROAD | 125 timing-repair buffers |
| STA (post-PnR) | OpenSTA | Zero violations all corners |
| DRC | Magic | 0 errors |
| LVS | Netgen | 0 errors |
| IR drop | OpenROAD | Worst drop: 113.9 µV (< 0.01 % of 1.80 V) |
| GDSII export | Magic | Final manufacturable layout |

### 5.4 Floorplan and Power Grid

- **Die boundary:** 0, 0 → 432.0, 432.0 µm
- **Core boundary:** 2.76, 2.72 → 429.18, 427.04 µm
- **I/O pins:** 43 floorplan I/Os, 45 total design I/Os
- **Core utilization:** 45.12 % (12,713 stdcells + fill cells in 180,939 µm² core)
- **Power grid:** Zero violations on both VPWR and VGND nets

### 5.5 Clock Tree Synthesis

| CTS Metric | Value |
|-----------|-------|
| Clock buffers | 149 |
| Clock inverters | 91 |
| Worst clock skew (setup) | −0.415 ns |
| Worst clock skew (hold) | −0.156 ns |

### 5.6 Sign-off Results

#### Static Timing Analysis (STA)

All nine PVT corners analyzed with **zero timing violations**:

| Corner | Setup WS (ns) | Hold WS (ns) | Violations |
|--------|-------------|-------------|-----------|
| nom_tt_025C_1v80 | 4.467 | 0.327 | 0 |
| nom_ss_100C_1v60 | 1.860 | 0.654 | 0 |
| nom_ff_n40C_1v95 | 5.092 | 0.205 | 0 |
| max_ss_100C_1v60 | **1.380** | 0.655 | **0** |
| max_ff_n40C_1v95 | 5.075 | 0.206 | 0 |
| min_tt_025C_1v80 | 4.491 | 0.326 | 0 |
| min_ss_100C_1v60 | 2.277 | 0.654 | 0 |
| min_ff_n40C_1v95 | 5.109 | 0.204 | 0 |
| max_tt_025C_1v80 | 4.444 | 0.327 | 0 |

The tightest corner (max_ss_100C_1v60) has **1.380 ns of setup margin** — 6.9 % of the 20 ns clock period — with zero violations.

#### Register-to-Register Timing (Intrinsic Logic Performance)

| Corner | R2R Setup WS (ns) |
|--------|------------------|
| nom_tt_025C_1v80 | 6.935 |
| max_ss_100C_1v60 | 3.379 |
| nom_ff_n40C_1v95 | 7.150 |

#### DRC and LVS

| Check | Result |
|-------|--------|
| Magic DRC errors | **0** |
| Magic illegal overlaps | **0** |
| LVS device mismatches | **0** |
| LVS net mismatches | **0** |
| LVS property failures | **0** |
| LVS total errors | **0** |

The design is **DRC/LVS clean** — it meets the bar for a manufacturable chip.

#### Antenna and Power Integrity

| Check | Result |
|-------|--------|
| Antenna-violating nets | 0 |
| Antenna-violating pins | 0 |
| Antenna diodes inserted | 4 |
| Worst IR drop (VPWR) | 113.9 µV |
| Average IR drop | 9.9 µV |
| Power grid violations | 0 |

The worst-case IR drop of **113.9 µV** is 0.0063 % of the 1.80 V supply — far below the 1 % budget of 18 mV. Power grid integrity is excellent.

---

## 6. Final PPA Metrics

### 6.1 Progressive PPA Evolution (DP1 → DP4)

| Metric | DP1 (Baseline) | DP2 (Optimized) | DP3 (Secured) | DP4 (Final Tapeout) |
|--------|---------------|----------------|--------------|---------------------|
| Std cell count | 13,981 | 13,165 | 12,713 | **12,713** |
| Std cell area (µm²) | 87,735 | 84,074 | 81,645 | **81,645** |
| Core utilization | 48.49 % | 46.47 % | 45.12 % | **45.12 %** |
| Total power (mW) | 6.432 | 6.543 | 6.413 | **6.413** |
| Setup WS, SS corner (ns) | 1.684 | 0.916 | 1.380 | **1.380** |
| Setup violations | 0 | 0 | 0 | **0** |
| Hold violations | 0 | 0 | 0 | **0** |
| Wire length (µm) | 257,132 | 225,599 | 219,602 | **219,602** |
| Via count | 63,396 | 59,968 | 57,044 | **57,044** |
| Routing iterations | 22 | 7 | 31 | **31** |
| DRC errors | 0 | 0 | 0 | **0** |
| LVS errors | 0 | 0 | 0 | **0** |
| Security vulnerabilities | 4 | 4 | 0 | **0** |

### 6.2 Power Breakdown (Final, TT 25°C 1.80 V)

| Component | Power | Fraction |
|-----------|-------|---------|
| Internal (gate switching) | 4.389 mW | 68.4 % |
| Switching (net toggling) | 2.024 mW | 31.6 % |
| Leakage | 80.9 nW | < 0.01 % |
| **Total** | **6.413 mW** | 100 % |

### 6.3 Area Breakdown (Post-PnR)

| Cell Class | Count | Fraction |
|-----------|-------|---------|
| Multi-input combinational | 3,926 | 30.9 % of logic |
| Sequential (flip-flops) | 1,300 | 10.2 % of logic |
| Buffers | 431 | 3.4 % |
| Inverters | 95 | 0.75 % |
| Timing-repair buffers | 125 | 0.98 % |
| Clock buffers | 149 | 1.17 % |
| Clock inverters | 91 | 0.72 % |
| Antenna cells | 4,068 | 32.0 % |
| Fill cells | 12,112 | — |
| Tap cells | 2,528 | — |

### 6.4 Final Performance Summary

| Dimension | Final Value | Notes |
|-----------|------------|-------|
| **Technology** | SKY130 HD, 130 nm | SkyWater PDK |
| **Clock frequency** | 50 MHz (20 ns) | Zero violations across all PVT corners |
| **Timing margin (worst)** | 1.380 ns | max_ss_100C_1v60 corner |
| **Area (core)** | 81,645 µm² | 45.12 % utilization |
| **Power** | 6.413 mW | At TT corner, 50 MHz, 1.80 V |
| **Wire length** | 219,602 µm | Post-route |
| **Sign-off status** | **DRC/LVS Clean** | Manufacturable |

---

## 7. Security Features Summary

The final design incorporates four hardware security countermeasures in `tqvp_dma.v`, all implemented at the RTL level using a **Security by Design** philosophy:

### 7.1 Defense Layer Overview

| ID | Feature | Mechanism | Attack Prevented |
|----|---------|-----------|-----------------|
| SEC-1 | Transfer-active write lock | `cfg_write_ok` wire gates all config writes during `ST_RUN` | TOCTOU race condition, mid-transfer config corruption |
| SEC-2 | One-time start-unlock key | `SEC_KEY = 0xA5` must precede every `CTRL[start]` write | Rogue writes, replay attacks, unauthorized DMA launches |
| SEC-3 | TX output zeroization | `uo_out` forced to `0x00` in all non-TX-active states | Residual data leakage on output pins |
| SEC-4 | RX buffer zeroization | All 256 bits of `dbuf` cleared at every RX transfer start | Stale data from previous sessions leaking to new captures |

### 7.2 Security by Design Principles Applied

1. **Fail-safe defaults:** `uo_out` defaults to zero; `sec_key_valid` defaults to 0 at reset
2. **Least privilege:** Configuration registers inaccessible during active transfers
3. **Defense in depth:** Multiple independent countermeasures — disabling one does not defeat the others
4. **Zero software dependency:** All countermeasures enforced by hardware logic, not software conventions

### 7.3 Threat Model Coverage

| CIA Property | Threats Addressed |
|-------------|-----------------|
| **Confidentiality** | SEC-3 (TX leakage), SEC-4 (RX stale data) |
| **Integrity** | SEC-1 (TOCTOU config corruption), SEC-2 (unauthorized control) |
| **Availability** | SEC-2 (prevents DoS via rogue transfer launches) |

### 7.4 PPA Cost of Security (Isolated)

| Countermeasure | Cells Added | Area Added |
|---------------|------------|-----------|
| SEC-1 (write-lock wire) | 0 (pure wire) | < 1 µm² |
| SEC-2 (key FF + comparator) | +3 | ≈ +15 µm² |
| SEC-3 (TX zeroization) | 0 | 0 |
| SEC-4 (RX buffer clear) | 0 | reset fanout only |
| **Total security overhead** | **≈ +3 cells** | **< 0.02 % of total area** |

The security features cost approximately 3 standard cells in isolation — a negligible overhead relative to the 12,713-cell design.

---

## 8. Reflections on the Process

### 8.1 What Worked Well

**Iterative RTL refinement:** The practice of writing explicit, readable RTL in Phase 1 — even if not area-optimal — gave us a clear baseline to measure against in Phase 2. The trade-off between code clarity and synthesis quality became very tangible when comparing the 32-case nested decoders against variable part-selects.

**Security as a design phase, not an afterthought:** Treating security as its own structured phase (with formal threat modeling frameworks) revealed vulnerabilities that would not have been found through functional testing alone. The TOCTOU race condition (SEC-1) is particularly hard to catch in simulation because it requires a specific concurrent timing of bus writes during active transfers.

**Concurrent optimization and hardening:** By applying RTL optimizations and security countermeasures in the same phase (DP3), we achieved a design that was simultaneously more secure, smaller, faster, and more power-efficient than DP2. This demonstrates that security does not inherently conflict with PPA goals.

**AI-assisted development:** Claude Code significantly accelerated RTL code generation, testbench development, and debugging. The key discipline was treating AI output as a starting point to be reviewed and verified — not a final product. Every AI-generated snippet was analyzed, tested, and refined before integration.

### 8.2 Challenges Encountered

**Verilator compatibility:** Migrating from Icarus Verilog to Verilator for simulation exposed two compatibility issues — a bit-indexing VPI difference and a reserved keyword conflict (`buf` → `dbuf`). Both were resolved, but the lesson is that simulator portability should be considered at the testbench design stage.

**Timing violation in DP3:** The −0.139 ns setup violation in the `max_ss_100C_1v60` corner after security/optimization changes was a placement-sensitivity issue for the reset-synchronizer negedge FF. The fix (`set_false_path`) was architecturally correct but required a thorough understanding of both the STA tool's constraint semantics and the design intent of the negedge register. This is the kind of subtle issue that doesn't appear in functional simulation.

**Power counter-intuition in DP2:** The +1.72 % power increase despite −5.84 % cell count was initially surprising. The root cause — cell-type migration to higher drive-strength cells when replacing flat MUX trees with subtractors — became clear only through careful analysis of the cell type breakdown. This reinforced the importance of examining all three PPA axes together, not optimizing for one in isolation.

**Routing iteration increase in DP3 (31 vs 7 in DP2):** Even though DP3 had fewer and smaller cells than DP2, the router required more iterations. This is likely due to changes in placement topology from the SDC fix: releasing the false timing pressure on the reset-synchronizer path changed which cells the placer prioritized, creating a different (though equally valid) physical arrangement that the router had to work harder to connect cleanly.

### 8.3 Lessons Learned

1. **Measure everything, assume nothing.** The counter-intuitive PPA results (power increase with area decrease, timing regression with cell count reduction) demonstrate that EDA tools are non-linear systems. Metrics must be measured empirically, not predicted from first principles alone.

2. **SDC correctness matters as much as RTL correctness.** An incorrect timing constraint can cause the tool to insert unnecessary buffering, artificially inflate area and power, and produce misleading sign-off results. Correctly classifying the negedge reset synchronizer as a false path improved timing margin by +2.6 ns in the worst corner.

3. **Security overhead is not inevitable.** The common assumption that security features increase area and power is only true in isolation. When security hardening is performed alongside RTL optimization, the net PPA impact can be negative — as demonstrated by the DP3 results.

4. **Test at every level.** Unit tests verified DMA isolation correctness. System integration tests verified that the authenticated launch sequence worked end-to-end through the CPU, bus fabric, and QSPI memory hierarchy. Both levels were necessary — the system test revealed a QSPI startup race condition that was invisible at the unit level.

5. **Physical design is iterative.** The 31-iteration routing run in DP4 shows that even a clean, optimized netlist requires significant tool effort to achieve a DRC-clean layout. The sign-off criteria (DRC/LVS clean, zero timing violations across all corners) are non-trivial targets that require understanding both the design and the tool flow.

### 8.4 Future Work

Given more time, the following improvements would be worth pursuing:

- **Higher clock frequency target:** The current 50 MHz target leaves significant timing margin (1.38 ns in the worst corner). A 60–65 MHz target would be achievable with the current optimized netlist.
- **Power optimization:** Enabling clock gating on idle DMA state registers could reduce switching power during quiescent periods. The DMA spends most of its time in `ST_IDLE`.
- **Extended DMA feature set:** Multi-channel DMA with independent base addresses, scatter-gather support, or AHB/APB bus compatibility would significantly increase the peripheral's utility.
- **Formal verification of security properties:** While the simulation proves the countermeasures work for the test cases exercised, formal property checking (using tools like SymbiYosys) would provide exhaustive mathematical proof of the TOCTOU protection and key consumption invariants.

---

## 9. References

### Standards and Frameworks

- CWE-362: Concurrent Execution using Shared Resource with Improper Synchronization ('Race Condition') — MITRE Corporation
- CWE-226: Sensitive Information in Resource Not Removed Before Reuse — MITRE Corporation
- CWE-212: Improper Removal of Sensitive Information Before Storage or Transfer — MITRE Corporation
- CWE-284: Improper Access Control — MITRE Corporation
- STRIDE Threat Modeling — Microsoft Security Development Lifecycle
- DREAD Risk Assessment Model — Microsoft Security Engineering

### Tools and Platforms

- OpenLane2 Physical Design Flow — efabless Corporation
- Yosys Open Synthesis Suite v0.46
- Verilator v5.032 — Wilson Snyder
- cocotb v1.9.2 — cocotb contributors
- SkyWater SKY130 Process Design Kit — SkyWater Technology / Google

### Design References

- TinyQV RISC-V CPU — Michael Bell (Apache-2.0 licence)
- Tiny Tapeout Platform — https://tinytapeout.com
- AI-HDL 2026 Program — University of Arizona PRISM Lab — https://csm.arizona.edu/AIHDL

### DMA Architecture

- *Direct Memory Access (DMA) Controller in Computer Architecture* — GeeksforGeeks
- *Direct Memory Access (DMA) in Embedded Systems* — Open4Tech

---

<!-- *Report prepared by ICLab_HUST — Hanoi University of Science and Technology*

*AI-HDL 2026 Design Phase 4 — Milestone Review 4 (MR#4) — April 23, 2026*

*AI tools (Claude Code, Anthropic) were used in the preparation of this report and throughout the design process. All results and metrics are derived from actual tool outputs captured in `metrics.csv` files and OpenLane sign-off reports.* -->
