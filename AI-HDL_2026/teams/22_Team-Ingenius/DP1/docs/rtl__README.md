# RTL Source Files – Ingenius CRC Peripheral

This folder contains all Verilog RTL files for our DP1 CRC peripheral.

## Files

- **tt_um_ingenius_crc.v**  
  MMIO wrapper for the CRC peripheral.  
  Handles register reads/writes, generates start/reset pulses, updates STATUS and RESULT, and raises `user_interrupt`.

- **crc_datapath.v**  
  Implements the CRC‑32 datapath using polynomial `0x04C11DB7`.  
  Processes one word per cycle and outputs `busy`, `done`, and `result`.

## Integration Notes
- The MMIO wrapper instantiates the datapath directly.
- All reads complete in one cycle (`data_ready = 1`).
- Interrupt is asserted when `crc_done` becomes high.
