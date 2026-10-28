# AI Hardware Design League (AI-HDL) Webinar 2 Detailed Overview

## Webinar Agenda Overview

This webinar, the second in a series, provides a deep dive into the AI-HDL competition structure and the
initial challenge. The competition ocially starts in **January**.

The webinar agenda covered the following topics:

```
. Recap: The AI-HDL Vision & Structure
. The Core Challenge: Project Scope & Base System
. Methodology: AI-First & Dual-Toolchain
. The 16-Week Journey: A Deep Dive
Phase 1: Base Design Expansion
Phase 2: Design Evaluation & PPA Optimization
Phase 3: Security Evaluation & Threat Mitigation
Phase 4: Netlist to Chip Tapeout
. Next Steps & Q&A
```
**Crucial Note for Registration:** The current registration deadline for the competition is the **end of
November**.

## 16-Week Competition Structure Recap

The competition is structured into four distinct phases, culminating in a physical chip tapeout:

```
Phase 1: Base Design Expansion (DP#1): Focuses on adding new functionality to the base chip.
Phase 2: Design Evaluation & PPA Optimization (DP#2): Focuses on improving the Power,
Performance, and Area (PPA) eciency of the design.
Phase 3: Security Evaluation & Threat Mitigation (DP#3): Teams submit their designs, which will
then be "hacked" by the organizing team to identify vulnerabilities. The teams must then x the
security aws.
Phase 4: Netlist to Chip Tapeout (DP#4): The nal stage, where the Register-Transfer Level
(RTL) code is converted to a GDSII le (the nal physical layout le for manufacturing).
```

## Key Technologies

The competition leverages a three-part technical foundation:

```
RISC-V: An open-source Instruction Set Architecture (ISA) that teams will build upon. This
provides a exible and modiable core.
AI (LLMs): Large Language Models are the primary tool used for design generation.
EDA Tools (Electronic Design Automation): Teams will gain hands-on experience with both open-
source and commercial tools for design implementation and verication.
```
## Methodology: AI-First

The core methodology for the competition is **AI-First** :

```
Key Rule: The core hardware design must be generated via prompting LLMs.
Scoring: Is based on the effective utilization of LLMs for design and optimization.
Minor manual corrections are allowed to the LLM-generated design.
Documentation: Participants must submit their prompt logs as a crucial part of the
documentation to demonstrate their use of the AI tools.
Support: Dedicated mentors and industry experts will be available via Discord (QR code provided
in the webinar) to help teams with technical questions and overcome any challenges, especially
regarding bugs or xing issues in the AI-generated code.
```
## The Core Challenge: Customizing a RISC-V Core

The project is a **Core-Based Implementation**. Teams will not be building a CPU from scratch.

```
You will be provided with a functional, base RISC-V processor core.
Your primary task is to extend this core with new, custom functionality (conceptually, adding a
"guest room" to the main "house").
Focus is on modifying and optimizing the provided core, not rebuilding the complex CPU logic.
```
### The "Guest Room" Specications

Teams will integrate a custom module into the RISC-V core using a full peripheral template (a guest
room connected to the main hallway).

```
Data Size: 32-bit (4 Bytes), the full width of the CPU.
Complexity: High (the nal module should handle complex operations).
Use Cases (Examples): AI Accelerator (Matrix Math), Encryption Engine, Math Coprocessor
(Faster calculations).
```

## Design Phase #1 (DP#1): Base Design Expansion

## (January)

The objective of the rst phase is to integrate the custom module into the RISC-V core and ensure it is
fully functional.

```
Timeline Milestone/Activity
January 15 League Starts with DP#1: Base Design Expansion
January 29 MR#1 (Milestone Review) & OH#1 (Oce Hours)
```
**Objective:** Integrate a custom module (e.g., accelerator, or instruction extension) into the base RISC-V
core.

**Deliverable:** Functionality, Verication, and Documentation. (Initial speed and size are **not** the primary
focus here).

### DP#1: Key Concepts - RTL & Synthesis

```
RTL (Register-Transfer Level): A high-level, behavioral description of your chip (your Verilog
code).
Synthesis: The process of converting your RTL into a structural description (a "netlist") made of
standard logic gates (NAND, NOR, etc.).
Your Objective: Produce an RTL code that is synthesizable (no errors) and functionally correct.
```
### DP#1: Weekly Goals

