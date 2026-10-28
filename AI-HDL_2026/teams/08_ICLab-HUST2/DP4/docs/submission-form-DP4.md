# AI-HDL Challenge [4] Submission Form

## Basic Information
- **Submission Date**: 2026-04-23
- **Challenge Number**: [4]
- **Team Name**: ICLab_HUST2
- **Team ID**: ICLab_HUST2

## Team Members
| Name | Role | Email | Contribution % |
|------|------|-------|----------------|
| [member] | Physical Design Lead, Documentation | [email] | 80% |
| [member] | Technical Research & Support | [email] | 5% |
| [member] | Technical Research & Support | [email] | 5% |
| [member] | Technical Research & Support | [email] | 5% |
| [member] | Technical Research & Support | [email] | 5% |

## Design Specifications Met
- [x] OpenLane2 full 67-step P&R flow completed (sky130A PDK, 50 MHz, 1900×520 µm die)
- [x] Synthesis — `results/synthesis/synthesis_summary.md` (OpenLane2 sky130A, DELAY 0 strategy)
- [x] Floorplan — 1900×520 µm die, 65% core utilization target, auto IO placement
- [x] Placement — OpenROAD global + detailed, 56.48% final utilization
- [x] Clock Tree Synthesis — 310 roots, 1479 buffers, 8907 sinks
- [x] Routing — 22-iteration detailed routing, **0 DRC errors** at completion
- [x] Post-route STA — **0 setup violations, 0 hold violations, all 9 corners** ✅
- [x] IR drop analysis — VPWR worst 0.241 mV, VGND worst 0.223 mV (< 50 mV limit) ✅
- [x] DRC sign-off (Magic) — **COUNT: 0** ✅ `results/signoff/drc_violations.magic.rpt`
- [x] LVS sign-off (Netgen) — **Circuits match uniquely** ✅ `results/signoff/lvs.netgen.rpt`
- [x] GDSII delivered — `results/openlane/runs/DP3/final/gds/tt_um_tt_tinyQV.gds`
- [x] Gate-level netlist — `results/openlane/runs/DP3/final/nl/`
- [x] Timing constraints — `results/openlane/runs/DP3/final/sdc/`
- [x] Parasitic extraction (SPEF) — `results/openlane/runs/DP3/final/spef/`
- [x] Timing annotation (SDF) — `results/openlane/runs/DP3/final/sdf/`
- [x] Liberty timing model (LIB) — `results/openlane/runs/DP3/final/lib/`
- [x] LEF abstract — `results/openlane/runs/DP3/final/lef/`
- [x] STA sign-off summary — `results/signoff/sta_signoff_summary.md`
- [x] PPA result report — `results/PPA result/PPA_result.md`
- [x] DP4 Final Report (DP1→DP4) — `docs/DP4_Final_Report.md`
- [x] AI Logs (physical design) — `ai_logs/physical_design.md`
- [x] Security testbench inherited from DP3 — 41/41 checks PASS ✅

## Physical Design Results

### Timing (OpenLane2 / OpenSTA, post-route, 9-corner sign-off)

| Check | Result |
|-------|--------|
| Setup WNS (worst, all corners) | **+0.605 ns** at max_ss_100C_1v60 |
| Setup TNS (all corners) | **0 ns** |
| Setup violations (all corners) | **0** ✅ |
| Hold WNS (worst, all corners) | **+0.169 ns** at max_ff_n40C_1v95 |
| Hold violations (all corners) | **0** ✅ |

### Area & Utilization

| Metric | Value |
|--------|-------|
| Standard cell instances | 68,673 |
| Sequential cells (FFs) | 8,598 |
| Clock gate cells (ICG) | 361 |
| Standard cell area | 550,034 µm² |
| Core area | 973,811 µm² |
| Core utilization | **56.48%** |
| Total wire length | 1,768,893 µm |

### Power (nom_tt_025C_1v80)

| Metric | Value |
|--------|-------|
| Internal power | 14.67 mW |
| Switching power | 21.33 mW |
| Leakage power | ~0.00 mW |
| **Total power** | **36.00 mW** |

### Clock Tree

| Metric | Value |
|--------|-------|
| Clock roots | 310 |
| Buffers inserted | 1,479 |
| Clock subnets | 1,479 |
| Clock sinks | 8,907 |

### Sign-off

| Check | Tool | Result |
|-------|------|--------|
| DRC | Magic v8.3 | **COUNT: 0** ✅ |
| LVS | Netgen 1.5.x | **Circuits match uniquely** ✅ |
| IR drop VPWR | OpenROAD PSM | **0.241 mV** (0.01%) ✅ |
| IR drop VGND | OpenROAD PSM | **0.223 mV** ✅ |
| Power grid violations | OpenROAD | **0** ✅ |

