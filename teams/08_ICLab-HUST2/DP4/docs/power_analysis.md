# Power Analysis Report — DP4 Final Sign-off
## Team ICLab_HUST2 | tt_um_tt_tinyQV | sky130A | OpenROAD PSM + OpenSTA

**Design:** Winograd F(2×2,3×3) Convolution Accelerator on TinyQV SoC  
**PDK:** SkyWater sky130A (sky130_fd_sc_hd)  
**Supply voltage:** 1.80 V (nominal)  
**Clock frequency:** 50 MHz  
**Corner:** nom_tt_025C_1v80 (power analysis corner)  
**Source:** `metrics.json` (OpenROAD/OpenSTA) + `irdrop.rpt` (OpenROAD PSM)

---

## 1. Total Power Breakdown

| Component | Power | % of Total |
|-----------|-------|-----------|
| Internal (dynamic, cell logic) | **14.672 mW** | 40.8% |
| Switching (dynamic, net toggling) | **21.328 mW** | 59.2% |
| Leakage (static) | **0.619 µW** | ~0.0% |
| **Total** | **36.00 mW** | 100% |

**Leakage power is negligible** (0.619 µW = 0.0017% of total) — sky130_fd_sc_hd is a digital standard cell library and leakage is not a primary concern at nominal temperature.

---

## 2. Power Component Analysis

### 2.1 Internal Power (14.672 mW)

Internal power represents dynamic power from cell output transitions charging internal node capacitances (not driving external nets). Main contributors:

| Block | Cell Type | Contribution (est.) |
|-------|-----------|---------------------|
| matrix_input.v registers | 16 × 32-bit ICG-gated FF arrays | ~3.5 mW |
| matrix_output.v registers | 16 × 32-bit ICG-gated FF arrays | ~3.5 mW |
| matrix_filter.v registers | 9 × 32-bit FF arrays | ~2.0 mW |
| element_wise.v (×16 Hadamard) | 16 multiplier-accumulator paths | ~3.0 mW |
| interface.v + control FSMs | MMIO registers + security logic | ~1.2 mW |
| TinyQV RISC-V core | CPU + memory controller | ~1.5 mW |

**ICG effectiveness:** 361 integrated clock gate cells reduce internal power by blocking clock to idle register arrays. Without ICG (DP1 baseline), internal power was 23.08 mW. The −8.4 mW reduction (−36.4%) demonstrates that the FSM-based gating covers the dominant register arrays effectively.

### 2.2 Switching Power (21.328 mW)

Switching power represents energy from driving net capacitances (wire + load cell input capacitances). The dominant contributor is the clock distribution network:

| Source | Contribution (est.) |
|--------|---------------------|
| Clock tree buffers (1,479 buffers + 299 inverters) | ~12–14 mW |
| Data nets (computation paths) | ~5–7 mW |
| IO and peripheral buses | ~1–2 mW |

The clock tree consumes disproportionate switching power because 1,479 `sky130_fd_sc_hd__clkbuf_*` cells switch at the full 50 MHz clock frequency with no gating. This is inherent to the USE_LIGHTER=1 clock tree strategy used for timing closure in DP2.

**Trade-off documented in DP2:** Switching power increased from 7.87 mW (DP1, no ICG) to 21.33 mW (DP4, with ICG) due to clock tree overhead. Internal power fell proportionally. Total power: 30.95 mW → 36.00 mW (+16%), with the benefit of timing closure and 36.4% internal power reduction.

---

## 3. Power Progression DP1 → DP4

| Phase | Internal (mW) | Switching (mW) | Leakage (µW) | Total (mW) | ICGs |
|-------|-------------|---------------|--------------|-----------|------|
| DP1 | 23.08 | 7.87 | — | **30.95** | 0 |
| DP2 | 15.22 (−34.1%) | 22.94 (+191%) | — | **38.16** | 360 |
| DP3 | 14.67 (−3.6%) | 21.33 (−7.0%) | — | **36.00** | 361 |
| **DP4** | **14.67** | **21.33** | **0.619** | **36.00** | **361** |

DP2 → DP3 total power reduction of −5.7% is due to CM-1 write-enable gating eliminating switching on input/filter buffer write paths.

---

## 4. IR Drop Analysis (OpenROAD PSM)

