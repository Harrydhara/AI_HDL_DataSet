# PPA Analysis - DP-1 UART vs Secure UART (Reduced)

## 1. Data Sources

- Team-built UART initial-run metrics: results/synthesis/openlane_metrics_uart_baseline.csv
- Secure reduced metrics (AES_BLOCK_BYTES=1): results/synthesis/openlane_metrics_secure_1byte.csv

## 2. Comparison Summary

| Metric | Team-built UART | Secure 1-byte | Delta |
|---|---:|---:|---:|
| DIEAREA_mm^2 | 0.01795472 | 0.0266 | +0.00864528 (+48.15%) |
| wns (ns) | 0.0 | -0.22 | -0.22 |
| tns (ns) | 0.0 | -78.76 | -78.76 |
| total typical power (uW) | 0.00138200536 | 0.00291201 | +0.00153000464 (+110.71%) |
| synth_cell_count | 628 | 1526 | +898 (+143.0%) |

## 3. Inclusion Evidence for Secure Logic

Secure synthesis hierarchy for the 1-byte run includes:

- secure_uart_peripheral
- aes_uart_streaming
- aes_core

These are present in the corresponding synthesis log for RUN_2026.04.20_21.32.54.

## 4. Run Status

- RUN_2026.01.20_21.36.00: flow completed
- RUN_2026.04.20_21.32.54 (AES_BLOCK_BYTES=1): flow completed
- AES_BLOCK_BYTES=2 attempt: flow fails during placement utilization

## 5. Stored Artifacts

- Synthesis metrics CSVs are stored under results/synthesis/.
- Full local run archives are under ../runs/RUN_*/.
- A lightweight, git-tracked latest snapshot is under ../runs/latest/.
