# Project Retrospective: Management Challenges & Lessons Learned
While Team BIG-4 successfully delivered a verified, low-area RTL design (~770 cells), the development process for DP1 was characterized by several internal project management hurdles. We believe that documenting these challenges is vital for demonstrating our growth as a professional engineering unit.

**1. Strategic Ambiguity & Time Inefficiency:**
- Our initial phase suffered from a lack of granular planning. While we had a high-level goal of building an AI accelerator as a TinyQV peripheral, we did not establish a strict, step-by-step roadmap from the outset.

- This ambiguity led to exploratory "trial-and-error" periods that consumed valuable development time.

- Without clearly defined milestones, the team spent significant effort on reactive problem-solving rather than proactive execution, resulting in a less-than-optimal use of our collective hours.

**2. Friction in Task Allocation:**
- Dividing the workload among the Lead Hardware Architect, Logic Engineer, and Verification Lead proved more complex than anticipated.

- We encountered "bottleneck" moments where ownership of specific interface handshakes was ill-defined.

- The intersection between RTL implementation and testbench development was a particular point of friction.

- Because the boundaries of responsibility were not rigorously set on Day 1, we experienced overlapping efforts and occasional delays in the handoff of critical design files.

**3. Information Asymmetry & Communication Gaps:**
- Maintaining a continuous "shared mental model" across the team was our most significant challenge.

- Individual members often worked in "silos," focusing deeply on their specific assignments (e.g., PPA optimization vs. Cocotb testbench logic). This led to inter-personal disconnects, where a member would exchange tasks or code without fully grasping the updated constraints or context of the other person's work.

- The lack of a centralized "source of truth" for design decisions meant that subtle protocol changes—such as the shift to a combinatorial data_ready signal—were not immediately understood by all stakeholders, requiring redundant explanations and rework.

**MOVING FORWARD:**

Recognizing these inefficiencies has allowed us to refine our workflow for the next phase. We have learned that in hardware design, communication bandwidth is just as important as bus bandwidth. For future iterations, we will prioritize daily synchronization and a centralized documentation log to ensure that "who is doing what" is transparent to the entire team at all times.