**Analysis corner:** nom_tt_025C_1v80  
**Method:** OpenROAD Power Supply Model (PSM), static IR drop

### 4.1 VPWR (Supply Rail)

| Metric | Value |
|--------|-------|
| Supply voltage | 1.800 V |
| Worst-case voltage (min across die) | **1.79976 V** |
| Worst-case IR drop | **0.241 mV** |
| Average IR drop | 0.0103 mV |
| Percentage drop | **0.013%** |
| Power grid violations | **0** ✅ |
| All VPWR shapes connected | ✅ |

### 4.2 VGND (Ground Rail)

| Metric | Value |
|--------|-------|
| Worst-case ground bounce | **0.223 mV** |
| Average ground bounce | 0.0105 mV |
| Percentage | **0.012%** |
| Power grid violations | **0** ✅ |
| All VGND shapes connected | ✅ |

### 4.3 IR Drop Assessment

| Criterion | Specification | Actual | Status |
|-----------|--------------|--------|--------|
| VPWR max drop | < 50 mV (10% of Vdd rule) | **0.241 mV** | ✅ 207× margin |
| VGND max bounce | < 50 mV | **0.223 mV** | ✅ 224× margin |
| Worst operating voltage | > 1.71 V (5% droop) | **1.79976 V** | ✅ |
| Power grid shorts/opens | 0 | **0** | ✅ |

**No IR drop hotspots identified.** The sky130_fd_sc_hd PDN topology (met4/met5 stripes at ~50 µm pitch, 10 µm wide VDD/VSS ring) provides sufficient current distribution for the 36 mW load at 50 MHz. The 0.241 mV worst-case drop is limited to the cells farthest from the nearest power stripe and is well within any manufacturable margin.

---

## 5. Power Hotspot Assessment

OpenROAD PSM reports average IR drop of 0.0103 mV across VPWR — this uniformly low average confirms **no localized power hotspots**. Regions of elevated switching activity are primarily:

- **Clock buffer columns** (1,479 clkbuf cells distributed across the core) — distributed by TritonCTS to minimize skew, inherently spreads switching load
- **element_wise.v Hadamard multiplier array** (16 parallel 32-bit multipliers) — highest computation density, placed centrally by OpenROAD for wire minimization

Both are well-distributed across the 1900×520 µm die. The met4/met5 stripe pitch of ~50 µm ensures all cells are within 25 µm of a power stripe — short enough that even peak-current cells experience negligible IR drop.

---

## 6. Power Consumption Context

| Metric | Value | Context |
|--------|-------|---------|
| Total power | 36.00 mW | Within TinyTapeout slot power budget |
| Power density | 36.00 mW / 0.988 mm² = **36.4 mW/mm²** | Well below sky130 typical limit (~200 mW/mm²) |
| Clock power (est.) | ~14 mW (clock tree switching) | 38.9% of total — acceptable for USE_LIGHTER CTS |
| Computation power | ~22 mW (data switching + internal) | 61.1% of total — efficient for 50 MHz operation |
| Leakage fraction | 0.619 µW / 36,000 µW = **0.0017%** | Negligible — purely dynamic design |

**Assessment:** 36.00 mW at 50 MHz is appropriate for a 70K-cell SoC design in sky130A. The power density of 36.4 mW/mm² is well within the process thermal limits. No thermal hotspots, no IR drop violations, no power grid connectivity issues.

---

## 7. Sign-off Summary

| Check | Result | Status |
|-------|--------|--------|
| Total power | 36.00 mW | ✅ Acceptable |
| Internal power | 14.672 mW (−36.4% vs DP1) | ✅ ICG effective |
| Switching power | 21.328 mW | ✅ Clock tree dominated |
| Leakage | 0.619 µW | ✅ Negligible |
| VPWR IR drop | 0.241 mV (0.013%) | ✅ 207× below spec |
| VGND bounce | 0.223 mV (0.012%) | ✅ 224× below spec |
| Power grid violations | 0 | ✅ |
| Power hotspots | None identified | ✅ |
| Power density | 36.4 mW/mm² | ✅ Well below limit |

**Power sign-off: PASS ✅**

---

*Power Analysis Report — Team ICLab_HUST2 | AI-HDL 2026 | April 2026*  
*Data source: OpenROAD PSM + OpenSTA (metrics.json, irdrop.rpt)*
