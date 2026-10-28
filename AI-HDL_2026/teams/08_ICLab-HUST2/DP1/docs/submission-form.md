# AI-HDL Challenge [X] Submission Form

## Basic Information
- **Submission Date**: [YYYY-MM-DD]
- **Challenge Number**: [1]
- **Team Name**: ICLab_HUST2
- **Team ID**: ICLab_HUST2

## Team Members
| Name | Role | Email | Contribution % |
|------|------|-------|----------------|
| [member] | RTL Design & Verification Lead | [email] | [60%] |     
| [member] | Specification & Documentation | [email] | [10%] |
| [member] | Physical Implementation | [email] | [10%] |
| [member] | Specification & Documentation | [email] | [10%] |
| [member] | Technical Research & Support | [email] | [10%] |
## Design Specifications Met
- [x] All required functionality implemented (Winograd $F(2,3)$ with TinyQV integration)
- [x] ASIC implementation successful (OpenLane RTL-to-GDSII flow)
- [x] Timing requirements met (WNS: +0.270 ns @ 50MHz)
- [x] Resource constraints satisfied (Core Area: 0.176 $mm^2$)
- [x] All test cases pass (RTL simulation & Physical Sign-off)

## AI Tool Usage Declaration
- **Primary AI Tool**:
  - Claude.ai (used during the RTL design phase for system architecture development and testbench generation)
  - Gemini 3.0 (used during the ASIC flow implementation phase on OpenLane, including Docker environment configuration and PPA metrics analysis).
- **Total Conversation Sessions**: 100+ sessions
- **Estimated AI-Generated Code %**: 30 - 40%
- **Manual Modifications Made**: Yes
  - Logic Design: Extensively modified the Finite State Machine (FSM) from 7 to 9 states to optimally handle complex nested loops in multi-channel convolution.
  - Mathematical Optimization: Integrated additional rounding-bit logic into the final accumulation stage to minimize fixed-point quantization errors—a critical precision enhancement that the AI had not optimized in the initial draft.
  - ASIC Flow Configuration: Manually tuned OpenLane parameters, such as FP_CORE_UTIL and PL_TARGET_DENSITY, based on Gemini’s error analysis and diagnostic feedback. This was essential to achieve "Timing Clean" status and resolve resource-density violations for the SkyWater 130nm process node.

## Special Considerations
- **Bonus Features Implemented**:
  - Full Physical Sign-off (Manufacturability): Unlike typical academic projects, this design achieved 0 DRC/LVS violations on the SkyWater 130nm node, ensuring it is fully manufacturable and ready for GDS submission. This directly addresses the criteria to avoid severe grade deductions.
  - Advanced Multi-Channel Hardware Architecture: We implemented a 9-state FSM that handles multi-channel accumulation entirely in hardware. This "advanced idea beyond scope" significantly reduces software overhead compared to standard single-tile implementations.
  - Creative AI/LLM Integration for PPA Optimization: Beyond simple code generation, we utilized LLMs (Gemini 3.0) as a diagnostic tool to analyze metrics.csv and iteratively tune physical design parameters (e.g., FP_CORE_UTIL, PL_TARGET_DENSITY) to reach timing closure.
  - Interrupt-Driven SoC Parallelism: Integrated a dedicated winograd_irq signal, enabling true asynchronous parallel execution between the TinyQV RISC-V core and the Winograd accelerator.
- **Known Issues**: 
  - Memory Bandwidth Limitation: While the processing core is high-performance, the overall system throughput is currently constrained by the CPU-bound Load/Store mechanism. We have identified this as a critical "performance bottleneck" targeted for improvement in future phases.
  - Power: The current design exhibits a dominant Internal Power component (14.23 mW), primarily attributed to the high register density required for the $F(2,3)$ algorithm's buffering system.
- **Future Improvements**: 
  - Further optimize the algorithm and data transfer efficiency, with a specific focus on PPA (Power, Performance, and Area) enhancement.
  - Implement fine-grained clock gating techniques to minimize and optimize the current power consumption of 20.3 mW.

## Verification Checklist
- [x] All source files compile without errors
    - Linting & Compilation: Performed linting using Verilator to ensure standardized source code, confirming the absence of syntax errors or warnings related to un-synthesizable logic.
    - Synthesis Success: All modules (including winograd.v, interface.v, tinyQV_winograd.v, and their respective sub-modules) were successfully synthesized through the OpenLane flow.
- [x] Testbenches run successfully
    - Module-level: Matrix transformation and element-wise multiplier blocks successfully passed individual test scenarios using reference data generated from Python.
    - ystem-level: Verified seamless data exchange between the TinyQV processor and the Winograd accelerator via the system bus at the 0x9000_0000 memory-mapped address.
    - Computational Accuracy: Simulation results from Icarus Verilog demonstrate that computational errors remain well within the permissible tolerance for the 32-bit fixed-point representation.
- [x] ASIC Physical Sign-off verified
    - DRC (Design Rule Check): Achieved 0 violations (verified using the Magic VLSI tool).
    - Timing Closure: Successfully met timing requirements with positive slack (WNS: +0.270 ns).
- [x] AI interaction logs are complete
    - A complete set of 11 Prompt Logs (from PL-01 to PL-11) is provided, detailing the entire process from the initial RTL design phase through PPA optimization and OpenLane debugging.
- [x] Documentation is thorough and clear

## Team Statement
We certify that this submission represents our original work, completed according to AI-HDL rules and academic integrity guidelines. All AI interactions have been logged and submitted.

**Team Representative**: Lily

**Date**: [YYYY-MM-DD]  
