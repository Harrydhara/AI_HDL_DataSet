# AI-HDL Challenge [X] Submission Form

## Basic Information
- **Submission Date**: 2026-02-26
- **Challenge Number**: [2]
- **Team Name**: ICLab_HUST2
- **Team ID**: ICLab_HUST2

## Team Members
| Name | Role | Email | Contribution % |
|------|------|-------|----------------|
| [member] | RTL Design, PPA Optimization & Verification Lead | [email] | 80% |
| [member] | Technical Research & Support | [email] | 5% |
| [member] | Technical Research & Support | [email] | 5% |
| [member] | Technical Research & Support | [email] | 5% |
| [member] | Technical Research & Support | [email] | 5% |

## Design Specifications Met
- [x] All required functionality preserved (Winograd $F(2\times2, 3\times3)$ with TinyQV integration — regression tests pass)
- [x] ASIC implementation successful (OpenLane RTL-to-GDSII, 15 runs)
- [x] Timing requirements met — **SS corner closed**: WNS nom_ss = **+0.900 ns**, setup violations = **0** (all corners)
- [x] Resource constraints satisfied — Core Utilization: **58.1%** (reduced from 90.0%)
- [x] All test cases pass (tb_wino Icarus Verilog PASS, cocotb v2 integration PASS)
- [x] DRC = 0, LVS = 0, Magic DRC = 0

## AI Tool Usage Declaration
- **Primary AI Tool**:
  - Claude Sonnet 4.5 / 4.6 (used throughout DP2 for RTL optimization, PPA analysis, OpenLane flow debugging, and report writing)
  - Gemini 2.5 Pro (used for supplementary physical design analysis and metrics interpretation)
- **Total Conversation Sessions**: 150+ sessions across DP1 and DP2
- **Estimated AI-Generated Code %**: 40–50% (RTL optimizations: Case 2a, Case 2b, PW-1)
- **Manual Modifications Made**: Yes
  - **RTL Pipelining**: Designed and verified PIPELINE_WAIT state insertion in `matrix_filter.v` (Case 2a) and 2-stage `fp_mult_reg` pipeline in `element_wise.v` (Case 2b) to break critical path.
  - **Clock Gating Architecture**: Designed PW-1 clock gating for `matrix_input.v` and `matrix_output.v` — separated FSM always block from gated register blocks to avoid hold violations; required 3 iterations (v1 hold vio → v2 overlap → v3 final clean).
  - **OpenLane Flow Tuning**: Manually selected SYNTH_STRATEGY DELAY 0, die expansion to 1900×520 µm, GPL_MAX_PHI_COF tuning, and antenna threshold sweep across 5 runs.
  - **Cocotb v2 Compatibility**: Fixed `_BitHandle` wrapper and `int()` conversion issues after cocotb 2.1.0 migration.

## Special Considerations
- **Bonus Features Implemented**:
  - **Full Timing Closure at SS Corner**: WNS nom_ss = +0.900 ns, WNS max_ss = +0.784 ns, TNS = 0.00 ns, setup violations = 0 across all corners — first clean closure in 8 runs of timing attempts.
  - **Clock Gating Implementation**: 360 ICG cells synthesized via USE_LIGHTER + PW-1 RTL clock gating on matrix_input/output register arrays. Internal power reduced 34.1% (23.08 → 15.22 mW).
  - **Systematic PPA Campaign**: 15 OpenLane runs with one parameter changed per run, enabling clear cause-effect attribution. Full run history with metrics documented in DP2 report.
  - **Antenna Violation Root Cause Analysis**: Analyzed `antenna.rpt` at the net level — identified all 20 violations as met3 side-area ratio (structural routing topology, not gate-area). Conducted 5-run threshold sweep (threshold 90–200) to characterize the repair plateau.

- **Known Issues**:
  - **Antenna violations**: 20 residual met3 side-area violations (worst ratio 4.4×, borderline). DRC=0, Magic DRC=0, LVS=0 confirmed. Non-functional, within TinyTapeout fab tolerance.
  - **Fanout violations**: 1,104 nets (target was <200). Timing is fully closed (WNS +0.900 ns, slew vio=4). Fanout violations are a signal quality warning caused by DELAY 0 large drive-strength cells — non-functional.
  - **Power total above baseline**: 38.16 mW vs 30.95 mW baseline (+23%). Caused by USE_LIGHTER clock buffers (~1,892 cells × 50 MHz). Internal power improved 34.1%; total power increase is a documented flow-level trade-off required for timing closure.

- **Future Improvements (DP3)**:
  - Security vulnerability analysis of SPI register interface (interface.v, 6-bit address map at 0x800_0380)
  - Power side-channel analysis — 360 ICG cells create state-dependent switching patterns observable in power traces
  - Complete P-2 (matrix_input pipeline) with larger die to further reduce fanout violations
  - Complete PW-2 explicit m_buffer clock enable

## Verification Checklist
- [x] All source files compile without errors
    - Verilator lint: 0 errors, 0 inferred latches, 3 pre-existing warnings (non-critical)
    - All 5 optimized modules (matrix_filter.v, element_wise.v, matrix_input.v, matrix_output.v, interface.v) synthesize cleanly through OpenLane
- [x] Testbenches run successfully
    - **tb_wino.v** (Icarus Verilog): PASS — output values match reference after +1 cycle pipeline latency compensation for Case 2a+2b
    - **cocotb integration** (v2.1.0, OSS CAD Suite): PASS — full TinyQV SPI bus simulation, register read/write, filter/input/output verified
    - Computational accuracy: fixed-point Q16.16 errors within tolerance
- [x] ASIC Physical Sign-off verified
    - DRC (Magic VLSI): **0 violations**
    - LVS (Netgen): **0 errors**
    - Timing (nom_ss corner): WNS = **+0.900 ns**, TNS = **0.00 ns**, violations = **0**
    - Timing (max_ss corner): WNS = **+0.784 ns**, violations = **0**
    - Hold timing: WNS hold = +0.279 ns, hold violations = **0**
- [x] AI interaction logs are complete
    - Prompt Logs updated through DP2 covering RTL optimization, OpenLane flow, cocotb debugging, and PPA analysis
- [x] Documentation is thorough and clear
    - DP2 Optimization Report (v6): 5 sections, 15-run history, before/after comparison, trade-off justification, rubric compliance checklist

## Team Statement
We certify that this submission represents our original work, completed according to AI-HDL rules and academic integrity guidelines. All AI interactions have been logged and submitted.

**Team Representative**: Member A
