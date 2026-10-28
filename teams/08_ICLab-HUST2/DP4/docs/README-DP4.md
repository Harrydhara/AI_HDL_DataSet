# Team ICLab_HUST2 — Challenge 4 (DP4: Netlist to Chip Tapeout )

## Quick Summary

This repository contains the complete DP4 physical design submission for the Winograd F(2×2, 3×3) convolution accelerator integrated onto the TinyQV RISC-V SoC. Starting from the DP3-hardened RTL, a full OpenLane2 ASIC flow (67 steps) was executed on sky130A PDK to produce a tape-out-ready GDSII with **zero DRC violations, clean LVS, and fully closed timing on all 9 sign-off corners**.

**Deadline:** April 23, 2026 (Milestone Review), May 1, 2026 (Final Submission)

---

## What Changed from DP3

DP4 advances from verified, security-hardened RTL to a complete physical implementation. The RTL is **identical to DP3** — no functional or security changes were made.

| Item | DP3 | DP4 |
|------|-----|-----|
| RTL | DP3-hardened (CM-1+CM-2+CM-3) | Identical ✓ |
| Synthesis | Yosys generic cell-count | OpenLane2 sky130A (step 06) |
| Floorplan | — | 1900×520 µm, auto IO placement |
| Placement | — | OpenROAD global + detailed |
| CTS | — | 310 roots, 1479 buffers, 8907 sinks |
| Routing | — | 22-iteration DR, 0 DRC violations |
| Sign-off | DRC=0, LVS=0 (DP3 run) | DRC=0, LVS=0, STA 9 corners ✅ |
| Output | .v netlist | **GDSII + SPEF + SDF + netlist + LEF + LIB** |

---

## Key Results at a Glance

| Metric | Value |
|--------|-------|
| Standard cell instances | 68,673 |
| Core utilization | 56.48% |
| Total power | 36.00 mW |
| WNS (worst setup, all corners) | **+0.605 ns** (0 violations) |
| WNS (worst hold, all corners) | **+0.169 ns** (0 violations) |
| DRC violations (Magic) | **0** ✅ |
| LVS result (Netgen) | **Circuits match uniquely** ✅ |
| IR drop VPWR worst | 0.241 mV (< 50 mV limit) ✅ |
| GDSII | `results/openlane/runs/DP3/final/gds/` ✅ |

---

## Repository Structure

```
team-ICLab_HUST2-challenge-4/
├── src/
│   ├── interface.v        ← DP3-hardened unchanged
│   ├── winograd.v         ← DP2 optimized 
│   ├── element_wise.v     ← DP2 clock-gated
│   ├── config.json        ← OpenLane2 config (50 MHz, 1900×520 µm die)
│   ├── base.sdc           ← Timing constraints
│   └── *.v                ← All other RTL modules
├── results/
│   ├── synthesis/
│   │   ├── synthesis_summary.md   ← DP4 final synthesis report
│   │   └── output/                ← Standalone Yosys output (reference)
│   ├── signoff/
│   │   ├── sta_signoff_summary.md ← STA 9-corner summary ✅
│   │   ├── drc_violations.magic.rpt         ← Magic DRC: COUNT=0 ✅
│   │   ├── lvs.netgen.rpt         ← Netgen LVS: match unique ✅
│   │   ├── irdrop.rpt      ← IR drop: 0.241 mV ✅
│   │   ├── metrics.json     ← Full OpenLane2 metrics
│   │   └── final_metrics.csv      ← Metrics in CSV format
│   ├── pnr_report.md          ← Placement, CTS, Routing detail report
│   ├── PPA result/
│   │   └── PPA_result.md          ← DP2→DP3→DP4 PPA progression
│   └── openlane/
│       └── runs/DP3/              ← Complete 67-step OpenLane2 run
│           ├── final/             ← GDSII, netlist, SPEF, SDF, LEF, LIB
│           ├── 06-yosys-synthesis/
│           ├── 34-openroad-cts/
│           ├── 57-openroad-irdropreport/
│           ├── 58-magic-streamout/   ← tt_um_tt_tinyQV.gds
│           ├── 62-magic-drc/
│           └── 66-netgen-lvs/
├── testbench/
│   ├── tb_security/
│   │   └── tb_security.v         ← 8-test security testbench (41/41 PASS)
│   └── tb_main/                  ← Functional testbench (cocotb)
├── docs/
│   └── DP4_Final_Report.md       ← Comprehensive DP1→DP4 journey report
├── ai_logs/
│   ├── security_hardening.md     ← DP3 AI log (retained for phase continuity)
│   └── physical_design.md        ← DP4 AI interaction log
├── submission-form-DP4.md        ← DP4 submission checklist
├── README-DP4.md                 ← this file
└── how_to_run.md
```

