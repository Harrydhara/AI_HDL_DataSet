# Design Methodology – Ingenius CRC Peripheral

This document explains how our CRC peripheral was designed, how it works, and how it integrates with the TinyQV RISC‑V core.

## 1. Design Goal
Implement a medium‑complexity CRC engine that:
- Computes CRC‑32
- Uses a clean MMIO register interface
- Signals completion through an interrupt
- Fits within DP1 timing and area constraints

## 2. Architecture Overview
The design has two main blocks:

1. **MMIO Wrapper (tt_um_ingenius_crc)**  
   - Handles register reads/writes  
   - Generates `start` and `reset` pulses  
   - Stores SEED, LEN, DATA  
   - Exposes STATUS and RESULT  
   - Raises `user_interrupt` when done  

2. **CRC Datapath (crc_datapath)**  
   - Performs CRC computation  
   - Uses polynomial `0x04C11DB7`  
   - Processes one word per cycle  
   - Outputs `busy`, `done`, and `result`

## 3. Data Flow Summary
1. Software writes SEED  
2. Software writes LEN  
3. Software writes DATA  
4. Software writes CTRL (start = 1)  
5. Datapath runs for LEN cycles  
6. Datapath sets `done = 1`  
7. MMIO wrapper latches RESULT  
8. Interrupt is raised

## 4. Integration with TinyQV
- Peripheral index: **14**  
- Connected through TinyQV bus signals  
- All reads complete in one cycle (`data_ready = 1`)  
- Interrupt mapped to `user_interrupt`

## 5. Why CRC?
- Medium difficulty (recommended for DP1)  
- Real‑world relevance (networking, storage, communication)  
- Easy to test with known vectors  
- Demonstrates datapath + control + MMIO design
