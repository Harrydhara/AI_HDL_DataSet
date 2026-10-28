# DP-2 Optimization Plan

## 1. Baseline Definition

Baseline for DP-2 is the current closed secure configuration:

- RTL path: peripheral/src/aes/
- Flow: scripts/run_synthesis_and_ppa.sh
- Baseline run mode: AES_BLOCK_BYTES=1

## 2. PPA Goals

1. Timing:
- Improve WNS toward non-negative values.
- Reduce TNS magnitude relative to baseline.

2. Power:
- Reduce switching activity in encryption/decryption datapaths.
- Reduce unnecessary always-on logic toggling.

3. Area:
- Avoid area regression larger than necessary for timing closure.

## 3. Planned Microarchitectural Changes

1. AES streaming datapath:
- Replace full 128-bit shift-per-byte serialization with indexed byte extraction.
- Latch bypass bytes so bypass mode is one-beat robust and does not depend on external valid staying high.

2. Secure UART integration:
- Use UART enable bits in stream handshake gating.
- Expose real TX/RX crypto busy status via AES_STATUS register.
- Gate baud generator enable based on active work to reduce idle toggling.

## 4. Planned Physical-Flow Experiments

1. Baseline run:
- AES_BLOCK_BYTES=1
- default DIE_AREA and PL_TARGET_DENSITY

2. Candidate run:
- AES_BLOCK_BYTES=1
- relaxed floorplan and lower placement density for improved timing/utilization margin

## 5. Validation Criteria

- Regression tests complete without new failures.
- Yosys synthesis succeeds after RTL changes.
- OpenLANE runs produce comparable metrics.csv artifacts.

## 6. Deliverables

- Before/after metrics report: reports/BEFORE_AFTER_PPA.md
- Trade-off and justification write-up: reports/OPTIMIZATION_REPORT.md
- DP-2 final tag target: DP2-Submission

## 7. Execution Snapshot

- RTL optimization pass: completed
- Regression (secure_uart cocotb): completed (5/5 pass)
- OpenLANE baseline/candidate runs: completed with tuned floorplan settings
- Comparison report generated: completed
