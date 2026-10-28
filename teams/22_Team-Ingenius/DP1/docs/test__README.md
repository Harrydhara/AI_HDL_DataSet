# DP1 Testbench – Ingenius CRC Peripheral

This folder contains the cocotb testbench used to verify the CRC peripheral for DP1.

## Testbench File
- `test.py`  
  Uses the TinyQV Python API to interact with our peripheral (index 14).

## What the Testbench Verifies
The testbench checks:
- Writing SEED, LEN, and DATA registers
- Generating a start pulse through CTRL
- Waiting for the interrupt (`user_interrupt`)
- Reading the RESULT register
- Logging CRC outputs for each test vector

## How to Run the Test
1. Ensure cocotb and TinyQV dependencies are installed.
2. Run the test using your simulator (e.g., Icarus Verilog or Verilator).
3. The testbench will:
   - Reset the system
   - Apply multiple CRC test vectors
   - Print the computed CRC results

## Notes
- The testbench uses `TinyQV(dut, peripheral_num=14)` which matches our integration slot.
- Expected CRC values are optional; the testbench logs results for manual comparison.