## PPA Progression (DP2 → DP3 → DP4)

| Metric | DP2 Baseline | DP3 Security | DP4 Final |
|--------|-------------|--------------|-----------|
| Cell instances | 70,427 | 68,673 | 68,673 |
| Cell area (µm²) | 565,415 | 550,034 | 550,034 |
| Core utilization | 58.06% | 56.48% | **56.48%** |
| Total power (mW) | 38.16 | 36.00 | **36.00** |
| WNS worst corner (ns) | +0.784 | +0.605 | **+0.605** |
| DRC | 0 | 0 | **0** ✅ |
| LVS | 0 | 0 | **0** ✅ |
| GDSII | ✅ | ✅ | **✅** |

## AI Tool Usage Declaration
- **Primary AI Tool**: Claude Sonnet 4.6
- **Total Conversation Sessions**: ~8 sessions for DP4
- **Estimated AI-Generated Content %**: 60–70% (documentation, analysis, report writing)
- **Manual Contributions**:
  - OpenLane2 config tuning (PL_TARGET_DENSITY_PCT, SYNTH_STRATEGY selection)
  - Decision to keep RTL identical to DP3 (no re-implementation of deferred security features)
  - OpenLane2 run execution and debugging
  - Interpretation of intermediate timing reports (expected pre-optimization failures at step 16)

## Tape-out Package Checklist

### Required Files
- [x] GDSII: `results/openlane/runs/DP3/final/gds/tt_um_tt_tinyQV.gds`
- [x] Gate-level netlist: `results/openlane/runs/DP3/final/nl/`
- [x] Timing constraints (SDC): `results/openlane/runs/DP3/final/sdc/`
- [x] Parasitic extraction (SPEF): `results/openlane/runs/DP3/final/spef/`
- [x] Timing annotation (SDF): `results/openlane/runs/DP3/final/sdf/`
- [x] Liberty models (LIB): `results/openlane/runs/DP3/final/lib/`
- [x] Abstract layout (LEF): `results/openlane/runs/DP3/final/lef/`

### Sign-off Reports
- [x] DRC report: `results/signoff/drc_violations.magic.rpt`
- [x] LVS report: `results/signoff/lvs.netgen.rpt`
- [x] IR drop report: `results/signoff/irdrop.rpt`
- [x] STA summary: `results/signoff/sta_signoff_summary.md`
- [x] Full metrics: `results/signoff/metrics.json`

### Documentation
- [x] README-DP4.md — this submission's overview
- [x] Synthesis summary: `results/synthesis/synthesis_summary.md`
- [x] PPA result: `results/PPA result/PPA_result.md`
- [x] Final report (DP1→DP4): `docs/DP4_Final_Report.md`
- [x] Security assessment: `docs/security_assessment.md`
- [x] DP3 security report: `docs/DP3_Security_Report.md`
- [x] AI logs (DP4): `ai_logs/physical_design.md`
- [x] AI logs (DP3): `ai_logs/security_hardening.md`

## Special Considerations

**RTL stability decision:** The DP3-hardened RTL was kept unchanged for DP4. The five deferred security features from DP3 (power side-channel, accumulator overflow, ECC, authentication, OOB secondary) were intentionally not implemented — they would introduce non-trivial PPA impact and structural changes that would require re-running the full P&R flow. With the DP4 deadline tight (2 weeks from April 9 to April 23), stability of the existing clean results (DRC=0, LVS=0, 0 timing violations) was prioritized over adding new unverified RTL.

**OpenLane2 run tag:** The run is labeled `DP3` in the runs/ directory (the run was originally executed during DP3 for the synthesis/P&R verification). This is the same run used for DP4 tape-out — no re-execution was needed as the RTL was not changed.

**Macros:** Zero macros (`design__instance__count__macros: 0`). Pure standard cell design, no SRAM or hard IP.

**IO placement:** Automatic placement via OpenROAD `place_pins -min_distance 3`. No custom FP_PIN_ORDER_CFG required — TinyTapeout wrapper defines the interface.

## Verification Checklist
- [x] OpenLane2 flow completed successfully (67/67 steps, no tool errors)
- [x] DRC: Magic reports COUNT=0
- [x] LVS: Netgen reports "Circuits match uniquely"
- [x] Timing: 0 setup violations, 0 hold violations, all 9 corners
- [x] IR drop: well within 50 mV spec (0.241 mV worst case)
- [x] Functional testbench: tb_main cocotb regression PASS
- [x] Security testbench: 41/41 checks PASS
- [x] GDSII file present and non-zero: `tt_um_tt_tinyQV.gds`
- [x] Repository organized with all deliverables in correct locations

## Team Statement
We certify that this submission represents our original work, completed according to AI-HDL rules and academic integrity guidelines. All AI interactions have been logged and submitted.

**Team Representative**: Member A
