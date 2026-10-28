# Design Report - DP-1 Secure UART Peripheral

## 1. Scope

This report summarizes the DP-1 hardware design integrated at top module tt_um_tqv_peripheral_harness.

## 2. Architecture

### 2.1 Team-built UART Path

- UART baud generation and TX/RX datapath
- Built by our team on top of the provided TinyQV CPU core integration environment
- Register interface to TinyQV bus
- Integration through peripheral.v and tt_wrapper.v

### 2.2 Secure UART Path

- AES module set included in source tree under src/peripheral/aes/
- secure_uart_peripheral and aes_uart_streaming integrated into peripheral path
- Reduced secure mode support via AES_BLOCK_BYTES configuration in synthesis flow

## 3. Source Snapshot in Submission

- src/peripheral/: peripheral, UART, AES, wrapper, and harness sources
- src/cpu/: TinyQV CPU files used for integrated top-level synthesis

## 4. Verification Assets in Submission

- testbench/peripheral/: cocotb and simulation collateral
- testbench/cpu/: CPU testbench collateral
- results/simulation/: archived run outputs and summaries

## 5. Physical-Design Validation

### 5.1 Closed Runs

- Team-built UART initial run: RUN_2026.01.20_21.36.00
- Secure reduced run (AES_BLOCK_BYTES=1): RUN_2026.04.20_21.32.54

### 5.2 Current Non-Closed Configuration

- AES_BLOCK_BYTES=2 currently fails placement due utilization overflow.

## 6. Artifacts

- Detailed PPA: PPA_ANALYSIS.md
- Submission docs: docs/
- Latest tracked run snapshot: ../runs/latest/
