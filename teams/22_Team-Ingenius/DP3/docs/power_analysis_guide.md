# DP3 Power Analysis Guide

**Purpose:** Help the team analyze, optimize, and validate power during DP3

---

## 1. Understanding DP2 Power Baseline

### DP2 Power Breakdown

From [DP2 Reports/31-rcx_sta.power.rpt](../../DP2/Reports/31-rcx_sta.power.rpt):

```
Group               Internal  Switching  Leakage    Total      %
Sequential          2.28e-03  3.45e-04  4.06e-09  2.63e-03  33.7%
Combinational       2.92e-03  2.26e-03  7.35e-09  5.18e-03  66.3%
Macro               0.00e+00  0.00e+00  0.00e+00  0.00e+00   0.0%
Pad                 0.00e+00  0.00e+00  0.00e+00  0.00e+00   0.0%
─────────────────────────────────────────────────────────────
Total               5.20e-03  2.61e-03  1.14e-08  7.81e-03 100%
                     66.6%     33.4%      0.0%
```

**Key Insight:** **Combinational logic = 66.3% of power** → Primary optimization target

### Power Composition

| Component | Power | Type | Note |
|-----------|-------|------|------|
| **Combinational** | 5.18 mW | Dynamic | Switching + internal |
| **Sequential** | 2.63 mW | Dynamic | Register clocking + transitions |
| **Leakage** | ~11.4 nW | Static | Negligible (<0.01%) |
| **Clock** | Est. 2-3 mW | Dynamic | Largest consumer (inside combinational) |

---

## 2. Where Is Combinational Power Consumed?

### Likely Power Consumers in CRC Design

| Module/Net | Est. Power | Strategy |
|-----------|-----------|----------|
| **Clock distribution** | 1-2 mW | Clock gating (no gating → 50% savings possible) |
| **XOR tree (CRC POLY)** | 0.8-1.2 mW | Restructure or gate during IDLE |
| **Data muxes/gates** | 0.5-1.0 mW | Use transmission gates instead of muxes |
| **Datapath registers** | 0.5-1.0 mW | Part of sequential, already pipelined |
| **Register enable logic** | 0.3-0.5 mW | Optimize enable generation |
| **Other logic** | 1.0-1.5 mW | Miscellaneous |

### How to Identify Major Power Consumers

```bash
# Step 1: Get detailed power report from OpenLane
cd /openlane/designs/DP2/runs/RUN_2026.04.15_22.41.08/reports/signoff/

# Step 2: Check if detailed breakdown available
ls -la *power* *sta*

# Step 3: Parse power per net (if available)
# Some reports include per-net power
grep -i "net\|signal\|power" 31-rcx_sta.power.rpt | head -100

# Step 4: Understand clock tree power
# Clock is typically 30-50% of total dynamic power
# Reducing clock activity = biggest win
```

---

## 3. Clock Gating Analysis & Opportunity

### What is Clock Gating?

Clock gating **stops the clock** to unused logic, eliminating switching power.

```verilog
// Without gating: Clock runs always
reg [31:0] crc_reg;
always @(posedge clk) crc_reg <= new_value;
// Power = C × V² × f × 100%

// With gating: Clock stops when busy=0
wire gated_clk;
CLKGATE gate_inst (.CLK(clk), .EN(busy), .GCLK(gated_clk));
always @(posedge gated_clk) crc_reg <= new_value;
// Power = C × V² × f × (activity %) << original
```

### Potential DP3 Gating Candidates

In the CRC datapath:

| Signal | Gating Opportunity | Est. Savings |
|--------|------------------|--------------|
| **crc_reg (main CRC register)** | Gate when `busy=0` | 1-2 mW |
| **shift_stage (pipeline)** | Gate when `busy=0` | 0.5-1.0 mW |
| **bit_cnt (bit counter)** | Gate when `busy=0` or bit-level gating | 0.2-0.5 mW |
| **data_reg** | Gate when state=IDLE | 0.3-0.7 mW |

**Total potential savings: 2-4 mW (25-50% reduction!)** ✅

### Implementing Clock Gating in OpenLane

OpenLane can automatically insert gating cells if enabled:

```tcl
# In config.tcl for DP3:
set ::env(CTS_ENABLE_GLOBAL_ROUTING) 1
set ::env(CTS_ROOT_BUFFER_PERCENTAGE) 100

# Enable clock gating during synthesis
set ::env(SYNTH_CLOCK_GATING) 1

# Specify gating enable signal
set ::env(CLOCK_GATING_ENABLE_SIGNAL) "busy"
```

---

## 4. Multi-Vt Cell Optimization

### Vt (Threshold Voltage) Basics

Different cell types available in Sky130:

| Vt Type | Speed | Leakage | Use Case |
|---------|-------|---------|----------|
| **LVt** (Low Vt) | ⚡⚡⚡ Fastest | 🔥 High | Critical paths only |
| **SVt** (Standard Vt) | ⚡⚡ Normal | 🔥🔥 Medium | Most paths |
| **HVt** (High Vt) | ⚡ Slower | 🟢 Low | Non-critical paths |

### Multi-Vt Strategy for DP3

```
DP2 design uses only SVt cells
      ↓
Analyze timing slack per gate
      ↓
Gates with setup slack > 0.5 ns:
  → Swap SVt → HVt
  → Reduce dynamic power (less leakage doesn't help, but less activity)
      ↓
Gates on critical path (setup slack < 0.2 ns):
  → Keep SVt or swap to LVt
  → Maintain timing
      ↓
Expected result:
  40-50% of gates become HVt
  → 8-12% power reduction
```

### Identifying HVt Swap Candidates

