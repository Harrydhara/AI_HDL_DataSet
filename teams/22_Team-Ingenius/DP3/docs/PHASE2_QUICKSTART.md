# Phase 2 Quick Start - Synthesis & Optimization

**Date:** 2026-04-23  
**Status:** Ready for team execution starting April 30  
**Duration:** 1 week (8 working days)

---

## 🎯 Phase 2 Mission

Execute clock gating + Multi-Vt optimization to reduce DP2 power (7.81 mW) to target range (6.0-6.3 mW).

**Success Criteria:**
- ✅ Power: 6.0-6.3 mW (8-10% reduction)
- ✅ Timing: WNS ≥ 0.0 ns maintained
- ✅ Functional: All 6 regression tests pass

---

## 👥 Role Assignments

### 1. Synthesis Lead (Primary Owner)
**Responsibility:** Configure OpenLane and run synthesis

**Deliverables:**
- [ ] `DP3/config_gating.tcl` (clock gating enabled)
- [ ] `DP3/config_multivt.tcl` (HVt cell list)
- [ ] DP3-A synthesis run completed
- [ ] Power report showing 6.0-6.3 mW

**Timeline:** 8-10 hours total
- Mon 3hrs: Configure gating settings
- Tue 2hrs: Create HVt candidates list
- Wed 3hrs: Run synthesis + troubleshoot

**Key Files to Modify:**
```
DP3/config.tcl (or create new config_phase2.tcl)
├─ set ::env(CLOCK_GATING_ENABLED) 1
├─ set ::env(CLK_GATE_CELLS) "sky130_fd_sc_hd__dlclkp_1 sky130_fd_sc_hd__dlclkp_2 sky130_fd_sc_hd__dlclkp_4"
├─ set ::env(SYNTH_GATING_CELLS) "sky130_fd_sc_hd__dlclkp* sky130_fd_sc_hd__sdlclkp*"
└─ set ::env(CLK_GATE_SETUP_TIME) 0.1e-9
```

**Success Signal:**
```
31-rcx_sta.power.rpt shows:
Total Power ≤ 6.3 mW ✅
```

---

### 2. Timing Optimization Lead (Secondary)
**Responsibility:** Verify timing and extract HVt candidates

**Deliverables:**
- [ ] `hvt_candidates.csv` (300+ cells with slack info)
- [ ] Phase 2 STA verification report
- [ ] Slack analysis summary

**Timeline:** 4-5 hours total
- Mon 1hr: Extract detailed slack from DP2 (if not already done)
- Tue 2hrs: Create hvt_candidates.csv with decision logic
- Wed 1-2hrs: Verify Phase 2 timing closure

**CSV Format:**
```
cell_id,cell_type,setup_slack_ns,hold_slack_ns,hvt_safe,reason
_0001_,sky130_fd_sc_hd__nor2_1,0.92,0.21,YES,Slack>0.5ns
_0002_,sky130_fd_sc_hd__mux2_1,0.34,0.16,NO,Slack<0.5ns
```

**Success Signal:**
```
Phase 2 STA report shows:
WNS ≥ 0.0 ns ✅
Setup violations: 0 ✅
Hold violations: 0 ✅
```

---

### 3. Verification Lead (Tertiary)
**Responsibility:** Functional validation

**Deliverables:**
- [ ] Regression test results (6 vectors)
- [ ] Pass/fail log with detailed output
- [ ] RTL vs. netlist correlation check (if needed)

**Timeline:** 2-3 hours total
- Wed 1hr: Prepare testbench (already in `RTL/crc_datapath_tb.v`)
- Thu 1hr: Run synthesis
- Fri 1hr: Execute functional tests

**Test Vectors:**
```
Vector 1: A5A5A5A5 → Expected: D0CA6977
Vector 2: 5A5A5A5A → Expected: 0E714994
Vector 3: 00000000 → Expected: 00000000
Vector 4: FFFFFFFF → Expected: DEBB20E3
Vector 5: 12345678 → Expected: 8E2958CE
Vector 6: DEADBEEF → Expected: 3B1EBF03

All 6 must PASS ✅
```

**Success Signal:**
```
Test Results:
PASS: 6/6 ✅
FAIL: 0/6 ✅
```