```
Week Date Goal
```
```
Week
1
```
```
Jan
15-
21
```
```
Project Kickoff & Base Integration: Develop your project plan and block diagrams for
your new module. Use LLMs to generate Verilog for your new module and a simple,
standalone testbench. Connect your new module to the top-level core.
```
```
Week
2
```
```
Jan
22-
28
```
```
Full-Core Simulation, Verication & Milestone Prep: Run the full simulation suite to
ensure you didn't break anything. Run a baseline synthesis to get initial PPA
estimates. Fix any bugs, clean up your code, reports, AI prompt logs, and tag your
nal commit on GitHub.
```
### DP#1: Key Tools

```
Category Tool Description
```

```
Category Tool Description
Simulation
(Verication) Verilator
```
```
Open-source simulator that converts your Verilog to C++ for high-
speed simulation.
GTKWaves The waveform viewer you will use to visually debug your design.
Synthesis
(Implementation) Yosys
```
```
The open-source synthesis tool you will use to check for synthesis
errors and get a baseline report.
Cadence
Genus The commercial alternative you will also have access to.
```
### DP#1: Final Deliverables

```
. Synthesizable RTL: Your complete, modied RISC-V core Verilog code.
. Verication Results: All testbenches (provided and custom) must pass.
. Baseline Synthesis Report: An initial report from Yosys/Genus showing area and timing
estimates.
. DP1 Report & Documentation (required):
Full RTL module package.
LLM prompt logs (Crucial!).
Write-up of your Design choice, PPA results, and schematic.
. GitHub Tag: A nal commit tagged as "DP1-Submission".
```
### DP#1: Scoring Rubric

```
Category Weight Criteria
Module Implementation 30% Completeness & correctness of your new module.
Verication & Testing 25% All testbenches pass; quality of custom unit tests.
Documentation & Planning 25% Clear project plan, block diagrams, and LLM prompt logs.
Code Quality & Repository 20% Use of GitHub tags, clean commits, code comments.
```
## Design Phase #2 (DP#2): Design Evaluation & PPA

## Optimization (February)

The second phase is dedicated to analyzing and optimizing the design generated in DP#1 for eciency.

```
Timeline Milestone/Activity
```

```
Timeline Milestone/Activity
February 12 DP#2: Design Evaluation and PPA Optimization Starts
February 26 MR#2 (Milestone Review) and OH#2 (Oce Hours)
```
**Objective:** Take your functional DP#1 design and make it ecient. Optimize for **Power, Performance,
and Area (PPA)**.

**Deliverable:** Analysis, Microarchitectural Tweaks, and Trade-offs.

### DP#2: Key Concepts (What is PPA?)

```
Power: How much power your chip consumes (measured in watts). Lower is better.
Performance: How fast your chip runs (measured in frequency, e.g., MHz, or delay, e.g.,
nanoseconds). Higher frequency / Lower delay is better.
Area: How much physical silicon space your chip uses. Smaller is better.
The "Iron Triangle": Improving one (e.g., Performance) could impact others (e.g., Power, Area).
Your objective is to nd the best trade-off.
```
### DP#2: Key Concepts (What is STA & CG?)

```
Static Timing Analysis (STA): The process of analyzing a design's timing without simulation. It
nds the critical path, the slowest path in your design, which limits your max clock speed.
Clock Gating (CG): A popular power-saving technique. The idea: if a part of your chip isn't being
used, stop sending it the clock signal. No clock = no switching = no power consumption.
```
### DP#2: Weekly Goals

```
Week Date Goal
```
```
Week
1
```
```
Feb
12-
18
```
```
Baseline Analysis & Planning: Run a full PPA analysis on your nal DP#1 design to get
a baseline. Create an "Optimization Plan" listing your PPA goals. Implement
microarchitectural tweaks to x your critical path (e.g., add pipeline stages).
Implement power-saving features like clock gating.
```
```
Week
2
```
```
Feb
19-
25
```
```
Performance Optimization & Submission: Run regression tests to ensure new
optimization tweaks did not break normal functionality. Analyze PPA trade-offs (e.g.,
did power saving hurt timing?). Generate nal PPA reports. Create a "before-and-
after" comparison report to show improvements. Tag your DP#2 submission on
GitHub.
```
### DP#2: Final Deliverables

The successful completion of Design Phase #2 requires the following nal submission components:


