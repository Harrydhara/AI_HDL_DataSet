# Phase 2 Results Extraction & Analysis Guide

**Purpose:** Extract power/timing results from OpenLane synthesis run  
**Status:** Awaiting synthesis completion  

---

## Step 1: Identify Latest Run Directory

After synthesis completes, OpenLane creates a timestamped results directory:

```powershell
# List all runs
Get-ChildItem "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3\runs" | Sort-Object Name -Descending | Select-Object -First 1

# Expected output: RUN_2026.04.23_HH.MM.SS
# Copy this timestamp for next steps
```

## Step 2: Check Power Report

```powershell
$RunDir = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3\runs\RUN_2026.04.23_XX.XX.XX"
$PowerReport = "$RunDir\reports\31-rcx_sta.power.rpt"

# View total power
Select-String "^Total" $PowerReport

# Expected format: "Total   5.8e-03   1.5e-03   1.14e-08   6.2e-03"
# Columns: Total, Clock, Internal, Leakage, Combined
```

### Power Interpretation

| Total Power | Result | Status |
|-------------|--------|--------|
| ≤ 6.3 mW | Excellent | Phase 2 SUCCESS |
| 6.3-6.5 mW | Good | Acceptable (minor Phase 3) |
| 6.5-6.8 mW | Fair | Phase 3 needed |
| > 6.8 mW | Poor | Major refinement needed |

**DP2 Baseline:** 7.81 mW  
**Target Reduction:** 8-10% → 6.0-6.3 mW  
**Expected savings:** 0.8-1.4 mW (from clock gating alone)

## Step 3: Check Timing Summary

```powershell
$TimingReport = "$RunDir\reports\31-rcx_sta.summary.rpt"

# View timing slack
Select-String "WNS|TNS|Setup|Hold" $TimingReport

# Expected:
# WNS: >= 0.0 ns (PASS)
# TNS: >= 0.0 ns (PASS)
# Setup slack: >= 0.8 ns (safe margin)
# Hold slack: >= 0.2 ns (safe margin)
```

## Step 4: Verify Clock Gating Implementation

```powershell
$Netlist = "$RunDir\results\final.v"

# Count gating cells
Select-String "dlclkp" $Netlist | Measure-Object

# Expected: > 0 cells (clock gating was inserted)
# Typical: 5-15 gating cells
```

## Step 5: Count Design Cells

```powershell
# Count total cells
Select-String "sky130_fd_sc" $Netlist | Measure-Object

# Expected: ~985-995 cells
# DP2 baseline: 988 cells
# Acceptable change: ±2 cells
```

## Step 6: Extract Key Metrics

```powershell
# Create summary file
$Summary = @"
DP3 Phase 2 Synthesis Results
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Run: $(Split-Path $RunDir -Leaf)

Power Report
-----------
"@

# Add power data
$PowerData = Select-String "^Total" $PowerReport
$Summary += "`n$PowerData`n"

# Add timing data
$Summary += "`nTiming Report`n"
$Summary += "-------------`n"
$TimingData = Select-String "WNS|TNS" $TimingReport
$Summary += $TimingData

# Save to file
$Summary | Out-File "$RunDir\PHASE2_SUMMARY.txt"
Write-Host "Summary saved to: $RunDir\PHASE2_SUMMARY.txt"
```

---

## Step 7: Functional Regression Test

After power verified:

```powershell
cd "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3\RTL"
iverilog -o crc_tb.vvp crc_datapath.v crc_datapath_tb.v
vvp crc_tb.vvp

# Expected output: All 6 test vectors PASS
# If any FAIL: Functional regression - requires netlist debug
```

---

## Phase 2 Success Criteria

**MUST PASS (All required):**
- [ ] Power ≤ 6.3 mW (target met)
- [ ] WNS ≥ 0.0 ns (timing closure)
- [ ] All 6 functional test vectors PASS
- [ ] Cell count ≤ 990 (minimal increase)

**If all criteria MET:**
✅ **PHASE 2 SUCCESS** → DP3 Power Optimization Complete!

**If power > 6.3 mW:**
⚠️ **PHASE 2 PARTIAL** → Continue to Phase 3 (logic refinement)

**If timing violation:**
❌ **PHASE 2 FAILED** → Reduce HVt candidates (use conservative threshold)

---

## Comparison: DP2 vs DP3-A

| Metric | DP2 | DP3-A Target | Expected Saving |
|--------|-----|---|---|
| Total Power | 7.81 mW | 6.0-6.3 mW | 0.8-1.4 mW (10%) |
| Clock Gating | None | Yes | 0.8-1.4 mW |
| Multi-Vt | Limited | Full (280+ cells) | 0.3-0.7 mW |
| Frequency | 125 MHz | 125 MHz | 0% |
| Setup Slack | 1.35 ns | ≥0.8 ns | -0.55 ns |
| Hold Slack | 0.32 ns | ≥0.2 ns | -0.12 ns |
| Cell Count | 988 | ~988 | ±0-2 cells |

---

## What to Do After Phase 2

**Outcome A: Power ≤ 6.3 mW**
```
SUCCESS! Project complete.
- Document results in DP3_FINAL_REPORT.md
- Archive run directory
- Prepare final tape-out package
```

**Outcome B: Power 6.3-6.8 mW**
```
ACCEPTABLE: Continue to Phase 3 for final optimization
- Phase 3 options:
  1. XOR tree restructuring (saves 0.2-0.4 mW)
  2. Register balancing (saves 0.1-0.3 mW)
  3. More aggressive Multi-Vt (risky, may break timing)
```

**Outcome C: Power > 6.8 mW**
```
INVESTIGATE: Check if clock gating was actually inserted
- Review OpenLane log for gating cell placement messages
- Verify config_phase2.tcl was correctly applied
- Check for synthesis timing violations preventing gating
```

---

## Files to Preserve

After successful synthesis, copy to Archive:

```powershell
$RunDir = "..."  # Set to actual run directory
$Archive = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3\Archive\$((Split-Path $RunDir -Leaf))"

New-Item $Archive -ItemType Directory -Force
Copy-Item "$RunDir\reports\31-rcx_sta.power.rpt" $Archive
Copy-Item "$RunDir\reports\31-rcx_sta.summary.rpt" $Archive
Copy-Item "$RunDir\results\final.v" $Archive
Copy-Item "$RunDir\results\final.def" $Archive
```

---

**Ready to analyze results once synthesis completes!**