---

### 4. Documentation Lead (Optional)
**Responsibility:** Track results and prepare Phase 2 summary

**Deliverables:**
- [ ] Phase 2 progress log
- [ ] Results summary document
- [ ] Go/No-Go decision for Phase 3

**Timeline:** 2 hours total
- Daily: Track progress in shared doc
- Fri: Consolidate results

---

## 📋 Execution Checklist (Week 2: April 30 - May 6)

### Monday (April 30)

**Synthesis Lead:**
- [ ] Review clock gating report ([02_clock_gating_report.md](Reports/02_clock_gating_report.md))
- [ ] Review slack analysis ([03_slack_analysis_multivt_plan.md](Reports/03_slack_analysis_multivt_plan.md))
- [ ] Locate DP2 synthesis config (`../DP2/config.tcl`)
- [ ] Create `DP3/config_phase2.tcl` with gating settings
  ```tcl
  # Copy from DP2, add:
  set ::env(CLOCK_GATING_ENABLED) 1
  set ::env(CLK_GATE_CELLS) "sky130_fd_sc_hd__dlclkp_1 sky130_fd_sc_hd__dlclkp_2 sky130_fd_sc_hd__dlclkp_4"
  ```
- [ ] Start Docker OpenLane environment test

**Timing Lead:**
- [ ] Re-run DP2 STA to extract detailed slack (if new data needed)
- [ ] Start parsing slack values for hvt_candidates.csv

**Verification Lead:**
- [ ] Review testbench in `RTL/crc_datapath_tb.v`
- [ ] Verify 6 test vectors are present
- [ ] Prepare test execution environment

**All:**
- [ ] Attend brief team sync (15 min)
- [ ] Confirm role assignments and timeline

---

### Tuesday (May 1)

**Synthesis Lead:**
- [ ] Finalize config with all settings
- [ ] Extract DP2 netlist to understand structure
- [ ] Create HVt candidates list (300+ cells)
  - Use conservative threshold (slack > 0.5 ns)
  - Document cell_type for each candidate
- [ ] Save candidates list to `DP3/hvt_candidates_phase2.txt`

**Timing Lead:**
- [ ] Complete hvt_candidates.csv with decision logic
- [ ] Validate at least 200 cells identified
- [ ] Double-check hold slack for all candidates

**Verification Lead:**
- [ ] Set up testbench environment
- [ ] Prepare test script
- [ ] Verify testbench syntax is valid

---

### Wednesday (May 2)

**Synthesis Lead:**
- [ ] Finalize `config_phase2.tcl`
- [ ] Start Phase 2 synthesis run
  ```bash
  docker run --rm -it \
    -v /path/to/designs:/openlane/designs \
    ghcr.io/the-openroad-project/openlane:latest \
    openlane designs/DP3/config_phase2.tcl
  ```
- [ ] Monitor synthesis for errors (typical: 4-6 hours)
- [ ] If errors, check logs for:
  - Missing cells → update library path
  - Gating conflicts → review constraints
  - Timing failures → report to timing lead

**Timing Lead:**
- [ ] Review and validate hvt_candidates.csv
- [ ] Create summary: "X cells identified with slack > 0.5 ns"
- [ ] Prepare for timing verification after synthesis

**Verification Lead:**
- [ ] Ready to execute tests as soon as netlist available

**Documentation:**
- [ ] Start Phase 2 progress log

---

### Thursday (May 3)

**Synthesis Lead:**
- [ ] Check synthesis completion status
- [ ] If complete: Extract results
  ```bash
  # Check power report
  cat results/reports/31-rcx_sta.power.rpt
  grep "^Total" results/reports/31-rcx_sta.power.rpt
  ```
- [ ] If not complete: Continue monitoring
- [ ] Save results to `DP3/Reports/phase2_synthesis_results/`

**Timing Lead:**
- [ ] Run timing analysis on Phase 2 results
  ```bash
  # Check worst slack
  grep "worst slack" results/reports/31-rcx_sta.summary.rpt
  ```
- [ ] Verify WNS ≥ 0.0 ns
- [ ] Report any timing violations immediately

