# DP2 RTL – Ingenius CRC Peripheral

This folder contains the optimized RTL for the CRC peripheral in Design Phase 2 (DP2).  
The DP2 RTL introduces pipelining and a refined FSM to improve timing and performance compared to DP1.

---

## 📌 Files

### **1. tt_um_ingenius_crc.v**
Top‑level wrapper module used for DP2 synthesis and signoff.

Responsibilities:
- Implements the memory‑mapped register interface  
- Generates one‑cycle `start` and `reset` pulses  
- Updates STATUS and RESULT registers  
- Asserts `user_interrupt` when CRC computation completes  
- Instantiates the pipelined CRC datapath (`crc_datapath`)  

This wrapper follows the TinyTapeout‑style interface used in DP2.

---

### **2. crc_datapath.v**
Pipelined CRC‑32 datapath using polynomial `0x04C11DB7`.

Key DP2 improvements:
- **Two‑stage pipeline** (`msb_stage`, `shift_stage`)  
- Intermediate register `crc_mid` to break the XOR/shift critical path  
- Explicit FSM states: `IDLE`, `LOAD`, `SHIFT`, `DONE`  
- Bit‑serial processing of each 32‑bit word  
- Higher achievable frequency (≈125 MHz in DP2 reports)

Outputs:
- `busy` – datapath is active  
- `done` – computation finished  
- `result` – final CRC value  

---

### **3. crc_datapath_tb.v**
Standalone Verilog testbench for validating the DP2 datapath.

Features:
- Generates a 100 MHz clock (`#5` period)  
- Dumps waveforms to `crc.vcd`  
- Includes a reusable task `run_single_sync`  
- Uses Python‑generated expected CRC values  
- Tests six regression vectors:
  - A5A5A5A5  
  - 5A5A5A5A  
  - 00000000  
  - FFFFFFFF  
  - 12345678  
  - DEADBEEF  

The testbench confirms functional correctness of the pipelined datapath.

---

## 📌 Summary

DP2 RTL introduces:
- A pipelined CRC datapath for improved timing  
- A refined FSM for cleaner control  
- A wrapper compatible with the DP2 synthesis flow  
- A regression testbench for functional validation  

These RTL changes directly support the performance improvements documented in `../docs/optimization_report.md`.
