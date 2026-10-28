# Team Farmceries - AI-HDL 2026

This repository contains our AI-HDL Design Phase 1 work built on the provided TinyQV CPU core: a team-built UART peripheral and a secure UART variant with AES support.

## Current Status

### Validated OpenLANE Runs

- Team-built UART initial run: RUN_2026.01.20_21.36.00 (flow complete)
  - Area: 0.01795472 mm^2
  - WNS: 0.0 ns
  - TNS: 0.0 ns
  - Total typical power: 0.00138200536 uW
- Secure UART reduced mode run (AES_BLOCK_BYTES=1): RUN_2026.04.20_21.32.54 (flow complete)
  - Area: 0.0266 mm^2
  - WNS: -0.22 ns
  - TNS: -78.76 ns
  - Total typical power: 0.00291201 uW

### Current Limitation

- AES_BLOCK_BYTES=2 is not yet closing with current floorplan/settings.
- Latest failure mode is placement over-utilization (GPL-0301 utilization exceeds 100%).

## Repository Map

- dp-1/: DP-1 implementation workspace
- dp-1/docs/: technical documentation and workflow guides
- dp-1/submission/: submission package aligned to challenge guidelines
- dp-1/runs/: local OpenLANE run archives (ignored by default)
- dp-1/runs/latest/: lightweight latest-run snapshot tracked in git

## AI Logs

- Raw full conversation log: dp-1/submission/ai_logs/raw_logs/00_complete_conversation.md
- Derived logs (to be refined further): dp-1/submission/ai_logs/

## Submission Artifacts

The submission package lives in dp-1/submission and includes:

- submission-form.md
- src/ and testbench/ snapshots
- ai_logs/ (raw + derivative)
- results/ (simulation, synthesis, timing, fpga)
- docs/ (methodology, AI strategy, challenges, lessons)
- media/diagrams/

## Notes

- Full OpenLANE run directories are large and remain local under dp-1/runs/RUN_*/.
- A compact snapshot of the newest run is maintained in dp-1/runs/latest/ for version control.
