# DP3 RTL – Ingenius CRC Peripheral (Power Optimization)

This folder contains the optimized RTL for the CRC peripheral in Design Phase 3 (DP3).  
The DP3 RTL focuses on **power optimization** while maintaining the excellent 125 MHz performance achieved in DP2.

---

## 📌 Files

### **1. crc_datapath.v** (DP3 Baseline from DP2)
Pipelined CRC-32 datapath using polynomial `0x04C11DB7`.

**DP3 Modifications** (planned):
- [ ] Add explicit clock gating logic to datapath (`gating_enable` signal)
- [ ] Restructure XOR tree if multi-Vt strategy reduces benefits
- [ ] Optimize MSB/shift pipeline for reduced switching activity
- [ ] Consider input slowing on non-critical nets

**Key Signals** (no change from DP2):
- `busy` – datapath is active  
- `done` – computation finished  
- `result` – final CRC value  
- `seed`, `len`, `data_in` – configuration inputs

**Performance Metrics**:
- Target: Maintain 125 MHz
- Power reduction goal: 7.81 mW → 6.5-6.8 mW

---

### **2. crc_datapath_tb.v** (Unchanged from DP2)
Standalone Verilog testbench for validating the DP3 datapath.

Features:
- Generates a 100 MHz clock (`#5` period)  
- Dumps waveforms to `crc.vcd`  
- Uses six regression test vectors  
- Validates functional correctness across DP3 optimizations

**Regression Vectors**:
- `A5A5A5A5` → `D0CA6977`
- `5A5A5A5A` → `0E714994`
- `00000000` → `00000000`
- `FFFFFFFF` → `DEBB20E3`
- `12345678` → `8E2958CE`
- `DEADBEEF` → `3B1EBF03`

**Usage**:
```bash
iverilog -o crc_tb.vvp crc_datapath.v crc_datapath_tb.v
vvp crc_tb.vvp
# View waveforms: gtkwave crc.vcd
```

---

## 📊 DP3 Optimization Status

| Item | Status | Notes |
|------|--------|-------|
| **Clock Gating** | ⏳ Planned | Week 1: Analyze and implement |
| **Multi-Vt Optimization** | ⏳ Planned | Week 2: Swap HVt/SVt cells |
| **XOR Restructuring** | ⏳ Optional | Week 3: If needed after Multi-Vt |
| **Functional Validation** | ✅ Ready | Testbench ready to validate changes |
| **Synthesis Config** | ⏳ Pending | Multi-Vt constraints (OpenLane) |

---

## 🔄 Design Flow

```
DP2 Baseline (7.81 mW)
        ↓
Clock Gating Analysis (-3-5%)
        ↓
DP3-A: 7.4-7.6 mW
        ↓
Multi-Vt Optimization (-8-10%)
        ↓
DP3-B: 6.7-7.0 mW
        ↓
Logic Refinement (-2-4%)
        ↓
DP3 Final: 6.5-6.8 mW ✅
```

---

## 📝 Notes

### **Baseline RTL (DP2)**
- Two-stage pipeline in datapath
- FSM states: `IDLE`, `LOAD`, `SHIFT`, `DONE`
- Bit-serial CRC computation
- 988 cells, 125 MHz, 7.81 mW

### **Expected DP3 Changes**
1. **Clock gating**: Controlled via synthesis constraints (no RTL change)
2. **Multi-Vt**: Applied during synthesis (no RTL change)
3. **XOR restructuring**: Minor RTL changes if beneficial
4. **Input slowing**: May require RTL register insertion

### **Validation**
- All changes must pass regression testbench
- Timing closure at 125 MHz required
- No functional changes expected

---

## 📚 Related Documents
- [DP3 README](../README.md)
- [DP3 Optimization Plan](../docs/dp3_optimization_plan.md)
- [DP2 Results](../../DP2/README.md)

---

**Status:** ⏳ Ready for Phase 1  
**Last Updated:** 2026-04-23
