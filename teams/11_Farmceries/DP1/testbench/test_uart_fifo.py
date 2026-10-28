"""
Cocotb testbench for UART FIFO

Tests:
1. Reset behavior - FIFO empty after reset
2. Single write/read operation
3. FIFO full condition (write 16 bytes)
4. FIFO empty condition
5. Overflow protection (write when full)
6. Underflow protection (read when empty)
7. Watermark detection (14-byte threshold)
8. Burst write operations
9. Burst read operations
10. Simultaneous read/write
11. Wrap-around behavior (pointers roll over)
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.regression import TestFactory

CLK_PERIOD_NS = 14  # 70 MHz


@cocotb.test()
async def test_reset(dut):
    """Test FIFO behavior after reset"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Apply reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wr_data.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Check reset state
    assert dut.empty.value == 1, "FIFO should be empty after reset"
    assert dut.full.value == 0, "FIFO should not be full after reset"
    assert dut.count.value == 0, f"Count should be 0, got {dut.count.value}"
    assert dut.watermark.value == 0, "Watermark should not be asserted"

    dut._log.info("✓ Reset test passed")


@cocotb.test()
async def test_single_write_read(dut):
    """Test single write followed by single read"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wr_data.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Write single byte
    test_data = 0xA5
    dut.wr_data.value = test_data
    dut.wr_en.value = 1
    await RisingEdge(dut.clk)
    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    # Check status after write
    assert dut.empty.value == 0, "FIFO should not be empty after write"
    assert dut.count.value == 1, f"Count should be 1, got {dut.count.value}"

    # Read the byte
    dut.rd_en.value = 1
    await RisingEdge(dut.clk)
    read_data = int(dut.rd_data.value)
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)

    # Verify data
    assert read_data == test_data, f"Expected {test_data:02X}, got {read_data:02X}"
    assert dut.empty.value == 1, "FIFO should be empty after read"
    assert dut.count.value == 0, f"Count should be 0, got {dut.count.value}"

    dut._log.info(f"✓ Single write/read test passed (data: 0x{test_data:02X})")


@cocotb.test()
async def test_fill_fifo(dut):
    """Test filling FIFO to capacity (16 bytes)"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Write 16 bytes
    test_data = []
    for i in range(16):
        data = (i * 17) & 0xFF  # Pattern: 0x00, 0x11, 0x22, ...
        test_data.append(data)
        dut.wr_data.value = data
        dut.wr_en.value = 1
        await RisingEdge(dut.clk)

    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    # Check count after all writes
    assert dut.count.value == 16, f"Count should be 16, got {dut.count.value}"

    # Check FIFO is full
    assert dut.full.value == 1, "FIFO should be full after 16 writes"
    assert dut.count.value == 16, "Count should be 16"
    assert dut.empty.value == 0, "FIFO should not be empty"

    dut._log.info("✓ Fill FIFO test passed (16 bytes written)")


@cocotb.test()
async def test_overflow_protection(dut):
    """Test that writes are ignored when FIFO is full"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Fill FIFO
    for i in range(16):
        dut.wr_data.value = i
        dut.wr_en.value = 1
        await RisingEdge(dut.clk)

    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    assert dut.full.value == 1, "FIFO should be full"

    # Try to write one more byte (should be ignored)
    dut.wr_data.value = 0xFF
    dut.wr_en.value = 1
    await RisingEdge(dut.clk)
    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    # Count should still be 16
    assert dut.count.value == 16, f"Count should remain 16, got {dut.count.value}"
    assert dut.full.value == 1, "FIFO should still be full"

    dut._log.info("✓ Overflow protection test passed")


@cocotb.test()
async def test_underflow_protection(dut):
    """Test that reads from empty FIFO don't cause issues"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Verify empty
    assert dut.empty.value == 1, "FIFO should be empty"
    assert dut.count.value == 0, "Count should be 0"

    # Try to read from empty FIFO
    dut.rd_en.value = 1
    await RisingEdge(dut.clk)
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)

    # Should still be empty
    assert dut.empty.value == 1, "FIFO should still be empty"
    assert dut.count.value == 0, "Count should still be 0"

    dut._log.info("✓ Underflow protection test passed")


