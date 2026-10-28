# Design Phase 4 — Netlist to Chip Tapeout

**AI-HDL 2026 · ICLab_HUST**

**Technology:** SkyWater 130 nm (sky130A) via TinyTapeout

**Clock:** 50 MHz · **Die:** 432 × 432 µm

---

## Overview

Design Phase 4 (DP4) takes the security-hardened, PPA-optimized RTL from DP3
and runs it through the complete **physical design flow** to produce a
manufacturable GDSII layout. The goal is a "DRC/LVS Clean" design — the bar
for a real chip that can be submitted to a silicon foundry.

The flow uses **OpenLane2** on the **SkyWater SKY130 HD** standard cell library,
covering synthesis, floorplanning, placement, clock tree synthesis (CTS),
routing, and full sign-off verification (STA, DRC, LVS).

---

## Sign-off Results

| Check | Result |
|-------|--------|
| DRC errors (Magic) | **0** |
| LVS errors (Netgen) | **0** |
| Setup timing violations | **0** (all 9 PVT corners) |
| Hold timing violations | **0** (all 9 PVT corners) |
| Antenna violations | **0** |
| Power grid violations | **0** |

The design is **DRC/LVS clean** across all sign-off checks.

---

## Final PPA Metrics

| Metric | DP1 Baseline | DP4 Final | Change |
|--------|-------------|-----------|--------|
| Stdcell count | 13,981 | 12,713 | −9.1 % |
| Core area | 87,735 µm² | 81,645 µm² | −6.9 % |
| Core utilization | 48.49 % | 45.12 % | ↓ |
| Total power | 6.432 mW | 6.413 mW | −0.3 % |
| Setup slack (worst corner) | 1.684 ns | 1.380 ns | positive |
| Wire length | 257,132 µm | 219,602 µm | −14.6 % |
| Via count | 63,396 | 57,044 | −10.0 % |

### Timing by Corner (Post-PnR STA)

| Corner | Setup WS (ns) | Hold WS (ns) |
|--------|-------------|-------------|
| nom_tt_025C_1v80 | 4.467 | 0.327 |
| nom_ss_100C_1v60 | 1.860 | 0.654 |
| nom_ff_n40C_1v95 | 5.092 | 0.205 |
| max_ss_100C_1v60 | **1.380** | 0.655 |
| max_ff_n40C_1v95 | 5.075 | 0.206 |

All corners report zero violations.

### Power (TT 25°C 1.80 V)

| Component | Power |
|-----------|-------|
| Internal | 4.389 mW |
| Switching | 2.024 mW |
| Leakage | 80.9 nW |
| **Total** | **6.413 mW** |

### IR Drop

| Metric | Value |
|--------|-------|
| Worst drop (VPWR) | 113.9 µV |
| Average drop | 9.9 µV |
| Worst net voltage | 1.79989 V |

IR drop is well within the 1 % budget (18 mV for 1.8 V supply).

---

## Physical Design Flow

| Stage | Tool | Key Output |
|-------|------|-----------|
| Synthesis | Yosys | Gate-level netlist (6,918 pre-map cells) |
| Floorplanning | OpenROAD | Die: 432 × 432 µm, core utilization target |
| Placement | OpenROAD | 45.12 % core utilization |
| Clock Tree Synthesis | OpenROAD | 149 clock buffers, 91 clock inverters |
| Global & Detailed Routing | OpenROAD | 31 iterations to DRC-clean |
| Post-route repair | OpenROAD | 125 timing-repair buffers |
| STA sign-off | OpenSTA | Zero violations, all 9 PVT corners |
| DRC | Magic | 0 errors |
| LVS | Netgen | 0 errors |
| GDSII export | Magic | Final manufacturable layout |

---

## Repository Structure

```
DP4/
├── src/                    # RTL source files (DP3 security-hardened design)
├── openlane/               # OpenLane2 config and SDC constraints
│   ├── config.json
│   └── tt_um_tt_tinyQV.sdc
├── test/                   # Cocotb testbenches carried over from DP3
├── output/                 # Synthesis netlist and statistics
│   ├── synth_netlist.v
│   ├── synth_netlist.json
│   └── synth_stats.txt
├── metrics.csv             # Final OpenLane2 PPA metrics
└── reports/                # Final project report (DP1–DP4 journey)
    └── final_project_report.md
```

---

## Design Lineage

| Phase | Focus | Key Result |
|-------|-------|-----------|
| DP1 | Base design — TinyQV + DMA peripheral | 13,981 cells, 6.432 mW, 1.684 ns slack |
| DP2 | PPA optimization (7 RTL changes) | −5.84 % cells, −12.3 % wire length |
| DP3 | Security hardening (4 countermeasures) | −3.43 % cells, +84 % timing margin |
| **DP4** | **Physical tapeout (Synthesis → GDSII)** | **DRC/LVS clean, 0 timing violations** |
