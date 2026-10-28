# AI-HDL 2026: Design Phase 1 Documentation

**Phase Title:** Additional Module Synthesis

**Duration:** January 15 – January 28, 2026

**Objective:** To integrate a custom functional module (accelerator, peripheral, or instruction
extension) into the provided base RISC-V core using an "AI-first" design methodology.

## 1. Technical Requirements & Environment

```
The competition utilizes a mix of industry-standard and open-source tools. Participants
must ensure their local environment is configured prior to the January 15th league start.
The Digital Workbench
```
- **Operating System:** Windows Subsystem for Linux (WSL) is recommended for
    Windows users to run the Linux-based toolchain.
- **Hardware Foundation:** A functional, base RISC-V processor core provided by the
    league.
- **AI Toolkit:** Access to leading LLMs (ChatGPT, Claude, Gemini, Llama) for generating
    Verilog code.
- **EDA Tool Stack: Yosys & OpenLane -** For logic synthesis and area estimation.

## 2. Weekly Milestone Journey

```
This phase is structured as a 2 - week sprint to ensure a stable foundation for the following
optimization phases.
Week 1 (Jan 15-21): Project Kickoff & Base Integration
```
- Develop your project plan and block diagrams for your new module.
- Use LLMs to generate Verilog for your new module and a simple, standalone
    testbench for just that module.
- Connect your new module to the top-level core
**Week 2 (Jan 22-28): Full-Core Simulation, Verification & Milestone**
- Run the full simulation suite to ensure you didn't break anything.
- Run a baseline synthesis to get initial PPA estimates.


- Fix any bugs, clean up your code, reports, AI prompt logs, and tag your final commit
    on GitHub.

## 3. Deliverables & Submission Guidelines

```
Teams must submit their work via a private GitHub repository, granting access to assigned
mentors and judges.
Required for DP1 Submission:
```
- **Synthesizable RTL:** Your complete, modified RISC-V core Verilog code.
- **Verification Results:** All testbenches (provided and custom) must pass.
- **Baseline Synthesis Report:** An initial report from Yosys/OpenLane showing area and
    timing estimates.
- **DP1 Report & Documentation (required):**
    o Full RTL module package.
    o **LLM prompt logs (Crucial!).**
    o Write-up of your Design choice, PPA results, and schematic.
- **GitHub Tag:** A final commit tagged as "DP1-Submission **".**

## 4. Grading & Advancement Criteria

```
DP1 accounts for 20% of the total cumulative score.
```
```
Category Weight Criteria
```
```
Module Implementation 30% Completeness & correctness of your new module.
```
```
Verification & Testing 25% All testbenches pass; quality of custom unit tests.
```
```
Documentation &
Planning
```
```
25 % Clear project plan, block diagrams, and LLM prompt
logs.
```
```
Code Quality &
Repository 20 %^ Use of GitHub tags, clean commits, code comments.^
```
## 5. Design Inspiration (Peripheral Ideas)

```
Teams are encouraged to be creative. Complex designs earn higher "Innovation Points".
```
- **Simple:** GPIO Controller, PWM Generator, or Watchdog Timer.


- **Medium:** UART/Serial Interface, SPI/I2C Controller, or CRC Unit.
- **Complex:** AI Accelerator (Matrix Math), AES Encryption Engine, or DMA Controller.

## 6. Useful links

- AI-HDL website link: https://csm.arizona.edu/AIHDL
- AI-HDL Github link: https://github.com/prismlabarizona/AIHDL- 2026
- RISC-V code repo: https://github.com/TinyTapeout/ttsky25a-tinyQV
- Peripheral template repo: https://github.com/prismlabarizona/AIHDL-
    2026/tree/master/tinyqv-full-peripheral-template
- Yosys Installation method:
    https://www.youtube.com/watch?v=XRexMO1B6s8&pp=2AYE
- OpenLane Installation method:
    https://www.youtube.com/watch?v=tFaTHGgpslA&pp=2AYB
- Design phase 1 example: https://www.youtube.com/watch?v=M20AJiT_ETE
- Webinar 3 – Base design Implementation:
    https://www.youtube.com/watch?v=rOaLiDxNm

**Important Date:** Milestone Review 1 (MR#1) is scheduled for **January 29, 2026.** Ensure your mentor
check-ins are completed weekly to receive advisory feedback.