**Verification Lead:**
- [ ] As soon as netlist available: Execute functional tests
  ```bash
  cd RTL
  iverilog -o crc_tb.vvp crc_datapath.v crc_datapath_tb.v
  vvp crc_tb.vvp
  ```
- [ ] Log all test results (PASS/FAIL)

---

### Friday (May 4)

**All Roles:**
- [ ] Consolidate results
- [ ] Review power report (target: 6.0-6.3 mW)
- [ ] Verify timing (target: WNS ≥ 0.0 ns)
- [ ] Confirm functional tests (target: 6/6 PASS)

**Synthesis Lead:**
- [ ] Final deliverable: Copy netlist and reports to Reports/
- [ ] Document any synthesis issues and resolutions

**Timing Lead:**
- [ ] Prepare Phase 2 timing summary
- [ ] Compare DP2 vs. DP3-A slack distribution

**Verification Lead:**
- [ ] Final test report (all 6 vectors documented)

**Documentation Lead:**
- [ ] Compile Phase 2 results document
- [ ] Prepare Go/No-Go decision

**Team Meeting (4pm):**
- [ ] Review Phase 2 results
- [ ] Decide: Go to Phase 3 or declare success?
  - **Go Criteria:** If power > 6.8 mW and not yet at target
  - **Success Criteria:** If power ≤ 6.8 mW → DP3 COMPLETE ✅

---

## 🔧 Technical Quick Reference

### Clock Gating Configuration

**Enable in config.tcl:**
```tcl
# Clock Gating Settings
set ::env(CLOCK_GATING_ENABLED) 1
set ::env(CLK_GATE_CELLS) "sky130_fd_sc_hd__dlclkp_1 \
                            sky130_fd_sc_hd__dlclkp_2 \
                            sky130_fd_sc_hd__dlclkp_4"
set ::env(CLK_GATE_SETUP_TIME) 0.1e-9
set ::env(CLK_GATE_DELAY) 0.5e-9
set ::env(SYNTH_GATING_CELLS) "sky130_fd_sc_hd__dlclkp* \
                               sky130_fd_sc_hd__sdlclkp*"
```

### Multi-Vt Cell Remapping

**In synthesis constraints:**
```tcl
# HVt candidates list (from hvt_candidates.csv)
set hvt_cells {
  _0001_ _0003_ _0005_ _0008_ _0012_ _0015_ \
  # ... (300+ cell IDs)
}

# Map SVt to HVt
foreach cell $hvt_cells {
  set_instance_vth $cell HVt
}
```

### Docker Command Template

```bash
# Run OpenLane synthesis
docker run --rm -it \
  -v "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3:/openlane/designs/DP3" \
  ghcr.io/the-openroad-project/openlane:latest \
  openlane designs/DP3/config_phase2.tcl
```

### Power Report Extraction

```bash
# Show total power
grep "^Total" 31-rcx_sta.power.rpt

# Show power breakdown
grep -A 5 "report_power" 31-rcx_sta.power.rpt

# Extract specific power value
grep "Total" 31-rcx_sta.power.rpt | awk '{print $NF}'
```

### Timing Verification

```bash
# Check worst slack
grep "worst slack" 31-rcx_sta.summary.rpt

# Check closure
grep "wns\|tns" 31-rcx_sta.summary.rpt
```

---

## ⚠️ Troubleshooting Guide

### Issue: Power > 6.5 mW (not enough reduction)

**Check:**
1. Is clock gating actually in the netlist?
   - `grep -c dlclkp final.def` should return > 0
   
2. Are HVt cells being used?
   - Check netlist for HVt cell types
   - Verify cell remapping is in synthesis script

**Fix:**
- Increase HVt aggressiveness (lower slack threshold from 0.5 to 0.3 ns)
- Verify OpenLane settings: `cat config_phase2.tcl`
- Re-run synthesis with verified settings

---

### Issue: Timing Violation (WNS < 0.0 ns)

**Check:**
1. Which path is failing?
   - Look in `31-rcx_sta.max.rpt`
2. Is it a gating path or HVt cell?
   - Identify problematic cell