```
. Optimized RTL: Your modied, functionally correct, and PPA-optimized Verilog code.
. Final STA & PPA Reports: The nal sign-off reports showing your new and improved Power,
Performance, and Area (PPA) numbers, as well as the Static Timing Analysis (STA) results.
. Optimization Report: A document containing:
Your baseline PPA analysis from Week 1.
A "before-and-after" comparison highlighting your nal improvements.
A write-up justifying the design trade-offs made during the optimization process (e.g.,
accepting slightly lower frequency for a signicant reduction in power consumption).
. GitHub Tag: A nal commit tagged as "DP2-Submission."
```
### DP#2: Scoring Rubric

```
Category Weight Criteria
Performance
Optimization 25% Measurable improvements in timing/frequency metrics.
Power
Optimization 25%
```
```
Implementation of power-saving features (e.g., clock gating) and a
measurable power reduction.
Final Results &
Reporting 20%
```
```
Quality of before/after comparisons and ensuring all regression tests
are clean (all pass).
Trade-off
Justication 15% Clear documentation of why certain PPA trade-offs were made.
Baseline PPA
Analysis 15%
```
```
Thorough analysis of the initial DP#1 design and clear identication
of bottlenecks.
```
## Design Phase #3 (DP#3): Security Evaluation & Threat

## Mitigation

### DP#3: Overview

```
Timeline: Starts March 12
Milestone Review & Oce Hours (MR#3 & OH#3): March 26
Objective: Assess your PPA-optimized design for hardware vulnerabilities and implement
countermeasures to make it secure. This phase is often the most "eye-opening" for students, as
secure chip design is a critical and often overlooked area in curriculum.
Deliverable: Security Assessment, Countermeasure Implementation, and Validation.
```
### DP#3: Key Concepts (What is Hardware Security?)


```
Hardware Vulnerability: A aw in your design (a weakness in the logic itself) that an attacker can
exploit.
Critical Distinction: Unlike software, hardware bugs cannot be addressed post-fabrication
(after the chip is printed).
Common Weakness Enumeration (CWE): A dictionary of known hardware and software weakness
types.
Examples: Side-channels, Hardware Trojans, Debug misuse, and Buffer overows.
Your Objective: You will act as a security audit team. You will nd potential CWEs in your design,
implement xes, and use the AI tools (LLMs) to help verify your design for vulnerabilities.
```
### DP#3: Weekly Goals

```
Week Date Goal
Week
1
(Mar
12-
18):
```
```
Security
Assessment &
Implementing
Security
Features
```
```
(1) Create a "Security Review Document" listing potential CWEs in your
DP#2 design. (2) Develop a "Mitigation Plan" for the features you will add.
(3) Implement at least one major security countermeasure (e.g., Add
privilege-level checks, data input authentication, or logic to randomize
power consumption).
Week
2
(Mar
19-
25):
```
```
Validation,
Hardening &
Documentation
```
```
(1) Test your security feature (how do you prove it works?). (2) Run all
regression tests to ensure you didn't break normal functionality. (3)
Analyze the PPA impact (i.e., how much did your security feature "cost" in
area or timing?). (4) Write your nal DP#3 Security Report and tag your
secure RTL for submission.
```
### DP#3: Final Deliverables

```
. Secure RTL: Your modied, hardened, and functionally correct Verilog code.
. Security Evaluation Report: A comprehensive document containing:
Your vulnerability assessment from Week 1.
A detailed explanation of the countermeasures you implemented.
Validation results (how you proved the x works).
PPA Overhead Analysis (the "cost" of your security feature).
. GitHub Tag: A nal commit tagged as "DP3-Submission."
```
### DP#3: Scoring Rubric

```
Category Weight Criteria
Security Feature
Implementation 30% Meaningful, well-implemented countermeasures.
Validation & Hardening 25% Comprehensive security testing to prove the x works.
```

```
Category Weight Criteria
Security Assessment 20% Thorough vulnerability review and a well-structured plan.
```
```
Documentation & Reporting 15% Clear DP#3 report, detailed explanation of mitigations &trade-offs.
```
```
Design Stability 10% Functional correctness is preserved; all regression testsare clean.
```
## Design Phase #4 (DP#4): Netlist to Chip Tapeout (April)

### DP#4: Overview (For Finalists Only)

```
Timeline: April 9 – April 22 (The competition phase).
Milestone Review & Oce Hours (MR#4 & OH#4): April 23.
Objective: Take your secure, optimized RTL design and turn it into a nal, manufacturable
physical layout (GDSII le).
Objective: From RTL to Silicon.
Deliverable: Physical Design, "Back-End" Flow, and Sign-off.
```
### DP#4: Key Concepts (The "Back-End" Flow)

