# ICLab_HUST2 — DP2 Submission: PPA Optimization

## Team Information
- **Team Name**: ICLab_HUST2
- **Institution**: Hanoi University of Science and Technology
- **Division**: Lower
- **Submission Tag**: DP2-Submission
- **Team Members**:
  - Member A — RTL Design, PPA Optimization & Verification Lead — [email]
  - Member B — Technical Research & Support — [email]
  - Member D — Technical Research & Support — [email]
  - Member C — Technical Research & Support — [email]
  - Member E — Technical Research & Support — [email]
- **Mentor**: [mentor]

## Challenge Summary

DP2 optimizes the Winograd $F(2\times2, 3\times3)$ convolution accelerator from DP1 for PPA on the SkyWater sky130A process. The primary DP1 issues — timing failure at SS corner (WNS −2.48 ns, 2,757 violations), 90% core utilization, and absent clock gating — are all resolved in the final submission R-PW1v2 after 15 OpenLane runs.

Note: Due to the large cell count, the baseline PPA run requires approximately 10 hours, while the optimized RTL run takes around 5 hours.

## DP2 Results Summary

| Metric | DP1 Baseline | DP2 R-PW1v2 | Change |
|--------|-------------|-------------|--------|
| WNS nom_ss (ns) | −2.48 | **+0.900** | +136% ✅ |
| WNS max_ss (ns) | −2.99 | **+0.784** | First positive ✅ |
| Setup violations (total) | 2,757 | **0** | −100% ✅ |
| Max fmax nom_ss | 44.5 MHz | **54.5 MHz** | +22.5% ✅ |
| Internal power | 23.08 mW | **15.22 mW** | −34.1% ✅ |
| ICG clock gate cells | 0 | **360** | Implemented ✅ |
| Core utilization | 90.0% | **58.1%** | −35% ✅ |
| Hold violations | 0 | **0** | Clean ✅ |
| DRC / LVS / Magic DRC | 0/0/0 | **0/0/0** | Clean ✅ |
| Power total | 30.95 mW | 38.16 mW | +23% ⚠️ (documented trade-off) |
| Fanout violations | 1,334 | 1,104 | −17% ⚠️ |
| Antenna violations | 24 | 20 | ⚠️ (structural, non-functional) |

## RTL Optimizations

