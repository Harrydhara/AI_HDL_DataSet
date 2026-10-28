# DP-2 Before/After PPA Comparison

- Baseline: RUN_2026.04.21_14.44.18
- Optimized: RUN_2026.04.21_14.53.40

| Metric | Baseline | Optimized | Delta | Delta % |
|---|---:|---:|---:|---:|
| Area (mm^2) | 0.0768 | 0.0768 | +0.000000 | +0.00% |
| WNS (ns) | -9.78 | -9.78 | +0.000000 | -0.00% |
| TNS (ns) | -8430.27 | -8430.27 | +0.000000 | -0.00% |
| Total Power (uW) | 0.00836003 | 0.00829003 | -0.000070 | -0.84% |
| Synth Cell Count | 3423 | 3423 | +0.000000 | +0.00% |

## Notes

- Positive delta for WNS is better.
- Negative delta for TNS magnitude is better when moving toward 0.
- Lower area and power are typically preferred unless justified by timing gains.
