User: Alright so, some more context:

The RISC-V core was one from https://github.com/TinyTapeout/ttsky25a-tinyQV

And the peripheral.v and tt_wrapper were from the https://github.com/TinyTapeout/tinyqv-full-peripheral-template

So I think instead of adding the peripheral to the ttsky25a shuttle of tinyQV, the AI HDL organizers, just needs us to work with the core only so we build on that (and they review onwards for the DPs)

And then the template's peripheral.v and tt_wrapper were the ones used in the #file:AI-HDL Design Phase 1 (DP#1) - Detailed Project Run & Technical Walkthrough.md example origanzed by AI HDL. So maybe I guess they are all just an example for now, but then you can inspect the specific files to see what they actually contain here. You can also read the README.md content of the peripheral template to see how TinyTapeout actually intends for peripherals to be added to the tinyQV instance here. However, like I said before, AI HDL seems to not really follow the process of adding the peripheral to tinyQV here, for example, in the DP 1 Detailed Project Run, they actually moved all of the source files into one directory (like no subdirectories like we organized into cpu/src, cpu/test cpu/verify peripheral/**/* - all files in one place and then they went on to simulate, synthesize and do PPA analysis with OpenROAD)

Also, I'm also confused about what src/test_harness is for in the peripheral source. How is this different from the peripheral/test directory contents? Are we going to be working with both as well? What are their differences?

Finally, I really do not know what the tt_wrapper does here

---

