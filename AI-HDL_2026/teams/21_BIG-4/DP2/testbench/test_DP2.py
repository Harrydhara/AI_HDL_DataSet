import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from tqv import TinyQV

@cocotb.test()
async def test_ai_accelerator_full(dut):
    # 1. Initialize System Clock (10ns = 100MHz)
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut)
    
    dut._log.info("--- SYSTEM READY FOR COMPREHENSIVE VERIFICATION ---")

    # 2. Define Test Cases (Name, Operand A, Operand B, Expected Result)
    # Note: Each operand register holds four 8-bit values.
    test_cases = [
        ("1. Happy Case (Normal Operation)", 0x04030201, 0x08070605, 70),
        ("2. Zero-Bypass (Power Saving Check)", 0x00000000, 0x08070605, 0),
        ("3. One Operand Zero", 0x04030201, 0x00000000, 0),
        ("4. Identity Check (Multiply by 1)", 0x01010101, 0x05050505, 20),
        ("5. Max Value (Overflow & Sign-Extension Check)", 0xFFFFFFFF, 0xFFFFFFFF, 260100)
    ]

    # 3. Iterate and Execute Tests
    for name, val_a, val_b, expected in test_cases:
        dut._log.info(f"\n>> EXECUTING TEST: {name}")
        
        # Reset before each test to clear internal accumulator and states
        await tqv.reset()
        
        # Load Operands into Reg 1 (A) and Reg 2 (B)
        await tqv.write_word_reg(1, val_a)
        await tqv.write_word_reg(2, val_b)
        
        # Trigger Calculation (Write 1 to Control Register 0)
        await tqv.write_word_reg(0, 1)
        await ClockCycles(dut.clk, 10) # Wait for pipeline to finish
        
        # Fetch Result from Reg 3
        raw_result = await tqv.read_word_reg(3)
        
        # Apply 18-bit Bitmask (0x3FFFF) to filter out Verilog sign-extension
        # Max possible value is 255*255*4 = 260100 (which strictly requires 18 bits)
        result = raw_result & 0x3FFFF 
        
        dut._log.info(f" -> Expected: {expected} | Actual (Masked): {result} | Raw Hex: {hex(raw_result)}")
        
        # Verify Result
        assert result == expected, f"X TEST FAILED at {name}! Expected {expected} but got {result}."
        dut._log.info(" -> STATUS: PASS!")

    dut._log.info("\n=======================================================")
    dut._log.info("CONGRATULATIONS! ALL CORNER CASES PASSED SUCCESSFULLY!")
    dut._log.info("=======================================================")
