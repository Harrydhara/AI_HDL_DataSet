# Lessons Learned

# Key Insights from DP1 Phase

The initial phase of the **Acona-Tech** project has provided critical insights into the intersection of traditional hardware design and AI-assisted development. Below are the key takeaways regarding architecture, tools, and methodology.

## **1. Architectural Integration & RISC-V**

Integrating a custom functional module like the AES-128 accelerator with a **RISC-V core** highlighted the complexities of System-on-Chip (SoC) design:

* **Main Unit-Peripheral Integration:** We learned that defining rigid handshake protocols (like valid/ready signals) is essential for stable communication between the RISC-V core and its **peripherals**.
* **Connection Management:** Managing the data bus and address decoding logic for memory-mapped peripherals requires meticulous planning to avoid signal contention.

## **2. Modular Design & Hierarchy**

Breaking the design into smaller, standalone **modules** proved to be the most effective way to manage complexity:

* **Sub-module Decomposition:** Decoupling the AES rounds into individual stages (SubBytes, ShiftRows, etc.) allowed for isolated testing and easier bug localization.
* **Code Reusability:** Designing modules with parameterization in SystemVerilog simplified the integration process across different parts of the **RTL**.

## **3. Toolchain & Environment Efficiency**

Working within the **WSL Ubuntu** environment emphasized the importance of automation:

* **Bash Scripting:** Mastery of **Bash** was crucial for creating automated test scripts that trigger **Icarus Verilog** simulations and **Yosys** synthesis pipelines with a single command.
* **Unified Workflow:** Establishing a consistent directory structure for `rtl/`, `tb/`, and `scripts/` significantly reduced environment-related errors.

## **4. Strategic Prompt Engineering**

Our "AI-first" approach revealed that the quality of hardware output is directly proportional to the specificity of the prompt:

* **Modular Decomposition:** We found that AI tools perform best when asked to design a single, specific sub-module rather than a whole system at once.
* **AI-Assisted Debugging:** Utilizing **Claude 4.5** for **code debugging** proved highly effective for spotting syntax errors in SystemVerilog or identifying uninitialized registers that caused simulation mismatches.

### 5. AI as Collaborative Tool, Not Oracle

Lesson: AI assistance is most effective when used strategically, not blindly.

What Worked:
- AI explaining error messages led to fast debugging
- AI generating Makefile templates saved time
- AI suggesting gitignore strategies created clean repo

What Required Caution:
- AI-generated RTL code must be verified for synthesizability
- AI interpreting competition rules requires checking official docs
- AI suggesting optimizations need verification with synthesis tools

Takeaway: Use AI for scaffolding and exploration. Use human judgment for critical decisions.

### 6. Version Control Discipline Matters

Lesson: Clean Git history is documentation for your future self and judges.

Good Practices Discovered:
1. Atomic commits - One logical change per commit
2. Descriptive messages - Better commit messages show professional work
3. Selective tracking - Not everything belongs in Git
4. Tags for milestones - Mark important states clearly

Takeaway: Your Git log tells a story. Make it readable.

### 7. Documentation is Code's Best Friend

Lesson: If it is not documented, it does not exist for others and your future self.

Applied Principles:
- README first - Write how to use it before building it
- Inline comments - Explain why, not what
- Decision logs - Record trade-offs made

Takeaway: Code whispers. Documentation shouts.

### What We Learned About Learning

1. Ask Why Not Just How - Understanding why tools work matters more than memorizing syntax
2. Fail Fast, Fail Forward - Early smoke test failure leads to quick fix. Late integration failure creates project risk.
3. Communicate Clearly - Document decisions for judges and future team members

## Looking Ahead: Applying Lessons to Next Phases

For Design Phase:
- Apply modular architecture principles
- Document design decisions in real-time
- Test each module incrementally

For Implementation:
- Use Git branches for experimental features
- Maintain synthesis baseline after each major change
- Keep testbench coverage growing with RTL

For Optimization:
- Baseline performance before optimizing
- Track metrics (area, timing) in reports
- Document trade-offs made

## Closing Thought

We planted our infrastructure tree in DP1. Now we watch it grow.

Document Status: DP1 reflection
Last Updated: January 2026
