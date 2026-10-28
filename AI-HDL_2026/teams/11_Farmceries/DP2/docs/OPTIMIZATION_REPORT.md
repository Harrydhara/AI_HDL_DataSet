# DP-2 Optimization Report

## 1. Baseline

This report compares the DP-2 optimized design against the DP-1 secure baseline configuration.

## 2. Implemented Changes

### 2.1 RTL Optimizations

1. aes_uart_streaming.v
- Eliminated wide 128-bit shift operations during TX/RX serialization.
- Added index-based byte extraction from buffered blocks.
- Added bypass-byte latching for robust one-beat bypass transfers.
- Added tx_busy_out and rx_busy_out status outputs.

2. secure_uart_peripheral.v
- Gated stream handshake by UART TX/RX enable controls.
- Plumbed stream busy outputs into AES_STATUS register bits.
- Added baud generator enable gating based on active work.

### 2.2 Flow Optimizations

1. run_synthesis_and_ppa.sh
- Added --die-area for reproducible floorplan sweeps.
- Added --pl-target-density for placement-density sweeps.

2. DP-2 automation
- Added scripts/run_dp2_experiments.sh.
- Added scripts/dp2_compare_metrics.py.

## 3. Before/After Metrics

Selected comparison:

- Baseline: RUN_2026.04.21_14.44.18 (density 0.60)
- Optimized: RUN_2026.04.21_14.53.40 (density 0.70)

| Metric | Baseline | Optimized | Delta |
|---|---:|---:|---:|
| Area (mm^2) | 0.0768 | 0.0768 | +0.000000 |
| WNS (ns) | -9.78 | -9.78 | +0.000000 |
| TNS (ns) | -8430.27 | -8430.27 | +0.000000 |
| Total Power (uW) | 0.00836003 | 0.00829003 | -0.000070 (-0.84%) |
| Synth Cell Count | 3423 | 3423 | +0 |

See reports/BEFORE_AFTER_PPA.md for the generated full table.

## 4. Trade-Off Analysis

- Replacing wide shifting with indexed byte selection lowers unnecessary register toggling in serializer phases.
- Activity-based baud enable reduces clock-driven activity in idle conditions.
- Baseline default floorplan failed at placement utilization > 100%, so DP-2 uses tuned floorplan knobs for convergence.
- At fixed die area, increasing target density from 0.60 to 0.70 reduced total typical power by about 0.84% with no observed timing/area change.

## 5. Regression Summary

See logs/REGRESSION_RESULTS.md.

## 6. Conclusion

DP-2 optimization introduced both microarchitectural and flow-level improvements. The current measured gain is modest but non-zero in power, and the flow is now reproducible with explicit knobs and documented fallback for placement-utilization failures.
