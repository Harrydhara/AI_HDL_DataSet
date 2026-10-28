# AI Interaction Log — DP3 Security Hardening

**Team:** ICLab_HUST2
**Challenge:** team-ICLab_HUST2-challenge-3
**Phase:** Design Phase 3 (Security Hardening)
**Period:** March 2026
**AI Tool:** Claude Sonnet 4.6 (claude.ai / Cowork mode)

---

## Conversation 1: Project Scan & DP3 Readiness Assessment

**Date:** March 2026
**Purpose:** Recursively scan the full project, assess DP1/DP2 status, and analyze DP3 requirements in detail.

**Prompt:**
> Scan the entire project recursively. 1. List all files. 2. Analyze the two folders team-ICLab_HUST2-challenge-1 (DP1) and team-ICLab_HUST2-challenge-2 (DP2) in detail. 3. Read DP3 requirements carefully and check whether DP2 is ready for DP3. 4. Analyze in detail what I need to do for DP3.

**AI Output Summary:**
- Recursively listed all files across challenge-1, challenge-2, and challenge-3 directories.
- Confirmed DP2 sign-off: WNS nom_ss = +0.900 ns (0 setup violations), DRC=0, LVS=0, cocotb PASS, lint 0 errors.
- Identified that DP3 starts from the DP2 optimized baseline (challenge-3 = copy of challenge-2 + security additions).
- Analyzed DP3 README: 4-week structure, grading weights (Security Implementation 30%, Validation 25%, Assessment 20%, Documentation 15%, Stability 10%), deadline March 26.
- Identified `interface.v` as the sole attack surface (all MMIO registers exposed here).

**Human Modification:**
- Confirmed that challenge-3 folder had already been created as a copy of challenge-2 RTL.
- Uploaded DP3 README (README (2).md) for detailed re-analysis.

---

## Conversation 2: Step-by-Step DP3 Planning

**Date:** March 2026
**Purpose:** Get a complete ordered checklist of everything to do for DP3 from start to finish.

**Prompt:**
> List every step I need to do from start to finish for DP3.

**AI Output Summary:**
Produced a 7-step ordered plan:
1. Security Assessment — identify all vulnerabilities in the design
2. Implement Security Features — RTL countermeasures in interface.v
3. Security Testbench — adversarial test cases simulating attacks
4. Run Cocotb Regression — confirm DP2 functionality is preserved
5. PPA Overhead Analysis — quantify cost of security additions
6. Write DP3 Security Report — full documentation
7. Git commit + tag DP3-Submission + push

**Human Modification:**
- No changes to the plan; used as-is.

---

## Conversation 3: Security Assessment Document

**Date:** March 2026
**Purpose:** Analyze the challenge-3 source code in detail and produce a comprehensive Security Assessment Document.

**Prompt:**
> Analyze the source code in detail (I already added it to team-ICLab_HUST2-challenge-3). Create the most complete and detailed Security Assessment Document possible.

**Key Analysis Performed:**
- Read `interface.v` (DP2 baseline) in full — identified MMIO register map, write/read paths, Feed FSM, IRQ logic.
- Applied CIA Triad analysis to identify Confidentiality, Integrity, and Availability threats.
- Applied STRIDE threat model across all 6 categories (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege).
- Scored 10 vulnerabilities using DREAD (1-10 scale): Damage, Reproducibility, Exploitability, Affected Users, Discoverability.

**Top 5 Vulnerabilities Identified:**

| ID  | Vulnerability                       | DREAD | CWE      |
|-----|-------------------------------------|-------|----------|
| V-1 | Write-while-busy buffer corruption  | 8.4   | CWE-284  |
| V-2 | CTRL re-trigger during computation  | 8.6   | CWE-362  |
| V-3 | No access control on CTRL register  | 8.6   | CWE-284  |
| V-5 | 32'hDEADBEEF information disclosure | 8.2   | CWE-200  |
| V-4 | Filter index out-of-bounds          | 6.2   | CWE-20   |

**AI Output:**
- Created `docs/security_assessment.md` (~400 lines): 8 sections covering Design Overview, CIA Analysis, STRIDE (16 specific threats), DREAD scoring table, CWE details, Per-Module vulnerability analysis, Mitigation Plan, and Summary Table.

**Human Modification:**
- Reviewed threat analysis and confirmed the vulnerability priorities matched the team's intuition about the design.

---

## Conversation 4: CM-1 — Write-While-Busy Protection Implementation

**Date:** March 2026
**Purpose:** Implement the highest-priority security feature (CM-1) in RTL.

