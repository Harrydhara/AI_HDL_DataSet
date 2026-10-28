# DP4 Synthesis Summary — Final Physical Design
## Team ICLab_HUST2 | OpenLane2 Built-in Synthesis (sky130A, Yosys + ABC)

**Phase:** Design Phase 4 — Tape-out preparation  
**Tool:** OpenLane2 v2.x (step 06-yosys-synthesis, sky130_fd_sc_hd technology library)  
**Top module:** `tt_um_tt_tinyQV`  
**RTL baseline:** DP3-hardened  
**Note:** RTL is **identical to DP3**. DP4 advances from verified RTL to full physical implementation (synthesis → floorplan → placement → CTS → routing → sign-off → GDSII).

---

## 1. Synthesis Overview

DP4 uses OpenLane2's built-in Yosys synthesis (step 06) as part of the full 67-step P&R flow. This is **not** the standalone Yosys cell-count run from earlier phases — it uses the actual sky130A technology library with OpenROAD-driven ABC optimization, targeting the `DELAY 0` synthesis strategy.

| Parameter | Value |
|-----------|-------|
| SYNTH_STRATEGY | `DELAY 0` (timing-optimized) |
| CLOCK_PERIOD | 20 ns (50 MHz target) |
| Technology library | sky130_fd_sc_hd (HD standard cells) |
| Die area | 1900 × 520 µm |
| Post-synth chip area (Yosys) | 435,388.8 µm² |
| Sequential elements | 48.22% of chip area |

---

## 2. Cell Count Summary (post-synthesis, sky130A)

| Metric | DP3 Yosys generic | DP4 OpenLane2 sky130A | Note |
|--------|------------------|-----------------------|------|
| Total instances (before P&R) | ~72,922 | ~66,000 (pre-P&R) | OpenLane2 optimizes more aggressively |
| Final instances (post-P&R) | — | **68,673** | After buffer insertion, antenna fixes |
| Sequential cells (FFs) | 5,444 | **8,598** | Includes clock gate Q-pins |
| Clock gate cells (ICG) | — | **361** | Inherited from DP2 clock gating |
| Timing repair buffers | — | **1,902** | Inserted by OpenROAD during routing |
| Antenna cells | — | **18,796** | Required for sky130A DRC compliance |
| Standard cell area (µm²) | est. 255,220 | **550,034** | Actual placed area, sky130A cells |

**Critical note on cell count difference:** The standard cell area of 550,034 µm² fits within the 973,811 µm² core area (56.48% utilization), well under the 80% congestion limit. The higher post-P&R count vs. pre-synthesis reflects OpenROAD's buffer insertion (1,902 timing repair buffers) and 18,796 antenna cells added for fabrication compliance.

---

## 3. What Changed from DP3 Synthesis to DP4

| Dimension | DP3 (standalone Yosys) | DP4 (OpenLane2 full flow) |
|-----------|----------------------|--------------------------|
| Technology | Generic Yosys cells | sky130A sky130_fd_sc_hd |
| Optimization | Yosys ABC basic | OpenROAD global + detailed P&R, multi-pass ECO |
| Area result | ~252,525 µm² (estimated) | 550,034 µm² (actual placed) |
| Power result | N/A | 36.00 mW (internal + switching) |
| Timing | WNS estimated +0.758 ns | WNS actual: **+0.605 ns** (worst corner) |
| DRC | N/A | **COUNT: 0** ✅ |
| LVS | N/A | **Circuits match uniquely** ✅ |
| Output | .v netlist only | GDSII + netlist + SPEF + SDF + LEF + LIB |

---

## 4. PPA at End of Full Flow (OpenLane2, all 9 corners)

### 4.1 Area

| Metric | Value |
|--------|-------|
| Standard cell instances | 68,673 |
| Standard cell area (µm²) | 550,034 |
| Core area (µm²) | 973,811 |
| Core utilization | **56.48%** |
| Total wire length (µm) | 1,768,893 |

### 4.2 Power (nom_tt_025C_1v80)

| Metric | Value |
|--------|-------|
| Internal power | 14.67 mW |
| Switching power | 21.33 mW |
| Leakage power | 0.00 mW |
| **Total power** | **36.00 mW** |

### 4.3 Timing Sign-off

| Corner | Setup WNS | Hold WNS | Violations |
|--------|-----------|----------|------------|
| nom_tt_025C_1v80 | 0 | 0 | **0** ✅ |
| nom_ss_100C_1v60 | 0 | 0 | **0** ✅ |
| nom_ff_n40C_1v95 | 0 | 0 | **0** ✅ |
| max_ss_100C_1v60 ★ | 0 | 0 | **0** ✅ |
| (all 9 corners) | 0 | 0 | **0** ✅ |

★ Worst setup slack: **+0.605 ns** at max_ss_100C_1v60  
★ Worst hold slack: **+0.169 ns** at max_ff_n40C_1v95

---

## 5. DP2 → DP3 → DP4 PPA Progression

| Metric | DP2 | DP3 | DP4 (final) |
|--------|-----|-----|-------------|
| Cell instances | 70,427 | 68,673 | 68,673 |
| Cell area (µm²) | 565,415 | 550,034 | 550,034 |
| Core utilization | 58.06% | 56.48% | **56.48%** |
| Total power (mW) | 38.16 | 36.00 | **36.00** |
| WNS nom_ss (ns) | +0.900 | +0.758 | **+0.758** |
| WNS worst corner | +0.784 | +0.605 | **+0.605** |
| DRC | 0 | 0 | **0** ✅ |
| LVS | 0 | 0 | **0** ✅ |
| GDSII | — | — | **✅ delivered** |

DP4 produces identical PPA to DP3 (same RTL, same OpenLane2 run), with the addition of the final tape-out deliverables: GDSII, SDF, SPEF, netlist, LEF, LIB files.

---

## 6. Synthesis Quality Notes

- **SYNTH_STRATEGY = DELAY 0:** Prioritizes timing over area, resulting in a smaller final netlist than area-optimized strategies would produce with this design (the MAC chain is already well-pipelined from DP2).
- **Sequential density (48.22%):** High ratio of flip-flop area confirms that the DP2 pipelining optimizations are effectively mapped to sky130A cells.
- **No latches (latch.rpt: empty):** Clean purely-synchronous RTL, no combinational loops.
- **Antenna count (18,796):** Normal for a ~70K-cell design in sky130A — diode insertion handled automatically by OpenLane2.

**Conclusion:** Synthesis complete and verified. The DP4 gate-level netlist at `results/openlane/runs/DP3/final/nl/` represents the final tape-out-ready gate-level description of the Winograd accelerator.
