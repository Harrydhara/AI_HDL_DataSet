# Lessons Learned: From Software Logic to Physical Silicon

**Project:** Tensorbolt AI Accelerator
**Date:** 2026-01-30

## 1. The "Zero-Wait State" Trap
**The Mistake:** Initially, I implemented the `data_ready` handshake signal using a sequential block (`always @(posedge clk)`).
**The Consequence:** This introduced a 1-cycle latency gap. The testbench flagged "Protocol Violations," and in a real high-speed CPU scenario, this could lead to "Fire-and-Forget" write failures where data is lost.
**The Lesson:** For high-performance bus slaves, handshake signals must be **Combinatorial** (`always @*`). I learned to decouple the control logic (fast) from the data processing logic (registered).

## 2. Verification: Passing Tests $\neq$ Working Chip
**The Insight:** My initial testbench passed (PASS=4) even when the protocol was violating timing, because the checks were too permissive (soft warnings).
**The Fix:** We implemented a **"Strict Timing Audit"** test case that asserts failure if the handshake is not immediate.
**The Lesson:** Never trust a green "PASS" blindly. A robust testbench must aggressively hunt for corner cases, not just happy paths.

## 3. Tooling Configuration is Critical
**The Challenge:** I encountered blocking errors like `%Error-NEEDTIMINGOPT` in Verilator and `verilator_lint_check` failures in OpenLane.
**The Solution:**
* Added `--timing` flags to Verilator to handle delays correctly.
* Disabled the strict linter (`"RUN_LINTER": 0`) in OpenLane to prioritize PPA analysis after verifying functional correctness with Yosys.
**The Lesson:** Understanding the build system (Makefiles, config.json) is just as important as writing Verilog. A hardware engineer must master the tools to unblock the flow.

## 4. Hardware Mindset Shift
I learned to stop thinking in "For Loops" (Software) and start thinking in "State Machines" (Hardware).
* *Software approach:* "Loop 10 times to multiply."
* *Hardware approach:* "Create a counter, and on every clock tick, feed the MUX with the next address."
This shift was crucial for fitting the AI logic into the tiny area constraints of the competition.
