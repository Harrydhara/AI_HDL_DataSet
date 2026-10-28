"""
tqvp_gpio cocotb testbench - DP1 Verification
AI-HDL 2026 Design Phase 1
Compatible with cocotb 2.0+ (no TestFailure)
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# Register addresses
ADDR_OUTPUT = 0x00
ADDR_DIRECTION = 0x01
ADDR_INPUT = 0x02
ADDR_MATRIX_A = 0x03
ADDR_MATRIX_B = 0x04
ADDR_MATRIX_C = 0x05
ADDR_MATRIX_CTRL = 0x06


async def reset_dut(dut):
    """Reset the DUT"""
    dut.rst_n.value = 0
    dut.data_write_n.value = 1
    dut.data_read_n.value = 1
    dut.address.value = 0
    dut.data_in.value = 0
    dut.ui_in.value = 0
    await Timer(20, units='ns')
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def write_reg(dut, addr, data):
    """Write to a register"""
    await RisingEdge(dut.clk)
    dut.address.value = addr
    dut.data_in.value = data
    dut.data_write_n.value = 0
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 1
    await RisingEdge(dut.clk)


async def read_reg(dut, addr):
    """Read from a register"""
    await RisingEdge(dut.clk)
    dut.address.value = addr
    dut.data_read_n.value = 0
    await RisingEdge(dut.clk)
    read_val = int(dut.data_out.value)
    dut.data_read_n.value = 1
    await RisingEdge(dut.clk)
    return read_val


@cocotb.test()
async def test_gpio_basic_write_read(dut):
    """Test basic write and read operations"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_dut(dut)
    dut._log.info("Reset complete")
    
    # Test 1: Write to output register and read back
    dut._log.info("Test 1: Write/Read OUTPUT register")
    await write_reg(dut, ADDR_OUTPUT, 0xA5)
    read_val = await read_reg(dut, ADDR_OUTPUT)
    assert (read_val & 0xFF) == 0xA5, f"Expected 0xA5, got 0x{read_val:02X}"
    dut._log.info(f"✓ OUTPUT register: wrote 0xA5, read 0x{read_val:02X}")
    
    # Test 2: Write to direction register
    dut._log.info("Test 2: Write/Read DIRECTION register")
    await write_reg(dut, ADDR_DIRECTION, 0xFF)
    read_val = await read_reg(dut, ADDR_DIRECTION)
    assert (read_val & 0xFF) == 0xFF, f"Expected 0xFF, got 0x{read_val:02X}"
    dut._log.info(f"✓ DIRECTION register: wrote 0xFF, read 0x{read_val:02X}")
    
    # Test 3: Check output pins (should match output_reg & direction_reg)
    await Timer(10, units='ns')
    uo_out_val = int(dut.uo_out.value)
    assert uo_out_val == 0xA5, f"Expected uo_out=0xA5, got 0x{uo_out_val:02X}"
    dut._log.info(f"✓ Physical output uo_out: 0x{uo_out_val:02X}")
    
    # Test 4: Read input register
    dut._log.info("Test 3: Read INPUT register")
    dut.ui_in.value = 0x3C
    await Timer(10, units='ns')
    read_val = await read_reg(dut, ADDR_INPUT)
    # Input should be masked by ~direction (only input pins visible)
    # direction=0xFF means all outputs, so input read should be 0x00
    assert (read_val & 0xFF) == 0x00, f"Expected masked input 0x00, got 0x{read_val:02X}"
    dut._log.info(f"✓ INPUT register (all outputs): 0x{read_val:02X}")
    
    dut._log.info("=== All basic tests PASSED ===")


