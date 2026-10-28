# DP3 Detailed Optimization Plan

**Project:** Ingenius CRC Peripheral  
**Phase:** DP3 – Power Optimization  
**Duration:** 3 weeks  
**Goal:** Reduce power by 12-17% while maintaining 125 MHz frequency

---

## Executive Summary

**Current State (DP2)**:
- Power: 7.81 mW (66.3% combinational, 33.7% sequential)
- Frequency: 125 MHz
- Area: 988 cells
- Timing: WNS = 0.0 ns (tight), Setup slack = 1.35 ns, Hold slack = 0.32 ns

**Target (DP3)**:
- Power: 6.5-6.8 mW (-12-17%)
- Frequency: 125 MHz (maintain)
- Area: 970-990 cells (slight improvement)
- Timing: WNS ≥ 0.0 ns, Setup/hold slack maintained

**Strategy**: Conservative, balanced approach with low technical risk

---

## Phase 1: Analysis & Clock Gating (Week 1)

### Objectives
1. Understand power distribution at module/gate level
2. Verify clock gating implementation
3. Identify optimization candidates
4. Plan Multi-Vt swaps

### Tasks

#### **1.1: Power Breakdown Analysis**
**Owner:** Power Analysis Lead  
**Effort:** 4 hours

**Deliverables:**
- Power breakdown by module (CRC datapath vs wrapper)
- Power by net type (register-to-register, combinational, clock)
- Leakage vs dynamic power split
- Switching activity per module

**Method:**
```bash
# In Docker, extract power report details
cd /openlane/designs/DP2/runs/RUN_2026.04.15_22.41.08/reports/
grep -A 50 "report_power" 31-rcx_sta.power.rpt

# Look for:
# - Internal power per state/comb
# - Switching power per module
# - Leakage power
```

**Expected Findings:**
- Combinational logic = 5.18 mW (66.3%)
- Sequential logic = 2.63 mW (33.7%)
- Total leakage: ~11.4 nW (negligible)

---

#### **1.2: Clock Gating Verification**
**Owner:** Synthesis Lead  
**Effort:** 6 hours

**Deliverables:**
- Clock gating cell count in DP2 netlist
- Enabled clock domain(s)
- Gating efficiency analysis

**Method:**
```bash
# Check if gating cells were inserted during DP2 synthesis
cd /openlane/designs/DP2/runs/RUN_2026.04.15_22.41.08/results/
grep -c "CLKGATE" final.v  # If >0, gating was applied

# Analyze gating enable signals
grep "enable" final.v | head -20

# Review synthesis logs
cat openroad_*.log | grep -i "gating"
```

**Expected Findings:**
- If CLKGATE count = 0 → Add clock gating in DP3 (5-10% gain)
- If gating enabled → Verify coverage is sufficient
- Non-critical paths may not be gated (optimization opportunity)

---

#### **1.3: Slack Margin Assessment**
**Owner:** Timing/PPA Lead  
**Effort:** 8 hours

**Deliverables:**
- Per-gate setup/hold slack spreadsheet
- Identification of non-critical paths
- Multi-Vt swap candidates (HVt/SVt/LVt)

**Method:**
```bash
# Generate detailed timing report
cd /openlane/designs/DP2/runs/RUN_2026.04.15_22.41.08/reports/
# Extract from 31-rcx_sta.max.rpt:
# - Paths with setup slack > 1.0 ns → HVt candidates
# - Paths with setup slack > 0.5 ns → Conservative HVt candidates
# - Paths on WNS path → Keep as SVt/LVt

# Create summary:
# | Cell | Setup Slack | Hold Slack | Recommendation |
# |------|-------------|-----------|-----------------|
# | gate1 | 1.5 ns | 0.4 ns | HVt swap |
# | gate2 | 0.2 ns | 0.1 ns | Keep SVt |
```

**Expected Findings:**
- ~40% of gates have setup slack > 0.5 ns (HVt candidates)
- ~200-300 cells could potentially be swapped
- Focus on non-critical paths away from WNS path

---

#### **1.4: Phase 1 Deliverables**
**Due:** End of Week 1

Checklist:
- [ ] Power breakdown analysis document (power_analysis_DP3_W1.txt)
- [ ] Clock gating verification report
- [ ] Per-gate slack spreadsheet (slack_analysis.csv)
- [ ] Optimization candidates list (candidates_hvt_svt.csv)
- [ ] Phase 1 summary presentation

**Success Criteria:**
- Clear understanding of power sources (66% combina)
- Confirmation of clock gating status
- >200 cells identified for HVt swap
- Expected power savings: 3-5% from clock gating

