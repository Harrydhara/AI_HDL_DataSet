# Baseline PPA Analysis
**Design:** `tt_um_tt_tinyQV` — TinyQV RISC-V SoC with DMA Peripheral

**Run:** `DP1/openlane/runs/Base_PPA_DP1`

**Technology:** Sky130 HD (1.8 V, 50 MHz target clock)

**Die area:** 432 × 432 µm (186,624 µm²) 

**Core area:** 180,939 µm²

---

## 1. Area

| Metric | Value |
|--------|-------|
| Standard cell count | 13,981 |
| Standard cell area | 87,735.4 µm² |
| Core utilisation | **48.49 %** |
| Macro count | 0 |
| Fill cells | 11,703 |
| Tap cells | 2,528 |

### Cell type breakdown

| Category | Count |
|----------|-------|
| Multi-input combinational | 4,230 |
| Sequential (flip-flops) | 1,300 |
| Buffer (timing repair) | 431 |
| Timing repair buffer | 170 |
| Inverter | 107 |
| Clock buffer | 146 |
| Clock inverter | 104 |
| Antenna cell | 4,965 |

**Observation:** Combinational cells dominate the logic cone at 4,230 instances,
reflecting the heavy use of explicit case/MUX trees in the original DMA RTL.
The 170 timing-repair buffers indicate that the placer and router had to insert
significant buffering to meet the 50 MHz constraint, suggesting over-deep logic paths.

---

## 2. Power

All figures at nominal TT corner (25 °C, 1.80 V).

| Component | Power |
|-----------|-------|
| Internal (gate switching) | 4.350 mW |
| Switching (net toggling) | 2.082 mW |
| Leakage | 85.1 nW |
| **Total** | **6.432 mW** |

Internal power is 67.6 % of total, which is characteristic of a combinational-heavy
design where wide MUX trees switch frequently. Switching power at 32.4 % reflects
the estimated toggle activity on the relatively long wire lengths.

### IR-drop summary (VPWR, TT corner)

| Metric | Value |
|--------|-------|
| Worst voltage drop | 130.7 µV |
| Average voltage drop | 10.0 µV |
| Worst net voltage | 1.79987 V |

IR drop is well within the 1 % budget (~18 mV for 1.8 V supply).

---

## 3. Performance (Timing)

Clock period constraint: **20 ns (50 MHz)**.
All corners report zero setup and hold violations.

### Setup worst slack by corner

| Corner | Setup WS (ns) | Setup r2r WS (ns) |
|--------|--------------|-------------------|
| TT 25 °C 1.80 V | 2.973 | 5.262 |
| SS 100 °C 1.60 V | 1.684 | 2.590 |
| FF −40 °C 1.95 V | 3.478 | 6.266 |

### Hold worst slack by corner

| Corner | Hold WS (ns) | Hold r2r WS (ns) |
|--------|-------------|------------------|
| TT 25 °C 1.80 V | 0.329 | 0.329 |
| SS 100 °C 1.60 V | 0.656 | 0.656 |
| FF −40 °C 1.95 V | 0.204 | 0.204 |

**Critical corner:** SS 100 °C 1.60 V gives the tightest setup slack at **1.684 ns**,
which is still 8.4 % of the clock period — a comfortable margin, though indicating
the design is not particularly fast relative to the target.

### Routing

| Metric | Value |
|--------|-------|
| Total wire length | 257,132 µm |
| Total vias | 63,396 |
| Maximum net wire length | 1,108.29 µm |
| Estimated wire length (pre-route) | 210,496 µm |
| Routing DRC errors | 0 |
| Routing iterations to clean | 22 |

The router required **22 iterations** before all DRC errors were resolved, indicating
moderate routing congestion caused by the dense placement of large MUX trees.

---

## 4. Physical Integrity

| Check | Result |
|-------|--------|
| Lint errors | 0 |
| Synthesis errors | 0 |
| Antenna violations (final) | 0 nets / 0 pins |
| Antenna diodes inserted | 2 |
| DRC errors | 0 |
| LVS errors | 0 |
| Floating nets | 0 |
| Power grid violations | 0 |

The design is clean at the physical level. Only 2 antenna diodes were needed,
which aligns with the `HEURISTIC_ANTENNA_THRESHOLD` of 200 µm — a setting that
is relatively conservative and would leave shorter but still-problematic wires
unprotected in a tighter subsequent run.

---

## 5. Summary and Optimisation Targets

| Axis | Baseline value | Observation |
|------|---------------|-------------|
| Area | 87,735 µm² | 170 timing-repair buffers signal logic too deep |
| Power | 6.432 mW | High internal power from wide MUX trees |
| Setup slack (SS) | 1.684 ns | Adequate but moderate; logic depth is limiting factor |
| Wire length | 257,132 µm | Long routes from distributed 32-case decoders |
| Routing iterations | 22 | Congestion from large flat MUX structures |

The primary optimisation targets identified from the baseline are:

1. **DMA buffer decoders** — 8 × 32-case nested structures inflate cell count and MUX depth.
2. **`dma_done` register** — redundant FF whose information is already encoded in the state machine.
3. **Up-counter comparator** — 8-bit magnitude comparator replaceable with a zero-detect.
4. **Peripheral wrapper** — redundant `data_ready_from_peri` factor on critical handshake paths.
