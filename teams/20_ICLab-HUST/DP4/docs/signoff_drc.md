# DRC Sign-off Report

**Design:** `tt_um_tt_tinyQV`

**Tool:** Magic v8.3 (DRC full style)

**PDK:** SkyWater SKY130 HD
<!-- 
**OpenLane run:** `DP4/openlane/runs/PPA_DP3`

**Stage:** `63-magic-drc` -->

---

## Verdict: CLEAN — 0 DRC Errors

```
DRC style is now "drc(full)"
Loading DRC CIF style.
No errors found.
```

| Check | Count |
|-------|-------|
| DRC rule violations | **0** |
| Illegal overlaps | **0** |

The design is **DRC clean** and meets all SkyWater SKY130 design rule requirements.

---

## Design Dimensions

| Parameter | Value |
|-----------|-------|
| Die area | 432.0 × 432.0 µm (186,624 µm²) |
| Core area | 426.42 × 424.32 µm (180,939 µm²) |
| Core utilization | 45.12 % |
| Metal layers used | li1, met1, met2, met3, met4 |

---

## DRC Violations Report

Source file: `63-magic-drc/reports/drc_violations.magic.rpt`

```
tt_um_tt_tinyQV
----------------------------------------
[INFO] COUNT: 0
[INFO] Should be divided by 3 or 4
```

Total violation count: **0**

---

## Antenna Violations

Checked at stage `48-openroad-checkantennas-1` (post-detailed-routing):

| Metric | Value |
|--------|-------|
| Antenna-violating nets | **0** |
| Antenna-violating pins | **0** |
| Antenna diodes inserted | 4 |

All antenna violations were resolved by diode insertion during routing.

---

## Physical Integrity Checklist

| Check | Tool | Result |
|-------|------|--------|
| DRC (full style) | Magic | **PASS** — 0 errors |
| Illegal overlaps | Magic | **PASS** — 0 overlaps |
| Antenna violations | OpenROAD | **PASS** — 0 nets |
| Power grid continuity (VPWR) | OpenROAD | **PASS** — 0 violations |
| Power grid continuity (VGND) | OpenROAD | **PASS** — 0 violations |
| Floating nets | OpenROAD | **PASS** — 0 floating nets |
| Disconnected critical pins | OpenROAD | **PASS** — 0 critical |

---

## Routing Summary

| Metric | Value |
|--------|-------|
| Total wire length | 219,602 µm |
| Total via count | 57,044 |
| Max single-net wire length | 1,109.52 µm |
| Routed nets | 6,026 |
| Routing iterations to DRC-clean | 31 |
| Final DRC errors (router) | **0** |

---

<!-- *Report extracted from OpenLane run `PPA_DP3`, stage `63-magic-drc`.*

*Design submitted for AI-HDL 2026 — ICLab_HUST — April 22, 2026.* -->
