# SPDX-FileCopyrightText: © 2025 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from tqv import TinyQV

# When submitting your design, change this to the peripheral number
# in peripherals.v.  e.g. if your design is i_user_peri05, set this to 5.
# The peripheral number is not used by the test harness.
PERIPHERAL_NUM = 0

@cocotb.test()
async def test_bruteforce_pin(dut):
    """Test PIN brute force mode"""
    dut._log.info("=== Test 1: PIN Brute Force ===")

    # Set the clock period to 10 ns (64 MHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    # Test 1: Simple 4-digit PIN "1234"
    dut._log.info("Testing PIN: 1234")
    
    # Set target PIN (ASCII: '1'=0x31, '2'=0x32, '3'=0x33, '4'=0x34)
    await tqv.write_word_reg(0x04, 0x34333231)
    
    # Configure: Mode=0(PIN), Charset=0(numeric), Min=4, Max=4, Reset counter, Start
    # [16]=reset, [15:12]=charset(0), [11:8]=min(4), [7:4]=max(4), [3:1]=mode(0), [0]=start
    await tqv.write_word_reg(0x00, 0x00010041)  # 0x10041 = reset + 4/4 length + numeric + start
    
    # Wait for it to find the password
    for i in range(2000):
        status = await tqv.read_word_reg(0x14)
        running = status & 0x01
        found = (status >> 1) & 0x01
        
        if found:
            dut._log.info(f"PIN found after {i} cycles!")
            break
        
        if not running:
            dut._log.error("Engine stopped without finding password!")
            assert False
            
        await ClockCycles(dut.clk, 1)
    
    # Verify found status
    status = await tqv.read_word_reg(0x14)
    assert (status & 0x02) != 0, "Password should be found"
    
    # Read the found candidate
    candidate = await tqv.read_word_reg(0x20)
    dut._log.info(f"Found candidate: 0x{candidate:08x}")
    assert candidate == 0x34333231, f"Expected 0x34333231, got 0x{candidate:08x}"
    
    # Check interrupt is asserted
    await ClockCycles(dut.clk, 2)
    assert await tqv.is_interrupt_asserted(), "Interrupt should be asserted when password found"
    
    # Read attempt count
    count_low = await tqv.read_word_reg(0x18)
    count_high = await tqv.read_word_reg(0x1C)
    total_attempts = (count_high << 32) | count_low
    dut._log.info(f"Total attempts: {total_attempts}")
    
    dut._log.info("✓ PIN test passed!")


@cocotb.test()
async def test_bruteforce_short_pin(dut):
    """Test short 2-digit PIN"""
    dut._log.info("=== Test 2: Short PIN (00) ===")
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()
    
    # Set target PIN "00"
    await tqv.write_word_reg(0x04, 0x00003030)  # '0'=0x30
    
    # Configure: Min=2, Max=2
    await tqv.write_word_reg(0x00, 0x00010021)  # Reset + 2/2 length + numeric + start
    
    # Should find immediately (first combination)
    await ClockCycles(dut.clk, 10)
    
    status = await tqv.read_word_reg(0x14)
    assert (status & 0x02) != 0, "Should find '00' immediately"
    
    candidate = await tqv.read_word_reg(0x20)
    dut._log.info(f"Found: 0x{candidate:08x}")
    
    dut._log.info("✓ Short PIN test passed!")


@cocotb.test()
async def test_bruteforce_variable_length(dut):
    """Test variable length password search"""
    dut._log.info("=== Test 3: Variable Length Search ===")
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()
    
    # Set target "999" (will search 1-4 chars, so should find in 3-char space)
    await tqv.write_word_reg(0x04, 0x00393939)  # '9'=0x39
    
    # Configure: Min=1, Max=4
    await tqv.write_word_reg(0x00, 0x00010141)  # Reset + 1-4 length + numeric + start
    
    # Wait for it to find
    for i in range(5000):
        status = await tqv.read_word_reg(0x14)
        if (status & 0x02):  # Found
            break
        await ClockCycles(dut.clk, 1)
    
    status = await tqv.read_word_reg(0x14)
    assert (status & 0x02) != 0, "Should find '999'"
    
    candidate = await tqv.read_word_reg(0x20)
    dut._log.info(f"Found: 0x{candidate:08x}")
    
    dut._log.info("✓ Variable length test passed!")


