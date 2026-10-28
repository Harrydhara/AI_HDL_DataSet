# Challenges Faced — DP2: PPA Optimization

## Overview

DP2 focused on closing the SS corner timing violation identified in DP1 (WNS −2.48 ns, 2,757 violations) while reducing power through clock gating. Over 15 OpenLane runs, the team resolved a cascading series of technical challenges — each fix exposing the next constraint. The final result (R-PW1v2) achieves WNS nom_ss = +0.900 ns, setup violations = 0, hold violations = 0, internal power −34.1%, DRC = 0.

---

## 1. Identifying the True Critical Path

**Challenge:** The DP1 baseline had WNS −2.48 ns at SS corner with 2,757 violations. The initial assumption was that the clock period (20 ns) was simply too tight. However, Run 2 (die expansion + USE_LIGHTER, no RTL change) improved WNS to −1.73 ns with 389 violations — significant improvement from config alone. This suggested the critical path was addressable by RTL restructuring, not just synthesis constraints.

**Investigation:** OpenSTA timing reports identified two cascading paths:
- `element_wise.v`: 32×32 Q16.16 multiply → truncation → accumulate → m_buffer — 3 logic stages in one cycle
- `matrix_filter.v`: COMPUTE_GG adder chain → COMPUTE_GGGT adder chain — two add stages crossing state boundary with no pipeline register

