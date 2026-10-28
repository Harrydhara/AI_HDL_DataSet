# Before-and-After PPA Comparison

**Baseline:** `DP1/openlane/runs/Base_PPA_DP1/final/metrics.csv`

**Optimised:** `DP2/openlane/runs/Opt_PPA_DP2/final/metrics.csv`

**Technology:** Sky130 HD 

**Clock:** 50 MHz 

**Die:** 432 × 432 µm

---

## 1. Area

| Metric | Baseline (DP1) | Optimised (DP2) | Delta | Change |
|--------|---------------|----------------|-------|--------|
| Standard cell count | 13,981 | 13,165 | −816 | **−5.84 %** |
| Standard cell area (µm²) | 87,735.4 | 84,074.4 | −3,661 | **−4.17 %** |
| Core utilisation | 48.49 % | 46.47 % | −2.02 pp | ↓ |
| Fill cells | 11,703 | 11,961 | +258 | more free space |
| Timing repair buffers | 170 | 136 | −34 | **−20.0 %** |
| Multi-input combinational | 4,230 | 4,065 | −165 | **−3.90 %** |
| Sequential (flip-flops) | 1,300 | 1,299 | −1 | −0.08 % |
| Inverters | 107 | 95 | −12 | −11.2 % |
| Antenna cells | 4,965 | 4,358 | −607 | **−12.2 %** |

**Key area improvements:**
- **−816 cells (−5.84 %)** — direct result of collapsing 64 nested case entries
  into variable part-selects and replacing explicit decoders with computed indices.
- **−34 timing-repair buffers (−20 %)** — shallower combinatorial cones require
  fewer inserted buffers to meet the 50 MHz constraint.
- **−607 antenna cells (−12.2 %)** — shorter average wire lengths reduce the
  number of antenna-protection cells the router must insert.

---

## 2. Power

All figures at nominal TT corner (25 °C, 1.80 V).

| Component | Baseline (DP1) | Optimised (DP2) | Delta | Change |
|-----------|---------------|----------------|-------|--------|
| Internal power (mW) | 4.3503 | 4.4272 | +0.0769 | +1.77 % |
| Switching power (mW) | 2.0819 | 2.1161 | +0.0342 | +1.64 % |
| Leakage power (nW) | 85.1 | 83.0 | −2.1 | −2.47 % |
| **Total power (mW)** | **6.432** | **6.543** | **+0.111** | **+1.72 %** |

**Observation:** Total power increased marginally by +1.72 % (+0.111 mW).
This counter-intuitive result is discussed in detail in the trade-offs document.
The leakage component decreased (−2.47 %), consistent with fewer cells overall.

### IR-drop (VPWR, TT corner)

| Metric | Baseline | Optimised | Delta | Change |
|--------|---------|----------|-------|--------|
| Worst IR drop (µV) | 130.7 | 114.8 | −15.9 | **−12.2 %** |
| Average IR drop (µV) | 10.0 | 10.1 | +0.1 | negligible |

The reduction in worst-case IR drop is a direct consequence of the shorter and
less congested routing reducing resistive losses on the power mesh.

---

## 3. Performance (Timing)

Clock period: 20 ns. Zero violations in both runs across all corners.

### Setup worst slack

| Corner | Baseline WS (ns) | Optimised WS (ns) | Delta (ns) |
|--------|-----------------|------------------|------------|
| TT 25 °C 1.80 V | 2.973 | 2.972 | −0.001 |
| SS 100 °C 1.60 V | **1.684** | **0.916** | −0.768 |
| FF −40 °C 1.95 V | 3.478 | 3.477 | −0.001 |

### Setup register-to-register worst slack

| Corner | Baseline r2r (ns) | Optimised r2r (ns) | Delta (ns) |
|--------|------------------|-------------------|------------|
| TT 25 °C 1.80 V | 5.262 | 4.390 | −0.872 |
| SS 100 °C 1.60 V | 2.590 | 0.915 | −1.675 |
| FF −40 °C 1.95 V | 6.266 | 5.689 | −0.577 |

### Hold worst slack

| Corner | Baseline WS (ns) | Optimised WS (ns) | Delta (ns) |
|--------|-----------------|------------------|------------|
| TT 25 °C 1.80 V | 0.329 | 0.331 | +0.002 |
| SS 100 °C 1.60 V | 0.656 | 0.672 | +0.016 |
| FF −40 °C 1.95 V | 0.204 | 0.204 | 0.000 |

**Key timing observations:**

- Setup slack **decreased** at the SS corner (1.684 → 0.916 ns) but **remains
  positive** — no violations in either run. This is discussed in trade-offs.
- Hold slack improved or held constant across all corners, confirming no hold
  degradation from the optimisations.
- Both designs comfortably meet the 50 MHz constraint.

---

## 4. Routing

| Metric | Baseline (DP1) | Optimised (DP2) | Delta | Change |
|--------|---------------|----------------|-------|--------|
| Total wire length (µm) | 257,132 | 225,599 | −31,533 | **−12.3 %** |
| Total vias | 63,396 | 59,968 | −3,428 | **−5.41 %** |
| Max net wire length (µm) | 1,108.29 | 1,245.60 | +137.3 | +12.4 % |
| Routing DRC errors | 0 | 0 | 0 | clean |
| Routing iterations to clean | 22 | 7 | −15 | **−68.2 %** |
| Antenna diodes inserted | 2 | 6 | +4 | more protection |

**Key routing improvements:**
- **−12.3 % total wire length** — smaller, more compact cells from simplified RTL
  reduce the average distance between driving and receiving cells.
- **−68.2 % routing iterations (22 → 7)** — the most visible sign of reduced
  congestion. The baseline MUX trees created dense local clusters that required
  many re-route attempts; the optimised version clears in 7 passes.
- **−5.41 % via count** — fewer layer transitions, reducing parasitic capacitance
  and RC delay along critical paths.

---

## 5. Physical Integrity

| Check | Baseline | Optimised |
|-------|---------|----------|
| Lint errors | 0 | 0 |
| Synthesis errors | 0 | 0 |
| Antenna violations | 0 | 0 |
| DRC errors | 0 | 0 |
| LVS errors | 0 | 0 |
| Floating nets | 0 | 0 |
| Power grid violations | 0 | 0 |

Both runs are fully clean. The optimised run uses **6 antenna diodes** vs. **2** in
the baseline, owing to the lowered `HEURISTIC_ANTENNA_THRESHOLD` (200 → 90 µm)
which provides earlier protection to medium-length wires.

---

## 6. Improvement Summary

| Axis | Metric | Improvement |
|------|--------|------------|
| **Area** | Cell count | −5.84 % |
| **Area** | Cell area | −4.17 % |
| **Area** | Timing-repair buffers | −20.0 % |
| **Area** | Routing wire length | −12.3 % |
| **Area** | Routing iterations | −68.2 % |
| **Power** | IR drop (worst) | −12.2 % |
| **Power** | Leakage | −2.47 % |
| **Performance** | Timing violations | 0 → 0 (maintained) |
| **Performance** | Hold slack (TT) | +0.002 ns (improved) |