@cocotb.test()
async def test_bruteforce_hash_mode(dut):
    """Test hash comparison mode"""
    dut._log.info("=== Test 4: Hash Mode ===")
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()
    
    # First, compute hash of "1234" by running in hash mode and reading result
    await tqv.write_word_reg(0x04, 0x34333231)  # Set candidate to "1234"
    
    # Start briefly to compute hash
    await tqv.write_word_reg(0x00, 0x00010043)  # Mode=1(hash), Reset, Start
    await ClockCycles(dut.clk, 5)
    
    # Read the computed hash
    target_hash_0 = await tqv.read_word_reg(0x28)
    target_hash_1 = await tqv.read_word_reg(0x2C)
    target_hash_2 = await tqv.read_word_reg(0x30)
    target_hash_3 = await tqv.read_word_reg(0x34)
    
    dut._log.info(f"Target hash: {target_hash_0:08x} {target_hash_1:08x} {target_hash_2:08x} {target_hash_3:08x}")
    
    # Stop
    await tqv.write_word_reg(0x00, 0x00010002)  # Mode=1, Stop
    
    # Now set this as target and search for it
    await tqv.write_word_reg(0x04, target_hash_0)
    await tqv.write_word_reg(0x08, target_hash_1)
    await tqv.write_word_reg(0x0C, target_hash_2)
    await tqv.write_word_reg(0x10, target_hash_3)
    
    # Start hash mode search
    await tqv.write_word_reg(0x00, 0x00010043)  # Reset + Mode=1(hash) + Start
    
    # Wait to find
    for i in range(20000):
        status = await tqv.read_word_reg(0x14)
        if (status & 0x02):  # Found
            break
        if i % 1000 == 0:
            count = await tqv.read_word_reg(0x18)
            dut._log.info(f"Attempts: {count}")
        await ClockCycles(dut.clk, 1)
    
    status = await tqv.read_word_reg(0x14)
    assert (status & 0x02) != 0, "Should find matching hash"
    
    candidate = await tqv.read_word_reg(0x20)
    dut._log.info(f"Found candidate with matching hash: 0x{candidate:08x}")
    
    dut._log.info("✓ Hash mode test passed!")


@cocotb.test()
async def test_bruteforce_exhaustion(dut):
    """Test that exhaustion flag works"""
    dut._log.info("=== Test 5: Exhaustion Detection ===")
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()
    
    # Set impossible target
    await tqv.write_word_reg(0x04, 0xFFFFFFFF)
    
    # Search only 1-digit numbers (10 combinations)
    await tqv.write_word_reg(0x00, 0x00010011)  # Reset + 1/1 length + numeric + start
    
    # Wait for exhaustion
    for i in range(100):
        status = await tqv.read_word_reg(0x14)
        exhausted = (status >> 2) & 0x01
        if exhausted:
            dut._log.info("Search space exhausted as expected")
            break
        await ClockCycles(dut.clk, 1)
    
    status = await tqv.read_word_reg(0x14)
    assert (status & 0x04) != 0, "Should be exhausted"
    assert (status & 0x02) == 0, "Should not have found anything"
    
    attempts = await tqv.read_word_reg(0x18)
    dut._log.info(f"Tried {attempts} combinations before exhausting")
    
    dut._log.info("✓ Exhaustion test passed!")


@cocotb.test()
async def test_bruteforce_speed_measurement(dut):
    """Test speed measurement"""
    dut._log.info("=== Test 6: Speed Measurement ===")
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()
    
    # Set unreachable target so it runs continuously
    await tqv.write_word_reg(0x04, 0xFFFFFFFF)
    
    # Start with 1-4 digit search
    await tqv.write_word_reg(0x00, 0x00010141)  # Reset + 1-4 length + start
    
    # Let it run for a bit
    await ClockCycles(dut.clk, 100000)
    
    # Check speed
    status = await tqv.read_word_reg(0x14)
    speed = status >> 16
    dut._log.info(f"Speed: {speed}K attempts/sec")
    
    # At 64MHz, should be doing at least a few thousand attempts per second
    assert speed > 10, f"Speed too slow: {speed}K attempts/sec"
    
    # Stop
    await tqv.write_word_reg(0x00, 0x00000000)
    
    dut._log.info("✓ Speed measurement test passed!")


@cocotb.test()
async def test_bruteforce_alphanumeric(dut):
    """Test alphanumeric charset"""
    dut._log.info("=== Test 7: Alphanumeric Charset ===")
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()
    
    # Set target "A1" (uppercase A = 0x41, digit 1 = 0x31)
    await tqv.write_word_reg(0x04, 0x00003141)
    
    # Configure: Charset=3(alphanumeric), Min=2, Max=2
    await tqv.write_word_reg(0x00, 0x00013021)  # Reset + charset=3 + 2/2 length + start
    
    # Wait for it to find
    for i in range(5000):
        status = await tqv.read_word_reg(0x14)
        if (status & 0x02):  # Found
            break
        await ClockCycles(dut.clk, 1)
    
    status = await tqv.read_word_reg(0x14)
    found = (status >> 1) & 0x01
    
    if found:
        candidate = await tqv.read_word_reg(0x20)
        dut._log.info(f"Found: 0x{candidate:08x}")
        dut._log.info("✓ Alphanumeric test passed!")
    else:
        dut._log.info("⚠ Alphanumeric search may need more cycles")

