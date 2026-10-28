# DP-1 Synthesis and PPA Workflow

This document describes the current, validated flow for synthesis and OpenLANE PPA in DP-1.

## 1. Scripts

- scripts/run_synthesis.sh
  - Purpose: fast Yosys synthesis sanity check
  - Main output: synthesis-work/synthesis.log (temporary)
- scripts/run_synthesis_and_ppa.sh
  - Purpose: full Yosys + OpenLANE flow
  - Supports reduced secure experiments via --aes-block-bytes {1|2|4|8|16}
  - Main outputs: outputs/synthesis.log, outputs/openlane.log, runs/RUN_*/

## 2. Validated Runs

### Team-built UART initial run (flow complete)

- Run ID: RUN_2026.01.20_21.36.00
- Metrics source: runs/RUN_2026.01.20_21.36.00/reports/metrics.csv
- Key PPA:
  - DIEAREA_mm^2: 0.01795472
  - wns: 0.0
  - tns: 0.0
  - power_typical_total_uW: 0.00138200536

### Secure reduced mode (AES_BLOCK_BYTES=1, flow complete)

- Run ID: RUN_2026.04.20_21.32.54
- Metrics source: runs/RUN_2026.04.20_21.32.54/reports/metrics.csv
- Key PPA:
  - DIEAREA_mm^2: 0.0266
  - wns: -0.22
  - tns: -78.76
  - power_typical_total_uW: 0.00291201

### Secure reduced mode (AES_BLOCK_BYTES=2, currently failing)

- Failure mode: placement utilization overflow (GPL-0301)
- Evidence: outputs/openlane.log

## 3. Commands

```bash
cd dp-1

# Synthesis only
./scripts/run_synthesis.sh

# Full PPA run
./scripts/run_synthesis_and_ppa.sh /path/to/OpenLane --cleanup

# Reduced secure run (currently stable)
./scripts/run_synthesis_and_ppa.sh /path/to/OpenLane --aes-block-bytes 1 --cleanup
```

## 4. Artifact Policy

- Local heavy artifacts:
  - runs/RUN_*/
- Git-tracked lightweight artifact:
  - runs/latest/

The run script now refreshes runs/latest automatically after a successful OpenLANE flow.

## 5. Cleanup Guidance

Safe to remove when not needed:

- synthesis-work/ (temporary staging)
- ad-hoc ppa_run.log files created by shell piping
- legacy synthesis_outputs/ directory

Keep:

- outputs/synthesis.log and outputs/openlane.log for immediate debugging
- runs/RUN_*/ for full local history
- runs/latest/ for versioned latest-run evidence
