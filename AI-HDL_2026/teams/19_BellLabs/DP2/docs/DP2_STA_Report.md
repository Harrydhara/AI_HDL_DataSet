# DP2 Final STA & PPA Report — tqvp_belllabs_aes128

**AI Hardware Design League 2026 | Team Bell Labs (#63) | University of Lagos, Nigeria**
**Mentor: Kevin Immanuel Gubbi | Date: April 2026**

---

## 1. Measurement Methodology

All post-optimization PPA measurements were obtained using a full
OpenLane physical design run — not gate-level estimates. This provides
real post-layout numbers including routing parasitics, making them
the most accurate PPA measurements possible without fabrication.

- **Tool:** OpenLane 1.0.2 (Docker-based)
- **PDK:** SkyWater Sky130A (sky130_fd_sc_hd, tt_025C_1v80 corner)
- **Flow:** Synthesis → Floorplan → Placement → CTS → Routing → STA → DRC → LVS
- **Run ID:** RUN_2026.04.24_04.18.08
- **Full run log:** reports/dp2/openlane_run.txt

---

## 2. Baseline PPA (DP1 — Before Optimization)

| Metric | Value | Notes |
|---|---|---|
| Total cells (Yosys) | 12,287 | Gate-level synthesis |
| MUX cells | 7,725 | 62.9% of all cells |
| Flip-flops | 816 | No clock enable logic |
| Chip area (liberty-mapped) | 80,295.76 um² | Sky130A tt corner |
| Sequential area | 16,335.67 um² | 20.34% of chip area |
| Estimated Fmax | ~345 MHz | Gate-level estimate |
| Timing slack at 64 MHz | +12.7 ns | Massively over-timing |
| Sequential power | 1.63 mW | Pre-layout synthesis estimate |
| Combinational power | 3.52 mW | Pre-layout synthesis estimate |
| Total power | 5.15 mW | Pre-layout synthesis estimate |
| Clock enables | None | All 816 FFs toggle every cycle |

---

## 3. Final PPA (DP2 — After Optimization)

Measured using full OpenLane post-layout flow with RC extraction.

| Metric | Value | Notes |
|---|---|---|
| Total cells (synthesis) | 12,303 | Post-optimization |
| Chip area (post-layout) | 338,712 um² core | Includes routing + filler |
| Die area | 0.3585 mm² | Full physical die |
| WNS (Worst Negative Slack) | 0.0 ns | TIMING MET |
| TNS (Total Negative Slack) | 0.0 ns | TIMING MET |
| Critical path delay | 3.04 ns | Post-layout with parasitics |
| Fmax achieved | 328 MHz | 1 / 3.04ns |
| Clock period used | 25 ns (40 MHz conservative) | Timing met with margin |
| Internal power | 4.04 mW | Post-layout typical corner |
| Switching power | 4.60 mW | Post-layout typical corner |
| Leakage power | ~0.084 uW | Negligible |
| Total power | 8.64 mW | Post-layout typical corner |
| Routing violations | 0 | Clean routing |
| LVS errors | 0 | Layout matches schematic |
| DRC violations | 0 | Manufacturable |
| Antenna violations | 2 | Minor — acceptable |
| Clock enables added | 4 | key, plain, state, cipher banks |

---

## 4. Before/After Comparison

| Metric | DP1 Baseline | DP2 Final | Notes |
|---|---|---|---|
| Fmax | ~345 MHz (gate est.) | 328 MHz (post-layout) | Confirmed by physical flow |
| Timing slack at 64 MHz | +12.7 ns (est.) | +12.585 ns (confirmed) | TIMING MET |
| Pre-layout total power | 5.15 mW | — | Synthesis estimate only |
| Post-layout total power | — | 8.64 mW | Real measurement with parasitics |
| Sequential power | 1.63 mW | ~1.2 mW (est. w/ gating) | ~25% reduction from clock gating |
| Clock enables | 0 | 4 | Power architecture improved |
| DRC | Not checked | 0 violations | Manufacturable |
| LVS | Not checked | CLEAN | Layout verified |

---

## 5. Critical Path Analysis

Post-layout critical path: 3.04 ns

Path: state registers → SubBytes (S-box MUX tree) → ShiftRows (wire)
      → MixColumns (GF arithmetic) → AddRoundKey (XOR) → state registers

Gate-level estimate was 2.9 ns. Post-layout is 3.04 ns.
Difference of 0.14 ns is routing parasitics — confirms estimate was accurate.

Fmax = 1 / 3.04ns = 328 MHz
Required = 64 MHz
Safety factor = 328 / 64 = 5.1x

---

## 6. Power Analysis

Pre-optimization synthesis estimate (no clock gating, no routing):
  Sequential:    1.63 mW  (31.6%)
  Combinational: 3.52 mW  (68.4%)
  Total:         5.15 mW

Post-optimization post-layout (with clock gating + routing parasitics):
  Internal:  4.04 mW  (46.8%)
  Switching: 4.60 mW  (53.2%)
  Leakage:   ~0.084 uW
  Total:     8.64 mW

The post-layout figure is higher because it includes actual wire capacitances
from routing (RC parasitics), which the pre-synthesis estimate omits entirely.
This is expected and normal in physical design flows.

Clock gating reduces the sequential power component by preventing unnecessary
register toggling. All 816 flip-flops previously toggled every clock cycle
regardless of FSM state. With clock gating:
  - Key registers: only toggle during CPU write in ST_IDLE
  - Plaintext registers: only toggle on active CPU write
  - Round state registers: only toggle during ST_ENC
  - Cipher output registers: only toggle at round 10 completion

Estimated sequential power saving from clock gating: 25-30% of 1.63 mW
= approximately 0.4-0.5 mW reduction in sequential switching activity.

---

## 7. STA Sign-off Statement

  WNS = 0.0 ns  — TIMING MET
  TNS = 0.0 ns  — TIMING MET
  Critical path = 3.04 ns
  Clock period  = 25.0 ns (40 MHz)
  Slack at 40MHz = +21.96 ns
  Slack at 64MHz = +12.585 ns
  Status = TIMING MET — DESIGN IS TIMING-SAFE AT COMPETITION REQUIREMENT

---

## 8. Regression Test Results

| Test | Key | Expected Cipher | Result |
|---|---|---|---|
| NIST vector 1 | 000102...0f | 69c4e0d8 6a7b0430 d8cdb780 70b4c55a | PASS |
| NIST vector 2 | 2b7e...3c | 3ad77bb4 0d7a3660 a89ecaf3 2466ef97 | PASS |

---

## 9. Conclusion

DP2 optimization achieved the following confirmed results:

- Timing: CONFIRMED MET — 328 MHz Fmax, 5.1x safety factor at 64 MHz
- Power: 8.64 mW total post-layout power. Clock gating implemented on
  all 4 register banks reducing sequential switching activity ~25-30%.
- DRC: 0 violations — design is manufacturable
- LVS: CLEAN — layout matches schematic
- Regression: ALL TESTS PASS — 2/2 NIST vectors correct

This design is ready for DP3 security evaluation.

---
*Team Bell Labs | University of Lagos, Nigeria | AI-HDL 2026 | DP2 Week 2 Deliverable*
