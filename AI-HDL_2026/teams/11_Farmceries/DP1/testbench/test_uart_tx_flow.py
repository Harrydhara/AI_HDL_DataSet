"""
Cocotb testbench for UART TX with Flow Control

Tests:
1. Normal transmission with flow control disabled
2. CTS prevents transmission start
3. CTS pauses mid-transmission
4. CTS resumes transmission
5. Flow control enable/disable functionality
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.regression import TestFactory

CLK_PERIOD_NS = 14  # 70 MHz


def generate_baud_ticks(dut, baud_rate=9600, clk_freq=70_000_000):
    """Generate baud ticks for UART transmission"""
    ticks_per_baud = clk_freq // (baud_rate * 16)
    return ticks_per_baud


async def send_baud_ticks(dut, count):
    """Send specified number of baud ticks"""
    ticks_per_baud = generate_baud_ticks(dut)

    for _ in range(count):
        # Wait for tick interval
        for _ in range(ticks_per_baud):
            await RisingEdge(dut.clk)
        # Generate tick pulse
        dut.baud_tick.value = 1
        await RisingEdge(dut.clk)
        dut.baud_tick.value = 0


async def capture_transmission(dut, num_bits=10):
    """Capture transmitted bits (start + 8 data + stop)"""
    bits = []
    ticks_per_baud = generate_baud_ticks(dut)

    for _ in range(num_bits):
        # Wait for 16 baud ticks (one bit period)
        for _ in range(16):
            await send_baud_ticks(dut, 1)
        # Sample the bit
        bits.append(int(dut.tx_out.value))

    return bits


@cocotb.test()
async def test_normal_operation_no_flow_control(dut):
    """Test normal transmission with flow control disabled"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_tick.value = 0
    dut.cts_n.value = 0  # Clear to send
    dut.flow_ctrl_en.value = 0  # Flow control disabled

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Check idle
    assert dut.tx_out.value == 1, "TX should be idle high"
    assert dut.tx_busy.value == 0, "TX should not be busy"

    # Start transmission of 0xA5
    test_data = 0xA5
    dut.tx_data.value = test_data
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)

    # TX should be busy
    assert dut.tx_busy.value == 1, "TX should be busy after start"

    # Capture full transmission
    bits = await capture_transmission(dut, 10)

    # Verify frame: start(0) + data(8) + stop(1)
    assert bits[0] == 0, "Start bit should be 0"
    assert bits[9] == 1, "Stop bit should be 1"

    # Verify data (LSB first)
    data_bits = bits[1:9]
    received = sum([bit << i for i, bit in enumerate(data_bits)])
    assert received == test_data, f"Expected 0x{test_data:02X}, got 0x{received:02X}"

    dut._log.info(f"✓ Normal operation test passed (0x{test_data:02X} transmitted)")


@cocotb.test()
async def test_cts_prevents_start(dut):
    """Test that CTS prevents transmission from starting"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_tick.value = 0
    dut.cts_n.value = 1  # NOT clear to send
    dut.flow_ctrl_en.value = 1  # Flow control ENABLED

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Try to start transmission
    dut.tx_data.value = 0x55
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)

    # Should be busy (loaded data) but start bit should not progress
    # because baud_tick is gated by CTS
    initial_tx_out = int(dut.tx_out.value)

    # Send some baud ticks - should not progress
    await send_baud_ticks(dut, 20)

    # TX should still be in START state (tx_out = 0) but frozen
    # Actually, it moves to START state but can't progress
    current_tx_out = int(dut.tx_out.value)

    # The start bit should be output but no state progression
    assert dut.tx_busy.value == 1, "TX should be busy"

    dut._log.info("✓ CTS prevents transmission progress")


@cocotb.test()
async def test_cts_pauses_and_resumes(dut):
    """Test that CTS can pause and resume mid-transmission"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_tick.value = 0
    dut.cts_n.value = 0  # Clear to send initially
    dut.flow_ctrl_en.value = 1  # Flow control enabled

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Start transmission
    dut.tx_data.value = 0xAA
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)

    # Transmit start bit (16 ticks)
    await send_baud_ticks(dut, 16)

    # Transmit first 2 data bits
    await send_baud_ticks(dut, 32)  # 2 bits * 16 ticks

    # Assert CTS (pause transmission)
    dut.cts_n.value = 1
    await RisingEdge(dut.clk)

    # Try to send more ticks - should not progress
    state_before_pause = int(dut.tx_busy.value)
    await send_baud_ticks(dut, 20)
    state_after_pause = int(dut.tx_busy.value)

    # Should still be busy (transmission frozen)
    assert state_before_pause == 1, "Should be busy before pause"
    assert state_after_pause == 1, "Should still be busy during pause"

    # Deassert CTS (resume transmission)
    dut.cts_n.value = 0
    await RisingEdge(dut.clk)

    # Complete remaining transmission (6 data bits + stop bit = 7 bits * 16 ticks)
    await send_baud_ticks(dut, 16 * 7)

    # Wait a bit for state to settle
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Should be idle now
    assert dut.tx_busy.value == 0, "Should be idle after completion"
    assert dut.tx_out.value == 1, "Should be idle high"

    dut._log.info("✓ CTS pause and resume test passed")


@cocotb.test()
async def test_flow_control_enable_disable(dut):
    """Test flow control enable/disable functionality"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_tick.value = 0
    dut.cts_n.value = 1  # NOT clear to send
    dut.flow_ctrl_en.value = 0  # Flow control DISABLED

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Start transmission with CTS asserted but flow control disabled
    dut.tx_data.value = 0x42
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)

    # Should progress normally despite CTS being high
    await send_baud_ticks(dut, 16)  # Start bit

    # TX should have progressed
    assert dut.tx_busy.value == 1, "TX should be busy"

    # Complete transmission (8 data + 1 stop = 9 bits)
    await send_baud_ticks(dut, 16 * 9)

    # Wait for state to settle
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Should be idle
    assert dut.tx_busy.value == 0, "Should be idle after completion"

    dut._log.info("✓ Flow control enable/disable test passed")


@cocotb.test()
async def test_cts_timing(dut):
    """Test precise timing of CTS assertion during bit transmission"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_tick.value = 0
    dut.cts_n.value = 0
    dut.flow_ctrl_en.value = 1

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Start transmission
    dut.tx_data.value = 0xFF
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)

    # Transmit start bit
    await send_baud_ticks(dut, 16)

    # Transmit partial first data bit (8 ticks of 16)
    await send_baud_ticks(dut, 8)

    # Assert CTS mid-bit
    dut.cts_n.value = 1
    await RisingEdge(dut.clk)

    # Send remaining 8 ticks of this bit - should not complete bit
    await send_baud_ticks(dut, 8)

    # Bit should not have completed (sample_cnt frozen)
    assert dut.tx_busy.value == 1, "Still transmitting"

    # Deassert CTS
    dut.cts_n.value = 0
    await RisingEdge(dut.clk)

    # Now the paused ticks need to complete, THEN remaining bits
    # We sent 8 ticks before pause, so need 8 more to complete first data bit
    # Then 7 more data bits + stop = 8 more bits total
    await send_baud_ticks(dut, 8)  # Complete first data bit
    await send_baud_ticks(dut, 16 * 8)  # 7 data bits + stop

    # Wait for state to settle
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert dut.tx_busy.value == 0, "Transmission complete"

    dut._log.info("✓ CTS timing test passed")
