"""
UART Loopback Test

Tests the uart_rx module by using uart_tx to generate test data.
This ensures perfect timing alignment since both TX and RX use the same baud_tick.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge


@cocotb.test()
async def test_loopback_single_byte(dut):
    """Test TX->RX loopback with a single byte"""

    # Start clock
    clock = Clock(dut.clk, 14, units="ns")  # 70 MHz
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_sel.value = 0  # 9600 baud
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Wait for things to settle
    await Timer(1, units="us")

    # Send a byte via TX
    test_byte = 0x55
    print(f"Sending byte: 0x{test_byte:02X}")

    dut.tx_data.value = test_byte
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0

    # Wait for complete reception (rx_ready pulse)
    # At 9600 baud, 1 byte = 1ms. Wait 2ms.
    try:
        await cocotb.triggers.with_timeout(RisingEdge(dut.rx_ready), 2000, "us")
    except cocotb.result.SimTimeoutError:
        assert False, "Timeout waiting for rx_ready"

    # Check if RX received the byte
    print(
        f"RX state: rx_ready={int(dut.rx_ready.value)}, rx_data=0x{int(dut.rx_data.value):02X}, rx_error={int(dut.rx_error.value)}"
    )

    assert dut.rx_error.value == 0, "Frame error detected"
    # rx_ready is 1 (we just woke up on edge)
    assert (
        dut.rx_data.value == test_byte
    ), f"Data mismatch: expected 0x{test_byte:02X}, got 0x{int(dut.rx_data.value):02X}"

    print(f"✓ Loopback successful: 0x{test_byte:02X}")


@cocotb.test()
async def test_loopback_multiple_bytes(dut):
    """Test TX->RX loopback with multiple bytes"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_sel.value = 0  # 9600 baud
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    await Timer(1, units="us")

    test_bytes = [0x00, 0xFF, 0xAA, 0x55, 0x12, 0x34, 0xDE, 0xAD]

    for test_byte in test_bytes:
        print(f"\nSending byte: 0x{test_byte:02X}")

        # Send byte
        dut.tx_data.value = test_byte
        dut.tx_start.value = 1
        await RisingEdge(dut.clk)
        dut.tx_start.value = 0

        # Wait for RX ready pulse
        try:
            await cocotb.triggers.with_timeout(RisingEdge(dut.rx_ready), 2000, "us")
        except cocotb.result.SimTimeoutError:
            print(f"DEBUG: Timeout waiting for rx_ready. rx_error={dut.rx_error.value}")
            assert False, f"Timeout waiting for RX (byte 0x{test_byte:02X})"

        # Check RX
        print(
            f"  RX: data=0x{int(dut.rx_data.value):02X}, error={int(dut.rx_error.value)}, ready={int(dut.rx_ready.value)}"
        )

        assert dut.rx_error.value == 0, f"Frame error for byte 0x{test_byte:02X}"
        assert (
            dut.rx_data.value == test_byte
        ), f"Mismatch: expected 0x{test_byte:02X}, got 0x{int(dut.rx_data.value):02X}"

        print(f"  ✓ Received correctly")

        # Wait for TX to be free before sending next byte
        # rx_ready asserts at the middle of the STOP bit (tick 7).
        # tx_busy stays high until end of STOP bit (tick 15).
        # So we must wait for tx_busy to drop.
        if dut.tx_busy.value == 1:
            await FallingEdge(dut.tx_busy)

        # Small safety gap between bytes
        await Timer(20, units="us")


@cocotb.test()
async def test_loopback_all_baud_rates(dut):
    """Test loopback at all supported baud rates"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    baud_rates = {0: 9600, 1: 19200, 2: 38400, 0xC: 115200}

    test_byte = 0xA5

    for baud_sel, baud in baud_rates.items():
        print(f"\n=== Testing at {baud} baud (sel=0x{baud_sel:X}) ===")

        # Reset with new baud rate
        dut.baud_sel.value = baud_sel
        dut.rst_n.value = 0
        dut.tx_start.value = 0
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        dut.rst_n.value = 1
        await RisingEdge(dut.clk)

        await Timer(10, units="us")

        # Send byte
        dut.tx_data.value = test_byte
        dut.tx_start.value = 1
        await RisingEdge(dut.clk)
        dut.tx_start.value = 0

        # Wait for RX ready pulse
        try:
            # Generous timeout for 9600 baud (~1ms for 10 bits)
            await cocotb.triggers.with_timeout(RisingEdge(dut.rx_ready), 3000, "us")
        except cocotb.result.SimTimeoutError:
            print(f"DEBUG: Timeout waiting for rx_ready at {baud} baud")
            assert False, f"Timeout waiting for RX at {baud} baud"

        # Check RX
        print(
            f"  RX: data=0x{int(dut.rx_data.value):02X}, error={int(dut.rx_error.value)}"
        )

        assert dut.rx_error.value == 0, f"Frame error at {baud} baud"
        assert (
            dut.rx_data.value == test_byte
        ), f"Mismatch at {baud} baud: expected 0x{test_byte:02X}, got 0x{int(dut.rx_data.value):02X}"

        print(f"  ✓ {baud} baud OK")

        await Timer(50, units="us")
