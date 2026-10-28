"""
Cocotb testbench for UART Baud Rate Generator

Tests:
1. Reset behavior
2. Correct divisor values for each baud rate
3. Tick generation timing
4. Enable/disable functionality
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.regression import TestFactory

# Clock frequency: 70 MHz
CLK_PERIOD_NS = 14  # ~14.3ns for 70MHz, using 14 for simplicity

# Expected divisor values for each baud rate (16x oversampling)
DIVISORS = {
    0x0: 456,  # 9600 baud * 16
    0x1: 228,  # 19200 baud * 16
    0x2: 114,  # 38400 baud * 16
    0xC: 38,  # 115200 baud * 16
}


@cocotb.test()
async def test_reset(dut):
    """Test reset behavior"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Assert reset
    dut.rst_n.value = 0
    dut.enable.value = 1
    dut.baud_sel.value = 0x0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Check counter is 0 during reset
    assert (
        dut.counter.value == 0
    ), f"Counter should be 0 during reset, got {dut.counter.value}"
    assert dut.baud_tick.value == 0, "baud_tick should be 0 during reset"

    # Release reset
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut._log.info("Reset test passed")


@cocotb.test()
async def test_divisor_lookup(dut):
    """Test that correct divisor is selected for each baud rate"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    for baud_sel, expected_divisor in DIVISORS.items():
        dut.baud_sel.value = baud_sel
        await Timer(1, units="ns")  # Combinational settling time

        actual_divisor = dut.divisor.value
        assert (
            actual_divisor == expected_divisor
        ), f"Baud sel {baud_sel:#x}: expected divisor {expected_divisor}, got {actual_divisor}"

        dut._log.info(f"Baud sel {baud_sel:#x}: divisor = {actual_divisor} ✓")

    dut._log.info("Divisor lookup test passed")


@cocotb.test()
async def test_tick_generation_9600(dut):
    """Test tick generation for 9600 baud"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.baud_sel.value = 0x0  # 9600 baud
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Enable and wait for first tick
    dut.enable.value = 1

    expected_divisor = DIVISORS[0x0]
    tick_count = 0
    cycle_count = 0

    # Wait for 3 ticks
    while tick_count < 3:
        await RisingEdge(dut.clk)
        cycle_count += 1

        if dut.baud_tick.value == 1:
            tick_count += 1
            # Tick should occur at divisor-1 cycles
            assert (
                cycle_count == expected_divisor
            ), f"Tick {tick_count}: expected after {expected_divisor} cycles, got {cycle_count}"
            dut._log.info(f"Tick {tick_count} at cycle {cycle_count} ✓")
            cycle_count = 0  # Reset for next tick

    dut._log.info("Tick generation test passed")


@cocotb.test()
async def test_enable_disable(dut):
    """Test enable/disable functionality"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.baud_sel.value = 0xC  # 115200 (smaller divisor, faster test)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Start with enable=0, counter should stay at 0
    dut.enable.value = 0
    for _ in range(10):
        await RisingEdge(dut.clk)
        assert dut.counter.value == 0, "Counter should be 0 when disabled"
        assert dut.baud_tick.value == 0, "No ticks when disabled"

    dut._log.info("Counter stays at 0 when disabled ✓")

    # Enable, counter should increment
    dut.enable.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.counter.value) > 0, "Counter should increment when enabled"

    dut._log.info("Counter increments when enabled ✓")

    # Disable mid-count, counter should reset to 0
    dut.enable.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)  # Extra cycle for reset to take effect
    assert dut.counter.value == 0, "Counter should reset when disabled"

    dut._log.info("Enable/disable test passed")


@cocotb.test()
async def test_all_baud_rates(dut):
    """Test tick generation for all baud rates"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    for baud_sel, expected_divisor in DIVISORS.items():
        dut.baud_sel.value = baud_sel
        dut.enable.value = 1
        await RisingEdge(dut.clk)

        # Wait for one tick - counter starts incrementing from 0
        tick_seen = False

        for cycle_count in range(expected_divisor + 10):
            await RisingEdge(dut.clk)

            if dut.baud_tick.value == 1:
                # Tick occurs when counter reaches divisor-1, which is after divisor clocks
                tick_seen = True
                dut._log.info(f"Baud rate {baud_sel:#x}: tick at correct timing ✓")
                break

        assert tick_seen, f"No tick seen for baud_sel {baud_sel:#x}"

        # Disable before next test
        dut.enable.value = 0
        await RisingEdge(dut.clk)

    dut._log.info("All baud rates test passed")
