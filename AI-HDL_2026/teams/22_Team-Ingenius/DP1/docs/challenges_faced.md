# Challenges Faced – Ingenius CRC Peripheral

This document lists the real challenges our team encountered during DP1 and how we solved them.  
All items here reflect actual issues from our RTL, testbench, and workflow.

## 1. CRC Logic Confusion
At the beginning, AI suggestions mixed up:
- Reflected CRC vs non‑reflected CRC
- Right‑shift vs left‑shift CRC update styles

**How we solved it:**  
We manually rewrote the CRC logic in `crc_datapath.v` to use the correct left‑shift polynomial `0x04C11DB7`.

## 2. Start Pulse Handling
The datapath needed a clean one‑cycle `start` pulse.  
Early AI drafts did not generate proper pulse logic.

**How we solved it:**  
We added `start_d` and `start_pulse` logic in the datapath to detect rising edges.

## 3. MMIO Register Mapping
AI‑generated register maps did not match TinyQV addressing rules.  
Some addresses were incorrect or out of alignment.

**How we solved it:**  
We manually assigned the correct addresses:
- CTRL → 0x00  
- STATUS → 0x04  
- SEED → 0x08  
- LEN → 0x0C  
- DATA → 0x10  
- RESULT → 0x14  

## 4. Integration with TinyQV Bus
The TinyQV bus uses `data_write_n`, `data_read_n`, and a 6‑bit address.  
AI examples used AXI‑Lite, which does not apply here.

**How we solved it:**  
We rewrote the MMIO wrapper (`tt_um_ingenius_crc.v`) to follow TinyQV’s bus protocol.

## 5. Testbench Adjustments
AI‑generated testbench examples did not match the TinyQV Python API.  
They used generic cocotb patterns instead of the `TinyQV` helper class.

**How we solved it:**  
We rewrote the testbench using:
```python
tqv = TinyQV(dut, peripheral_num=14)
```
and used `write_word_reg()` and `read_word_reg()` correctly.

## 6. Synthesis Setup
OpenLane initially needed correct file paths and clock settings.

**How we solved it:**  
We created a clean `config.tcl` with:
- Correct top module (`tt_um_ingenius_crc`)
- Correct RTL file list
- Clock = 20 ns (50 MHz)

## 7. Interrupt Behavior
The interrupt needed to assert only when CRC computation finished.

**How we solved it:**  
We mapped:
```
user_interrupt = status_reg[1]
```
which reflects the `done` signal from the datapath.
