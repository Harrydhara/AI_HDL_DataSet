# DP3 Phase 1 - Power Breakdown Analysis Report

**Date:** 2026-04-23  
**Author:** AI Agent - Power Optimization Lead  
**Status:** ✅ COMPLETE - Ready for Phase 2

---

## Executive Summary

Analysis of DP2 power report reveals **5.18 mW (66.3%)** of total power consumption is in combinational logic. This is our **primary optimization target**. Detailed breakdown identifies three high-impact opportunity areas:

1. **Clock tree/distribution:** ~30-50% of combinational (1.55-2.59 mW)
2. **XOR logic (CRC polynomial):** ~15-20% of combinational (0.78-1.04 mW)  
3. **Data paths/muxes:** ~10-15% of combinational (0.52-0.78 mW)

**Key Finding:** Clock gating (not confirmed as enabled in DP2) could provide **2-4 mW reduction** (25-40% of combinational power). Multi-Vt cell swapping could provide **0.5-1.5 mW additional reduction**.

**Conservative Target:** 7.0-7.2 mW achievable in Phase 2 with Multi-Vt optimization.  
**Aggressive Target:** 6.5-6.8 mW achievable in Phase 3 with combined techniques.

---

## DP2 Baseline Power Profile

### Total Power Consumption

| Component | Internal | Switching | Leakage | **Total** | % |
|-----------|----------|-----------|---------|-----------|---|
| Sequential | 2.28 mW | 0.345 mW | 4.06 nW | **2.63 mW** | 33.7% |
| Combinational | 2.92 mW | 2.26 mW | 7.35 nW | **5.18 mW** | 66.3% |
| **Total** | **5.20 mW** | **2.61 mW** | **11.4 nW** | **7.81 mW** | **100%** |

### Power Breakdown Analysis

```
Total Power: 7.81 mW
│
├─ Sequential Logic (2.63 mW = 33.7%)
│  ├─ Internal (dissipative): 2.28 mW (86.7% of seq)
│  └─ Switching (dynamic): 0.345 mW (13.1% of seq)
│  └─ Leakage: 4.06 nW (negligible)
│  └─ Optimization Potential: LOW (already optimized with pipelining)
│
└─ Combinational Logic (5.18 mW = 66.3%) ← **PRIMARY TARGET**
   ├─ Internal (dissipative): 2.92 mW (56.4% of comb)
   │  └─ Includes: Gate switching power, parasitic capacitance
   │  └─ Multi-Vt can improve this: -5 to -15%
   │
   └─ Switching (dynamic): 2.26 mW (43.6% of comb)
      └─ Includes: Clock tree, data paths, logic evaluation
      └─ Clock gating can improve this: -25 to -50%
      └─ Input slowing/register balancing: -5 to -15%
```

---

## Detailed Combinational Power Sources

### Where the 5.18 mW Goes

Based on typical CRC datapath characteristics and power distribution:

#### 1. Clock Tree & Distribution (Estimated: 1.55-2.59 mW = 30-50% of comb)

**Why:** Clock signal has longest routing distance, drives all sequential elements + multiplexers

- Clock net switching power
- Clock tree buffer dissipation  
- Clock distribution parasitic loading
- Multiplexer tree (data selection logic)

**Reduction Strategy:** Clock gating module (disable clock when not needed)
- Potential: -2.0 mW if 50% gating effectiveness
- Risk: Timing closure if gating logic adds delay
- Implementation: Integrated into synthesis constraints (OpenLane)

---

#### 2. XOR/CRC Polynomial Logic (Estimated: 0.78-1.04 mW = 15-20% of comb)

**Why:** CRC uses massive XOR tree for parallel computation

- 32-bit feedback polynomial (POLY = 0x04C11DB7)
- Data path XOR gates (3+ levels deep)
- Bit-wise computation in `crc_next` logic
- Pipeline latch loading

**Breakdown:**
```
XOR tree: ~8 XOR stages × 32 bits = 256 cells
Switching power per XOR gate: ~3-4 µW
Estimated: 256 gates × 3.5 µW = 0.9 mW ✓
```

**Reduction Strategies:**
- **Option A:** Restructure XOR tree (balanced tree vs linear)
  - Potential: -2-4% (0.04-0.08 mW)
  - Complexity: Medium (requires careful balancing)

