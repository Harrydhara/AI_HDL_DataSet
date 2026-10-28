# CRC Peripheral (tqvp_ingenius_crc)

**Author:** Team Ingenius  
**Peripheral Index:** 14  

---

## Overview

The Ingenius CRC Peripheral implements a **Cyclic Redundancy Check (CRC) engine** with a register‑mapped interface.  
It allows software to configure a seed value, specify the length of the data stream, feed input data, and read back the computed CRC result.  
This design is intended for error detection in communication protocols and data integrity verification.

---

## Register Map

| Address | Name    | Access | Description                                                                 |
|---------|---------|--------|-----------------------------------------------------------------------------|
| 0x00    | CTRL    | W      | Bit0 = Enable, Bit1 = Start. Writing `0x3` triggers CRC computation.        |
| 0x04    | SEED    | W      | Initial CRC seed value (32‑bit).                                            |
| 0x08    | LEN     | W      | Length of the data stream (number of bytes).                                |
| 0x0C    | DATA    | W      | Data input register. Each write pushes one byte into the CRC datapath.      |
| 0x10    | STATUS  | R      | Bit0 = Done. Set when CRC computation finishes.                             |
| 0x14    | RESULT  | R      | Final CRC result after computation (32‑bit).                                |

---

## Usage / How to Test

1. Reset the peripheral.  
2. Write the seed value to `SEED`.  
3. Write the length of the data stream to `LEN`.  
4. Stream data bytes into `DATA`.  
5. Write `0x3` to `CTRL` (enable + start).  
6. Poll `STATUS` until the `done` bit is set.  
7. Read the CRC result from `RESULT`.  

The testbench (`test/user_peripherals/tqvp_ingenius/test.py`) uses the **TinyQV class** to perform register reads/writes.  
It verifies correctness by comparing the hardware CRC result against expected values from multiple test vectors.

---

## Simulation Results

Example test vectors:

- Seed = `0x12345678`, Data = `0xDEADBEEF` → Result = `0x5e509033`  
- Seed = `0xFFFFFFFF`, Data = `0x00000000` → Result = `0x4e08bfb4`  
- Seed = `0x00000000`, Data = `0xCAFEBABE` → Result = `0xe6f8348a`  

All tests passed successfully in cocotb simulation.

---

## External Hardware

No external hardware is required.  
The peripheral is tested entirely through the TinyQV SPI test harness.  

- `user_interrupt` → connected to `uio[0]` for interrupt signaling  
- `data_ready` → connected to `uio[1]` for result availability  

---

## Notes

- Designed for educational use as part of TinyTapeout SkyWater 130 shuttle.  
- Avoid using `ui_in[7]` and `uo_out[0]` to ensure compatibility with TinyQV Micropython.  
- Can be extended to support multiple CRC polynomials in future revisions.