# Design Methodology: AI-Assisted Hardware Design

**Project:** Tensorbolt AI Accelerator (TinyQV Peripheral)
**Competition:** AI-HDL Design Phase 1
**Author:** Member B (Team BIG-4)

## 1. Philosophy: AI as a Technical Partner
Unlike traditional workflows where AI is used merely to generate code, this project adopted an **"AI-First Engineering"** approach. The AI agent (Gemini Pro) was treated as a Senior Technical Mentor.
* **The "Why" before "How":** Every design phase started with an architectural debate (e.g., *Why use polling instead of stalling?*) before writing any Verilog.
* **Iterative Refinement:** We moved from a "Safe Skeleton" to a "Performance-Optimized" design through rigorous feedback loops.

## 2. Architectural Decisions
### 2.1. Time-Multiplexed SIMD Architecture
Given the strict **< 2000 standard cell** constraint of the TinyQV layout, a fully parallel matrix multiplication engine was impossible.
* **Decision:** We implemented a **"Streaming SIMD Dot-Product Unit"**.
* **Mechanism:** Instead of 16 physical multipliers, we use a single pipelined MAC (Multiply-Accumulate) unit. The FSM cycles through data over time (Time-Multiplexing), trading throughput (cycles) for area (cells).
* **Result:** The design fits comfortably (~980 cells) while maintaining sufficient performance for edge AI inference.

### 2.2. Polling-Based Bus Interface
To prevent system deadlocks where a peripheral hangs the main CPU:
* **Decision:** Adopted a **Non-Blocking Polling Model**.
* **Mechanism:** The CPU triggers a calculation and polls a Status Register (`0x00`) instead of being frozen by a hardware `WAIT` signal. This ensures the CPU remains responsive to interrupts even during long AI computations.

## 3. Toolchain & Verification Strategy
* **Synthesis:** Yosys (Generic & Sky130) was used early to monitor cell count usage, ensuring we never exceeded the budget.
* **Verification:** We used **Cocotb + Verilator** for Python-based verification.
* **Strict Auditing:** A dedicated "Strict Protocol Audit" testbench was developed to mathematically prove **0-wait state compliance**, ensuring the `data_ready` signal responds combinationally within the same clock cycle.
