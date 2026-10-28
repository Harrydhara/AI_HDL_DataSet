# DP-4: Netlist to Chip Tapeout (Team Farmceries)

This folder contains the final tapeout package for Team Farmceries' AI-HDL 2026 project.

Our DP-4 work is not an isolated flow run. It is the end of a four-phase progression:
- DP-1: Team-built UART plus secure UART baseline integration.
- DP-2: Flow and RTL optimization with reproducible PPA experiments.
- DP-3: Security hardening (CM#1 lock, CM#2 key masking, CM#3 baud clamp) validated by 9/9 tests.
- DP-4: Physical sign-off packaging of the hardened design into a submission-grade chip package.

## Submission Intent
This directory is organized to satisfy the DP-4 competition requirements directly and transparently:
- Final GDSII
- Sign-off reports (DRC/LVS/STA)
- Final project report covering DP1 to DP4
- Traceable, reproducible run history

## Final Run Selection
Canonical run chosen for submission:
- Run ID: `RUN_2026.04.24_00.19.16`
- Why selected: smallest area among successful DP-4 closure sweeps with equivalent sign-off cleanliness.

## Folder Layout
- `scripts/`: reproducible run orchestration (`run_dp4_tapeout.sh`)
- `results/`: per-run metrics and command provenance
- `reports/`: final report and compliance audit
- `ai_logs/`: DP-4 Copilot conversation logs used to produce this package
- `signoff/`: promoted DRC/LVS/STA reports
- `netlist/`: final gate-level netlists
- `gds/`: final GDSII output
- `constraints/`: final SDC constraints

## Reproduce the Flow
```bash
cd dp-4
./scripts/run_dp4_tapeout.sh /ABSOLUTE/PATH/TO/OpenLane \
	--aes-block-bytes 1 \
	--die-area "0 0 320.00 240.00" \
	--pl-target-density 0.61 \
	--cleanup
```

## Story-Specific Notes
- We intentionally preserved the DP-3 hardened configuration because it is the security-validated design, not a stripped benchmark variant.
- Early runs in this project showed sensitivity to placement knobs and reduced AES block settings; DP-4 uses the proven settings that converged cleanly for our hardened netlist.
- Remaining timing-check caveats (max fanout and unconstrained path sections in checks report) are explicitly disclosed in the audit and final report instead of being hidden.
