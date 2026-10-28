# AI-HDL 2026: Design Phase 4 Documentation

**Phase Title:** Netlist to Chip Tapeout
**Duration:** April 9 – April 23 , 2026
**Objective:** To take your Secure DP# 3 optimized RTL design and turn it into a final, manufacturable
physical layout (GDSII file).

## 1. Weekly Milestone Journey

```
This phase is structured as a 2-week sprint to ensure a stable foundation for the following
optimization phases.
Week 1 (Apr 9-15): Synthesis, Floorplanning, Placement, CTS & Routing
```
- Run your final synthesis on the DP3 design.
- Create your chip's floorplan, including power grid and I/O pin placement.
- Run the main Placement, Clock Tree Synthesis (CTS), and Routing tools.
- This is a highly iterative process. You will run the tool, analyze timing, tweak settings,
    and run it again.
**Week 2 (Apr 16-22):** Sign-off Verification & Final Tape-out Package
● Run your final STA, DRC, and LVS checks.
● Your goal is “DRC/LVS Clean” with zero errors.
● This is the bar for a manufacturable chip.
● Package your final GDSII file.
● Write your final, comprehensive project report covering the entire 16-week journey
(DP1-DP4).

## 2. Deliverables & Submission Guidelines

```
Teams must submit their work via a private GitHub repository, granting access to assigned
mentors and judges.
Required for DP 4 Submission:
```
- **Final GDSII File:** The manufacturable layout of your chip.
- **Sign-off Reports:** Clean DRC, LVS, and final STA reports.
- **Final Project Report:** A comprehensive report detailing your entire journey from DP1 to
    DP4, including your final PPA metrics, security features, and reflections on the process.
- **GitHub Tag** : A final commit tagged as “DP4-Submission”.


## 3. Grading & Advancement Criteria

```
DP 4 accounts for 30 % of the total cumulative score.
Category Weight Criteria
Physical Design Flow
Execution
```
### 30%

```
Successful, complete flow (Synth, P&R, CTS); no
critical gaps.
Sign-off Quality 20% DRC/LVS clean reports. A manufacturable design.
```
```
Timing Closure & PPA 20%
```
```
Final STA reports are clean; final PPA metrics are well-
documented.
```
```
Submission Package 20% Complete GDSII, netlist, constraints, and final
comprehensive report.
Presentation & Clarity 10% Clear repository organization and project story.
```
## 4. Useful links

- AI-HDL website link: https://csm.arizona.edu/AIHDL
- AI-HDL Github link: https://github.com/prismlabarizona/AIHDL- 2026
- Design phase 4 example: https://youtu.be/wDXgCwzYYIc
- Design phase 3 example: https://youtu.be/bSISaX4ymXg
- Design phase 2 example: https://www.youtube.com/watch?v=fUBtewf05rE
- Design phase 1 example: https://www.youtube.com/watch?v=M20AJiT_ETE&t=33s
- Webinar 3 – Base design Implementation:
    https://www.youtube.com/watch?v=rOaLiDxNm
- RISC-V code repo: https://github.com/TinyTapeout/ttsky25a-tinyQV
- Peripheral template repo: https://github.com/prismlabarizona/AIHDL-
    2026/tree/master/tinyqv-full-peripheral-template
- Yosys Installation method:
    https://www.youtube.com/watch?v=XRexMO1B6s8&pp=2AYE
- OpenLane Installation method:
    https://www.youtube.com/watch?v=tFaTHGgpslA&pp=2AYB

**Important Date:** Milestone Review 4 (MR# 4 ) is scheduled for **April 23 , 2026.** Ensure your mentor
check-ins are completed weekly to receive advisory feedback.


