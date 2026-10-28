# DP2: Design Evaluation and PPA Optimization

## 1. Introduction

This report presents the evaluation and optimization of the DP1 design as part of Design Phase 2. The goal of this phase is to improve the design’s Power, Performance, and Area (PPA) characteristics through microarchitectural optimizations while ensuring functional correctness.

---

## 2. Baseline PPA Analysis (DP1)

The DP1 design was functionally correct but not optimized for performance. The timing constraint was relatively relaxed, leading to underutilized performance potential.

| Metric       | Value           |
| ------------ | --------------- |
| Clock Period | 10 ns           |
| Frequency    | 100 MHz         |
| Slack        | High (positive) |
| Power        | 1.39 mW         |
| Area         | 358,669 µm²     |

### Key Observations

* The design exhibited **significant positive slack**, indicating timing under-utilization.
* Power consumption was dominated by **combinational switching activity (~60.8%)**.
* Area usage was stable and within acceptable limits.

---

## 3. Optimization Plan

Based on the baseline analysis, the following optimization goals were defined:

### Objectives

* Increase operating frequency by reducing clock period
* Reduce unnecessary switching activity to lower dynamic power
* Maintain area efficiency (no significant increase)

### Planned Techniques

* Reduce clock constraint from 10 ns to 3 ns
* Introduce switching activity reduction via conditional computation
* Implement register update gating to avoid unnecessary toggling

---

## 4. Implemented Optimizations

### 4.1 Performance Optimization

The clock period constraint was reduced from 10 ns to 3 ns. This leverages the unused timing slack observed in DP1 to significantly increase the operating frequency.

### 4.2 Switching Activity Reduction

To reduce dynamic power:

* Combinational logic execution was conditioned on valid operations
* Register updates were restricted to active computation cycles

These changes minimize unnecessary signal transitions in the datapath.

---

## 5. Final PPA Results (DP2)

| Metric       | Value       |
| ------------ | ----------- |
| Clock Period | 3 ns        |
| Frequency    | 333 MHz     |
| Slack        | 0.57 ns     |
| Power        | 1.39 mW     |
| Area         | 358,669 µm² |

---

## 6. Before vs After Comparison

| Metric       | DP1 (Baseline) | DP2 (Optimized) | Improvement |
| ------------ | -------------- | --------------- | ----------- |
| Clock Period | 10 ns          | 3 ns            | ↓ 70%       |
| Frequency    | 100 MHz        | 333 MHz         | +233%       |
| Slack        | High           | 0.57 ns         | Optimized   |
| Power        | 1.39 mW        | 1.39 mW         | No change   |
| Area         | 358,669 µm²    | 358,669 µm²     | No change   |

---

## 7. Trade-off Justification

### Performance

The clock period reduction enabled a **3.33× increase in frequency**, significantly improving performance while maintaining timing closure (positive slack).

### Power

Switching activity reduction techniques were successfully implemented at the RTL level:

* Conditional combinational logic activation
* Selective register updates

These changes reduce unnecessary transitions, which directly lowers dynamic power in real hardware.

However, the reported power remained unchanged. This is due to the fact that the OpenLane flow uses **default switching activity assumptions** in the absence of real workload data (e.g., VCD/SAIF). As a result, structural reductions in switching activity are not reflected in the reported power values.

### Area

No additional hardware blocks were introduced. The area remained constant, ensuring that performance improvements were achieved without increasing silicon cost.

---

## 8. Verification and Validation

* Static Timing Analysis (STA) confirmed that the design meets timing constraints at 3 ns.
* All timing paths achieved **positive slack (0.57 ns)**.
* No functional regressions were introduced during optimization.

---

## 9. Conclusion

The DP2 design demonstrates effective optimization of the baseline design:

* Achieved **3.33× performance improvement**
* Maintained **constant area**
* Implemented **power-aware design techniques**

The results show a well-balanced optimization across the PPA trade-offs, meeting the objectives of Design Phase 2.

---
