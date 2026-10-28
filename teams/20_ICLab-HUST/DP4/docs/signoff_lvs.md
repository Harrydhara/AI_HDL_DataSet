# LVS Sign-off Report

**Design:** `tt_um_tt_tinyQV`

**Tool:** Netgen 1.5.280

**PDK:** SkyWater SKY130 HD
<!-- 
**OpenLane run:** `DP4/openlane/runs/PPA_DP3`

**Stage:** `67-netgen-lvs` -->

---

## Verdict: CLEAN — Circuits Match Uniquely

```
Circuit 1 contains 6538 devices, Circuit 2 contains 6538 devices.
Circuit 1 contains 6133 nets,    Circuit 2 contains 6133 nets.
Circuits match uniquely.
```

| Check | Count |
|-------|-------|
| Device mismatches | **0** |
| Net mismatches | **0** |
| Property failures | **0** |
| Unmatched devices | **0** |
| Unmatched nets | **0** |
| Unmatched pins | **0** |
| Total LVS errors | **0** |

The layout **matches the netlist uniquely**. The design is LVS clean.

---

## Circuit Comparison Summary

| Property | Layout (Circuit 1) | Schematic (Circuit 2) |
|----------|-------------------|----------------------|
| Device instances | 6,538 | 6,538 |
| Nets | 6,133 | 6,133 |
| Disconnected pins | 5 | 5 |
| Match result | **Unique match** | **Unique match** |

> **Note on disconnected pins:** The 5 disconnected pins are antenna diode
> cells (`sky130_fd_sc_hd__diode_2`) and decap cells where power pins
> (`VPWR`, `VGND`) are connected via the global power mesh rather than
> explicit signal wires. Netgen reports these as "disconnected" because the
> LVS extraction does not include the power straps, but they are correctly
> connected in the physical layout. This is expected and does not indicate
> an error.

---

## Cell Equivalence Results

All standard cell classes in the design were verified as equivalent between
layout and schematic. Key classes checked:

| Cell Class | Instances | Match |
|-----------|-----------|-------|
| `sky130_fd_sc_hd__diode_2` | 4 | ✓ Equivalent |
| `sky130_fd_sc_hd__decap_3` | (fill) | ✓ Equivalent |
| `sky130_ef_sc_hd__decap_12` | (fill) | ✓ Equivalent |
| `sky130_fd_sc_hd__tapvpwrvgnd_1` | 2,528 | ✓ Equivalent |
| `tt_um_tt_tinyQV` (top) | 1 | ✓ Equivalent |

Top-level pin comparison confirmed all I/O ports match:

| Port group | Example pins | Match |
|-----------|-------------|-------|
| Data output | `uo_out[0..7]` | ✓ |
| Bidir I/O | `uio_in[0..7]`, `uio_out[0..7]`, `uio_oe[0..7]` | ✓ |
| Data input | `ui_in[0..7]` | ✓ |
| Control | `clk`, `rst_n`, `ena` | ✓ |
| Power | `VPWR`, `VGND` | ✓ |

---

## LVS Inputs

| Input | Source |
|-------|--------|
| Layout netlist (SPICE) | `65-magic-spiceextraction` |
| Schematic netlist (Verilog) | `07-yosys-synthesis` gate-level netlist |
| PDK device models | SkyWater SKY130 SPICE library |

---

## LVS Error Metrics (from `metrics.csv`)

| Metric | Value |
|--------|-------|
| `design__lvs_device_difference__count` | **0** |
| `design__lvs_net_difference__count` | **0** |
| `design__lvs_property_fail__count` | **0** |
| `design__lvs_error__count` | **0** |
| `design__lvs_unmatched_device__count` | **0** |
| `design__lvs_unmatched_net__count` | **0** |
| `design__lvs_unmatched_pin__count` | **0** |

---
<!-- 
*Report extracted from OpenLane run `PPA_DP3`, stage `67-netgen-lvs`.*

*Design submitted for AI-HDL 2026 — ICLab_HUST — April 22, 2026.* -->
