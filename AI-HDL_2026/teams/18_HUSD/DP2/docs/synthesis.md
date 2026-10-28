# Synthesis Results – DP2 Optimization Phase

## 1. Overview

RTL synthesis was performed using the OpenLane automated digital ASIC flow
(Yosys-based synthesis) targeting a TinyTapeout-compatible standard-cell ASIC
technology.

The objective of this stage was to:

- Validate full synthesizability of the RTL
- Evaluate area, routing complexity, and timing metrics
- Compare baseline (DP1) and optimized (DP2) implementations
- Quantify PPA improvements resulting from RTL optimization

All results reported here are derived directly from OpenLane synthesis metrics.

---

## 2. Synthesis Configuration

- Synthesis Tool: OpenLane (Yosys-based)
- Target Technology: Standard-cell ASIC flow
- Clock Constraint: 14 ns (≈ 71.43 MHz)
- Optimization Goal: Maintain timing closure while reducing area and routing complexity

Two separate synthesis runs were performed:

- DP1 Baseline RTL
- DP2 Optimized RTL

Results are stored in:

- `results/synthesis/dp1_baseline/`
- `results/synthesis/dp2_optimized/`

---

## 3. Area and Structural Comparison

### Synthesized Cell Count

| Version | Cell Count |
|----------|------------|
| DP1 (Baseline) | 998 |
| DP2 (Optimized) | 741 |

Cell count reduction: **−25.75%**

This reduction reflects successful logic simplification and the removal of redundant
register structures.

---

### Routing Complexity Metrics

| Metric | DP1 | DP2 | Improvement |
|--------|------|------|------------|
| Wire Length | 50,376 | 40,836 | −18.94% |
| Via Count | 8,837 | 6,449 | −27.02% |
| HPWL | 38,147,292 | 32,621,230 | −14.49% |
| Wires Count | 967 | 692 | −28.44% |
| Wire Bits | 1,286 | 949 | −26.21% |

The optimized RTL exhibits:

- Reduced interconnect complexity
- Improved placement compactness
- Lower routing congestion

These improvements indicate better physical design efficiency.

---

## 4. Timing Summary

Both baseline and optimized designs were synthesized under an identical
clock constraint of 14 ns.

| Metric | DP1 | DP2 |
|--------|------|------|
| WNS | 0 | 0 |
| TNS | 0 | 0 |

Timing closure was preserved after optimization.

No negative slack was introduced.

Critical path delay remains within the defined constraint.

Detailed timing analysis is documented separately in:

`results/timing/timing.md`

---

## 5. Power Estimation

Power estimation was generated through OpenLane’s post-synthesis analysis.

Observations:

- No abnormal switching activity
- No excessive leakage behavior
- Power scales proportionally with reduced cell count

Power estimation is considered preliminary but sufficient for DP2 evaluation.

---

## 6. DRC / Antenna Observations

A slight increase in antenna violations was observed:

- Pin antenna violations: 16 → 20
- Net antenna violations: 15 → 18

The increase remains manageable and does not affect functional correctness.
Further routing refinement can mitigate these violations in future iterations.

---

## 7. Synthesis Artifacts

All reported metrics are traceable to:

- `results/synthesis/dp1_baseline/metrics.csv`
- `results/synthesis/dp2_optimized/metrics.csv`

This ensures reproducibility and transparency of the PPA comparison.

---

## 8. Conclusion

The DP2 optimization phase was successfully achieved:

- 25% reduction in synthesized cell count
- 19–28% reduction in routing complexity metrics
- Maintained timing closure under identical constraints

The optimized RTL demonstrates improved physical efficiency while preserving
functional correctness and timing integrity.

The design is fully synthesizable and meets DP2 submission requirements.
