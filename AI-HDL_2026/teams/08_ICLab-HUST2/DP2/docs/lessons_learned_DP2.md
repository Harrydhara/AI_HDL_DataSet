# Lessons Learned — DP2: PPA Optimization

## 1. Timing Closure Is a System-Level Problem, Not a Single-Fix Problem

The most important lesson from DP2 is that SS corner timing closure required three changes to happen simultaneously — no single optimization was sufficient alone:

- **RTL pipelining alone (Case 2a+2b):** Best WNS with AREA 1 was −0.975 ns (Run 4) — not closed.
- **Die expansion alone:** Utilization improved but critical path remained the same.
- **SYNTH_STRATEGY DELAY 0 alone:** Without RTL pipelining, timing tools had nothing to fix.

Only when all three combined (RTL pipeline + die 1900×520 + DELAY 0) did WNS cross zero at +0.121 ns (Run R-DELAY0). PW-1 then brought it further to +0.900 ns by reducing hold-margin pressure and repair buffer count.

**Takeaway:** PPA optimization requires understanding how synthesis strategy, floorplan, and RTL structure interact. Changing one without the others often produces no improvement or makes things worse.

## 2. USE_LIGHTER Is a Two-Edged Tool

In DP1, USE_LIGHTER was unused. Enabling it in DP2 produced the single largest power improvement (internal power −34.1%, 360 ICG cells) but also the single largest power regression (switching +192%). The clock buffers that Lighter inserts to enable ICG synthesis each toggle at 50 MHz — this is the root cause of total power exceeding baseline.

The lesson: **clock gating at the flow level trades internal power for switching power**. The net result depends on the ratio of gated FFs to inserted buffers. For designs with dense register arrays (like our matrix_input/output), RTL-level clock gating (PW-1) is needed to complement PW-3 and recover the switching overhead.

## 3. RTL Structure Determines Whether Clock Gating Works

PW-1 required three iterations before working correctly:

- **v1 (multi-block, separate always per array):** Synthesis inferred ICG correctly but created short combinational paths between blocks → hold violations in nom_tt/min_tt corners. The FSM block had longer paths; register blocks had shorter — timing tools saw the imbalance.
- **v2 (single always block, `if (active)` wrapping entire case statement):** Synthesizer correctly inferred one ICG for the whole module, but `active = (state != IDLE)` gated the FSM transitions too — the module could never receive `start=1` and got stuck → TIMEOUT in tb_input.
- **v3 (separate FSM block + gated register blocks):** FSM runs every cycle (no gating), register arrays gated by per-state enable wires (`d_we`, `tmp_we`, `v_we`). Clean: hold=0, ICG inferred per array, functional.

**Takeaway:** Clock gating requires explicit understanding of which signal paths you are gating. Gating the wrong scope causes either hold violations (too many paths) or functional failures (too broad a gate). Separate FSM from data paths.

## 4. RePlAce Divergence Is a Density Signal, Not a Tool Bug

The `GPL-0307 RePlAce divergence` error appeared 4 times during DP2 (Runs with P-2 at die 1900×520). Each time, the HPWL value at divergence was similar (~1.2–1.4B), indicating the placer ran out of legal positions given the density constraint.

The fix is not `GPL_MAX_PHI_COF` tuning alone — that only slows convergence. The real fix is either: (1) increase die area, or (2) reduce density target below the tool's `Suggested target density` in the error message. After R-P2+PW1 required die 2100×560 to converge, we confirmed that the P-2 state addition increased the design's effective density beyond the 1900×520 threshold.

**Takeaway:** Always read the `GPL-0302` suggested density value — the tool tells you exactly what it needs. If the required density means die expansion, evaluate whether the resulting WNS degradation is worth it before running.

## 5. Antenna Violations Have a Structural Floor

We spent 5 runs (R-Ant90, R-Ant110, R-Ant95, plus two implicit attempts) trying to reach antenna violations = 0. The analysis of `antenna.rpt` revealed the answer: all 20 violations are met3 side-area ratio violations on nets that the router chose to route as long met3 segments. The router cannot re-route these nets to shorter paths without violating DRC elsewhere — they are topologically constrained.

Threshold tuning below 90 inserts 47,605+ diode cells (the R-Ant90 result) but still leaves 2 violations on the two clock nets where the router has zero flexibility. This is a hard floor.

**Takeaway:** Before running multiple antenna repair runs, read the antenna report and classify violations by layer and ratio. met3 side-area violations with ratio < 5× and no gate-area violations are likely structural — aggressive diode insertion will hurt power and fanout without reaching zero. Accept and document.

## 6. AI-Assisted PPA Analysis Requires Structured Prompting

During DP2, the most effective AI interactions followed a consistent pattern:
1. **Provide the full metrics.csv** — not a summary, the actual file
2. **State one specific hypothesis** ("I think the hold violations are caused by X — confirm or refute")
3. **Ask for the next run config change** based on the analysis

Generic prompts like "how do I improve timing?" were less effective than "Run 8 has WNS +0.121 ns but max_ss corner has −0.064 ns and 1 violation — what is causing the max_ss violation and what one config change addresses it specifically?"

The AI's value in DP2 was less in code generation and more in **cause-effect attribution across 15 runs** — identifying which metric changed due to which parameter.

## 7. Cocotb v2 Migration Is a Silent Breaking Change

After upgrading to cocotb 2.1.0 (OSS CAD Suite), the existing testbenches silently failed on packed signal indexing — `port.value[i]` returns a `LogicArray` in v2, not an integer, and `_BitHandle` class was removed. The failures appeared as incorrect output values, not exceptions, making them hard to diagnose.

**Fix:** Wrap all packed signal index accesses with `_BitHandle`, and add explicit `int()` conversion on all `port.value` reads in `tqv.py` and `tqv_reg.py`.

**Takeaway:** Pin simulation tool versions in the project requirements. When upgrading cocotb, explicitly check the CHANGELOG for `LogicArray`, `BinaryValue`, and signal access API changes.

## 8. Future Direction — DP3

DP2 has established a stable, timing-clean baseline for DP3. The 360 ICG cells and state-dependent switching patterns from PW-1 create a measurable power side-channel profile. The SPI register interface at `0x800_0380` is the primary attack surface. DP3 should begin with power trace analysis at different operational states (IDLE vs COMPUTE_BTD vs OUTPUT) to characterize leakage before attempting any countermeasures.