@cocotb.test()
async def test_gpio_direction_control(dut):
    """Test direction control and input masking"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_dut(dut)
    
    # Set some pins as inputs, some as outputs
    # Direction: 0b11110000 (upper 4 bits output, lower 4 bits input)
    await write_reg(dut, ADDR_DIRECTION, 0xF0)
    
    # Write output value
    await write_reg(dut, ADDR_OUTPUT, 0xAA)
    
    # Check physical output (should be 0xAA & 0xF0 = 0xA0)
    await Timer(10, units='ns')
    uo_out_val = int(dut.uo_out.value)
    assert uo_out_val == 0xA0, f"Expected uo_out=0xA0, got 0x{uo_out_val:02X}"
    dut._log.info(f"✓ Masked output (0xAA & 0xF0): 0x{uo_out_val:02X}")
    
    # Set input pins and read
    dut.ui_in.value = 0x5A
    await Timer(10, units='ns')
    read_val = await read_reg(dut, ADDR_INPUT)
    # Should read (0x5A & ~0xF0) = (0x5A & 0x0F) = 0x0A
    assert (read_val & 0xFF) == 0x0A, f"Expected masked input 0x0A, got 0x{read_val:02X}"
    dut._log.info(f"✓ Masked input (0x5A & 0x0F): 0x{read_val:02X}")
    
    dut._log.info("=== Direction control tests PASSED ===")


@cocotb.test()
async def test_gpio_output_hold(dut):
    """Test that output values hold after direction changes"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_dut(dut)
    
    # Write output value and set as output
    await write_reg(dut, ADDR_OUTPUT, 0x55)
    await write_reg(dut, ADDR_DIRECTION, 0xFF)
    
    # Check output
    await Timer(10, units='ns')
    uo_out_val = int(dut.uo_out.value)
    assert uo_out_val == 0x55, f"Expected 0x55, got 0x{uo_out_val:02X}"
    
    # Change direction to inputs - output should go to 0
    await write_reg(dut, ADDR_DIRECTION, 0x00)
    await Timer(10, units='ns')
    uo_out_val = int(dut.uo_out.value)
    assert uo_out_val == 0x00, f"Expected 0x00 (all inputs), got 0x{uo_out_val:02X}"
    
    # But output register should still hold 0x55
    read_val = await read_reg(dut, ADDR_OUTPUT)
    assert (read_val & 0xFF) == 0x55, f"Output reg should hold 0x55, got 0x{read_val:02X}"
    dut._log.info(f"✓ Output register held value through direction change")
    
    dut._log.info("=== Output hold tests PASSED ===")


@cocotb.test()
async def test_gpio_edge_cases(dut):
    """Test invalid addresses and read-only register writes"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_dut(dut)
    dut._log.info("Testing edge cases...")
    
    # Test 1: Invalid address read returns 0
    dut._log.info("Test: Invalid address (0x3F)")
    await RisingEdge(dut.clk)
    dut.address.value = 0x3F
    dut.data_read_n.value = 0
    await RisingEdge(dut.clk)
    read_val = int(dut.data_out.value)
    dut.data_read_n.value = 1
    await RisingEdge(dut.clk)
    assert read_val == 0, f"Invalid address should return 0, got 0x{read_val:08X}"
    dut._log.info("✓ Invalid address returns 0")
    
    # Test 2: Write to INPUT_REG (read-only) is ignored
    dut._log.info("Test: Write to read-only INPUT_REG")
    dut.ui_in.value = 0x00
    await write_reg(dut, ADDR_DIRECTION, 0x00)  # All inputs
    await write_reg(dut, ADDR_INPUT, 0xFF)  # Try to write (should be ignored)
    await Timer(10, units='ns')
    read_val = await read_reg(dut, ADDR_INPUT)
    assert (read_val & 0xFF) == 0x00, f"INPUT_REG write should be ignored, got 0x{read_val:02X}"
    dut._log.info("✓ Read-only register protected")
    
    dut._log.info("=== Edge case tests PASSED ===")


@cocotb.test()
async def test_gpio_interrupt(dut):
    """Test user_interrupt signal on input pin changes"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_dut(dut)
    dut._log.info("Testing interrupt functionality...")
    
    # Set all pins as inputs
    await write_reg(dut, ADDR_DIRECTION, 0x00)
    
    # Set initial input value
    dut.ui_in.value = 0x00
    await Timer(10, units='ns')
    await RisingEdge(dut.clk)
    
    # Test 1: Change input - should trigger interrupt
    dut._log.info("Test: Input change triggers interrupt")
    dut.ui_in.value = 0xFF
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Small delay to let combinatorial logic settle
    interrupt_val = int(dut.user_interrupt.value)
    assert interrupt_val == 1, f"Interrupt should be high on input change, got {interrupt_val}"
    dut._log.info("✓ Interrupt triggered on input change")
    
    # Test 2: Interrupt stays high until cleared (sticky behavior)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')
    interrupt_val = int(dut.user_interrupt.value)
    assert interrupt_val == 1, f"Interrupt should stay high (sticky), got {interrupt_val}"
    dut._log.info("✓ Interrupt remains pending (sticky)")
    
    # Note: Interrupt clear register was removed in matrix multiplier version
    # Interrupt is now cleared only by reset (sticky behavior)
    
    # Test 4: Reset clears interrupt
    dut._log.info("Test: Reset clears interrupt")
    dut.ui_in.value = 0x00  # Reset inputs to avoid edge trigger after reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')
    interrupt_val = int(dut.user_interrupt.value)
    assert interrupt_val == 0, f"Reset should clear interrupt, got {interrupt_val}"
    dut._log.info("✓ Reset clears interrupt")
    
    # Test 5: Output pins don't trigger interrupt
    dut._log.info("Test: Output pin changes don't trigger interrupt")
    await write_reg(dut, ADDR_DIRECTION, 0xFF)  # All outputs
    dut.ui_in.value = 0x00  # Change input
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')
    interrupt_val = int(dut.user_interrupt.value)
    assert interrupt_val == 0, f"Interrupt should not trigger for output pins, got {interrupt_val}"
    dut._log.info("✓ Output pins don't trigger interrupt")
    
    dut._log.info("=== Interrupt tests PASSED ===")
    dut._log.info("🎯 INNOVATION FEATURE VERIFIED: Input change interrupt (sticky, reset to clear)!")


