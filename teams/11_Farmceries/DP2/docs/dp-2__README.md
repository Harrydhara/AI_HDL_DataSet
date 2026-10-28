# DP-2 Workspace: Design Evaluation and PPA Optimization

This directory tracks all DP-2 planning, experiments, and reports for the Secure UART design.

## Scope

- Baseline: DP-1 secure run configuration used as the DP-2 starting point.
- Optimization targets:
  - Improve timing headroom (WNS/TNS).
  - Reduce power and switching where possible.
  - Keep area growth bounded and justified.

## Contents

- reports/OPTIMIZATION_PLAN.md
- reports/OPTIMIZATION_REPORT.md
- reports/BEFORE_AFTER_PPA.md
- logs/REGRESSION_RESULTS.md
- results/ (captured experiment metrics)
- ai_logs/raw_logs/00_complete_conversation.md

## Deliverables Mapping (DP-2 Docs)

This DP-2 folder is organized by phase-2 deliverables rather than cloning DP-1 submission layout exactly.

- Optimized RTL:
  - canonical source remains in dp-1/peripheral/src/aes/
  - key optimized modules: aes_uart_streaming.v, secure_uart_peripheral.v
- Final STA and PPA reports:
  - dp-1/runs/latest/reports/
  - dp-2/results/*.csv
- Optimization report:
  - reports/OPTIMIZATION_PLAN.md
  - reports/BEFORE_AFTER_PPA.md
  - reports/OPTIMIZATION_REPORT.md
- AI logs:
  - ai_logs/raw_logs/00_complete_conversation.md (raw-only, no derived split required)

## Automation

- scripts/run_dp2_experiments.sh: executes baseline and candidate OpenLANE runs, then generates before/after report.
- scripts/dp2_compare_metrics.py: compares two metrics.csv files and renders markdown summary.
