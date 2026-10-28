# AI Strategy – Ingenius CRC Peripheral

This document explains how AI tools were used during the development of our CRC peripheral in DP1.  
All AI usage listed here reflects the real prompts and workflow our team followed.

## 1. Purpose of Using AI
We used AI mainly to:
- Draft initial versions of the CRC datapath
- Draft the MMIO wrapper structure
- Suggest register map layouts
- Provide example testbench structures
- Explain CRC concepts during early planning

AI was used as a helper, not as an automatic code generator.  
All generated code was reviewed and corrected by team members.

## 2. What AI Actually Generated
From our prompt logs in `docs/prompts/`:
- Initial CRC datapath skeleton (later modified by the team)
- Initial MMIO wrapper outline
- Early ideas for register map fields
- Explanations of CRC polynomial logic
- Suggestions for verification steps

## 3. What the Team Wrote Manually
The following parts were written or heavily edited by the team:
- Final CRC datapath (`crc_datapath.v`)
- Final MMIO wrapper (`tt_um_ingenius_crc.v`)
- Integration with TinyQV bus
- Cocotb testbench (`test.py`)
- OpenLane configuration (`config.tcl`)
- All synthesis and PPA work
- All documentation

## 4. AI Limitations We Encountered
During DP1, AI:
- Sometimes suggested CRC logic that did not match our design style
- Produced register maps that did not match TinyQV addressing
- Gave testbench examples that needed rewriting for TinyQV
- Mixed up reflected vs non‑reflected CRC polynomials

These issues were corrected manually by the team.

## 5. How We Ensured Correctness
To avoid relying blindly on AI:
- We reviewed all AI‑generated code line by line
- We tested the design using cocotb
- We compared CRC outputs with known vectors
- We validated timing and area using OpenLane

This ensured the final design matched DP1 requirements.
