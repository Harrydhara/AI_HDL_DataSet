# DP3 Quick Start Guide

**Created:** 2026-04-23  
**Status:** ✅ Ready for Phase 1

---

## 📂 DP3 Folder Structure (Ready)

```
DP3/
├── .gitignore                           # Git ignore patterns
├── README.md                            # Phase overview & status
├── RTL/
│   ├── crc_datapath.v                  # CRC datapath (DP2 baseline)
│   ├── crc_datapath_tb.v               # Functional testbench
│   └── README.md                        # RTL documentation
├── Netlist/                            # [Empty] Will contain gate-level netlist
├── Reports/                            # [Empty] Will contain synthesis reports
├── Test/                               # [Empty] Will contain test scripts
└── docs/
    ├── dp3_optimization_plan.md         # 3-week detailed plan (THIS IS THE ROADMAP)
    └── power_analysis_guide.md          # Power analysis how-to guide
```

---

## 🚀 Getting Started (Right Now)

### Step 1: Assign Roles (5 min)
- [ ] Power Optimization Lead: Manage DP3 overall
- [ ] Synthesis Lead: Run OpenLane, configure Multi-Vt
- [ ] Timing/PPA Lead: Analyze slack, identify HVt candidates
- [ ] Verification Lead: Run functional tests

### Step 2: Read Key Documents (15 min)
1. ✅ [README.md](README.md) – Overview & goals
2. ✅ [docs/dp3_optimization_plan.md](docs/dp3_optimization_plan.md) – The roadmap
3. ✅ [docs/power_analysis_guide.md](docs/power_analysis_guide.md) – How-to guide

### Step 3: Baseline Comparison (Optional, 10 min)
```bash
# If you want to see DP2 numbers:
cd ../DP2/Reports
cat 31-rcx_sta.power.rpt
# Total: 7.81 mW (baseline for DP3)
```

---

## 📋 DP3 Targets (From DP2 Baseline)

| Metric | DP2 | DP3 Goal | Reduction |
|--------|-----|----------|-----------|
| **Power** | 7.81 mW | 6.5-6.8 mW | 12-17% ↓ |
| **Frequency** | 125 MHz | 125 MHz | 0% (maintain) |
| **Area** | 988 cells | <990 cells | 0-1% ↓ |
| **Timing** | WNS=0.0ns | WNS≥0.0ns | Maintain |

---

## 📅 3-Week Timeline

### Week 1: Analysis Phase
**Owner:** Power/Timing Lead  
**Effort:** 18 hours

**Deliverables:**
- Power breakdown analysis
- Clock gating assessment
- Multi-Vt swap candidate list

**Key Files:**
- Read: [dp3_optimization_plan.md - Phase 1](docs/dp3_optimization_plan.md#phase-1-analysis--clock-gating-week-1)
- Checklist in plan document

### Week 2: Multi-Vt Optimization
**Owner:** Synthesis Lead  
**Effort:** 18 hours

**Deliverables:**
- DP3-A netlist (Multi-Vt optimized)
- Power validated (7.0-7.2 mW)
- Functional tests pass

**Commands:**
```bash
cd /openlane/designs/DP3
docker run ... openlane designs/DP3/config.tcl
# Then validate in RTL/crc_datapath_tb.v
```

### Week 3: Final Refinement
**Owner:** Synthesis Lead  
**Effort:** 12 hours

**Deliverables:**
- Final DP3 netlist (6.5-6.8 mW)
- Power/timing/area reports
- DP2 vs DP3 comparison

---

## ✅ Phase 1 Checklist (Start This Week)

- [ ] Read all documents (30 min)
- [ ] Assign team roles
- [ ] Review DP2 power report (15 min)
- [ ] Plan Week 1 meetings
- [ ] Set up Docker environment (if needed)
- [ ] Start Phase 1 analysis tasks

**Week 1 Deadline:** Complete power breakdown analysis + candidates list

---

## 📞 Key Contacts & Resources

**Documentation:**
- [DP3 Optimization Plan](docs/dp3_optimization_plan.md) ← **Start here for details**
- [Power Analysis Guide](docs/power_analysis_guide.md) ← **How-to reference**
- [RTL Notes](RTL/README.md) ← **Technical details**

**Related:**
- [DP2 Report](../DP2/README.md) ← Reference baseline
- [DP1 Report](../DP1/README.md) ← Historical context

---

## 🎯 Success Indicators

✅ **Phase 1 Success:**
- Clear understanding of where power is spent
- >200 HVt swap candidates identified
- Clock gating opportunity quantified

✅ **Phase 2 Success:**
- DP3-A synthesized successfully
- Power = 7.0-7.2 mW (validated)
- All functional tests pass

✅ **Phase 3 Success:**
- DP3 Final = 6.5-6.8 mW (target met)
- Timing = WNS ≥ 0.0 ns (maintained)
- Documentation complete

---

## 💡 Quick Tips

1. **Read the plan first** – It has everything you need
2. **Use the guide** – Power analysis guide answers "how?"
3. **Validate early** – Test after each optimization
4. **Track metrics** – Monitor power/timing after each phase
5. **Communicate** – Daily standup on progress

---

## 📊 Quick Stats to Remember

- **Target Power:** 6.5-6.8 mW (12-17% reduction)
- **Frequency:** 125 MHz (no change)
- **Effort:** ~48 hours (3 people × 3 weeks)
- **Risk:** Low (conservative approach)
- **Timeline:** 3 weeks

---

## 🔗 Next Action

👉 **Assign Power Optimization Lead**

Then:
1. Read [dp3_optimization_plan.md](docs/dp3_optimization_plan.md)
2. Assign roles to team
3. Schedule Week 1 kickoff

---

**Status:** ⏳ Ready to start Phase 1  
**Created:** 2026-04-23  
**Updated:** [TBD]
