# AIHDL-Team_Ingenius- — DP1

This folder contains our Design Phase 1 (DP1) work for the Arizona AI-HDL Challenge 2026.  
We implemented a medium-complexity CRC peripheral (Ingenius CRC Engine) for the TinyQV RISC-V core.

## Contents
- `rtl/` – Verilog source files (MMIO wrapper + CRC datapath)
- `test/` – Cocotb testbench for the CRC peripheral
- `docs/` – Documentation and peripheral description
- `reports/` – Synthesis, timing, and power reports
- `openlane_run/` – OpenLane configuration and run files
- `info.yaml` – Build configuration for the peripheral

## Documentation
All DP1 documentation is located in the `docs/` folder:

- `design_methodology.md` – How the CRC peripheral was designed
- `ai_strategy.md` – How AI was used during development
- `challenges_faced.md` – Issues we encountered and how we solved them
- `lessons_learned.md` – What the team learned during DP1
- `block_diagram.md` – Text-based architecture diagram of the design
