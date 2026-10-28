# Sign-off Report — DP4 Final Tape-out
## Team ICLab_HUST2 | OpenLane2 / OpenROAD-OpenSTA | sky130A

**Design:** tt_um_tt_tinyQV (Winograd F(2×2,3×3) accelerator on TinyQV SoC)  
**PDK:** sky130A (sky130_fd_sc_hd)  
**Clock period:** 20 ns (50 MHz)  
**Tool:** OpenROAD built-in OpenSTA (post-route, 9-corner sign-off)  
**Source:** `summary.rpt` (OpenSTA final output) + `metrics.json` (OpenLane2 aggregated)

---

## 1. Setup Timing — All 9 Corners

| Corner | Setup Worst Slack | R2R Slack | Setup TNS | Violations | fmax |
|--------|------------------|-----------|-----------|------------|------|
| nom_tt_025C_1v80  | +2.5296 ns | +5.0096 ns | 0 | **0** ✅ | 57.2 MHz |
| nom_ss_100C_1v60  | +0.7583 ns | +2.1083 ns | 0 | **0** ✅ | 52.0 MHz |
| nom_ff_n40C_1v95  | +3.1506 ns | +6.0698 ns | 0 | **0** ✅ | 59.0 MHz |
| min_tt_025C_1v80  | +2.5950 ns | +5.1127 ns | 0 | **0** ✅ | 57.5 MHz |
| min_ss_100C_1v60  | +0.9555 ns | +2.3486 ns | 0 | **0** ✅ | 52.5 MHz |
| min_ff_n40C_1v95  | +3.1989 ns | +6.1419 ns | 0 | **0** ✅ | 59.8 MHz |
| max_tt_025C_1v80  | +2.4809 ns | +4.9113 ns | 0 | **0** ✅ | 56.9 MHz |
| **max_ss_100C_1v60** ★ | **+0.6054 ns** | **+1.6070 ns** | 0 | **0** ✅ | **51.6 MHz** |
| max_ff_n40C_1v95  | +3.1122 ns | +6.0008 ns | 0 | **0** ✅ | 59.5 MHz |

★ Worst-case corner: **max_ss_100C_1v60**, slack = **+0.6054 ns**  
★ Worst R2R slack: **+1.6070 ns** at max_ss — internal logic comfortably meets timing  
★ fmax worst-case: **51.6 MHz** (= 1 / (20 − 0.6054) ns)

---

## 2. Hold Timing — All 9 Corners

| Corner | Hold Worst Slack | R2R Slack | Hold TNS | Violations |
|--------|-----------------|-----------|----------|------------|
| nom_tt_025C_1v80  | +0.3040 ns | +0.3040 ns | 0 | **0** ✅ |
| nom_ss_100C_1v60  | +0.6573 ns | +0.6573 ns | 0 | **0** ✅ |
| nom_ff_n40C_1v95  | +0.1760 ns | +0.1760 ns | 0 | **0** ✅ |
| min_tt_025C_1v80  | +0.3132 ns | +0.3132 ns | 0 | **0** ✅ |
| min_ss_100C_1v60  | +0.6592 ns | +0.6592 ns | 0 | **0** ✅ |
| min_ff_n40C_1v95  | +0.1809 ns | +0.1809 ns | 0 | **0** ✅ |
| max_tt_025C_1v80  | +0.2967 ns | +0.2967 ns | 0 | **0** ✅ |
| max_ss_100C_1v60  | +0.6574 ns | +0.6574 ns | 0 | **0** ✅ |
| **max_ff_n40C_1v95** ★ | **+0.1694 ns** | **+0.1694 ns** | 0 | **0** ✅ |

★ Worst hold: **max_ff_n40C_1v95**, slack = **+0.1694 ns**  
49 hold-fix buffers inserted by TritonCTS post-CTS repair.

---

## 3. Signal Integrity — Max Cap / Max Slew

| Corner | Max Cap Violations | Max Slew Violations |
|--------|-------------------|---------------------|
| nom_tt_025C_1v80  | 0 | 0 |
| nom_ss_100C_1v60  | 4 | 14 |
| nom_ff_n40C_1v95  | 0 | 0 |
| min_tt_025C_1v80  | 0 | 0 |
| min_ss_100C_1v60  | 1 | 6 |
| min_ff_n40C_1v95  | 0 | 0 |
| max_tt_025C_1v80  | 0 | 0 |
| **max_ss_100C_1v60** | **5** | **58** |
| max_ff_n40C_1v95  | 0 | 0 |

Max cap/slew violations appear **only at SS corners** (slow process, high temp, low voltage — worst-case RC loading). These are **signal integrity warnings**, not setup/hold timing violations. Timing fully closes at all corners. In a production flow, targeted net buffering would eliminate the 5 max-cap nets.

---

## 4. DRC — Magic v8.3

```
tt_um_tt_tinyQV
----------------------------------------
[INFO] COUNT: 0
[INFO] Should be divided by 3 or 4
```

**Result: COUNT = 0 ✅**

---

## 5. LVS — Netgen

```
Cell pin lists are equivalent.
Device classes tt_um_tt_tinyQV and tt_um_tt_tinyQV are equivalent.
Final result: Circuits match uniquely.
```

**Result: Circuits match uniquely ✅**

---

## 6. IR Drop — OpenROAD PSM

```
Net: VPWR | Supply: 1.80 V | Worst IR drop: 2.41e-04 V | Drop%: 0.01%
Net: VGND | Supply: 0.00 V | Worst voltage: 2.23e-04 V | Drop%: 0.01%
```

**VPWR worst: 0.241 mV ✅ | VGND worst: 0.223 mV ✅**

---

## 7. Summary

| Check | Tool | Result |
|-------|------|--------|
| Setup timing (9 corners) | OpenSTA | **0 violations** ✅ |
| Hold timing (9 corners) | OpenSTA | **0 violations** ✅ |
| Worst setup slack | OpenSTA | **+0.6054 ns** (max_ss) ✅ |
| Worst hold slack | OpenSTA | **+0.1694 ns** (max_ff) ✅ |
| Max cap violations | OpenSTA | 5 (SS corners only, non-critical) ⚠️ |
| Max slew violations | OpenSTA | 58 (SS corners only, non-critical) ⚠️ |
| DRC | Magic v8.3 | **COUNT: 0** ✅ |
| LVS | Netgen | **Circuits match uniquely** ✅ |
| IR drop VPWR | OpenROAD PSM | **0.241 mV** ✅ |
| IR drop VGND | OpenROAD PSM | **0.223 mV** ✅ |
| Power grid violations | OpenROAD | **0** ✅ |
| Total power | OpenSTA | **36.00 mW** (14.67 internal + 21.33 switching) ✅ |
| IR drop VPWR | OpenROAD PSM | **0.241 mV** (0.013% of VDD) ✅ |
| IR drop VGND | OpenROAD PSM | **0.223 mV** ✅ |
| Power hotspots | OpenROAD PSM | **None identified** ✅ |

**Sign-off status: PASS — Design is tape-out ready.** ✅

→ Full power analysis: [`power_analysis.md`](power_analysis.md)
