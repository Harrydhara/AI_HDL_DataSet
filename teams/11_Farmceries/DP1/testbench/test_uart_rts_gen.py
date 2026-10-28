"""
Cocotb testbench for UART RTS Generator

Tests:
1. Reset behavior - RTS deasserted (ready)
2. RTS asserts when watermark reached
3. RTS deasserts when watermark clears
4. Flow control enable/disable
5. RTS timing and edge cases
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

CLK_PERIOD_NS = 14  # 70 MHz


@cocotb.test()
async def test_reset(dut):
    """Test RTS behavior after reset"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.rx_fifo_watermark.value = 0
    dut.flow_ctrl_en.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # RTS should be deasserted (low = ready to receive)
    assert dut.rts_n.value == 0, "RTS should be ready (low) after reset"

    dut._log.info("✓ Reset test passed")


@cocotb.test()
async def test_rts_asserts_on_watermark(dut):
    """Test RTS asserts when watermark is reached"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.rx_fifo_watermark.value = 0
    dut.flow_ctrl_en.value = 1  # Enable flow control

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Initially ready
    assert dut.rts_n.value == 0, "RTS should be ready initially"

    # Assert watermark (FIFO getting full)
    dut.rx_fifo_watermark.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # RTS should be asserted (high = not ready)
    assert dut.rts_n.value == 1, "RTS should assert when watermark reached"

    dut._log.info("✓ RTS assertion test passed")


@cocotb.test()
async def test_rts_deasserts_on_watermark_clear(dut):
    """Test RTS deasserts when watermark clears"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset with watermark already asserted
    dut.rst_n.value = 0
    dut.rx_fifo_watermark.value = 1  # Watermark already high
    dut.flow_ctrl_en.value = 1

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # RTS should be asserted
    assert dut.rts_n.value == 1, "RTS should be asserted with watermark"

    # Clear watermark (FIFO has space again)
    dut.rx_fifo_watermark.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # RTS should deassert (ready to receive again)
    assert dut.rts_n.value == 0, "RTS should deassert when watermark clears"

    dut._log.info("✓ RTS deassertion test passed")


@cocotb.test()
async def test_flow_control_disabled(dut):
    """Test RTS behavior when flow control is disabled"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.rx_fifo_watermark.value = 0
    dut.flow_ctrl_en.value = 0  # Flow control DISABLED

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # RTS should be ready
    assert dut.rts_n.value == 0, "RTS should be ready"

    # Assert watermark
    dut.rx_fifo_watermark.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # RTS should STILL be ready (flow control disabled)
    assert dut.rts_n.value == 0, "RTS should stay ready when flow control disabled"

    dut._log.info("✓ Flow control disabled test passed")


@cocotb.test()
async def test_rts_toggle(dut):
    """Test multiple RTS toggle cycles"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.rx_fifo_watermark.value = 0
    dut.flow_ctrl_en.value = 1

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Perform multiple toggle cycles
    for i in range(5):
        # Assert watermark
        dut.rx_fifo_watermark.value = 1
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        assert dut.rts_n.value == 1, f"Cycle {i}: RTS should assert"

        # Clear watermark
        dut.rx_fifo_watermark.value = 0
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        assert dut.rts_n.value == 0, f"Cycle {i}: RTS should deassert"

    dut._log.info("✓ RTS toggle test passed (5 cycles)")


@cocotb.test()
async def test_enable_disable_transition(dut):
    """Test flow control enable/disable transitions"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset with watermark asserted and flow control enabled
    dut.rst_n.value = 0
    dut.rx_fifo_watermark.value = 1
    dut.flow_ctrl_en.value = 1

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # RTS should be asserted
    assert dut.rts_n.value == 1, "RTS should be asserted initially"

    # Disable flow control
    dut.flow_ctrl_en.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # RTS should deassert (ready)
    assert dut.rts_n.value == 0, "RTS should be ready when flow control disabled"

    # Re-enable flow control (watermark still high)
    dut.flow_ctrl_en.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # RTS should assert again
    assert dut.rts_n.value == 1, "RTS should reassert when flow control re-enabled"

    dut._log.info("✓ Enable/disable transition test passed")
