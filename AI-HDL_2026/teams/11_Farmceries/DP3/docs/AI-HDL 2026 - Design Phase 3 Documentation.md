# AI-HDL 2026: Design Phase 3 Documentation

**Phase Title:** Security Evaluation and Threat Mitigation
**Duration:** March 12 – March 26, 2026
**Objective:** To take your Optimized DP# 2 design and make it secure. Focus on Security Assessment,
Countermeasure Implementation, and Validation.

## 1. Weekly Milestone Journey

```
This phase is structured as a 2-week sprint to ensure a stable foundation for the following
optimization phases.
Week 1 (Mar 12-18): Security Assessment & Implementing Security Features
```
- Create a "Security Review Document" using current Threat models like CIA, STRIDE,
    and DREAD.
       ▪ **The CIA Triad:** The goal is to ensure data remains secret (Confidentiality), is
          never altered by a hacker (Integrity), and the hardware is always ready to work
          when needed (Availability).
       ▪ **STRIDE:** This is a checklist used to imagine how a hacker might attack us, from
          "Spoofing" a user's identity to "Elevating" their privileges to gain total control
          over the chip.
       ▪ **DREAD:** This is a scoring system (1–10) that helps us decide which security
          bugs are the most dangerous and need to be fixed immediately versus those
          that are low risk.
- Use LLMs to identify threats and vulnerabilities in your codebase.
- List potential **Common Weakness Enumerations** (common hardware bugs like
    buffer overflows or insecure debug ports) relevant to your DP2 design.
- Develop a "Mitigation Plan" for every hole you found, decide on a "fix" (e.g., adding
    encryption, locking a port, or masking signals).
- Use LLMs to counter identified threats and vulnerabilities.
**Week 2 (Mar 19-25): Validation, Hardening & Documentation**
- Implement at least one major security countermeasure. (e.g., Add privilege-level
checks, data input authentication, or logic to randomize power consumption).
- The "Proof of Security" Test: How do you know it works? Try to "break" your own
design. If you added a lock, show that a "hacker" input now gets blocked.
- Run your original tests to make sure the new security features didn't break normal
functionality or the original purpose of the chip.
- Analyze the PPA impact. How much did your security feature "cost" in area or timing?


- Write your final DP3 Security Report and tag your secure RTL for submission.

## 2. Deliverables & Submission Guidelines

```
Teams must submit their work via a private GitHub repository, granting access to assigned
mentors and judges.
Required for DP 3 Submission:
● Secure RTL: Your modified, hardened, and functionally correct Verilog code.
● Security Evaluation Report:
❑ Your vulnerability assessment from Week 1.
❑ A detailed explanation of the countermeasures you implemented.
❑ Validation results (how you proved the fix works).
❑ PPA overhead analysis (the "cost" of your security feature).
● GitHub Tag: A final commit tagged as "DP3-Submission".
```
## 3. Grading & Advancement Criteria

```
DP 3 accounts for 25% of the total cumulative score.
Category Weight Criteria
Security Feature
Implementation 30%^ Meaningful, well-implemented countermeasures.^
Validation & Hardening 25% Comprehensive security testing; prove the fix works.
Security Assessment 20% Thorough vulnerability review; well-structured plan.
```
```
Documentation & Reporting 15% Clear DP3 report; detailed explanation of
mitigations & trade-offs.
```
```
Design Stability 10%
```
```
Functional correctness is preserved; all regression
tests are clean.
```
## 4. Useful links

- AI-HDL website link: https://csm.arizona.edu/AIHDL
- AI-HDL Github link: https://github.com/prismlabarizona/AIHDL- 2026
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

**Important Date:** Milestone Review 3 (MR# 3 ) is scheduled for **March 26, 2026.** Ensure your mentor
check-ins are completed weekly to receive advisory feedback.