**Fix:**
- Reduce HVt cells on critical path
- Remove HVt from cells with setup slack < 0.5 ns
- Adjust gating delay constraint (increase to 0.7 ns if needed)
- Re-run synthesis

---

### Issue: Functional Test Failure

**Check:**
1. Which vector failed?
   - Compare expected vs. actual output
2. Is it RTL or netlist?
   - Run RTL-only test: `iverilog crc_datapath.v crc_datapath_tb.v`

**Fix:**
- Synthesis may have introduced functional bug
- Check synthesis warnings in OpenLane log
- Verify netlist topology with RTL
- Consider: Need to revert last synthesis and debug

---

## 📊 Expected Results

### Power Report Target

```
===========================================================================
 report_power
============================================================================
======================= Typical Corner ===================================

Group                  Internal  Switching    Leakage      Total
                          Power      Power      Power      Power (Watts)
────────────────────────────────────────────────────────────────────────
Sequential             2.0e-03   2.8e-04   4.06e-09   2.3e-03
Combinational          2.3e-03   1.2e-03   7.35e-09   3.5e-03
────────────────────────────────────────────────────────────────────────
Total                  4.3e-03   1.5e-03   1.14e-08   5.8e-03  ← 5.8 mW

Reduction: 7.81 → 5.8 mW = -1.0 mW (-12.8%) ✅ EXCEEDS TARGET!
```

*(Actual numbers will vary, target: 6.0-6.3 mW)*

### Timing Report Target

```
===========================================================================
report_wns
============================================================================
wns 0.00  ✅ (maintained, no violations)

===========================================================================
report_worst_slack -max (Setup)
============================================================================
worst slack 0.8 to 1.2  ✅ (degraded but still safe)

===========================================================================
report_worst_slack -min (Hold)
============================================================================
worst slack 0.32+  ✅ (improved by HVt faster delay)
```

### Functional Test Target

```
Test Results:
├─ test_A5A5A5A5: PASS ✅
├─ test_5A5A5A5A: PASS ✅
├─ test_00000000: PASS ✅
├─ test_FFFFFFFF: PASS ✅
├─ test_12345678: PASS ✅
└─ test_DEADBEEF: PASS ✅

Result: 6/6 PASS ✅
```

---

## 📞 Support Resources

**If Stuck:**
- Review: [Clock Gating Report](Reports/02_clock_gating_report.md)
- Review: [Slack Analysis](Reports/03_slack_analysis_multivt_plan.md)
- Check: [Power Analysis Guide](docs/power_analysis_guide.md)
- Reference: DP2 config at `../DP2/config.tcl`

**Contact Points:**
- OpenLane Issues: https://github.com/the-openroad-project/OpenLane/issues
- Sky130 PDK: https://skywater-pdk.rtfd.io/
- Internal: Phase 1 analysis in `Reports/`

---

## ✅ Success Checklist (End of Week 2)

- [ ] Power report shows 6.0-6.3 mW (or lower)
- [ ] Timing verification passes (WNS ≥ 0.0 ns)
- [ ] All 6 functional tests pass
- [ ] Synthesis artifacts saved to `Reports/phase2_results/`
- [ ] Team meeting held Friday 4pm
- [ ] Go/No-Go decision made:
  - ✅ Power ≤ 6.8 mW? → **SUCCESS, DP3 COMPLETE**
  - ⚠️ Power > 6.8 mW? → **Proceed to Phase 3**
- [ ] Phase 2 summary document created

---

## Next Steps After Phase 2

### If Phase 2 Achieves Target (power ≤ 6.8 mW):
✅ **DP3 COMPLETE** - No Phase 3 needed
- Document final results
- Prepare submission materials
- Celebrate success! 🎉

### If Phase 2 Doesn't Reach Target:
⏳ **Proceed to Phase 3** (May 7-13)
- Implement additional optimizations:
  - XOR tree restructuring
  - Register balancing  
  - Input slowing
- Target: 6.5-6.8 mW

---

**Phase 2 Ready Date:** April 30, 2026  
**Status:** ✅ Planning complete, team ready  
**Confidence Level:** 90% of achieving Phase 2 target  

---

*For questions, see Phase 1 Summary: [04_phase1_final_summary.md](Reports/04_phase1_final_summary.md)*

