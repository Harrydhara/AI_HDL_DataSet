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
- [x] All required functionality implemented (Winograd $F(2\times2, 3\times3)$ with TinyQV integration)
- [x] ASIC implementation successful (OpenLane RTL-to-GDSII flow)
- [x] Timing requirements met (WNS: +2.448 ns @ 66.7 MHz, TT corner)
- [x] Resource constraints satisfied (Core Area: ~0.564 mm²)
- [x] All test cases pass (RTL simulation & Physical Sign-off)

## AI Tool Usage Declaration
- **Primary AI Tool**:
  - Claude Sonnet 4.5 (used during the RTL design phase for system architecture development and testbench generation)
  - Gemini 2.5 Pro (used during the ASIC flow implementation phase on OpenLane, including Docker environment configuration and PPA metrics analysis).
- **Total Conversation Sessions**: 100+ sessions (distilled into 11 primary Prompt Logs)
- **Estimated AI-Generated Code %**: 30–40%
- **Manual Modifications Made**: Yes
  - Logic Design: Extensively modified the Finite State Machine (FSM) from 7 to 9 states to optimally handle complex nested loops in multi-channel convolution.
  - Mathematical Optimization: Integrated additional rounding-bit logic into the final accumulation stage to minimize fixed-point quantization errors—a critical precision enhancement that the AI had not optimized in the initial draft.
  - ASIC Flow Configuration: Manually tuned OpenLane parameters, such as `FP_CORE_UTIL` and `PL_TARGET_DENSITY`, based on Gemini's error analysis and diagnostic feedback. This was essential to achieve timing closure and resolve resource-density violations for the SkyWater 130nm process node.

## Special Considerations
- **Bonus Features Implemented**:
  - Full Physical Sign-off (Manufacturability): This design achieved 0 DRC violations (Magic VLSI) and 0 LVS errors (Netgen) on the SkyWater 130nm node, ensuring it is fully manufacturable and ready for GDS submission.
  - Advanced Multi-Channel Hardware Architecture: We implemented a 9-state FSM that handles multi-channel accumulation entirely in hardware, significantly reducing software overhead compared to standard single-tile implementations.
  - Creative AI/LLM Integration for PPA Optimization: Beyond simple code generation, we utilized LLMs (Gemini 2.5 Pro) as a diagnostic tool to analyze `metrics.csv` and iteratively tune physical design parameters (e.g., `FP_CORE_UTIL`, `PL_TARGET_DENSITY`) to reach timing closure.
  - Interrupt-Driven SoC Parallelism: Integrated a dedicated `winograd_irq` signal, enabling true asynchronous parallel execution between the TinyQV RISC-V core and the Winograd accelerator.
- **Known Issues**:
  - Memory Bandwidth Limitation: The overall system throughput is currently constrained by the CPU-bound Load/Store mechanism. This has been identified as a critical performance bottleneck targeted for improvement in DP2.
  - SS Corner Timing: The SS worst-case corner (nom_ss_100C_1v60) exhibits Setup WNS = −2.478 ns (959 violations, TNS = −622.68 ns), primarily attributed to high fanout (1334) on critical nets. This is the primary DP2 optimization target.
  - Power: The design exhibits a dominant Internal Power component (23.08 mW out of 30.95 mW total), primarily attributed to the high register density required for the $F(2,3)$ algorithm's buffering system.
- **Future Improvements**:
  - Resolve SS corner timing violations by inserting buffers and reducing fanout on high-fanout nets (currently 1334 violations).
  - Implement fine-grained clock gating techniques to reduce total power consumption (currently 30.95 mW at TT corner).
  - Further optimize PPA through re-targeting `CLOCK_PERIOD` and `PL_TARGET_DENSITY` in OpenLane2.

## Verification Checklist
- [x] All source files compile without errors
    - Linting & Compilation: Performed linting using Verilator to ensure standardized source code, confirming 0 lint errors, 0 inferred latches, and 3 non-critical warnings.
    - Synthesis Success: All modules (including `winograd.v`, `interface.v`, `tqvp_winograd.v`, and their respective sub-modules) were successfully synthesized through the OpenLane flow, producing 63,311 cells post-synthesis.
- [x] Testbenches run successfully
    - Module-level: Matrix transformation and element-wise multiplier blocks successfully passed individual test scenarios using reference data generated from Python.
    - System-level: Verified seamless data exchange between the TinyQV processor and the Winograd accelerator via the system bus at the `0x800_0380` memory-mapped address.
    - Computational Accuracy: Simulation results from Icarus Verilog demonstrate that computational errors remain well within the permissible tolerance for the 32-bit fixed-point representation.
- [x] ASIC Physical Sign-off verified
    - DRC (Design Rule Check): 0 violations (Magic VLSI). 
    - LVS (Layout vs. Schematic): 0 errors (Netgen). 
    - Timing Closure (TT corner): Setup WNS = +2.448 ns, TNS = 0.0 ns. 
    - Timing (SS corner): Setup WNS = −2.478 ns — identified as DP2 optimization target.
- [x] AI interaction logs are complete
    - A complete set of 11 Prompt Logs (PL-01 to PL-11) is provided, detailing the entire process from the initial RTL design phase through PPA optimization and OpenLane debugging.
- [x] Documentation is thorough and clear

## Team Statement
We certify that this submission represents our original work, completed according to AI-HDL rules and academic integrity guidelines. All AI interactions have been logged and submitted.

**Team Representative**: Member A
