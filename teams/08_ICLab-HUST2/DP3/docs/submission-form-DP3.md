# AI-HDL Challenge [3] Submission Form

## Basic Information
- **Submission Date**: 2026-03-26
- **Challenge Number**: [3]
- **Team Name**: ICLab_HUST2
- **Team ID**: ICLab_HUST2

## Team Members
| Name | Role | Email | Contribution % |
|------|------|-------|----------------|
| [member] | RTL Security Hardening, Verification Lead | [email] | 80% |
| [member] | Technical Research & Support | [email] | 5% |
| [member] | Technical Research & Support | [email] | 5% |
| [member] | Technical Research & Support | [email] | 5% |
| [member] | Technical Research & Support | [email] | 5% |

## Design Specifications Met
- [x] DP2 baseline preserved — all DP2 optimizations (PIPELINE_WAIT, fp_mult_reg pipeline, clock gating) retained intact
- [x] Security Assessment completed — `docs/security_assessment.md` (10 vulnerabilities, STRIDE/DREAD/CWE analysis)
- [x] Security Feature CM-1 implemented — Write-While-Busy Protection in `interface.v`
- [x] Security Feature CM-2 implemented — Debug Sentinel Removal in `interface.v`
- [x] Security Feature CM-3 implemented — Filter Index Out-of-Bounds Clamping in `interface.v`
- [x] Security testbench — `testbench/tb_security/tb_security.v` (8 tests, **41/41 checks PASS**)
- [x] Post-attack regression PASS — accelerator functional correctness preserved
- [x] PPA overhead measured via Yosys synthesis — **+772 cells (+1.07%) full design; +1 FF; 0 ns timing impact**
- [x] PPA overhead verified via OpenLane2 physical synthesis (sky130A, 50 MHz) — **Area −2.7%, Power −5.7%, WNS_ss +0.758 ns, 0 violations all corners, DRC=0, LVS=0**
- [x] Synthesis summary — `results/synthesis/synthesis_summary.md` (Yosys cell-count + OpenLane2 full comparison)
- [x] OpenLane2 PPA report — `results/PPA result/PPA_result.md` (full DP2 vs DP3 physical metrics)
- [x] RTL lint clean — pyslang 0 errors, 0 warnings on `interface.v` (DP3 version)
- [x] DP3 Security Report — `docs/DP3_Security_Report.md` (Yosys + OpenLane2 real numbers, CM-1/CM-2/CM-3)
- [x] AI Logs — `ai_logs/security_hardening.md` (English, 9 conversation entries)

## Security Features Implemented

### CM-1: Write-While-Busy Protection (CWE-284, CWE-362, CWE-667)

**Vulnerability addressed:** In DP2, `input_buffer`, `filter_buffer`, and `CTRL[START]` had no access control during computation. An attacker (or racing interrupt handler) could corrupt buffers mid-computation or re-trigger the FSM from an undefined state.

**RTL changes in `interface.v`:**
- Added `wire busy_guard = status_reg[STATUS_BUSY_BIT]` — 0-delay tap on existing BUSY status bit
- Added `localparam STATUS_SEC_VIO_BIT = 2` — new STATUS register bit for violation reporting
- Added `reg sec_violation_flag` — 1-bit register, set on blocked attack, clear-on-read
- INPUT_DATA write: fully blocked when `busy_guard=1`
- FILTER_DATA write: fully blocked when `busy_guard=1`
- CTRL write: START bit masked to 0 when `busy_guard=1`; other bits (ACCUM_EN, CLEAR_ACC, IRQ_EN) remain writable
- STATUS read: `sec_violation_flag` inserted live at bit 2 (no 1-cycle lag via pipeline)
- Dedicated `always @(posedge clk)` block for `sec_violation_flag` (sole-driver, prevents synthesis multi-driver issues)

### CM-2: Debug Sentinel Removal (CWE-200, CWE-1233)

**Vulnerability addressed:** DP2 returned `32'hDEADBEEF` for three unmapped register address offsets. This leaks structural information about the register map to a bus enumerator.

**RTL changes in `interface.v`:**
- All three `32'hDEADBEEF` occurrences in default read case-arms replaced with `32'h00000000`

## AI Tool Usage Declaration
- **Primary AI Tool**:
  - Claude Sonnet 4.6 (used throughout DP3 for vulnerability analysis, RTL implementation, testbench generation, and report writing)