---

## Physical Design Flow (OpenLane2, 67 steps)

The full flow was executed as a single OpenLane2 run (`run_tag: DP3`) using sky130A PDK:

```
Lint (steps 1–4) → Synthesis (5–9) → Pre-P&R checks (10–11) →
Pre-P&R STA (12) → Floorplan (13–18) → IO placement (24) →
Tap/Decap (25) → Global placement (26–27) → Resizing (28–32) →
CTS (33–35) → Post-CTS optimization (36–40) →
Global routing (41–46) → Detailed routing (47–50) →
Post-route optimization (51–54) → Post-route STA (55–56) →
IR drop (57) → GDSII export (58–59) → DRC (62) →
Parasitic extraction (63–65) → LVS (66) → Final metrics (67)
```

Each step's output is preserved in `results/openlane/runs/DP3/`.

---

## How to Verify Results

### Check DRC
```bash
cat results/signoff/drc_violations.magic.rpt
# Expected: [INFO] COUNT: 0
```

### Check LVS
```bash
tail -5 results/signoff/lvs.netgen.rpt
# Expected: Final result: Circuits match uniquely.
```

### Check Timing
```bash
cat results/signoff/sta_signoff_summary.md
# All 9 corners: WNS = 0, TNS = 0, Violations = 0
```

### Check IR Drop
```bash
cat results/signoff/irdrop.rpt
# Expected: Worstcase IR drop: 2.41e-04 V (0.01%)
```

### Run Security Testbench
```bash
cd testbench/tb_security
iverilog -o sim_security tb_security.v \
  ../../src/interface.v ../../src/winograd.v \
  ../../src/matrix_filter.v ../../src/matrix_input.v \
  ../../src/matrix_output.v ../../src/element_wise.v
vvp sim_security
# Expected: Tests PASSED: 41 | Tests FAILED: 0
```

---

## DP4 Config Summary

```json
{
  "DESIGN_NAME": "tt_um_tt_tinyQV",
  "CLOCK_PORT": "clk",
  "CLOCK_PERIOD": 20,
  "DIE_AREA": "0 0 1900 520",
  "FP_CORE_UTIL": 65,
  "PL_TARGET_DENSITY_PCT": 63,
  "SYNTH_STRATEGY": "DELAY 0"
}
```

---

## Key Documents

- [DP4 Final Report](docs/DP4_Final_Report.md) — Full DP1→DP4 journey (16 weeks)
- [STA Sign-off Summary](results/signoff/sta_signoff_summary.md) — 9-corner timing closure
- [Power Analysis Report](results/signoff/power_analysis.md) — total power, IR drop, hotspot assessment
- [DRC Report](results/signoff/drc_violations.magic.rpt) — Magic: COUNT=0
- [LVS Report](results/signoff/lvs.netgen.rpt) — Netgen: Circuits match uniquely
- [IR Drop Report](results/signoff/irdrop.rpt) — 0.241 mV worst-case
- [P&R Report](results/pnr_report.md) — Placement, CTS, Routing: full stage data
- [Synthesis Summary](results/synthesis/synthesis_summary.md) — DP4 final synthesis analysis
- [PPA Result](results/PPA%20result/PPA_result.md) — DP2→DP3→DP4 metrics progression
- [Security Assessment](docs/security_assessment.md) — STRIDE/DREAD/CWE analysis
- [DP3 Security Report](docs/DP3_Security_Report.md) — CM-1+CM-2+CM-3 implementation
- [AI Logs — Physical Design](ai_logs/physical_design.md) — DP4 AI interaction log
- [Submission Form](submission-form-DP4.md) — Complete DP4 checklist
