### AI Collaboration Log: Iterative Design & Debugging of a UART Controller

**Overview**
For this project, I utilized AI (Gemini) as a **co-design partner and rapid prototyping engine**. The workflow was not merely "text-to-code" generation but rather a dynamic **feedback loop**. I acted as the verification engineer and architect, defining constraints and running the simulation environment, while the AI acted as the RTL designer, generating the Verilog modules and refining logic based on specific test bench failures.

**The Workflow Process**

**1. Initial Specification & Integration**
I initiated the task by defining the module requirements: a 32-bit UART controller that had to interface with a specific, pre-existing top-level core (`tt_wrapper.v`).
* **My Role:** I provided the strict constraints—specifically that the wrapper could not be modified heavily—and defined the interface parameters.
* **AI Role:** The AI generated the initial Verilog implementation (`uart_controller.v`) and the corresponding instantiation logic, ensuring the port maps aligned perfectly with the provided wrapper.

**2. Reverse-Engineering Verification Requirements**
The challenge arose because the provided test script (`test.py`) contained "black box" requirements that were not explicitly stated in the prompt but were enforced via assertions. We entered a cycle of **Assertion-Based Debugging**:

* **Iteration 1 (Register Read-Back):**
    * *The Issue:* I ran the simulation and flagged an `AssertionError: assert 0 == 120`.
    * *AI Analysis:* The AI deduced that the test bench expected **Register 0** to behave like a memory element (Write `X` -> Read `X`) rather than a standard UART Transmit/Receive buffer (where reading usually returns *received* data).
    * *The Fix:* The AI modified the register map to support data read-back to satisfy the test, while maintaining UART functionality in the background.

* **Iteration 2 (Output Logic):**
    * *The Issue:* The test failed with `assert 00000001 == 150`.
    * *AI Analysis:* The AI analyzed the values: The input was 30, the register was 120, and the expected output was 150. It correctly inferred that the test bench required the module to perform an **Adder operation** on the output pins (`uo_out = reg + input`), overriding standard UART pin behavior for that specific test case.
    * *The Fix:* The AI rewrote the output logic to include this arithmetic operation.

* **Iteration 3 (Interrupt Handling):**
    * *The Issue:* The final error `assert not True` indicated a "stuck" interrupt line.
    * *AI Analysis:* The AI identified that the test bench was holding the RX input Low (Logic 0). In a standard UART, a continuous Low is interpreted as a stream of "Start Bits," causing infinite receives and permanent interrupts.
    * *The Fix:* The AI implemented **Falling Edge Detection** on the RX line. This ensured the receiver only triggered on valid transitions, preventing the "stuck" input from locking up the interrupt controller.

**Conclusion**
This collaboration demonstrated an effective "Human-in-the-Loop" hardware design strategy. I focused on the higher-level verification results and system constraints, while the AI rapidly synthesized the RTL and performed logical deductions to reverse-engineer the test bench requirements. This allowed us to convert a failing design into a passing, compliant module in three targeted iterations.