This phase represents the nal steps to transition from logical code to a physical chip layout:

```
Step Process Description
```
```
1.
Floorplanning
```
```
Dening the chip's "oorplan" where the major functional blocks (CPU,
Memory, I/O) along with the logic blocks, I/O pins, and power grid will
go.
```
**2. Place &
Route (P&R)**

```
Placement: The tool places all the millions of standard cells onto the
oorplan. Routing: The tool connects all the cells with tiny metal
wires (traces).
```
**3. Sign-off
(DRC/LVS)**

```
DRC (Design Rule Check): Ensures your layout is manufacturable
(e.g., no wires are too close or too thin). LVS (Layout vs. Schematic):
Ensures the physical layout matches the logical circuit/design (RTL
logic) you intended.
```
### DP#4: Weekly Goals

```
Week Date Goal
```

```
Week Date Goal
```
```
Week
1
(Apr
9-
15):
```
```
Synthesis,
Floorplanning,
Placement, CTS
(Clock Tree
Synthesis) &
Routing
```
```
(1) Run your nal synthesis on the DP#3 design. (2) Create your chip's
oorplan, including power grid and I/O pin placement. (3) Run the main
Placement, CTS, and Routing tools. (This is a highly iterative process
where you will run the tool, analyze timing, tweak settings, and run it
again until timing closure is met).
```
```
Week
2
(Apr
16-
22):
```
```
Sign-off
Verication &
Final Tape-out
Package
```
```
(1) Run your nal STA, DRC, and LVS checks. (2) Your goal is "DRC/LVS
Clean" (zero errors). This is the bar for a manufacturable chip. (3) Package
your nal GDSII le. (4) Write your nal, comprehensive project report
covering the entire 16-week journey (DP#1-DP#4).
```
### DP#4: Final Deliverables

```
. Final GDSII File: The manufacturable layout of your chip (the geometric data le for fabrication).
. Sign-off Reports: Clean DRC, LVS, and nal STA reports (showing zero errors).
. Final Project Report: A comprehensive report detailing your entire journey from DP#1 to DP#4,
including your nal PPA metrics, security features, and reections on the process.
. GitHub Tag: A nal commit tagged as "DP4-Submission."
```
### DP#4: Scoring Rubric

```
Category Weight Criteria
Physical Design Flow
Execution 30%
```
```
Successful, complete ow (Synth, P&R, CTS); no critical
gaps.
Sign-off Quality 20% DRC/LVS clean reports (A manufacturable design).
```
```
Timing Closure & PPA 20% Final STA reports are clean; nal PPA metrics are well-documented.
```
```
Submission Package 20% Complete GDSII, netlist, constraints, and nalcomprehensive report.
```
```
Presentation & Clarity 10% Clear repository organization and project story.
```
## Final Competition Summary

### How are the Winners Chosen?

Final ranking is based on a **Cumulative Weighted Score** across all four design phases (Total: 100%):


```
Design PhaseDesign Phase FocusFocus WeightWeight
DP#1 Functionality 20%
DP#2 PPA Optimization 25%
DP#3 Security 25%
DP#4 Layout 30%
```
```
The Top 3 Teams with the highest cumulative score will be recognized as Winners.
The Top-Performing Team will win a Chip Tapeout (having their design manufactured as a
physical chip).
```
### Bonus Opportunities & Penalties

```
Category Examples
Bonus Points
(For
Exceptional
Innovation)
```
```
Exceptional, creative use of AI/LLMs. Implementing an advanced feature.
Contributing a bug-x or feature back to an open-source tool.
```
```
Major
Penalties
(Major
Deductions)
```
```
A design that doesn't simulate or synthesize at nal submission. Failing to submit a
GDSII le in DP#4. Failing DRC/LVS checks (not a manufacturable design).
Incomplete documentation (e.g., missing AI prompt logs).
```
### Your Journey Starts Here: Next Steps

```
Action Details
Registration
Closes
```
```
November 30th, 2025. All team members must register individually using their
institutional email address.
Attend Next
Webinar
```
```
Initial RTL Demo & Environment Walkthrough (Dec 18). A live demo of the base core
and the open-source tool setup will be provided.
Join the
Discord Start talking with other participants and mentors now.
```
**_Note: All competition materials, including video tutorials and the base design core, will be made
available through the competition website and Discord channel._**

