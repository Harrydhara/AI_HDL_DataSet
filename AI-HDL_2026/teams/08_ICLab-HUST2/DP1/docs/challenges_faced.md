# Challenges Faced

## Overview
During the development of the Winograd SoC Accelerator, the team encountered several complex technical hurdles, ranging from ASIC flow environment setup to PPA (Power, Performance, and Area) optimization for production readiness. These challenges were successfully addressed through a combination of systems design thinking and deep analytical insights provided by AI tools.
  
## 1. Environment & Flow Setup
- **Challenge:** Setting up the OpenLane environment on Docker faced repeated failures due to incompatibilities in PDK (SkyWater 130nm) library paths and file access permission configurations within the container.
- **Solution:** Utilized Gemini 3.0 to analyze system error logs. The team correctly re-mapped volume mounts and established the PDK_ROOT environment variable so the toolchain could properly recognize all standard libraries.
- **Result:** Successfully established a stable execution flow, enabling continuous runs from RTL source to GDSII without environment-related errors.
  
## 2. Timing & Congestion Optimization
- **Challenge:** The initial design faced severe timing violations with negative slack (WNS < 0), failing to meet the 50 MHz target frequency. The root causes were identified as excessive logic depth in the Winograd transformation blocks and high cell density causing routing congestion.
- **Solution:**
  - Refactored the Verilog source code to replace constant multipliers with bit-shift and addition logic (multiplier-less), significantly reducing path delay.
  - Adjusted the cell density parameter FP_CORE_UTIL to 40% to create more space for routing tracks.
- **Result:** Achieved Timing Clean status with a positive slack of +0.270 ns.
## 3. Physical Verification: DRC and LVS Violations
- **Challenge:** Post-OpenLane layout results showed over 100 DRC (Design Rule Check) violations, primarily related to metal spacing and Power Delivery Network (PDN) density. Additionally, LVS (Layout Versus Schematic) errors occurred due to mismatches in power/ground pin naming.
- **Solution:**
  - Based on AI analysis of 130nm design rules, the team adjusted FP_PDN_VPITCH and FP_PDN_HPITCH in the config.json file to loosen the power grid.
  - Manually synchronized power pin names in the module wrapper to ensure consistency between the schematic and physical layout.
- **Result:** The design achieved 0 DRC and 0 LVS violations, meeting all requirements for manufacturing submission.
## 4. Cumulative Errors in Fixed-Point Arithmetic
- **Challenge:** During multi-channel computation, rounding errors in 32-bit fixed-point arithmetic accumulated, leading to a discrepancy between the hardware output and the theoretical model.
- **Solution:** Instead of standard truncation, the team implemented rounding-bit logic in the final accumulation stage as suggested by AI tools.
- **Result:** Improved the accelerator's precision, ensuring errors remain within acceptable limits for Edge AI applications without significantly increasing hardware area.