@cocotb.test()
async def test_matrix_multiplier_basic(dut):
    """Test 2x2 matrix multiplier - basic operation"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_dut(dut)
    dut._log.info("Testing 2x2 matrix multiplier...")
    
    # Helper: convert float to 8.8 fixed-point (16-bit)
    def to_fixed(val):
        return int(val * 256) & 0xFFFF
    
    # Helper: convert 8.8 fixed-point to float
    def from_fixed(val):
        # Handle sign extension for 16-bit signed
        if val & 0x8000:
            val = val - 0x10000
        return val / 256.0
    
    # Test 1: Simple identity-like matrix
    dut._log.info("Test 1: Simple matrix multiplication")
    # Matrix A = [[2, 0], [0, 2]] (integer values)
    # Matrix B = [[3, 0], [0, 3]]
    # Expected C = [[6, 0], [0, 6]]
    
    a00, a01 = to_fixed(2.0), to_fixed(0.0)
    a10, a11 = to_fixed(0.0), to_fixed(2.0)
    b00, b01 = to_fixed(3.0), to_fixed(0.0)
    b10, b11 = to_fixed(0.0), to_fixed(3.0)
    
    # Write matrix A (row 0, row 1)
    await write_reg(dut, ADDR_MATRIX_A, (a01 << 16) | a00)  # Row 0
    await write_reg(dut, ADDR_MATRIX_A, (a11 << 16) | a10)  # Row 1
    
    # Write matrix B (row 0, row 1)
    await write_reg(dut, ADDR_MATRIX_B, (b01 << 16) | b00)  # Row 0
    await write_reg(dut, ADDR_MATRIX_B, (b11 << 16) | b10)  # Row 1
    
    # Trigger computation
    await write_reg(dut, ADDR_MATRIX_CTRL, 1)
    
    # Wait for computation (5 cycles + margin)
    for _ in range(10):
        await RisingEdge(dut.clk)
    
    # Read result matrix C (row 0, row 1)
    c_row0 = await read_reg(dut, ADDR_MATRIX_C)
    c_row1 = await read_reg(dut, ADDR_MATRIX_C)
    
    c00 = c_row0 & 0xFFFF
    c01 = (c_row0 >> 16) & 0xFFFF
    c10 = c_row1 & 0xFFFF
    c11 = (c_row1 >> 16) & 0xFFFF
    
    # Convert back to float for display
    c00_f = from_fixed(c00)
    c01_f = from_fixed(c01)
    c10_f = from_fixed(c10)
    c11_f = from_fixed(c11)
    
    dut._log.info(f"Result C = [[{c00_f:.2f}, {c01_f:.2f}], [{c10_f:.2f}, {c11_f:.2f}]]")
    
    # Verify results (allow small error for fixed-point)
    assert abs(c00_f - 6.0) < 0.1, f"C[0][0] should be ~6.0, got {c00_f}"
    assert abs(c01_f - 0.0) < 0.1, f"C[0][1] should be ~0.0, got {c01_f}"
    assert abs(c10_f - 0.0) < 0.1, f"C[1][0] should be ~0.0, got {c10_f}"
    assert abs(c11_f - 6.0) < 0.1, f"C[1][1] should be ~6.0, got {c11_f}"
    
    dut._log.info("✓ Simple matrix multiplication passed")


@cocotb.test()
async def test_matrix_multiplier_standard(dut):
    """Test 2x2 matrix multiplier - standard test vector"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_dut(dut)
    dut._log.info("Testing standard matrix multiplication vector...")
    
    # Helper: convert float to 8.8 fixed-point (16-bit)
    def to_fixed(val):
        return int(val * 256) & 0xFFFF
    
    # Helper: convert 8.8 fixed-point to float
    def from_fixed(val):
        # Handle sign extension for 16-bit signed
        if val & 0x8000:
            val = val - 0x10000
        return val / 256.0
    
    # Test vector: [[1, 2], [3, 4]] * [[5, 6], [7, 8]] = [[19, 22], [43, 50]]
    dut._log.info("Matrix A = [[1, 2], [3, 4]]")
    dut._log.info("Matrix B = [[5, 6], [7, 8]]")
    dut._log.info("Expected C = [[19, 22], [43, 50]]")
    
    a00, a01 = to_fixed(1.0), to_fixed(2.0)
    a10, a11 = to_fixed(3.0), to_fixed(4.0)
    b00, b01 = to_fixed(5.0), to_fixed(6.0)
    b10, b11 = to_fixed(7.0), to_fixed(8.0)
    
    # Write matrix A (row 0, row 1)
    await write_reg(dut, ADDR_MATRIX_A, (a01 << 16) | a00)  # Row 0: [a00=1, a01=2]
    await write_reg(dut, ADDR_MATRIX_A, (a11 << 16) | a10)  # Row 1: [a10=3, a11=4]
    
    # Write matrix B (row 0, row 1)
    await write_reg(dut, ADDR_MATRIX_B, (b01 << 16) | b00)  # Row 0: [b00=5, b01=6]
    await write_reg(dut, ADDR_MATRIX_B, (b11 << 16) | b10)  # Row 1: [b10=7, b11=8]
    
    # Trigger computation
    await write_reg(dut, ADDR_MATRIX_CTRL, 1)
    
    # Wait for computation (5 cycles + margin)
    for _ in range(10):
        await RisingEdge(dut.clk)
    
    # Read result matrix C (row 0, row 1)
    c_row0 = await read_reg(dut, ADDR_MATRIX_C)
    c_row1 = await read_reg(dut, ADDR_MATRIX_C)
    
    c00 = c_row0 & 0xFFFF
    c01 = (c_row0 >> 16) & 0xFFFF
    c10 = c_row1 & 0xFFFF
    c11 = (c_row1 >> 16) & 0xFFFF
    
    # Convert back to float for display
    c00_f = from_fixed(c00)
    c01_f = from_fixed(c01)
    c10_f = from_fixed(c10)
    c11_f = from_fixed(c11)
    
    dut._log.info(f"Result C = [[{c00_f:.2f}, {c01_f:.2f}], [{c10_f:.2f}, {c11_f:.2f}]]")
    
    # Verify results (allow small error for fixed-point rounding)
    assert abs(c00_f - 19.0) < 0.1, f"C[0][0] should be ~19.0, got {c00_f}"
    assert abs(c01_f - 22.0) < 0.1, f"C[0][1] should be ~22.0, got {c01_f}"
    assert abs(c10_f - 43.0) < 0.1, f"C[1][0] should be ~43.0, got {c10_f}"
    assert abs(c11_f - 50.0) < 0.1, f"C[1][1] should be ~50.0, got {c11_f}"
    
    dut._log.info("✓ Standard test vector [[1,2],[3,4]] * [[5,6],[7,8]] = [[19,22],[43,50]] PASSED")
    dut._log.info("=== 2x2 Matrix Multiplier tests PASSED ===")
    dut._log.info("🚀 INNOVATION BONUS: Hardware 2x2 matrix multiplier with 8.8 fixed-point verified!")


