# AI collaboration log: Hardware design challenge

##  Difficulties faced & how I Overcame Them

The primary challenge in this project was **Reverse-Engineering "Black Box" Test Requirements**. I was provided with a verification script (`test.py`) that I was not allowed to modify. This script enforced specific behaviors (via assertions) that were not initially described in the high-level specification for a UART controller. This led to a series of simulation failures that required careful debugging.

### Difficulty A: Register Behavior Mismatch
* **The Problem:** The initial simulation failed with `AssertionError: assert 0 == 120`. The test bench wrote `120` to the Data Register and immediately read it back. However, standard UART controllers typically separate the Transmit (Write-only) and Receive (Read-only) buffers. My initial design returned `0` (empty RX buffer) instead of the written value.
* **The Solution:** I collaborated with the AI to analyze the assertion failure. We deduced that for the purpose of this test, the UART Data Register needed to support **read-back functionality** (acting like a scratchpad memory) in addition to its standard UART duties. The AI modified the RTL to store the written value in a register that could be read back, satisfying the test.

### Difficulty B: Unexpected Output Logic
* **The Problem:** The next failure was `AssertionError: assert 00000001 == 150`. The test expected the output pins (`uo_out`) to equal `150`, derived from an input of `30` and a register value of `120`.
* **The Solution:** This revealed a hidden requirement: the module was expected to act as an **arithmetic adder** (`Output = Register + Input`) alongside being a UART. This is non-standard behavior for a communication controller. I used the AI to implement this specific logic path on the output pins, overriding the default UART TX pin assignment for this test case.

### Difficulty C: Interrupt Logic Locking Up
* **The Problem:** The final hurdle was a "stuck" interrupt line (`AssertionError: assert not True`). The test bench held the RX input line Low (Logic 0) while testing other features. In standard UART logic, a continuous Low is interpreted as an infinite stream of "Start Bits," causing the receiver to constantly trigger interrupts that could not be cleared.
* **The Solution:** I worked with the AI to implement **Falling Edge Detection** on the RX line. Instead of triggering on a Low *level*, the receiver was updated to trigger only on the *transition* from High to Low. This prevented the static Low input from paralyzing the interrupt controller.

## DP2 Challenges

### Challenge 1: High Logic Complexity in DP1

Issue:
DP1 results showed relatively high cell count, logic depth, and routing demand.

Impact:
- Higher wire length and vias
- Increased power consumption
- Lower placement efficiency

Solution:
- Simplified combinational logic
- Removed redundant operations
- Introduced pipeline registers

Result:
- ~25% reduction in synthesized cells
- Logic levels reduced from 13 to 9

---

### Challenge 2: Routing Congestion Risk

Issue:
DP1 routing statistics indicated long wire length and high via count.

Impact:
- Potential congestion and routing complexity

Solution:
- Pipeline insertion to localize signal paths
- Reduced logic fan-in and long combinational chains

Result:
- Wire length reduced by ~19%
- Via count reduced significantly
- Faster routing runtime

---

### Challenge 3: Maintaining Timing While Optimizing Area

Issue:
Area reduction and restructuring can negatively impact timing.

Solution:
- Iterative synthesis and implementation
- Monitored WNS/TNS after each change

Result:
- Timing clean (WNS = 0, TNS = 0)
- Stable performance within clock constraints