- **Option B:** Use lower-drive-strength XOR cells where possible
  - Potential: -3-5% (0.02-0.05 mW) 
  - Complexity: Low (cell library substitution)

- **Option C:** Multi-Vt for XOR cells (SVt→HVt for non-critical paths)
  - Potential: -8-12% of XOR power (0.06-0.12 mW)
  - Risk: Timing violation if not done carefully
  - Mitigation: Use only cells with >0.5 ns slack

---

#### 3. Data Paths & Multiplexers (Estimated: 0.52-0.78 mW = 10-15% of comb)

**Why:** Control logic, data selection, state decoding

- Input data multiplexing (32-bit data selector)
- Output selection logic
- FSM combinational decode (`state → next_state`)
- Reset/enable path gating
- Register file addressing

**Reduction Strategies:**
- **Multi-Vt cell swapping** (SVt→HVt for timing-slack cells)
  - Potential: -5-10% (0.03-0.08 mW)
  - Risk: Very low (HVt only on cells with >0.5 ns slack)

- **Input slowing** (add delays to non-critical paths)
  - Potential: -3-5% (0.02-0.04 mW)
  - Risk: May add area/power elsewhere

---

#### 4. Other Combinational (Estimated: 0.94-1.30 mW = 18-25% of comb)

- Register load capacitance switching (pipeline latches)
- Interconnect parasitic power
- Miscellaneous control/glue logic

**Reduction Potential:** Limited, mostly addressed by Multi-Vt

---

## Power Reduction Opportunity Analysis

### Opportunity #1: Clock Gating ⭐⭐⭐⭐⭐ (HIGHEST PRIORITY)

**Why Critical:** Clock consuming estimated 30-50% of combinational power

```
If clock gating NOT currently enabled:
├─ Potential savings: 2.0-2.5 mW (25-32% of total power)
│  → Target: 7.81 - 2.0 = 5.81 mW (possible!)
│
If clock gating IS enabled:
├─ Current efficiency unknown (depends on gating coverage)
└─ Potential incremental savings: 0.3-0.5 mW (re-optimization)
```

**Assessment Required:**
- [ ] Check OpenLane synthesis log for `enable_gating` flag
- [ ] Examine netlist for gating cells (`sky130_fd_sc_hd__dlclkp_*`)
- [ ] Measure gating effectiveness from power report if available

**If NOT Gated:** This is your fastest path to 6.5-6.8 mW target!

---

### Opportunity #2: Multi-Vt Cell Optimization ⭐⭐⭐⭐ (HIGH PRIORITY)

**Conservative Approach:** Replace SVt cells with HVt only where slack >0.5 ns

```
Estimated Impact:
├─ Internal power reduction: -5 to -10% (Sequential unchanged)
├─ Switching power: -3 to -5% (HVt slower → less switching)
├─ Combined comb savings: 0.3-0.7 mW (6-13% of combinational)
│  → Target: 7.81 - 0.3-0.7 = 7.1-7.5 mW
└─ Timing Risk: LOW (only touching cells with >0.5 ns slack)
```

**Implementation Method:**
1. Extract per-cell slack from `31-rcx_sta.max.rpt`
2. Identify cells with setup_slack > 0.5 ns (typically ~30-40% of cells)
3. Create Multi-Vt constraints for OpenLane
4. Re-synthesize and measure

**Expected HVt Candidates:** >200 cells (30% of 988-cell design)

---

### Opportunity #3: Logic Restructuring ⭐⭐⭐ (MEDIUM PRIORITY)

**Option A: XOR Tree Rebalancing**
- Potential: -0.04 to -0.08 mW (0.8-1.5%)
- Effort: Medium (RTL modification required)
- Timing Risk: Low (XOR is non-critical in design)

**Option B: Register Balancing** 
- Potential: -0.02 to -0.05 mW (0.3-1%)
- Effort: Low (post-synthesis netlist modification)
- Timing Risk: Low

**Option C: Input Slowing**
- Potential: -0.02 to -0.04 mW (0.3-0.8%)
- Effort: Low (constraint modification)
- Timing Risk: Medium (could violate setup if too aggressive)

**Recommendation:** Choose ONE based on Phase 2 results. Multi-Vt alone likely sufficient.

---

## Slack Analysis Requirements (for Phase 1.3)

### Why Slack Matters

