# Team ICLab_HUST2 — Challenge 3 (DP3: Security Hardening)

## Quick Summary

This repository contains the DP3-hardened Winograd F(2×2, 3×3) convolution accelerator, starting from the DP2-optimized baseline. Three security countermeasures (CM-1, CM-2, CM-3) have been implemented in `src/interface.v` and validated via a dedicated 8-test security testbench (41/41 checks PASS).

**Deadline:** March 26, 2026 (Milestone Review #3)

---

## What Changed from DP2

Only `src/interface.v` was modified. All other RTL files are unchanged from DP2.

| Change | CWE | Description |
|--------|-----|-------------|
| CM-1 | CWE-284/362/667 | Write-While-Busy Protection: blocks input/filter buffer writes and CTRL[START] when BUSY=1 |
| CM-2 | CWE-200/1233 | Debug Sentinel Removal: `32'hDEADBEEF` → `32'h00000000` in unmapped read paths |
| CM-3 | CWE-20 | Filter Index Out-of-Bounds Clamping: FILTER_IDX > 8 clamped to 8, SEC_VIO set |
| New: `STATUS[2]` | — | SEC_VIO bit — set on any blocked/invalid write attempt, clear-on-read |

---

## Repository Structure

```
team-ICLab_HUST2-challenge-3/
├── src/
│   ├── interface.v        ← DP3 MODIFIED (CM-1 + CM-2 security hardening)
│   ├── winograd.v         ← unchanged from DP2
│   ├── matrix_filter.v    ← unchanged from DP2
│   ├── matrix_input.v     ← unchanged from DP2
│   ├── matrix_output.v    ← unchanged from DP2
│   └── element_wise.v     ← unchanged from DP2
├── testbench/
│   ├── tb_security/
│   │   └── tb_security.v  ← NEW: 8-test security testbench (41 checks)
│   └── tb_main/           ← original functional testbench (DP2, updated src/)
├── docs/
│   ├── security_assessment.md   ← NEW: full vulnerability analysis
│   └── DP3_Security_Report.md   ← NEW: implementation + PPA + validation
├── submission-form-DP3.md        ← NEW: DP3 submission form
├── how_to_run.md
└── README-DP3.md                 ← this file
```

---

## How to Run Security Testbench

Requires: Icarus Verilog (`iverilog` + `vvp`)

```bash
cd testbench/tb_security

iverilog -o sim_security \
  tb_security.v \
  ../../src/interface.v \
  ../../src/winograd.v \
  ../../src/matrix_filter.v \
  ../../src/matrix_input.v \
  ../../src/matrix_output.v \
  ../../src/element_wise.v

vvp sim_security
```

Expected output:
```
Tests PASSED : 41
Tests FAILED : 0
*** ALL SECURITY CHECKS PASSED — DP3 CM-1+CM-2+CM-3 VERIFIED ***
```

8 test cases:
- TEST 1: Normal baseline (regression)
- TEST 2: INPUT_DATA write-while-busy blocked (CM-1)
- TEST 3: FILTER_DATA write-while-busy blocked (CM-1)
- TEST 4: CTRL[START] re-trigger blocked (CM-1)
- TEST 5: SEC_VIO clear-on-read (CM-1)
- TEST 6: Debug sentinel removed — 0x0 not 0xDEADBEEF (CM-2)
- TEST 7: Post-attack regression
- TEST 8: FILTER_IDX out-of-bounds clamped (CM-3)

---

## DP2 Baseline (inherited)

- WNS nom_ss: +0.900 ns (timing closed, 0 setup violations)
- DRC: 0 | LVS: 0
- Clock gating: 360 ICG cells, internal power −34.1%
- Core utilization: 58.1%

## DP3 PPA Results (OpenLane2, sky130A, 50 MHz)

| Metric | DP2 Baseline | DP3 (this work) | Delta |
|--------|-------------|-----------------|-------|
| Cell instances | 70,427 | 68,673 | **−2.5%** |
| Cell area (µm²) | 565,415 | 550,034 | **−2.7%** |
| Total power (mW) | 38.16 | 36.00 | **−5.7%** |
| WNS nom_ss (ns) | +0.900 | +0.758 | 0 violations |
| DRC / LVS | 0 / 0 | **0 / 0** | ✅ Clean |

Security hardening achieves **zero PPA regression** — power improves due to CM-1 write-enable gating.
New hardware: +1 FF (sec_violation_flag), +1 ICG cell.

---

## Key Documents

- [Security Assessment](docs/security_assessment.md) — 10 vulnerabilities, STRIDE/DREAD/CWE analysis, 3 countermeasures planned
- [DP3 Security Report](docs/DP3_Security_Report.md) — full implementation report (CM-1+CM-2+CM-3, Yosys + OpenLane2 PPA, 41/41 tests)
- [Synthesis Summary](results/synthesis/synthesis_summary.md) — Yosys cell-count + OpenLane2 full comparison
- [PPA Result](results/PPA%20result/PPA_result.md) — DP2 vs DP3 OpenLane2 physical metrics
- [Submission Form](submission-form-DP3.md) — checklist + feature descriptions
- [AI Interaction Log](ai_logs/security_hardening.md) — English, 9 AI-assisted development sessions