@cocotb.test()
async def test_watermark(dut):
    """Test watermark detection at 14-byte threshold"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Write 13 bytes - watermark should NOT be asserted
    for i in range(13):
        dut.wr_data.value = i
        dut.wr_en.value = 1
        await RisingEdge(dut.clk)

    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    assert dut.watermark.value == 0, "Watermark should not be asserted at 13 bytes"
    assert dut.count.value == 13, "Count should be 13"

    # Write 14th byte - watermark should assert
    dut.wr_data.value = 13
    dut.wr_en.value = 1
    await RisingEdge(dut.clk)
    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    assert dut.watermark.value == 1, "Watermark should be asserted at 14 bytes"
    assert dut.count.value == 14, "Count should be 14"

    # Write 15th and 16th bytes - watermark should stay asserted
    for i in range(2):
        dut.wr_data.value = 14 + i
        dut.wr_en.value = 1
        await RisingEdge(dut.clk)

    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    assert dut.watermark.value == 1, "Watermark should remain asserted"
    assert dut.full.value == 1, "FIFO should be full"

    # Read bytes until watermark deasserts
    for i in range(3):  # Read 3 bytes (16 -> 13)
        dut.rd_en.value = 1
        await RisingEdge(dut.clk)

    dut.rd_en.value = 0
    await RisingEdge(dut.clk)

    assert dut.watermark.value == 0, "Watermark should deassert at 13 bytes"
    assert dut.count.value == 13, "Count should be 13"

    dut._log.info("✓ Watermark test passed (threshold = 14)")


@cocotb.test()
async def test_full_write_read_cycle(dut):
    """Test complete write-then-read cycle with data verification"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Write 16 unique bytes
    test_pattern = [
        0x00,
        0x11,
        0x22,
        0x33,
        0x44,
        0x55,
        0x66,
        0x77,
        0x88,
        0x99,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
    ]

    for data in test_pattern:
        dut.wr_data.value = data
        dut.wr_en.value = 1
        await RisingEdge(dut.clk)

    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    # Read and verify all 16 bytes
    read_data = []
    for _ in range(16):
        dut.rd_en.value = 1
        await RisingEdge(dut.clk)
        read_data.append(int(dut.rd_data.value))

    dut.rd_en.value = 0
    await RisingEdge(dut.clk)

    # Verify all data matches
    for i, (expected, actual) in enumerate(zip(test_pattern, read_data)):
        assert (
            expected == actual
        ), f"Byte {i}: expected 0x{expected:02X}, got 0x{actual:02X}"

    # FIFO should be empty now
    assert dut.empty.value == 1, "FIFO should be empty after reading all data"
    assert dut.count.value == 0, "Count should be 0"

    dut._log.info("✓ Full write/read cycle test passed (16 bytes verified)")


@cocotb.test()
async def test_simultaneous_read_write(dut):
    """Test simultaneous read and write operations"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Pre-fill with some data
    for i in range(8):
        dut.wr_data.value = i
        dut.wr_en.value = 1
        await RisingEdge(dut.clk)

    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    initial_count = int(dut.count.value)
    assert initial_count == 8, "Initial count should be 8"

    # Simultaneous read and write (count should stay same)
    dut.wr_data.value = 0xAA
    dut.wr_en.value = 1
    dut.rd_en.value = 1
    await RisingEdge(dut.clk)
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)

    # Count should remain the same
    assert (
        dut.count.value == initial_count
    ), f"Count should remain {initial_count}, got {dut.count.value}"

    dut._log.info("✓ Simultaneous read/write test passed")


@cocotb.test()
async def test_wrap_around(dut):
    """Test pointer wrap-around behavior"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Write, read, write, read pattern multiple times to exercise wrap-around
    for cycle in range(3):
        # Write 16 bytes
        for i in range(16):
            dut.wr_data.value = (cycle * 16 + i) & 0xFF
            dut.wr_en.value = 1
            await RisingEdge(dut.clk)

        dut.wr_en.value = 0
        await RisingEdge(dut.clk)

        assert dut.full.value == 1, f"FIFO should be full in cycle {cycle}"

        # Read 16 bytes
        for i in range(16):
            dut.rd_en.value = 1
            await RisingEdge(dut.clk)
            expected = (cycle * 16 + i) & 0xFF
            actual = int(dut.rd_data.value)
            assert (
                expected == actual
            ), f"Cycle {cycle}, byte {i}: expected 0x{expected:02X}, got 0x{actual:02X}"

        dut.rd_en.value = 0
        await RisingEdge(dut.clk)

        assert dut.empty.value == 1, f"FIFO should be empty in cycle {cycle}"

    dut._log.info("✓ Wrap-around test passed (3 complete cycles)")


@cocotb.test()
async def test_burst_operations(dut):
    """Test rapid burst write and read operations"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Burst write 10 bytes with no gaps
    burst_data = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC]

    for data in burst_data:
        dut.wr_data.value = data
        dut.wr_en.value = 1
        await RisingEdge(dut.clk)

    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    assert dut.count.value == 10, "Count should be 10 after burst write"

    # Burst read with no gaps
    for i, expected in enumerate(burst_data):
        dut.rd_en.value = 1
        await RisingEdge(dut.clk)
        actual = int(dut.rd_data.value)
        assert (
            expected == actual
        ), f"Burst byte {i}: expected 0x{expected:02X}, got 0x{actual:02X}"

    dut.rd_en.value = 0
    await RisingEdge(dut.clk)

    assert dut.empty.value == 1, "FIFO should be empty after burst read"

    dut._log.info("✓ Burst operations test passed (10-byte burst)")