```bash
# Step 1: Extract setup slack per gate
# From 31-rcx_sta.max.rpt, find report_slack command output
# Look for lines like:
# gate_name    slack
# AND2_1       1.5ns    ← candidate for HVt
# XOR2_2       0.1ns    ← keep SVt (critical)

# Step 2: Create swap list
# Create CSV file: candidates_hvt_svt.csv
# gate_id,current_type,setup_slack,recommendation
# AND2_1,SVt,1.5ns,HVt_swap
# XOR2_2,SVt,0.1ns,keep_SVt

# Step 3: Configure OpenLane to use mixed Vt
# In config.tcl, specify Liberty file with mixed Vt cells

# Step 4: Re-synthesize and measure power
# Compare before/after
```

---

## 5. Power Estimation & Validation

### DP2 → DP3 Power Trajectory

```
DP2 Baseline:                  7.81 mW (100%)
                                    ↓
Clock Gating (-3-5%):          7.40 mW (95%)
DP3-A Checkpoint
                                    ↓
Multi-Vt Optimization (-8-10%): 6.70 mW (86%)
DP3-B Checkpoint
                                    ↓
Logic Refinement (-2-4%):      6.50 mW (83%)
DP3 Final Target ✅

Total reduction: 12-17% (0.95-1.31 mW savings)
```

### Measuring Power in OpenLane

```bash
# After DP3 synthesis:
cd /openlane/designs/DP3/runs/RUN_<DATE>/reports/signoff/

# Extract power metrics
cat 31-rcx_sta.power.rpt | grep -A 10 "report_power"

# Expected DP3 result:
# Total: 6.5-6.8 mW
# Internal: ~4.0-4.2 mW (49-51%)
# Switching: ~2.5-2.6 mW (38-40%)
# Leakage: ~14-16 nW (<0.01%)
```

### Validating Improvements

```bash
# Comparison script
cat > compare_power.sh << 'EOF'
echo "DP2 vs DP3 Power Comparison"
echo "=============================="

echo -e "\nDP2 Power:"
grep "Total" /openlane/designs/DP2/runs/RUN_2026.04.15_22.41.08/reports/signoff/31-rcx_sta.power.rpt

echo -e "\nDP3 Power:"
grep "Total" /openlane/designs/DP3/runs/RUN_*/reports/signoff/31-rcx_sta.power.rpt

echo -e "\nReduction Achieved:"
# Calculate: (DP2 - DP3) / DP2 * 100%
EOF

chmod +x compare_power.sh
./compare_power.sh
```

---

## 6. Functional Validation

**Important:** Verify correctness after each optimization!

### Regression Test Suite

```bash
# File: RTL/crc_datapath_tb.v
# Contains 6 test vectors covering:
# - Patterns: 0xA5A5A5A5, 0x5A5A5A5A
# - Extremes: 0x00000000, 0xFFFFFFFF
# - Random: 0x12345678, 0xDEADBEEF

cd /openlane/designs/DP3/RTL

# Run simulation
iverilog -o crc_tb.vvp crc_datapath.v crc_datapath_tb.v
vvp crc_tb.vvp

# Expected output:
# PASS: Input a5a5a5a5, CRC d0ca6977
# PASS: Input 5a5a5a5a, CRC 0e714994
# PASS: Input 00000000, CRC 00000000
# PASS: Input ffffffff, CRC debb20e3
# PASS: Input 12345678, CRC 8e2958ce
# PASS: Input deadbeef, CRC 3b1ebf03
# Regression completed.
```

---

## 7. Troubleshooting

### Problem: Power Reduction < 8% in DP3-A

**Possible Causes:**
1. Clock gating not enabled in synthesis
2. Not enough HVt swap candidates
3. Timing constraints too tight

**Solution:**
- Verify `SYNTH_CLOCK_GATING` enabled in config.tcl
- Check if OpenLane actually inserted gating cells
- Relax timing by 0.5 ns, re-synthesize

### Problem: Timing Violation After Multi-Vt

**Possible Causes:**
1. Too many HVt swaps on critical paths
2. Slack measurement pessimistic

**Solution:**
- Revert some HVt swaps (keep more SVt on near-critical paths)
- Check actual slack vs. reported slack in detailed report
- Use more conservative threshold (swap only if slack > 1.0 ns)

### Problem: Leakage Increases in DP3

**Note:** HVt cells reduce dynamic power but increase leakage slightly.  
**Expected:** Net reduction still 12-17% (dynamic savings >> leakage increase)

---

## 8. Documentation & Reporting

### Phase 1 Report Template
```
# DP3 Phase 1 Analysis Report

## Power Breakdown
- Combinational: X.XX mW (XX%)
- Sequential: X.XX mW (XX%)
- Total: 7.81 mW

## Clock Gating Analysis
- Current gating cells: N
- Opportunity: X-Y mW savings
- Recommendation: [Enable clock gating in Phase 2]

## Multi-Vt Analysis
- Gates with slack > 0.5 ns: N (X% of total)
- HVt swap candidates: N
- Estimated savings: X-Y mW

## Risks & Mitigations
[List any concerns]

## Next Steps
1. Configure clock gating
2. Run DP3-A synthesis
3. Validate timing & power
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Extract DP2 power | `grep "Total" DP2/Reports/31-rcx_sta.power.rpt` |
| Run DP3 synthesis | `openlane designs/DP3/config.tcl` (in Docker) |
| Simulate testbench | `iverilog -o crc_tb.vvp *.v && vvp crc_tb.vvp` |
| Check timing | `grep "wns\|slack" DP3/Reports/31-rcx_sta.summary.rpt` |
| Compare power | `diff <(power_dp2) <(power_dp3)` |

---

**For questions or issues, contact:** [TBD - Power Optimization Lead]

**Last Updated:** 2026-04-23