---

## Phase 2: Multi-Vt Optimization (Week 2)

### Objectives
1. Configure OpenLane Multi-Vt constraints
2. Swap SVt → HVt on safe paths
3. Re-run synthesis and validate timing
4. Measure power reduction

### Tasks

#### **2.1: Create OpenLane Multi-Vt Configuration**
**Owner:** Synthesis Lead  
**Effort:** 6 hours

**Deliverables:**
- Updated `designs/DP3/config.tcl` with Multi-Vt constraints
- Liberty files for HVt/SVt cells (if needed)

**Method:**
```tcl
# In config.tcl, add:

# Multi-Vt Cell Constraints
set ::env(CELL_PAD) 2
set ::env(SYNTH_CELL_TYPE) "hvt"  # Default to HVt
set ::env(SYNTH_TIMING_DRIVEN) 1

# Specify cells that MUST use LVt/SVt (critical paths)
set critical_cells {
  # From slack analysis:
  # "cell_on_wns_path_1"
  # "cell_on_wns_path_2"
}

# Mark these cells in Liberty:
# .cell_type : "lv"  (LVt for critical)
# .cell_type : "sv"  (SVt for near-critical)
# .cell_type : "hv"  (HVt for non-critical) [default]
```

**Expected Outcome:**
- OpenLane configured to use mixed Vt cells
- Synthesis will attempt to use HVt where slack allows
- Critical paths protected with SVt/LVt

---

#### **2.2: Run DP3-A Synthesis (Multi-Vt Only)**
**Owner:** Synthesis Lead  
**Effort:** 8 hours

**Deliverables:**
- DP3-A netlist (first iteration)
- Timing report (verify closure)
- Power report (DP3-A_power.txt)
- Comparison vs DP2

**Method:**
```bash
# In Docker:
cd /openlane/designs/DP3
openlane designs/DP3/config.tcl

# Extract results:
# - Timing: reports/signoff/sta_summary.rpt
# - Power: reports/signoff/power_report.txt
# - Area: reports/signoff/area.rpt
```

**Expected Results:**
- WNS: ≥ 0.0 ns (should maintain or improve)
- Power: 7.0-7.2 mW (-8-10% from DP2)
- Area: ~980-990 cells (slight reduction)
- Setup slack: ≥ 0.8 ns (safe margin)
- Hold slack: ≥ 0.2 ns (safe margin)

**If timing fails:**
- Add more SVt cells on critical paths
- Adjust timing constraints
- Re-run synthesis

---

#### **2.3: Validate Functionality**
**Owner:** Verification Lead  
**Effort:** 4 hours

**Deliverables:**
- Regression test results
- Functional validation report

**Method:**
```bash
# Simulate DP3-A netlist with testbench
cd /openlane/designs/DP3/RTL
iverilog -o crc_tb.vvp crc_datapath.v crc_datapath_tb.v
vvp crc_tb.vvp

# Expected output:
# PASS: Input a5a5a5a5, CRC d0ca6977
# PASS: Input 5a5a5a5a, CRC 0e714994
# ... (all 6 vectors pass)
# Regression completed.
```

**Success Criteria:**
- All 6 regression vectors pass
- No timing violations
- Power reduction ≥ 8%

---

#### **2.4: Phase 2 Deliverables**
**Due:** End of Week 2

Checklist:
- [ ] DP3-A netlist (gate-level Verilog)
- [ ] Power comparison: DP2 vs DP3-A
- [ ] Timing report confirming closure
- [ ] Functional validation results
- [ ] Phase 2 summary (achieved ~10% power reduction)

**Success Criteria:**
- Power: 7.0-7.2 mW (validated)
- Timing: WNS ≥ 0.0 ns (validated)
- Functionality: All tests pass (validated)

---

## Phase 3: Logic Refinement (Week 3)

### Objectives
1. Select and implement one additional optimization
2. Fine-tune power further
3. Finalize DP3 results

### Options (Pick One)

#### **Option A: XOR Tree Restructuring** (MEDIUM EFFORT)
**Expected Gain:** 2-4% power

Focus on CRC polynomial XOR operations in `crc_datapath.v`:
```verilog
// Current (DP2):
wire [31:0] crc_next = msb_stage ? (shift_stage ^ POLY) : shift_stage;

// Optimized (DP3): Rearrange XOR operations for better gate sharing
// Or use carry-lookahead-like structure for faster XOR tree
```

**Steps:**
1. Analyze XOR depth in shift_stage ^ POLY operation
2. Restructure for reduced gate count / activity
3. Implement in RTL
4. Re-synthesize and measure