### Case 2a — matrix_filter.v: PIPELINE_WAIT State (P-1)
Added FSM state `PIPELINE_WAIT` (3'd5) between `COMPUTE_GG` and `COMPUTE_GGGT`. Splits the two-adder-chain critical path across two clock cycles. Effect: eliminates the deepest combinational path from the timing cone. Cost: +1 cycle per filter load.

### Case 2b — element_wise.v: 2-Stage fp_mult Pipeline (P-1 / PW-2 partial)
Registered `fp_mult` output into `fp_mult_reg`. Stage 1 (cycle N): u_in × v_in → `fp_mult_reg`. Stage 2 (cycle N+1): `fp_mult_reg` → accumulate `m_buffer`. Eliminates 32×32 multiplier from timing cone. Cost: +1 cycle per element.

### PW-1 — matrix_input.v + matrix_output.v: Clock Gating
Separated FSM always block (runs every cycle) from gated register array blocks (`d_we`, `tmp_we`, `v_we`). Synthesis infers ICG cells per array, gating clock when state is IDLE. Required 3 iterations: v1 (multi-block → hold violations) → v2 (if(active) wrap → TIMEOUT in tb) → v3 (separate FSM + gated register blocks, final clean).

### PW-3 — config.json: USE_LIGHTER=1
Enabled OpenLane automatic ICG synthesis from Run 2 onward. Synthesized 360 ICG cells. Internal power −34.1%.

## OpenLane Flow Optimizations

| Change | Run | Effect |
|--------|-----|--------|
| Die 1336→1700×480 µm | R2 | Utilization 90→56%, routing iterations 48→19 |
| USE_LIGHTER=1 | R2+ | 360 ICG cells, internal power −34% |
| Die 1700→1900×520 µm | R-DieXL | Utilization 49%, enables DELAY 0 stable placement |
| SYNTH_STRATEGY DELAY 0 | R-DELAY0 | WNS −1.04 → +0.121 ns (timing closure breakthrough) |
| Antenna threshold sweep | R-Ant90 to R-Ant95 | Plateau at 9–10 nets; accept 20 from R-PW1v2 |

## Optimization Plan Status

| ID | Technique | Status | Result |
|----|-----------|--------|--------|
| P-1 | Pipeline matrix_filter COMPUTE_GG→GGGT | ✅ Done | WNS −2.48 → +0.900 ns |
| P-2 | Pipeline matrix_input COMPUTE_BTD→BTDB | ⚠️ Tested | Needs larger die; WNS drops to +0.575 ns |
| P-3 | SYNTH_MAX_FANOUT tuning | ⚠️ Partial | 18→16; fanout 1,334→1,104 |
| A-1 | Register sharing matrix_filter | ❌ Skipped | 0.4% gain, high FSM refactor risk |
| A-2 | Remove debug wire u_matrix | ✅ Done | Dead code eliminated |
| A-3 | Register sharing matrix_input | ❌ Skipped | Incompatible with PW-1 structure |
| PW-1 | Clock gate matrix_input + matrix_output | ✅ Done (v3) | +360 ICG, internal −34.1% |
| PW-2 | Clock gate fp_mult / m_buffer | ⚠️ Partial | fp_mult_reg done; m_buffer gate pending |
| PW-3 | USE_LIGHTER auto ICG | ✅ Done | 360 ICG cells |

## Known Issues and Acceptability

**Power total +23% (38.16 mW):** Caused by ~1,892 USE_LIGHTER clock buffer cells toggling at 50 MHz (+15.1 mW switching). USE_LIGHTER is required for timing closure — 7 runs without it show switching 8–9 mW but 1,400–3,894 setup violations. Internal power improved 34.1%. IR drop = 0.000246 V (within spec). Non-functional, acceptable.

**Fanout violations 1,104:** Caused by DELAY 0 large drive-strength cells and antenna diode cell load. Timing fully closed (WNS +0.900 ns, vio=0, slew vio=4). Signal quality warning only — non-functional.

**Antenna violations 20 (met3 side-area):** All 20 are met3 side-area ratio violations (worst 4.4×, borderline). Threshold tuning runs confirmed structural routing plateau — threshold 90 achieved 2 violations but inserted 47,605 diode cells (+148%), degrading timing. DRC=0, Magic DRC=0, LVS=0. Within TinyTapeout fab tolerance. Non-functional.

## AI Tools Used

- **Claude Sonnet 4.5 / 4.6**: Primary tool for RTL optimization design (Case 2a, 2b, PW-1 iterations), OpenLane flow debugging (RePlAce divergence, hold violations, DPL-0036), PPA metrics analysis across 15 runs, cocotb v2 compatibility fixes, and DP2 report writing.
- **Gemini 2.5 Pro**: Supplementary tool for physical design parameter analysis and metrics interpretation.
- **Icarus Verilog / cocotb v2.1.0**: Functional simulation and system-level verification.
- **OpenLane 2.3.10**: RTL-to-GDSII flow (Yosys, OpenROAD, Magic, Netgen, KLayout).
- **Verilator**: Linting before each OpenLane submission.

## File Changes vs DP1

| File | Change |
|------|--------|
| `matrix_filter.v` | Case 2a: PIPELINE_WAIT state (3'd5) added |
| `element_wise.v` | Case 2b: fp_mult_reg 2-stage pipeline |
| `matrix_input.v` | PW-1 v3: FSM block + 3 gated register blocks |
| `matrix_output.v` | PW-1 v3: FSM block + 3 gated register blocks |
| `interface.v` | Declaration order fix for iverilog compatibility |
| `config.json` | DELAY 0, die 1900×520, USE_LIGHTER=1, density 63% |
| All other files | Unchanged from DP1 |

## Verification

- **tb_wino.v** (Icarus Verilog): PASS — all outputs match reference after +1 cycle pipeline latency compensation
- **cocotb v2.1.0** integration test: PASS — full TinyQV SPI bus, register map, filter/input/output verified
- **Verilator lint**: 0 errors, 0 inferred latches, 3 pre-existing non-critical warnings
- **DRC / LVS / Magic DRC**: 0 / 0 / 0

## Team Reflection

DP2 demonstrated that timing closure at SS corner requires coordinated changes at three levels simultaneously: RTL pipelining (reduce combinational depth), synthesis strategy (DELAY 0 for fast cell selection), and physical floorplan (die expansion for placement quality). No single change alone achieved closure — it took 8 runs to find the right combination.

The most unexpected finding was the USE_LIGHTER trade-off: enabling automatic clock gating improves placement quality enough to close timing, but the clock buffers it inserts increase total switching power significantly. This is a fundamental constraint of the sky130A flow at 50 MHz that cannot be avoided without comprehensive RTL-level clock gating (PW-1, PW-2) to compensate.

PW-1 required 3 iterations due to subtle RTL structure issues (multi-block short paths → hold violations; single-block FSM wrapping → TIMEOUT). The final v3 approach (separate FSM block + gated register blocks) is clean and generalizable to other modules in DP3.
