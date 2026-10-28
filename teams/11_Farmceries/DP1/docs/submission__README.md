# Team Farmceries - DP-1 Submission

## Team Information

- Team Name: Farmceries
- Challenge: AI-HDL Design Phase 1 (DP-1)
- Design: TinyQV-integrated Secure UART peripheral

## Challenge Summary

This submission contains our DP-1 work built on the provided TinyQV CPU core: a team-developed UART peripheral and secure UART integration artifacts.

Our team-built UART flow is fully closed in OpenLANE, and a secure reduced configuration (AES_BLOCK_BYTES=1) also closes in OpenLANE. We include both initial UART and secure run metrics in this package.

## Key Features

- UART TX/RX with register-mapped CPU interface
- Secure UART integration path with AES modules
- OpenLANE runs archived locally under dp-1/runs/
- Git-tracked lightweight latest-run snapshot under dp-1/runs/latest/

## Results Snapshot

- Team-built UART initial run (RUN_2026.01.20_21.36.00)
  - Area: 0.01795472 mm^2
  - WNS: 0.0 ns
  - TNS: 0.0 ns
  - Total typical power: 0.00138200536 uW
- Secure reduced run (RUN_2026.04.20_21.32.54, AES_BLOCK_BYTES=1)
  - Area: 0.0266 mm^2
  - WNS: -0.22 ns
  - TNS: -78.76 ns
  - Total typical power: 0.00291201 uW
- Secure reduced run with AES_BLOCK_BYTES=2 currently fails placement utilization and is not in the closed set.

## AI Logs

- Raw conversation log: ai_logs/raw_logs/00_complete_conversation.md
- Derived logs (first-pass split):
  - ai_logs/design_generation.md
  - ai_logs/optimization.md
  - ai_logs/debugging.md

## Submission Structure

```text
submission/
├── README.md
├── submission-form.md
├── src/
├── testbench/
├── ai_logs/
├── results/
├── docs/
└── media/
```

## Notes

- media/diagrams/ is populated from authoritative documentation in dp-1/docs/.
- Screenshots are intentionally left for incremental updates.
- AI log derivatives are a first pass and will be refined after final raw-log refresh.