---

#### **Option B: Register Balancing** (LOW EFFORT)
**Expected Gain:** 1-2% power

Review pipelined registers for optimization:
- Remove redundant registers
- Consolidate adjacent pipeline stages if possible
- Adjust register widths on non-critical signals

---

#### **Option C: Input Slowing** (MEDIUM EFFORT)
**Expected Gain:** 2-3% power

Reduce switching activity on non-critical input nets:
- Add input condition logic to slow down transitions
- Register critical inputs earlier
- Use techniques like wave pipelining

---

#### **2.4: Phase 3 Deliverables**
**Due:** End of Week 3

Checklist:
- [ ] Final DP3 netlist
- [ ] Final power/timing/area reports
- [ ] Functional validation (all tests pass)
- [ ] DP2 vs DP3 comparison document
- [ ] Optimization summary and lessons learned

**Success Criteria:**
- Power: 6.5-6.8 mW (target achieved)
- Timing: WNS ≥ 0.0 ns (maintained)
- Functionality: All tests pass (validated)
- Area: <990 cells (maintained/improved)

---

## Measurement & Validation

### Power Measurement
```bash
# DP2 baseline:
cd /openlane/designs/DP2/runs/RUN_2026.04.15_22.41.08/reports/
grep "Total" 31-rcx_sta.power.rpt
# Total: 7.81 mW (66.3% comb, 33.7% seq)

# DP3 result:
cd /openlane/designs/DP3/runs/RUN_<DATE>/reports/
grep "Total" 31-rcx_sta.power.rpt
# Expected: 6.5-6.8 mW
```

### Timing Verification
```bash
# DP3 timing closure:
grep "wns\|worst slack" 31-rcx_sta.summary.rpt
# WNS must be ≥ 0.0 ns
# Setup slack ≥ 0.8 ns
# Hold slack ≥ 0.2 ns
```

### Functional Validation
```bash
# Run regression tests on DP3 netlist
cd RTL
iverilog -o crc_tb.vvp crc_datapath.v crc_datapath_tb.v
vvp crc_tb.vvp
# All 6 vectors must PASS
```

---

## Risk Mitigation

| Risk | Probability | Mitigation |
|------|-------------|-----------|
| **Timing violation in DP3-A** | Medium | Revert to more SVt cells on critical paths |
| **Insufficient power savings** | Low | Proceed to Option C (input slowing) |
| **Functional regression** | Low | Keep detailed test vectors in regression suite |
| **Netlist complexity** | Low | Use OpenLane's automated optimization |

---

## Success Metrics (Final)

| Metric | DP2 | DP3 Target | DP3 Actual | Status |
|--------|-----|-----------|-----------|--------|
| **Power** | 7.81 mW | 6.5-6.8 mW | TBD | |
| **Frequency** | 125 MHz | 125 MHz | TBD | |
| **Area** | 988 cells | <990 cells | TBD | |
| **WNS** | 0.0 ns | ≥0.0 ns | TBD | |
| **Setup Slack** | 1.35 ns | ≥0.8 ns | TBD | |
| **Hold Slack** | 0.32 ns | ≥0.2 ns | TBD | |
| **Functionality** | ✅ | ✅ All tests pass | TBD | |

---

## Timeline

| Week | Phase | Deliverable | Owner |
|------|-------|------------|-------|
| **W1** | Analysis | Power breakdown, slack analysis, candidates list | Power/Timing Lead |
| **W2** | Multi-Vt | DP3-A netlist, power validation, functional tests | Synthesis Lead |
| **W3** | Refinement | Final DP3 netlist, results comparison, summary | Synthesis/Power Lead |

---

## Sign-Off

- **Prepared by:** [Name TBD]
- **Reviewed by:** [Name TBD]
- **Approved by:** [Name TBD]
- **Date:** 2026-04-23

---

## Appendix: Tools & Commands

### OpenLane Synthesis
```bash
docker run --rm -it -v /path/to/designs:/openlane/designs \
  ghcr.io/the-openroad-project/openlane:latest \
  openlane designs/DP3/config.tcl
```

### Power Analysis
```bash
# Extract power from STA report
grep -A 20 "report_power" reports/31-rcx_sta.power.rpt
```

### Timing Analysis
```bash
# Check WNS and setup/hold slack
cat reports/31-rcx_sta.max.rpt | head -50
```

### Functional Validation
```bash
# Simulate netlist
iverilog -o test.vvp design.v testbench.v
vvp test.vvp
```

---

**End of DP3 Optimization Plan**
