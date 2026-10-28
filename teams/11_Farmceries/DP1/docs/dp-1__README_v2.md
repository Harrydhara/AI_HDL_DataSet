# AI-HDL Design Phase 1 (DP-1) - Secure UART Peripheral

DP-1 builds a team-developed UART peripheral on top of the provided TinyQV CPU core and includes a secure UART configuration with AES datapath support.

## Quick Status

- Team-built UART initial OpenLANE run passed: RUN_2026.01.20_21.36.00
- Secure UART reduced run (AES_BLOCK_BYTES=1) OpenLANE passed: RUN_2026.04.20_21.32.54
- Secure UART reduced run (AES_BLOCK_BYTES=2) currently fails placement due over-utilization

## Key Commands

```bash
# From dp-1/

# Fast synthesis-only sanity check
./scripts/run_synthesis.sh

# Full OpenLANE run (default AES block bytes = 16)
./scripts/run_synthesis_and_ppa.sh /path/to/OpenLane --cleanup

# Reduced secure experiment (1-byte block mode)
./scripts/run_synthesis_and_ppa.sh /path/to/OpenLane --aes-block-bytes 1 --cleanup

# Attempted 2-byte reduced mode (currently not closing)
./scripts/run_synthesis_and_ppa.sh /path/to/OpenLane --aes-block-bytes 2 --cleanup
```

## Output and Artifacts

- outputs/: latest local build logs
  - outputs/synthesis.log
  - outputs/openlane.log
- runs/: local OpenLANE run archives (ignored by default)
- runs/latest/: compact git-tracked snapshot of latest run
  - RUN_ID.txt
  - SUMMARY.md
  - reports/metrics.csv
  - reports/manufacturability.rpt
  - logs/synthesis_1.log.txt
  - logs/openlane_flow.log.txt

## Submission Package

Use dp-1/submission/ as the canonical submission directory.

It includes:

- README.md
- submission-form.md
- src/
- testbench/
- ai_logs/
- results/
- docs/
- media/

## DP-2 Workspace

- dp-2/: DP-2 planning, reports, logs, AI logs, and metrics artifacts
- scripts/run_dp2_experiments.sh: runs baseline/candidate PPA and generates comparison report
- scripts/dp2_compare_metrics.py: compares two OpenLANE metrics.csv files into markdown

## Directory Layout

```text
dp-1/
├── cpu/
├── peripheral/
├── scripts/
├── docs/
├── submission/
├── outputs/
├── runs/
└── venv/
```

## Notes

- synthesis-work/ is temporary and recreated by scripts, so it is not kept in the repository.
- runs/RUN_*/ can be regenerated; use runs/latest/ for tracked evidence of the newest flow result.