**Solution:**
- **Case 2b:** Inserted `fp_mult_reg` between multiply and accumulate stages in `element_wise.v`. Stage 1 (cycle N): compute fp_mult. Stage 2 (cycle N+1): accumulate. Eliminates the multiply from the timing cone entirely.
- **Case 2a:** Inserted `PIPELINE_WAIT` state (3'd5) between `COMPUTE_GG` and `COMPUTE_GGGT` in `matrix_filter.v`. Splits the two-adder chain across two clock cycles.

**Result:** TNS ss −622.7 → −7.8 ns (Run 4). Combined with DELAY 0 synthesis (Run R-DELAY0): WNS +0.121 ns — first timing closure. With PW-1: WNS +0.900 ns.

---

## 2. SYNTH_STRATEGY AREA 1 Could Not Close Timing

**Challenge:** After applying Case 2a+2b RTL fixes, Runs 4–7 still showed negative WNS at SS corner (best: −0.975 ns, Run 4). AREA 1 synthesis optimizes for minimum cell area and defers all timing repair to post-placement resizing. At this design size (70K+ cells) and 50 MHz on sky130A SS corner, the post-placement resizer could not compensate for the remaining 1 ns+ gap.

**Solution:** Changed `SYNTH_STRATEGY` from `AREA 1` to `DELAY 0`. DELAY 0 instructs Yosys to select fast drive-strength cells during technology mapping, reducing the critical path before placement begins. This single change (Run R-DieXL → R-DELAY0) moved WNS from −1.04 to +0.121 ns.

**Cost:** Instance count increased ~10%, switching power +3 mW (larger cells have higher input capacitance). These costs were accepted as necessary for timing closure.

**Result:** WNS nom_ss = +0.121 ns (R-DELAY0) → +0.900 ns (R-PW1v2 with PW-1 added).

---

## 3. PW-1 Clock Gating — Three Iterations to Get Right

**Challenge:** Implementing clock gating on `matrix_input.v` and `matrix_output.v` required separating register writes from the FSM to allow synthesis to infer ICG cells. Three distinct failure modes were encountered across iterations:

**Iteration v1 — Hold violations (R-PW1a):**
Separated into 4 always blocks (FSM block + one block per register array). Synthesis inferred ICG cells correctly, but the register array blocks had shorter combinational paths than the FSM block. The timing tool saw path imbalance → hold violations in nom_tt, min_tt, max_tt corners. `QUIT_ON_HOLD_VIOLATIONS: False` was added but did not resolve the structural issue.

**Iteration v2 — Functional TIMEOUT:**
Rewrote as single always block with `wire active = (state != IDLE) || start` guarding the entire case statement. Simulation in tb_input returned TIMEOUT — the FSM never received `start=1` because `active=0` when `state=IDLE` and `start=0`, gating the very transition that should respond to `start`. The gate was too broad.

**Iteration v3 — Final clean solution:**
Separated into: (1) FSM always block — runs every cycle, no gating; (2) three register array always blocks, each with a per-state enable wire (`d_we`, `tmp_we`, `v_we`). FSM block has full combinational depth → no hold imbalance. Register blocks are gated only when their state is active → ICG inferred per array. Functional: PASS. Hold violations: 0. ICG cells: 360.

**Result:** R-PW1v2 — WNS nom_ss +0.900 ns, hold vio = 0, internal power −34.1%.

---

## 4. RePlAce Global Placement Divergence

**Challenge:** Four runs encountered `GPL-0307: RePlAce divergence` during global placement. The error is caused by the placement engine failing to converge when the design's effective density exceeds the available legal positions at the target density setting.

The first occurrence (P-2 run at die 1900×520, density 63%) showed HPWL 1.4B at Iter 470 before diverging — the same HPWL appeared in subsequent runs with `GPL_MAX_PHI_COF` tuning, confirming phi_cof was not the root cause.

**Solution process:**
- `GPL_MAX_PHI_COF: 5` → same HPWL, same divergence point (phi_cof slows convergence, does not fix density)
- `GPL_MAX_PHI_COF: 4` → identical result
- `PL_TARGET_DENSITY_PCT: 58` (removed phi_cof) → HPWL improved to 1.24B but still diverged
- **Die expansion to 2100×560** (+19% area) → convergence achieved

**Root cause:** Adding `PIPELINE_WAIT_BTD` in P-2 increased the design's synthesized area enough to push the 1900×520 die above its convergence threshold. The tool's `GPL-0302` suggested density message (65% for the antenna run) was the correct signal — when the tool suggests a density, use it directly.

**Result:** P-2 converged at die 2100×560 but WNS degraded to +0.575 ns vs R-PW1v2 +0.900 ns. P-2 was not included in final submission.

---

## 5. Antenna Violations Would Not Reach Zero

**Challenge:** R-PW1v2 completed with 20 antenna violations. Initial expectation was that reducing `HEURISTIC_ANTENNA_THRESHOLD` would drive violations to 0. Five runs tested thresholds from 200 down to 90:

| Threshold | Violations | Diode cells | Power | WNS |
|-----------|-----------|-------------|-------|-----|
| 200 (R-PW1v2) | 20 | 19,802 | 38.16 mW | +0.900 ns |
| 150 | 10 | 32,669 | 38.04 mW | +0.159 ns |
| 110 | 9 | 42,615 | 38.67 mW | +0.185 ns |
| 95 | 3 | 49,119 | 39.32 mW | +0.323 ns |
| 90 | 2 | 47,605 | 39.09 mW | +0.002 ns |

Analysis of `antenna.rpt` revealed the underlying cause: all 20 violations are met3 side-area ratio violations on nets with structurally long routing segments. Two violations persist at threshold 90 on `clknet_2_2__leaf__*` — clock nets that the router cannot re-route. The remaining 18 violations converge to ~9 nets that are structurally unmovable regardless of threshold.

Adding `DIODE_PADDING: 2` to force diode placement caused `DPL-0036 Detailed placement failed` — not enough physical space for the inserted diode cells. `GPL_CELL_PADDING: 4` with density 65% resolved the placement but further increased instance count to ~99,884 cells.

**Solution:** Accept 20 violations from R-PW1v2. Worst ratio 4.4× is borderline. DRC=0, Magic DRC=0, LVS=0. Within TinyTapeout fab tolerance (<50–100 violations at this ratio level).

---

## 6. Cocotb v2.1.0 Compatibility Failures

**Challenge:** After upgrading the simulation environment to OSS CAD Suite with cocotb 2.1.0, existing testbenches produced incorrect output values with no exceptions or obvious error messages. The failures were silent — simulation completed but results were wrong.

**Root cause:** cocotb 2.1.0 removed the `_BitHandle` class used for packed signal index access (`port.value[i]`), and changed `port.value` to return a `LogicArray` object instead of an integer. Code in `tqv.py` and `tqv_reg.py` was reading signal values without conversion, producing `LogicArray` comparison failures that evaluated to unexpected truthy/falsy values.

**Solution:**
- Added `_BitHandle` wrapper class in `tqv.py` to restore packed signal indexing behavior
- Added explicit `int()` conversion on all `port.value` reads in `tqv.py` and `tqv_reg.py`
- Fixed declaration order in `interface.v` — `feed_state` localparams must be declared before wire assignments that reference them (iverilog strict ordering)

**Result:** All cocotb tests PASS after fixes. Lesson: when simulation results are wrong but no exception is raised, suspect API-level type changes in the simulation framework.