**Prompt:**
> Check the information carefully, and if correct, implement Step 2: Implement Security Features in RTL.

**Design Decisions Made (with AI reasoning):**

1. **`busy_guard` wire vs register:** Chose a pure wire tap `wire busy_guard = status_reg[STATUS_BUSY_BIT]` (zero latency) rather than a registered copy that would add 1-cycle lag.

2. **`sec_violation_flag` sole-driver architecture:** Placed in a dedicated `always @(posedge clk)` block (not merged into the write block) to prevent multi-driver synthesis issues. Priority: reset > attack-set > STATUS-read-clear.

3. **CTRL write strategy:** Mask only START bit (`{data_in[31:1], 1'b0}`) when BUSY, rather than blocking the full CTRL write. This allows ACCUM_EN, CLEAR_ACC, IRQ_EN to remain writable during computation.

4. **STATUS live insertion:** Insert `sec_violation_flag` directly into the STATUS read MUX (not through status_reg pipeline) to ensure CPU sees the violation flag on the very next STATUS read — no 1-cycle lag.

**RTL Changes in `interface.v`:**
```verilog
localparam STATUS_SEC_VIO_BIT = 2;
wire busy_guard = status_reg[STATUS_BUSY_BIT];
reg  sec_violation_flag;

// Write protection
if (is_ctrl)
    ctrl_reg <= busy_guard ? {data_in[31:1], 1'b0} : data_in;
if (is_input_data)
    if (!busy_guard) input_buffer[input_idx] <= data_in;
if (is_filter_data)
    if (!busy_guard) filter_buffer[filter_idx] <= data_in;

// Violation flag management (dedicated block)
always @(posedge clk or negedge rstn) begin
    if (!rstn) sec_violation_flag <= 0;
    else if (write_req && busy_guard && (is_input_data || is_filter_data
             || (is_ctrl && data_in[CTRL_START_BIT])))
        sec_violation_flag <= 1;
    else if (read_req && is_status)
        sec_violation_flag <= 0;  // clear-on-read
end

// STATUS read: insert flag live
6'h04: data_out <= {status_reg[31:3], sec_violation_flag, status_reg[1:0]};
```

**Lint Check Result:** pyslang — 0 errors, 0 warnings ✅

**Human Modification:**
- Architecture decisions were reviewed and approved before implementation.

---

## Conversation 5: CM-2 — Debug Sentinel Removal

**Date:** March 2026
**Purpose:** Remove CWE-200 information disclosure vulnerability.

**Prompt:** (part of same implementation session as CM-1)

**Analysis:**
Three locations in the MMIO read path returned `32'hDEADBEEF` for unmapped addresses. This fingerprint reveals the register map structure to a bus enumerator.

**Fix:**
Replaced all 3 occurrences with `32'h00000000`:
```verilog
// DP2 (vulnerable):
default: data_out <= 32'hDEADBEEF;

// DP3 (fixed):
default: data_out <= 32'h00000000;
```

**Human Modification:** None — straightforward replacement verified via grep.

---

## Conversation 6: Security Testbench Development

**Date:** March 2026
**Purpose:** Create a dedicated security testbench that proves CM-1 and CM-2 work under adversarial conditions.

**Prompt:**
> Do the next step for me and tell me what commands I need to run.

**AI Output:**
Created `testbench/tb_security/tb_security.v` with:
- 7 test cases (later extended to 8 with CM-3)
- MMIO task library: `mmio_write`, `mmio_read`, `wait_busy`, `wait_done`, `check_eq`, `check_ne`, `check_bit`
- Reference data: filter = all 1.0 (Q16.16 = 0x00010000), input = 1.0–16.0

**Run Commands:**
```bash
iverilog -o sim_security testbench/tb_security/tb_security.v src/*.v
vvp sim_security
gtkwave tb_security.vcd &
```

**Human Modification:**
- After running, TEST 5 (SEC_VIO clear-on-read) failed. Root cause: TEST 4's STATUS read had already triggered clear-on-read, so the flag was 0 by the time TEST 5 checked it.
- Fix: Made TEST 5 self-contained by triggering a fresh violation at the start of the test.

---

## Conversation 7: Test Failure Debug — TEST 5 Clear-on-Read Timing

**Date:** March 2026
**Purpose:** Debug the 1 failing test case (TEST 5) in the security testbench.

