# Sign-off Summary Report
## Team Acona-Tech | AI-HDL 2026 | Design Phase 4

**Design:** AES-128 Secure Accelerator on TinyQV RISC-V SoC  
**Top Module:** tt_um_tqv_peripheral_harness  
**PDK:** SkyWater Sky130 (sky130_fd_sc_hd)  
**Tool:** OpenLane v1.0.2 (Yosys + OpenROAD + Magic + Netgen)  
**Date:** April 27, 2026

---

## 1. DRC (Design Rule Check)

| Parameter | Result |
|-----------|--------|
| **Status** | **CLEAN ✅** |
| Violations after detailed routing | 0 |
| Violations after GDS streaming | 0 |
| Report file | `drc.rpt` |

---

## 2. LVS (Layout vs. Schematic)

| Parameter | Result |
|-----------|--------|
| **Status** | **CLEAN ✅** |
| Final result | **Circuits match uniquely** |
| Circuit 1 (Layout) devices | 45,702 |
| Circuit 2 (Schematic) devices | 45,702 |
| Circuit 1 nets | 45,414 |
| Circuit 2 nets | 45,414 |
| Disconnected pins | 14 (unused I/O — expected) |
| Report file | `39-tt_um_tqv_peripheral_harness.lvs.rpt` |

---

## 3. STA (Static Timing Analysis)

### 3.1 Timing Summary (Nominal Corner)

| Parameter | Value | Status |
|-----------|-------|--------|
| **Clock Period** | 15.625 ns (64 MHz) | Target |
| **WNS (Worst Negative Slack)** | 0.00 ns | **PASS ✅** |
| **TNS (Total Negative Slack)** | 0.00 ns | **PASS ✅** |
| **Worst Setup Slack** | +3.73 ns | **PASS ✅** |
| **Worst Hold Slack** | +0.07 ns | **PASS ✅** |
| **Setup Violations** | 0 | **CLEAN ✅** |
| **Hold Violations** | 0 | **CLEAN ✅** |
| Achievable Fmax (estimated) | ~84 MHz | +31% margin |

### 3.2 Multi-Corner Analysis

| Corner | Setup | Hold |
|--------|-------|------|
| Min (Fast) | Clean | Clean |
| Nom (Typical) | Clean — +3.73 ns slack | Clean — +0.07 ns slack |
| Max (Slow) | Clean | Clean |

Reports: `sta_min_corner/`, `sta_nom_corner/`, `sta_max_corner/`

---

## 4. XOR Verification (Magic vs. KLayout)

| Parameter | Result |
|-----------|--------|
| **Status** | **MATCH ✅** |
| XOR differences | 0 |
| Report file | `35-xor.rpt` |

---

## 5. Antenna Check

| Parameter | Result |
|-----------|--------|
| **Status** | **PASS ✅** |
| Antenna violations | Repaired during routing |

---

## 6. ERC (Electrical Rule Check)

| Parameter | Result |
|-----------|--------|
| **Status** | **PASS ✅** |

---

## 7. PPA Metrics

| Metric | Value |
|--------|-------|
| Total Devices | 45,702 |
| Total Nets | 45,414 |
| Die Size | 1488.56 × 1476.96 µm |
| Core Utilization | ~45% |
| GDSII File Size | 122 MB (24 MB compressed) |
| Clock Frequency | 64 MHz |
| Encryption Latency | 22 cycles / 128-bit block |
| Throughput @ 64 MHz | ~372 Mbps |

---

## 8. Warnings (Non-Critical)

| Warning | Explanation |
|---------|-------------|
| Max slew violations | Minor — non-critical paths |
| Max fanout violations | Minor — addressed by resizer |
| Blackboxed modules (tapvpwrvgnd, decap, fill) | Standard — physical-only cells |
| VSRC_LOC_FILES not defined | IR drop analysis approximate |

These warnings are informational and do not affect manufacturability.

---

## 9. Conclusion

**All sign-off checks pass. The design is manufacturable.**

| Check | Result |
|-------|--------|
| DRC | ✅ CLEAN — 0 violations |
| LVS | ✅ CLEAN — Circuits match uniquely |
| STA (Setup) | ✅ CLEAN — +3.73 ns slack at 64 MHz |
| STA (Hold) | ✅ CLEAN — +0.07 ns slack |
| XOR | ✅ MATCH — Magic and KLayout agree |
| Antenna | ✅ PASS |
| ERC | ✅ PASS |

---

*Generated from OpenLane v1.0.2 run: dp4_run1*  
*PDK: sky130A | Standard Cell Library: sky130_fd_sc_hd*