- **Total Conversation Sessions**: ~20 sessions for DP3
- **Estimated AI-Generated Code %**: 50–60% (security logic, testbench, report structure)
- **Manual Modifications Made**: Yes
    - **Security Architecture Decisions**: Chose dedicated always block for `sec_violation_flag` (vs. combined write block) to prevent multi-driver RTL. Chose to mask only START bit in CTRL (not full CTRL block) to minimize functional restriction.
  - **Live STATUS Insertion**: Decided to insert `sec_violation_flag` directly into the STATUS read MUX (not routed through status_reg) to ensure software sees the violation flag on the same clock cycle it's set — no lag.
  - **Priority Logic Design**: Set `sec_violation_flag` priority order: reset > attack-set > read-clear, ensuring security-biased behavior (attack on same cycle as read = flag stays set).
  - **CM-3 Boundary Design**: Chose to clamp OOB index to last-valid slot (8) rather than 0, to avoid resetting attacker-controlled index unexpectedly. OOB detection uses combinational `filter_idx_oob = (data_in[3:0] > 4'd8)` — 4-bit compare, single gate level.

## Special Considerations
- **Security Features Scope Decision:**
  Five additional lower-risk vulnerabilities (power side-channel CWE-1300, accumulator overflow CWE-190, ECC CWE-1259, no authentication CWE-693, index out-of-bounds CWE-20) were identified but deferred to DP4. All five require either physical-layer countermeasures or structural changes to the computation core — out of DP3 RTL scope and would introduce non-trivial PPA impact not justified by risk level at this design stage.

- **Bonus Features:**
  - **`sec_violation_flag` clear-on-read**: Provides software with a hardware-managed attack log — no manual flag-clear register needed. The OS driver can detect security events simply by polling STATUS bit 2.
  - **SVA formal properties**: Five SystemVerilog assertions provided in `docs/DP3_Security_Report.md` for future JasperGold/SymbiYosys formal closure.
  - **Comprehensive threat model**: Full STRIDE × 6 × 3 (threat agents) + DREAD (1–10) scoring for all 10 vulnerabilities documented in `docs/security_assessment.md`.

- **Known Limitations:**
  - Formal verification (JasperGold/SymbiYosys) not run — tool unavailable. SVA properties are provided in `docs/DP3_Security_Report.md` for manual formal closure if required.
  - Power side-channel (CWE-1300) remains unmitigated — 361 ICG cells create operand-dependent switching patterns. Recommended mitigation is operand masking in `element_wise.v` (DP4 item).

- **Future Improvements (DP4):**
  - Power side-channel countermeasure: constant-time multiply or operand masking in `element_wise.v`
  - Accumulator saturation arithmetic to prevent CWE-190 overflow silent wraparound
  - SECDED parity on `input_buffer[]` and `filter_buffer[]` for fault injection resilience
  - Privilege-level gating on CTRL[START] if TinyQV deploys in multi-privilege configuration

## Verification Checklist
- [x] All source files compile without errors
    - pyslang lint on `interface.v` (DP3): **0 errors, 0 warnings**
    - All other src/*.v files: unchanged from DP2 (lint verified in DP2)
- [x] Security testbench runs successfully — **41/41 checks PASS**
    - TEST 1: Normal baseline — PASS
    - TEST 2: INPUT_DATA write-while-busy blocked — PASS
    - TEST 3: FILTER_DATA write-while-busy blocked — PASS
    - TEST 4: CTRL START re-trigger blocked — PASS
    - TEST 5: SEC_VIO clear-on-read — PASS
    - TEST 6: No DEADBEEF sentinel (CM-2) — PASS
    - TEST 7: Post-attack regression — PASS
    - TEST 8: CM-3 filter index bounds clamping (5 checks) — PASS
- [x] Functional regression preserved (TEST 7 + tb_main cocotb/iverilog from DP2)
- [x] Synthesis PPA verified (Yosys): **+772 cells (+1.07%) full design, +1 FF, 0 ns timing**
    - `results/synthesis/synthesis_summary.md` — Yosys cell-count + OpenLane2 comparison table
- [x] Physical PPA verified (OpenLane2, sky130A): **Area −2.7%, Power −5.7%, 0 violations all corners**
    - `results/PPA result/PPA_result.md` — full DP2 vs DP3 OpenLane2 metrics (area, power, timing, DRC, LVS)
- [x] Documentation complete
    - `docs/security_assessment.md`: Full vulnerability analysis (STRIDE, DREAD, CWE)
    - `docs/DP3_Security_Report.md`: Implementation + Yosys + OpenLane2 PPA numbers + validation (CM-1/CM-2/CM-3)
    - `ai_logs/security_hardening.md`: English AI interaction log (9 conversations)
- [x] Repository organized for DP4 handoff
    - `src/` — DP3-hardened RTL (interface.v updated, all others unchanged from DP2)
    - `testbench/tb_security/` — security-specific testbench
    - `testbench/tb_main/` — original functional testbench (DP2, updated with DP3 interface.v)
    - `docs/` — security_assessment.md + DP3_Security_Report.md

## Team Statement
We certify that this submission represents our original work, completed according to AI-HDL rules and academic integrity guidelines. All AI interactions have been logged and submitted.

**Team Representative**: Member A
