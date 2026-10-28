"""
test_uart_tx.py — cocotb tests for uart_tx.

Testbench parameters: BIT_RATE=10, CLK_HZ=100  → CYCLES_PER_BIT = (100-1)//10 = 9
So each UART bit lasts 10 clock cycles (counter 0..9, next_bit on 9).

Frame format: 1 start bit (0) + 8 data bits (LSB first) + 1 stop bit (1).
Total = 10 bits → 100 clock cycles per byte.
"""

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

# Must match tb_uart_tx.v parameters
BIT_RATE     = 10
CLK_HZ       = 100
PAYLOAD_BITS = 8
STOP_BITS    = 1
CYCLES_PER_BIT = (CLK_HZ - 1) // BIT_RATE   # = 9, next_bit fires at cycle 9


async def reset_dut(dut):
    dut.resetn.value       = 0
    dut.uart_tx_en.value   = 0
    dut.uart_tx_data.value = 0
    await ClockCycles(dut.clk, 5)
    dut.resetn.value = 1
    await ClockCycles(dut.clk, 2)


async def receive_byte(dut):
    """Wait for a complete UART frame and return the received byte."""
    # Wait for start bit (txd goes low)
    while int(dut.uart_txd.value) == 1:
        await RisingEdge(dut.clk)

    # We are now at the start of the start bit.
    # Sample each bit in the middle of its period (half-way through).
    half_bit  = (CYCLES_PER_BIT + 1) // 2   # ~5 cycles
    full_bit  = CYCLES_PER_BIT + 1           # 10 cycles

    # Skip to middle of start bit and verify it's 0
    await ClockCycles(dut.clk, half_bit)
    assert int(dut.uart_txd.value) == 0, "Start bit not 0"

    received = 0
    for bit_idx in range(PAYLOAD_BITS):
        await ClockCycles(dut.clk, full_bit)
        bit = int(dut.uart_txd.value)
        received |= bit << bit_idx   # LSB first

    # Stop bit
    await ClockCycles(dut.clk, full_bit)
    assert int(dut.uart_txd.value) == 1, "Stop bit not 1"

    return received


@cocotb.test()
async def test_idle_high(dut):
    """uart_txd must be high after reset (idle state)."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)
    await ClockCycles(dut.clk, 5)
    assert int(dut.uart_txd.value) == 1, "UART idle should be high"
    assert int(dut.uart_tx_busy.value) == 0, "Should not be busy after reset"


@cocotb.test()
async def test_send_single_byte(dut):
    """Send 0x55 (0101_0101) and verify the received frame."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    test_byte = 0x55
    dut.uart_tx_data.value = test_byte
    dut.uart_tx_en.value   = 1
    await ClockCycles(dut.clk, 1)
    dut.uart_tx_en.value   = 0

    received = await receive_byte(dut)
    assert received == test_byte, f"Expected {test_byte:#04x}, got {received:#04x}"

    # After stop bit, should be idle again
    await ClockCycles(dut.clk, 5)
    assert int(dut.uart_tx_busy.value) == 0


@cocotb.test()
async def test_send_0x00(dut):
    """Send 0x00 — all data bits low."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    dut.uart_tx_data.value = 0x00
    dut.uart_tx_en.value   = 1
    await ClockCycles(dut.clk, 1)
    dut.uart_tx_en.value   = 0

    received = await receive_byte(dut)
    assert received == 0x00, f"Expected 0x00, got {received:#04x}"


@cocotb.test()
async def test_send_0xff(dut):
    """Send 0xFF — all data bits high."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    dut.uart_tx_data.value = 0xFF
    dut.uart_tx_en.value   = 1
    await ClockCycles(dut.clk, 1)
    dut.uart_tx_en.value   = 0

    received = await receive_byte(dut)
    assert received == 0xFF, f"Expected 0xFF, got {received:#04x}"


@cocotb.test()
async def test_busy_signal(dut):
    """uart_tx_busy must be high during transmission and low after."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    dut.uart_tx_data.value = 0xA5
    dut.uart_tx_en.value   = 1
    await ClockCycles(dut.clk, 1)
    dut.uart_tx_en.value   = 0

    await ClockCycles(dut.clk, 2)
    assert int(dut.uart_tx_busy.value) == 1, "Should be busy during transmission"

    # Wait for full frame: (1 start + 8 data + 1 stop) * 10 cycles + margin
    total_cycles = (1 + PAYLOAD_BITS + STOP_BITS) * (CYCLES_PER_BIT + 1) + 20
    await ClockCycles(dut.clk, total_cycles)
    assert int(dut.uart_tx_busy.value) == 0, "Should be idle after transmission"


@cocotb.test()
async def test_random_bytes(dut):
    """Send 10 random bytes and verify each one."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    for _ in range(10):
        test_byte = random.randint(0, 255)
        dut.uart_tx_data.value = test_byte
        dut.uart_tx_en.value   = 1
        await ClockCycles(dut.clk, 1)
        dut.uart_tx_en.value   = 0

        received = await receive_byte(dut)
        assert received == test_byte, \
            f"Expected {test_byte:#04x}, got {received:#04x}"

        # Brief gap between bytes
        await ClockCycles(dut.clk, 5)
