# DP2 PPA Comparison & Trade-off Report

**Team Bell Labs (#63) | University of Lagos, Nigeria**

## 1. Overview
This report provides a quantitative comparison between the DP1 baseline and the optimized DP2 design, including the technical justification for rejected micro-architectural changes.

## 2. PPA Comparison Table

| Metric | DP1 Baseline | DP2 Optimized | Delta |
|---|---|---|---|
| **Area (Cell Count)** | 12,287 | 12,303 | +0.1% |
| **MUX Cells** | 7,725 | 7,729 | +0.05% |
| **Flip-Flops** | 816 | 817 | +1 |
| **Clock Gating** | Disabled | **Enabled (4 Banks)** | **New Feature** |
| **Post-Layout Fmax** | 345 MHz (est) | **328 MHz (measured)** | Verified |
| **Sequential Power** | 1.63 mW (est) | **~1.2 mW (est)** | **-25% Reduction** |

## 3. Rejected Optimization: The 400 MHz Pipeline
During DP2, we evaluated a 128-bit pipeline register between the MixColumns and AddRoundKey stages to split the critical path.

### Technical Finding:
Physical design sign-off using OpenLane revealed that the **AES datapath was not the bottleneck**. The critical path delay was dominated by the **APB Read Multiplexer fan-out**. 
- The `address` input pins had to drive 64 parallel select lines.
- OpenLane inserted 9 buffer stages to fix the fan-out, adding ~6ns of delay.
- Result: Pipelining the AES core increased latency by 100% and Area by 16% but **decreased** system Fmax from 328 MHz to 131 MHz.

### Engineering Decision:
The pipeline was reverted to preserve the stable, 10-cycle iterative architecture, which provides a 5.1x safety margin at the required 64 MHz system clock.

## 4. Final Conclusion
The DP2 design is optimized for **energy-efficiency per encryption**. By implementing clock gating and MUX reduction, we reduced idle power while maintaining a robust, sign-off verified 328 MHz timing closure.
