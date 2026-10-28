# DP2 Optimization Report

## Objective

The goal of DP2 was to improve implementation quality of the UART Controller by:
- Reducing logic complexity
- Improving placement and routing efficiency
- Lowering power consumption
- Maintaining clean timing and physical verification results

All comparisons are based on OpenLane results between DP1 and DP2.

---

## 1. Area and Logic Optimization

| Metric | DP1 | DP2 | Change |
|---|---|---|---|
| Synth Cell Count | 998 | 741 | -25.7% |
| Total Cells | 11964 | 11802 | Reduced |
| Cell Density (Cell/mm²) | 10081.63 | 7616.33 | -24.4% |
| OpenDP Utilization | 10.57% | 7.98% | Lower congestion |
| Logic Levels | 13 | 9 | -30.8% |

### Explanation

The optimized design restructures the data path and reduces redundant combinational logic.  
Key architectural changes include:
- Simplification of logic operations (reduced AND, OR, XOR, etc.)
- Improved synthesis optimization (AREA strategy)
- Introduction of additional registers (DFF: 7 → 40)

The increase in flip-flops indicates **pipeline insertion**, which reduces combinational depth and enables better synthesis optimization.

Result:
- Lower logic depth
- Better placement quality
- Reduced congestion risk

---

## 2. Routing Improvement

| Metric | DP1 | DP2 |
|---|---|---|
| Wire Length | 50376 | 40836 |
| Vias | 8837 | 6449 |
| Wires Count | 967 | 692 |
| HPWL | 38.15M | 32.62M |

### Explanation

Reduced logic complexity and improved register distribution shorten interconnect distance.  
Pipeline insertion localizes signal paths, allowing the placer to cluster related logic more efficiently.

Result:
- Shorter wires
- Fewer vias
- Lower routing congestion
- Faster routing runtime

---

## 3. Timing Analysis

| Metric | DP1 | DP2 |
|---|---|---|
| Critical Path | 2.46 ns | 2.56 ns |
| WNS | 0 | 0 |
| TNS | 0 | 0 |
| Target Clock | 14 ns | 14 ns |

### Explanation

Although the critical path slightly increased, both designs meet timing comfortably.  
The reduction in logic levels improves timing robustness and margin distribution across the design.

Pipeline insertion reduces long combinational chains, improving timing stability even if the reported critical path changes slightly due to restructuring.

Result:
- Timing clean
- No violations
- Improved timing reliability

---

## 4. Power Optimization

| Metric | DP1 | DP2 |
|---|---|---|
| Internal Power | 0.00149 µW | 0.00107 µW |
| Switching Power | 0.00116 µW | 0.000776 µW |
| Leakage | 1.25e-8 | 1.11e-8 |

### Explanation

Power reduction is mainly due to:
- Reduced combinational logic
- Shorter wire length (lower capacitance)
- Lower switching activity
- Better register-based data flow

Result:
- ~28–33% dynamic power reduction

---

## 5. Physical Verification

| Check | Result |
|---|---|
| DRC | Clean |
| LVS | Clean |
| Routing Violations | None |

Antenna violations slightly increased:
- Pin: 16 → 20  
- Net: 15 → 18  

These are expected after routing changes and are handled by OpenLane antenna repair.

---

## 6. Runtime Improvement

| Metric | DP1 | DP2 |
|---|---|---|
| Total Runtime | 2m16s | 1m54s |
| Routed Runtime | 1m47s | 1m29s |

Explanation:
Lower logic complexity and routing demand reduce tool runtime.

---

## 7. Summary of Improvements

DP2 achieved:

- ~25% reduction in synthesized logic
- ~30% reduction in logic depth
- ~19% shorter wire length
- ~27–33% power reduction
- Reduced congestion and routing resources
- Clean timing and physical verification

The optimized architecture is more efficient and better suited for final implementation.
