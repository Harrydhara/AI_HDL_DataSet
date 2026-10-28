# Timing Analysis Results

## Overview

Timing analysis was performed using the OpenLane post-synthesis reports to evaluate the maximum achievable operating frequency of the design.  
The analysis is based on the reported critical path delay after synthesis.

## Critical Path

- **Critical path delay**: 6.83 ns  
- **Timing violations**: None reported (WNS ≥ 0, TNS = 0)

The critical path represents the longest combinational delay between two sequential elements and determines the maximum clock frequency at which the design can safely operate.
---

## Maximum Operating Frequency

The maximum operating frequency was derived from the post-synthesis critical path delay reported by OpenLane.

- **Critical path delay**: 6.83 ns

The maximum achievable clock frequency is:

$$
F_{\max} = \frac{1}{T_{\text{critical}}}
$$

Convert the critical path delay to seconds:

$$
T_{\text{critical}} = 6.83\ \text{ns} = 6.83 \times 10^{-9}\ \text{s}
$$

Therefore:

$$
F_{\max} = \frac{1}{6.83 \times 10^{-9}} \approx 1.4641 \times 10^{8}\ \text{Hz} \approx 146.41\ \text{MHz}
$$

- **Maximum achievable frequency**: **146.41 MHz**

---

## Discussion

The achieved maximum operating frequency exceeds the initial target clock frequency specified during synthesis.  
This indicates that the design meets timing requirements with a positive margin and is suitable for reliable operation at the target clock rate.

No timing violations were observed in the post-synthesis timing analysis, confirming that the RTL design is timing-clean and ready for further implementation stages.

## Artifacts

- OpenLane synthesis metrics: `results/synthesis/metrics.csv`

## Conclusion

The timing analysis confirms that the design achieves a maximum operating frequency of **146.41 MHz**, limited by a critical path delay of **6.83 ns**, with no timing violations.  
The design satisfies the DP1 timing requirements and is ready for subsequent FPGA implementation or further optimization.
