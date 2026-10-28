# Lessons Learned – Ingenius CRC Peripheral

This document summarizes the key lessons our team learned while completing DP1.  
All lessons here reflect our actual workflow, debugging experience, and design process.

## 1. AI Is Helpful but Not Always Accurate
We learned that AI can generate useful starting points, but:
- It sometimes produced CRC logic that did not match our intended design
- It mixed up TinyQV bus rules
- It gave testbench examples that needed rewriting

We realized AI is a tool, not a replacement for understanding.

## 2. Manual Review Is Essential
Every AI‑generated block had to be checked manually.  
We caught issues in:
- Pulse generation
- Register mapping
- CRC polynomial handling
- Testbench structure

This taught us the importance of human verification.

## 3. TinyQV Bus Protocol Must Be Followed Carefully
The TinyQV bus uses:
- `data_write_n`
- `data_read_n`
- 6‑bit addresses

We learned that even small mistakes in these signals break the peripheral.

## 4. Testing Early Helps Catch Mistakes
Using the cocotb testbench early helped us:
- Confirm register writes worked
- Confirm interrupts triggered correctly
- Validate CRC outputs
- Debug timing of start pulses

Testing saved us from bigger issues later.

## 5. Synthesis Reports Matter
Running OpenLane/Yosys taught us:
- How area and timing are measured
- How to read WNS/TNS
- How clock period affects timing closure

We confirmed our design meets 50 MHz, which is required for DP1.

## 6. Documentation Must Be Clear
We learned that:
- Good documentation helps the whole team understand the design
- Register maps must be written clearly
- Block diagrams make the architecture easier to follow

This is especially important for a team with mixed experience levels.

## 7. Team Collaboration Improves Quality
Each member contributed differently:
- RTL writing
- Debugging
- Testing
- Documentation
- Synthesis

Working together helped us catch mistakes and improve the final design.