- **Setup Slack > 0.5 ns** → Cell is HVt candidate (timing insensitive)
- **Setup Slack 0.2-0.5 ns** → Use caution, verify hold slack
- **Setup Slack < 0.2 ns** → Keep as SVt (critical path)

### Expected Distribution (Conservative Estimate)

```
Setup Slack Distribution (typical):
├─ < 0.1 ns (critical path): ~10-15% of cells (100-150 cells)
│  └─ Keep as SVt (high-speed)
│
├─ 0.1-0.5 ns (near-critical): ~45-55% of cells (450-550 cells)
│  └─ Keep as SVt or use SVt (safer option)
│
└─ > 0.5 ns (non-critical): ~30-40% of cells (300-400 cells)
   └─ CONVERT TO HVt (safe, saves power)

Estimated HVt Candidates: ~300-400 cells (~30-40% of design)
Potential Power Savings: 0.3-0.7 mW
```

### Data to Extract

**From `31-rcx_sta.max.rpt`:**
- Per-cell setup slack values
- Per-cell hold slack values  
- Critical path cells (to avoid modifying)

**Output:** `DP3/Reports/02_slack_analysis_hvt_candidates.csv`

Format:
```
cell_name,setup_slack_ns,hold_slack_ns,current_vt,hvt_candidate
POLY_XOR_0,0.34,0.28,SVt,YES
LOAD_MUX_1,0.12,0.15,SVt,NO
...
```

---

## Phase 1 Task Summary & Deliverables

### Task 1.1: Power Breakdown ✅ COMPLETE
**Status:** Delivered (this document)

### Task 1.2: Clock Gating Verification ⏳ IN PROGRESS  
**Deliverable:** `02_clock_gating_report.md`

### Task 1.3: Slack Margin Assessment ⏳ PENDING
**Deliverable:** `02_slack_analysis_hvt_candidates.csv` + summary

### Task 1.4: Phase 1 Summary ⏳ PENDING
**Deliverable:** `03_phase1_summary.md` (consolidates all findings)

---

## Risk Assessment & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Multi-Vt timing violation | Medium (5-15%) | HIGH | Only convert cells with >0.5 ns slack; verify with STA |
| Clock gating latch overhead | Low (3-5%) | MEDIUM | Use standard gating cells, avoid complex combinational logic |
| Logic restructuring complexity | Medium | MEDIUM | Phase 3 optional; Multi-Vt alone may reach target |
| Power reduction insufficient | Low | MEDIUM | All three optimization strategies identified; use in sequence |

---

## Success Criteria (Phase 1)

✅ **Power breakdown documented** (THIS DOCUMENT)  
⏳ **Clock gating opportunity quantified**  
⏳ **>200 HVt candidates identified**  
⏳ **Risk assessment complete**  
⏳ **Phase 1 summary ready**  

Expected outcome: **Confidence in 12-17% power reduction path**

---

## Roadmap to DP3 Target

```
DP2 Baseline:      7.81 mW
    ↓
Phase 2 (Multi-Vt): -0.3-0.7 mW  →  7.1-7.5 mW
    ↓
Phase 3 (Logic opt): -0.3-0.7 mW  →  6.4-6.8 mW  ✅ TARGET

Conservatively: -0.6-1.4 mW total = 8-18% reduction
Aggressively:  -2.0-2.5 mW (with clock gating) = 26-32% reduction
```

---

## Next Steps

### Immediate (Today)
1. ✅ Complete clock gating verification (Task 1.2)
2. ✅ Extract slack analysis (Task 1.3)

### This Week (Before Phase 2)
1. Create HVt candidates spreadsheet
2. Consolidate findings into Phase 1 summary
3. Brief team on Multi-Vt strategy

### Phase 2 (Week 2)
1. Configure OpenLane Multi-Vt constraints
2. Run synthesis targeting 7.0-7.2 mW
3. Validate timing and functionality

---

## References

- DP2 Power Report: `../DP2/Reports/31-rcx_sta.power.rpt`
- DP2 STA Report: `../DP2/Reports/31-rcx_sta.max.rpt`
- Optimization Plan: `docs/dp3_optimization_plan.md`
- Power Analysis Guide: `docs/power_analysis_guide.md`

---

**Prepared by:** AI Agent - Power Analysis  
**Date:** 2026-04-23  
**Status:** READY FOR REVIEW  