**Root Cause Analysis:**
```
RTL behavior: When mmio_read(STATUS) is called at clock edge N:
  - data_out[2] captures sec_violation_flag (= 1) via non-blocking assignment
  - sec_violation_flag <= 0 is scheduled simultaneously
  - After edge N: data_out[2] = 1 (old), sec_violation_flag = 0 (new)
```
TEST 4 had performed `mmio_read(STATUS)` to verify `SEC_VIO=1`, which cleared the flag. TEST 5 then assumed the flag was still 1.

**Fix Applied:**
Added `full_setup_and_start() + wait_busy() + mmio_write(attack)` at the start of TEST 5 to trigger a fresh violation before checking the clear-on-read mechanism.

**Final Result:** 36/36 checks PASS ✅

---

## Conversation 8: CM-3 — Filter Index Out-of-Bounds Clamping

**Date:** March 2026
**Purpose:** Implement additional security countermeasure for CWE-20 (Improper Input Validation).

**Prompt:**
> Check where I can do better with security, then implement it for me.

**Vulnerability Identified:**
`filter_wr_idx` is a 4-bit register, but the filter buffer only has 9 elements (indices 0–8). Writing `FILTER_IDX = 9–15` places the pointer in an undefined region; while the `default: ;` case prevents actual buffer writes, the index register enters an invalid state.

**Fix Implemented:**
```verilog
// CM-3: Clamp FILTER_IDX to valid range [0,8]
wire filter_idx_oob = (data_in[3:0] > 4'd8);
...
else if (is_filter_idx)
    filter_wr_idx <= filter_idx_oob ? 4'd8 : data_in[3:0];

// CM-3: OOB index write also sets sec_violation_flag
if ((write_req && busy_guard && (is_input_data || is_filter_data
     || (is_ctrl && data_in[CTRL_START_BIT]))) ||
    (write_req && is_filter_idx && filter_idx_oob)) begin
    sec_violation_flag <= 1'b1;
end
```

**New TEST 8 added to testbench:**
- FILTER_IDX = 12 (OOB) → SEC_VIO=1, clamped to 8 ✅
- FILTER_IDX = 15 (OOB) → SEC_VIO=1 ✅
- FILTER_IDX = 0 (valid) → SEC_VIO=0 ✅
- FILTER_IDX = 8 (boundary, valid) → SEC_VIO=0 ✅
- FILTER_IDX = 9 (just OOB) → SEC_VIO=1 ✅

**Lint Result:** 0 errors, 0 warnings ✅

---

## Conversation 9: PPA Overhead Discussion & Yosys Script

**Date:** March 2026
**Purpose:** Address the mandatory "Updated PPA metrics" deliverable from Week 3.

**Prompt:**
> Should I run synthesis and OpenLane2? There's a requirement to analyze PPA impact.

**AI Analysis:**
DP3 adds the following to `interface.v` compared to DP2 baseline:

| Element             | Type         | Estimated cost (sky130A) |
|---------------------|--------------|--------------------------|
| sec_violation_flag  | 1-bit FF     | ~6.0 µm²                |
| busy_guard          | Wire (0 LUTs)| 0 µm²                   |
| CM-1 muxes          | ~5 AND/MUX2  | ~13 µm²                 |
| CM-3 comparator     | 4-bit compare| ~4 µm²                  |
| filter_idx_oob wire | Combinational| ~2 µm²                  |
| **Total**           |              | **~25 µm²**             |

DP2 core area: ~33,000 µm² → overhead **< 0.08%**

**Yosys Script Created:** `synth_dp3.ys` (for user to run locally where Yosys is available)

**Human Modification:**
- User confirmed Yosys was used during DP2; will run locally for actual cell count.

---

## Summary of AI Contributions

| Task                              | AI Role                    | Human Role                          |
|-----------------------------------|----------------------------|-------------------------------------|
| Vulnerability identification      | Full STRIDE/DREAD/CWE analysis | Confirmed priorities               |
| CM-1 RTL architecture             | Design + implementation    | Reviewed and approved key decisions |
| CM-2 sentinel removal             | Implementation             | Verification via grep               |
| CM-3 bounds clamping              | Design + implementation    | Identified general need             |
| Security testbench                | Full testbench authoring   | Ran simulation, reported results    |
| TEST 5 debug                      | Root cause + fix           | Ran simulation to reproduce         |
| Security Assessment document      | Full document (8 sections) | Reviewed content                    |
| DP3 Security Report               | Full document              | Reviewed content                    |
| Submission form                   | Drafted                    | Final review                        |
| Yosys synthesis script            | Authored                   | Will run locally                    |

**Estimated AI-Generated Code:** 50–60% (RTL security logic, testbench, documentation)
**Estimated Human Contribution:** 40–50% (design decisions, architecture review, simulation execution, result verification)
