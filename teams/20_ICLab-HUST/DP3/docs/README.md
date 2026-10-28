# Design Phase 3 — Security Hardening of TinyQV DMA

**AI-HDL 2026 · ICLab_HUST**

**Technology:** SkyWater 130 nm (sky130A) via TinyTapeout

**Clock:** 50 MHz · **Die:** 432 × 432 µm

---

## Overview

Design Phase 3 (DP3) focuses on **security evaluation and threat mitigation** of
the TinyQV RISC-V SoC designed in DP2. The work covers identifying hardware
vulnerabilities in the DMA peripheral, implementing RTL-level countermeasures,
validating that the fixes work, and measuring the PPA cost of security.

The threat model uses three standard frameworks in combination:

- **CIA Triad** — defines what needs to be protected (Confidentiality, Integrity, Availability)
- **STRIDE** — classifies attack types (Spoofing, Tampering, Info Disclosure, DoS, EoP)
- **DREAD** — scores each vulnerability on a 1–10 risk scale

---

## What Was Secured

All countermeasures target `tqvp_dma.v`, the DMA peripheral that moves data
between the CPU memory buffer and the physical I/O ports.

| ID | Vulnerability | Fix | DREAD |
|---|---|---|---|
| SEC-1 | Config registers writable during active transfer (TOCTOU) | Hardware write-lock `cfg_write_ok` | 8/10 |
| SEC-2 | Any bus write can launch the DMA — no authentication | One-time start-unlock key `SEC_KEY = 0xA5` | 7/10 |
| SEC-3 | Last TX byte lingers on output pins after transfer ends | Output bus forced to `0x00` in all non-TX states | 5/10 |
| SEC-4 | Stale RX data from previous session bleeds into shorter new capture | Full 32-byte buffer zeroed in hardware at every RX start | 6/10 |

---

## Repository Structure

```
DP3/
├── src/                    # RTL source files (tqvp_dma.v contains security features)
├── openlane/               # OpenLane config and SDC constraints
│   ├── config.json
│   └── tt_um_tt_tinyQV.sdc
├── test/                   # Cocotb testbenches (unit + full-system)
├── reports/                # Security evaluation reports
│   ├── 1_vulnerability_assessment.md
│   ├── 2_countermeasures.md
│   ├── 3_validation_results.md
│   └── 4_ppa_overhead_analysis.md
├── metrics.csv             # Final OpenLane PPA metrics
└── output/                 # Synthesis netlist and statistics
```

---

## PPA Result

Despite adding security logic, the DP3 implementation is **smaller and faster**
than DP2. Six concurrent RTL optimizations in `tqvp_dma.v` more than offset the
overhead of the four countermeasures.

| Metric | DP2 | DP3 | Change |
|---|---|---|---|
| Stdcell count | 13,165 | 12,713 | −3.4 % |
| Core area | 84,074 µm² | 81,645 µm² | −2.9 % |
| Total power | 6.54 mW | 6.41 mW | −2.0 % |
| Setup slack (worst corner) | 0.75 ns | 1.38 ns | +84 % |

---

## Validation

- **12/12 unit tests passed** — functional regression and direct security proof tests
- **Full-system SoC simulation passed** — RISC-V binary drives the DMA through the
  authenticated launch sequence; correct byte stream captured on output

---

## Reports

Detailed documentation is in the [`reports/`](reports/) directory:

| File | Contents |
|---|---|
| [`1_vulnerability_assessment.md`](reports/1_vulnerability_assessment.md) | Threat model, CWE mapping, DREAD scores |
| [`2_countermeasures.md`](reports/2_countermeasures.md) | RTL implementation of each security feature |
| [`3_validation_results.md`](reports/3_validation_results.md) | Simulation setup, test results, security proofs |
| [`4_ppa_overhead_analysis.md`](reports/4_ppa_overhead_analysis.md) | PPA comparison DP2 vs DP3, timing violation analysis |