My team has decided to go for the UART (rated "Medium" in the DP 1 Documentation #file:AI-HDL 2026 - Design Phase 1 Documentation.md) as the peripheral we'd be adding to the core. I personally opted for a Complex peripheral from the start lol (the AES Encryption Engine rated "Complex") esp since complexity moeans more marks as documented in Webinar 2 but however we've conlcuded tos tart simple with the UART

GitHub Copilot: 

User: Alright so, some more context:

The RISC-V core was one from https://github.com/TinyTapeout/ttsky25a-tinyQV

And the peripheral.v and tt_wrapper were from the https://github.com/TinyTapeout/tinyqv-full-peripheral-template

So I think instead of adding the peripheral to the ttsky25a shuttle of tinyQV, the AI HDL organizers, just needs us to work with the core only so we build on that (and they review onwards for the DPs)

And then the template's peripheral.v and tt_wrapper were the ones used in the #file:AI-HDL Design Phase 1 (DP#1) - Detailed Project Run & Technical Walkthrough.md example origanzed by AI HDL. So maybe I guess they are all just an example for now, but then you can inspect the specific files to see what they actually contain here. You can also read the README.md content of the peripheral template to see how TinyTapeout actually intends for peripherals to be added to the tinyQV instance here. However, like I said before, AI HDL seems to not really follow the process of adding the peripheral to tinyQV here, for example, in the DP 1 Detailed Project Run, they actually moved all of the source files into one directory (like no subdirectories like we organized into cpu/src, cpu/test cpu/verify peripheral/**/* - all files in one place and then they went on to simulate, synthesize and do PPA analysis with OpenROAD)

Also, I'm also confused about what src/test_harness is for in the peripheral source. How is this different from the peripheral/test directory contents? Are we going to be working with both as well? What are their differences?

Finally, I really do not know what the tt_wrapper does here

---

My team has decided to go for the UART (rated "Medium" in the DP 1 Documentation #file:AI-HDL 2026 - Design Phase 1 Documentation.md) as the peripheral we'd be adding to the core. I personally opted for a Complex peripheral from the start lol (the AES Encryption Engine rated "Complex") esp since complexity moeans more marks as documented in Webinar 2 but however we've conlcuded tos tart simple with the UART #file:AI-HDL Design Phase 1 (DP#1) - Detailed Project Run & Technical Walkthrough.md  #file:AI-HDL 2026 - Design Phase 1 Documentation.md 

GitHub Copilot: Optimizing tool selection...Great questions! Let me help clarify the structure and workflow. First, let me read the key files to give you accurate explanations: 

Read [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/tinyqv-full-peripheral-template/README.md#1-1), lines 1 to 150

Read [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/src/peripheral.v)

Read [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/src/tt_wrapper.v)

Read [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/src/test_harness)

User: @agent Try Again

GitHub Copilot: Perfect! Now I can answer all your questions clearly:

## **Understanding the Architecture**

### **1. tt_wrapper.v - The Bridge**

The `tt_wrapper` is a **test harness** that allows you to test your peripheral **independently** before integrating it with the full TinyQV CPU. Here's what it does:

- **Creates an SPI interface** to communicate with your peripheral (via `spi_reg.sv`)
- **Simulates the CPU's register interface** (address, data_in, data_out, data_write_n, data_read_n)
- **Connects to TinyTapeout pins** for standalone testing

**Key insight:** In the AI-HDL workflow, `tt_wrapper` becomes your **top module** for synthesis, not the full CPU core.

### **2. test_harness/ vs peripheral/test**

**src/test_harness/** (SystemVerilog modules):
- Helper modules for the `tt_wrapper` test harness
- `spi_reg.sv` - SPI to register interface converter
- `synchronizer.sv` - Clock domain crossing
- `falling_edge_detector.sv`, `rising_edge_detector.sv` - Utility modules
- These are **part of the wrapper**, not your design

**peripheral/test/** (Python testbenches):
- Python scripts using Cocotb/Verilator to **simulate and verify** your peripheral
- `test.py` - Main test that drives SPI transactions to test your peripheral
- `tqv.py` - Helper class to simplify register read/write operations
- These **run simulations** to verify functionality

### **3. AI-HDL Workflow vs TinyTapeout Workflow**

**TinyTapeout's intended workflow:**
1. Create peripheral.v
2. Submit PR to ttsky25a-tinyQV repo
3. Peripheral gets integrated into the full CPU's `peripherals.v`
4. TinyTapeout builds everything together

**AI-HDL's simplified workflow** (from the walkthrough):

## **Quick Action Plan for UART Implementation**

Since you're doing UART, here's what you need:

**UART Peripheral Requirements:**
- **Register Map** (typically):
  - Address 0x00: TX Data Register (write to transmit)
  - Address 0x04: RX Data Register (read to receive)
  - Address 0x08: Status Register (TX ready, RX ready, etc.)
  - Address 0x0C: Control Register (baud rate divisor, enable, etc.)
  
- **Connections:**
  - `ui_in[7]` → UART RX (as noted in template)
  - `uo_out[0]` → UART TX (as noted in template)

- **Interrupt:**
  - Use `user_interrupt` to signal RX data ready

Would you like me to:
1. **Generate a UART peripheral module** using the template structure?
2. **Set up the flat directory structure** for synthesis/PPA like the walkthrough?
3. **Create a basic testbench** for the UART?

Let me know which direction you want to start with!

User: 1. So asides peripheral.v, do I have to modify anyting in the tt_wrapper and test_harness/? And do I have to write my own tests as well for my UART simulations in the test/ directory? What does a "test harness" even mena

2. Do we really have to go flat directory like they did in the example? I just feel the code is better organized the way we've done it or we're not allowed to do that?

3. But what exactly does the peripheral that was simulated+synthesized+analyzed in the DP 1 example contain? I though it was just an exmple from the tinyqv template?


Using "Replace String in File"

Let me read the current state of the file: 

Read [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/src/aes/uart_aes_peripheral.v)

I see the issue - the existing UART peripheral doesn't expose the internal byte streams I need. Rather than modifying the existing working UART, let me create a standalone integrated peripheral from scratch that combines everything properly. This will be cleaner: 

Created [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/src/aes/secure_uart_peripheral.v)

Now create a comprehensive test for this fully integrated module: 

Created [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/test/test_secure_uart.py)

Created [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/test/test_secure_uart.mk)

Now let's test it: 

Ran terminal command: cd /home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/test && timeout 180 make -f test_secure_uart.mk 2>&1 | tee /tmp/secure_uart_test.log && tail -60 /tmp/secure_uart_test.log

Summarized conversation historyGood progress! 4/5 tests passing. One failure in key configuration test - KEY1 readback is returning 0 instead of the written value. Let me check the register interface: Optimizing tool selection...

Read [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/src/aes/secure_uart_peripheral.v#220-220), lines 220 to 260

Read [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/src/aes/secure_uart_peripheral.v#260-260), lines 260 to 290

The register read logic looks correct. The issue might be a timing problem in the test. Let me check the test: 

Read [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/test/test_secure_uart.py#80-80), lines 80 to 110

I see - the address field is 6-bit but we're using values that might overflow. Let me check the address mapping: 

Read [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/src/aes/secure_uart_peripheral.v#1-1), lines 1 to 50

The addresses look correct (0x28, 0x2C, 0x30, 0x34 all fit in 6 bits). But wait - the test is using `0x28 + i` which gives 0x28, 0x29, 0x2A, 0x2B but should be 0x28, 0x2C, 0x30, 0x34! That's the bug - incrementing by 1 instead of 4: 

Using "Replace String in File"


```

```
Now let's test again: 

Ran terminal command: cd /home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/test && timeout 180 make -f test_secure_uart.mk 2>&1 | grep -A 30 "TESTS="

Perfect! **5/5 tests PASS** ✅

Now let's update the todo list and continue with documentation: 

Starting: *Address key management limitations* (4/5)

Let me create a documentation file for the secure UART peripheral: 

Created [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/docs/SECURE_UART_PERIPHERAL.md)

Now let's update the AES integration summary to reflect the complete picture: Let me create it: 

Created [](file:///home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/docs/AES_INTEGRATION_SUMMARY.md)

Perfect! Now let's update the todo list and create a final summary: 

Completed: *Address key management limitations* (4/5)

Let me run a final comprehensive test to ensure everything still works: 

Ran terminal command: cd /home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/test && echo "=== Testing AES-UART Component (aes_uart_controller) ===" && timeout 180 make -f test_aes_uart_integration.mk 2>&1 | grep -E "(PASS|FAIL|TESTS=)" | tail -20

Checked background terminal output

Ran terminal command: cd /home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/test && timeout 180 make -f test_aes_uart_integration.mk 2>&1 | tail -40

The issue is that the previous test left the simulator set to `secure_uart_peripheral`. Let me clean and rerun: 

Ran terminal command: cd /home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/dp-1/peripheral/test && make -f test_aes_uart_integration.mk clean && timeout 180 make -f test_aes_uart_integration.mk 2>&1 | grep -A 5 "TESTS="

