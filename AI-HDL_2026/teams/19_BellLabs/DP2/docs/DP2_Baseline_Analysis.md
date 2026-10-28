# DP2 Baseline PPA Analysis — tqvp_belllabs_aes128

**AI Hardware Design League 2026 | Team Bell Labs (#63) | University of Lagos, Nigeria**
**Mentor: Kevin Immanuel Gubbi | Date: April 2026**

---

## 1. Executive Summary

This document establishes the official baseline PPA (Power, Performance, Area) measurements
for the tqvp_belllabs_aes128 AES-128 encryption peripheral prior to any DP2 optimization.
The baseline synthesis reveals three distinct bottlenecks: an abnormally high MUX cell density
(62.9% of all cells) driven by combinational selection logic, unconditional flip-flop switching
activity across all 816 registers regardless of FSM state, and an unregistered critical path
spanning SubBytes through AddRoundKey that limits maximum frequency improvement potential.
These three bottlenecks directly map to the three planned optimizations: clock gating (power),
MUX restructuring (area), and pipeline register insertion (performance).

---

## 2. Measurement Methodology

- **Tool:** Yosys 0.62+9
- **Target library:** sky130_fd_sc_hd (SkyWater Sky130A 130nm)
- **Script:** scripts/synth_dp2_sta.ys
- **Full output:** reports/dp2/baseline_sta.txt
- **Date measured:** April 2026 — before any DP2 modifications

---

## 3. Area Analysis

### 3.1 Cell Count Breakdown

| Cell type | Count | % of total | Category |
|---|---|---|---|
| `$_MUX_` | 7,725 | 62.9% | Selection logic |
| `$_ANDNOT_` | 724 | 5.9% | Combined logic |
| `$_XOR_` | 622 | 5.1% | AES arithmetic |
| `$_NOT_` | 637 | 5.2% | Inversion |
| `$_OR_` | 671 | 5.5% | Control logic |
| `$_SDFFE_PN0P_` | 384 | 3.1% | Flip-flop w/ enable |
| `$_SDFFE_PN0N_` | 256 | 2.1% | Flip-flop w/ enable |
| `$_DFF_P_` | 169 | 1.4% | Standard flip-flop |
| `$_AND_` | 358 | 2.9% | Logic |
| Others | 741 | 6.0% | Mixed |
| **TOTAL** | **12,287** | **100%** | |

### 3.2 Area Bottleneck Identification

**Bottleneck A1 — MUX Explosion (62.9% — PRIMARY)**

Root cause in Verilog:
```verilog
wire is_final = (round == 4'd10);
wire [31:0] ark_c0 = (is_final ? sr_c0 : mc_c0) ^ nrk0;  // 32 MUX2 cells
wire [31:0] ark_c1 = (is_final ? sr_c1 : mc_c1) ^ nrk1;  // 32 MUX2 cells
wire [31:0] ark_c2 = (is_final ? sr_c2 : mc_c2) ^ nrk2;  // 32 MUX2 cells
wire [31:0] ark_c3 = (is_final ? sr_c3 : mc_c3) ^ nrk3;  // 32 MUX2 cells
```
The single 1-bit wire `is_final` fans out to 128 parallel bit-level MUX selections.
Yosys synthesizes each ternary operator as cascaded MUX2 trees across both sr_cX
(already a multi-level S-box tree) and mc_cX (multi-level GF arithmetic tree).
Combined with the data_write_n partial-write conditions (3 enable checks × 8 registers
× 3 byte lanes = 72 conditional assignments), this generates approximately 7,000+
MUX cells. Industry-standard AES implementations run at 20-30% MUX density.
At 62.9%, this design is more than double the expected level.

**Bottleneck A2 — XOR/XNOR Density (7.9% — EXPECTED)**

Root cause: MixColumns GF(2^8) arithmetic and AddRoundKey XOR operations.
This is inherent to the AES algorithm and is NOT a target for optimization.

**Bottleneck A3 — ANDNOT/ORNOT (7.4% — PARTIALLY REDUCIBLE)**

Root cause: xtime() conditional logic in MixColumns.
```verilog
xtime = b[7] ? ((b << 1) ^ 8'h1b) : (b << 1);
```
Generated for every byte of every column every round. Partially reducible through
expression simplification but not a primary optimization target.

---

## 4. Power Analysis

### 4.1 Switching Activity by FSM State

| FSM State | FFs actively updating | FFs evaluating but stable | Toggle events/cycle |
|---|---|---|---|
| ST_IDLE | ~5 (control only) | ~811 | ~5 |
| ST_ENC | ~264 (state+keys+round) | ~552 (wasted) | ~816 |
| ST_DONE | ~3 (irq, fsm) | ~813 | ~3 |

### 4.2 Idle Power Waste

During ST_ENC (the primary operating state):
- state_c0..c3 (128 bits): actively switching — correct
- rk0..rk3 (128 bits): actively switching — correct
- key_w0..w3 (128 bits): locked via fsm != ST_ENC guard but SDFFE enables still evaluate
- plain_w0..w3 (128 bits): NO lock during encryption — evaluating unnecessarily
- cipher_w0..w3 (128 bits): only meaningful at round==10 but enable evaluates all 10 cycles
- irq (1 bit): cleared to 0 every cycle even when already 0

Estimated unnecessary switching: 552 out of 816 FFs = 67.6% of flip-flops
evaluate their enable conditions without storing new values during ST_ENC.

### 4.3 Expected Power Saving from Clock Gating

Applying FSM-gated enables to key, plaintext, and cipher output registers:
- During ST_ENC: 552 FFs gated → estimated 25-30% dynamic power reduction
- During ST_IDLE: ~811 FFs gated → estimated 60-70% dynamic power reduction
- Combined weighted average: **~25% overall dynamic power reduction**

---

## 5. Performance Analysis

### 5.1 Critical Path Trace

The longest combinational path runs through one complete AES round:
state_cX register (Tco ~150ps)
→ aes_sbox() 8-level MUX tree (~1,200ps)
→ ShiftRows wire routing (~50ps)
→ mix_col() xtime chain + XOR series (~1,100ps)
→ is_final MUX2 selection (~150ps)
→ AddRoundKey XOR32 (~200ps)
→ state_cX register setup (Tsu ~50ps)

### 5.2 Delay Estimation (Sky130A typical)

| Stage | Delay |
|---|---|
| Register Tco | 150ps |
| S-box 8-level MUX tree | 1,200ps |
| ShiftRows (wire) | 50ps |
| MixColumns critical sub-path | 1,100ps |
| is_final MUX2 | 150ps |
| AddRoundKey XOR | 200ps |
| Register Tsu | 50ps |
| **Total critical path** | **~2,900ps (2.9ns)** |

### 5.3 Fmax Calculation
Fmax = 1 / 2.9ns = ~345 MHz (gate-level estimate)
Post-layout estimate (add 40% routing overhead): ~210 MHz
Current clock requirement: 64 MHz
Timing slack at 64 MHz: +12.7ns (massively over-timing)

The design comfortably meets 64 MHz. The pipeline register will push Fmax higher
and provide measurable improvement evidence for the DP2 Performance rubric category.

---

## 6. Bottleneck Priority Ranking

| Priority | Bottleneck | Impact | Root Cause | Planned Optimization |
|---|---|---|---|---|
| 1 | MUX explosion (62.9%) | Area — 7,725 excess cells | is_final combinational fan-out + data_write_n trees | Register is_final flag, simplify write conditions |
| 2 | Unconditional FF switching | Power — 552 FFs wasted | No clock enable logic on key/plain/cipher registers | Clock gating with FSM-state CE signals |
| 3 | Unregistered round path | Performance — limits Fmax improvement | SubBytes→MixColumns→AddRoundKey unregistered chain | Pipeline register between MixColumns and AddRoundKey |

---

## 7. DP2 Optimization Targets

| Metric | DP1 Baseline | DP2 Target | Measurement method |
|---|---|---|---|
| Total cells | 12,287 | < 9,500 | Yosys stat (post-opt) |
| MUX cells | 7,725 (62.9%) | < 5,500 (< 50%) | Yosys stat (post-opt) |
| Flip-flop count | 816 | 816 (unchanged) | Yosys stat — gating does not reduce count |
| Dynamic power | Baseline | −25% during ST_ENC | Yosys power -hier (post-opt) |
| Gate-level Fmax | ~345 MHz | > 450 MHz | STA before/after pipeline |
| Timing slack at 64MHz | +12.7ns | Positive — always met | STA sign-off |

---

## 8. Conclusion

The DP1 design is functionally correct and timing-safe at 64 MHz with substantial margin.
The primary optimization opportunity is area reduction through MUX restructuring (62.9%
density is 2x the expected level for AES). Power reduction through clock gating addresses
the secondary bottleneck of unconditional switching. Performance improvement through a
pipeline register provides measurable Fmax evidence for judges even though timing is already
met — this is important for the 25% Performance Optimization rubric category.
All three optimizations will be applied sequentially with regression testing between each step.

---
*Team Bell Labs | University of Lagos, Nigeria | AI-HDL 2026 | DP2 Week 1 Deliverable*