## Q&A: Competition Logistics & Enrollment


### Team Composition and Submission Process

```
Individual Registration: Every participant in the team must register individually on the website
using their institutional email.
Team Size Requirement: Teams must consist of 3 to 5 members. If a team registers with only two
members, the organizers will assign a third member from the same institution to their team to
ensure they meet the minimum requirement.
Team Lead & Communication: Once a team is formed, one person will be designated as the
Team Lead.
This individual will be the main point of contact for the organizers.
The Team Lead is responsible for all GitHub submissions for the team.
The Team Lead acts as the central link to receive resources and pose any questions
(including tool or technical troubleshooting) to the dedicated mentors.
```
### Ocial Resources and Timeline

```
Competition Timeline: The entire competition timeline, including all Design Phase (DP) and
Milestone Review (MR) dates, is available on the AI-HDL website under the "Timeline" tab.
Webinar Recordings: The recordings for all past webinars, including this one, will be posted on
the AI-HDL website. The registration link for a webinar will be updated to a link for the YouTube
video recording shortly after the session.
Next Key Webinar: Participants are advised to attend Webinar 3 (Dec 18) , which will feature a live
demo of the base RISC-V core design and a walkthrough of the tool environment setup.
```
## Q&A: Technical & Development Process

### Educational Resources and Prerequisites

```
Learning Materials: The website contains an extensive section of "Educational Resources" for
participants who may not have a deep background in all areas of hardware design.
Content Includes: Training materials on:
The fundamentals of hardware and semiconductors (e.g., what is an FPGA, ASIC, CPU
architecture).
An introduction to Verilog (the hardware description language used in the competition).
How to utilize AI for hardware design, including using LLMs for ASIC design.
```
### Asynchronous Workload & Flexibility

```
Self-Paced Work: The AI-HDL competition is asynchronous. Teams are encouraged to work on
their own time and schedule to best accommodate their academic commitments (e.g., nal
```

```
exams in January).
Design Phase Submission: While the timeline suggests completing the phases sequentially,
teams can submit all four Design Phases at once if they wish. The overall cumulative score at the
end is what matters. However, following the suggested schedule is highly recommended for
pacing and iterative improvement.
Suggested Weekly Commitment: The organizers suggest a weekly commitment of approximately
6 hours per team , broken down as:
1 hour for weekly check-ins/meetings (Milestone Reviews, Oce Hours).
5 hours for project work, which can be distributed among team members.
```
### Advanced Features and Bonus Points

```
Advanced Feature Denition (DP#1): The core task involves creating a new, custom module (a
"guest room") for the provided RISC-V core. An "advanced feature" refers to the complexity and
novelty of the function built into this module, such as a specialized AI Accelerator, an Encryption
Engine, or a Math Coprocessor.
Bonus Points Opportunities: Teams can earn bonus points for:
Exceptional use of AI/LLMs in the design process.
Implementing highly advanced features or optimizations in DP#1 or DP#2.
Identifying and reporting a novel security vulnerability (CWE) in the design (DP#3) that the
organizing team had not previously found.
DP#4 Back-End Tooling: For Design Phase 4 (Netlist to Chip Tapeout), teams are given exibility
in how they manage the complex transition between the synthesis tools (Yosys/Cadence) and the
physical design tools (OpenROAD/Synopsys). Creating a unied script or makele to automate the
process of managing intermediate les, data passing, and constraints would be considered a
valuable contribution to the overall design process and scored accordingly.
```
## Final Review: Key Takeaways & Next Steps

```
Overall Goal: The competition's main goal is for every participant to learn a valuable, in-demand
hardware design skill set using modern AI tools and gain experience with industry-standard
ows.
Winner Recognition: The competition will recognize:
The Top 3 teams in both the Undergraduate and Graduate divisions based on the cumulative
weighted score across all four Design Phases.
The overall single best design from either division will win the prize of having their chip
fabricated (Chip Tapeout).
All participants who actively engage in the competition will receive a certicate of
completion.
Critical Next Steps:
. Register: Finalize your team and register by November 30th, 2025.
```

. **Join Discord:** The Discord server is the ocial hub for all communication, peer-to-peer
discussions, and mentor support. (Use the QR code provided in the webinar).
. **Attend Webinar 3:** Mark your calendar for **December 18th** for the initial RTL demo and
environment walkthrough.


