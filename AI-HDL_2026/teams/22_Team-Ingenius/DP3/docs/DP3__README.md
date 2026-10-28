# DP3 – Power Optimization Phase  
Ingenius CRC Peripheral (AI‑HDL Challenge 2026)

Design Phase 3 (DP3) focuses on **power optimization** while maintaining the excellent frequency gains achieved in DP2.  
The goal of this phase is to reduce **dynamic power by 12-17%** through conservative, low-risk optimizations.

---

## 🎯 DP3 Objectives

### **Primary Goal: Power Reduction**
- **DP2 Power:** 7.81 mW (66.3% combinational, 33.7% sequential)  
- **DP3 Target:** 6.5-6.8 mW
- **Reduction:** 12-17% improvement

### **Secondary Goals**
- Maintain frequency at **125 MHz** (no timing risk)
- Maintain/improve area (target: <990 cells)
- Ensure zero timing violations

---

## 📋 DP3 Optimization Strategy

### **Phase 1: Clock Gating & Analysis** (Week 1)
- [ ] Verify clock gating implementation on datapath
- [ ] Generate detailed power breakdowns per module
- [ ] Analyze slack margins per gate
- [ ] Identify HVt/SVt swap candidates
- **Expected Impact:** 3-5% power savings

### **Phase 2: Multi-Vt Optimization** (Week 2)
- [ ] Identify non-critical paths (setup slack > 0.5 ns)
- [ ] Configure OpenLane Multi-Vt constraints
- [ ] Swap SVt → HVt on safe paths
- [ ] Re-run synthesis and verify timing
- **Expected Impact:** 8-10% additional power savings

### **Phase 3: Logic Refinement** (Week 3)
- [ ] Choose optimization: XOR restructuring OR register balancing
- [ ] Implement RTL changes if applicable
- [ ] Re-run synthesis
- [ ] Finalize DP3 PPA results
- **Expected Impact:** 2-4% additional power savings

---

## 📂 Folder Structure

| Folder | Description |
|--------|-------------|
| **RTL/** | Optimized datapath and wrapper (DP2 baseline → DP3 modifications) |
| **Netlist/** | Gate‑level netlist generated during DP3 synthesis |
| **Reports/** | STA, power, and CVC signoff reports |
| **Test/** | Regression testbenches and power analysis scripts |
| **docs/** | DP3 optimization plan and before/after comparisons |

---

## 📊 Key Files

### **RTL Changes**
- `crc_datapath.v` – Baseline from DP2; may add clock gating logic
- `tt_um_ingenius_crc.v` – Wrapper (no changes expected)
- `crc_datapath_tb.v` – Functional testbench (validate across all optimizations)

### **Documentation**
- `docs/dp3_optimization_plan.md` – Detailed phase breakdown
- `docs/power_analysis.md` – Power breakdown analysis
- `docs/dp2_vs_dp3_comparison.md` – Final PPA comparison

---

## ✅ Success Criteria

| Metric | DP2 | DP3 Target | Status |
|--------|-----|-----------|--------|
| **Power** | 7.81 mW | 6.5-6.8 mW | TBD |
| **Frequency** | 125 MHz | 125 MHz | TBD |
| **Area** | 988 cells | 970-990 cells | TBD |
| **WNS** | 0.00 ns | 0.00 ns | TBD |
| **Setup Slack** | 1.35 ns | ≥1.0 ns | TBD |
| **Hold Slack** | 0.32 ns | ≥0.2 ns | TBD |

---

## 🚀 Getting Started

### **1. Review DP2 Baseline**
```bash
# Check DP2 reports
cd ../DP2/Reports
cat 31-rcx_sta.power.rpt     # Power breakdown
cat 31-rcx_sta.summary.rpt   # Timing summary
```

### **2. Copy DP2 RTL to DP3 as Baseline**
```bash
cp ../DP2/RTL/*.v ./RTL/
cp ../DP2/Test/*.py ./Test/
```

### **3. Start Phase 1 Analysis**
- Examine power report in detail
- Identify where 66% combinational power is consumed
- Plan clock gating strategy

---

## 📝 Progress Tracking

- **Phase 1 Start:** [Date TBD]
- **Phase 1 Complete:** [Date TBD]
- **Phase 2 Complete:** [Date TBD]
- **Phase 3 Complete:** [Date TBD]
- **DP3 Submission:** [Date TBD]

---

## 🔗 Related Documents

- [DP2 Report](../DP2/README.md)
- [DP3 Optimization Plan](docs/dp3_optimization_plan.md)
- [Power Analysis Guide](docs/power_analysis.md)

---

## ✍️ Team Notes

**Lead Engineer:** [TBD]  
**Power Optimization Lead:** [TBD]  
**Sign-off:** [TBD]  

---

**Status:** ⏳ In Preparation  
**Last Updated:** 2026-04-23
