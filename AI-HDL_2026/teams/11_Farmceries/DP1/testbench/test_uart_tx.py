"""
Cocotb testbench for UART Transmitter

Tests:
1. Idle state (tx_out = 1, tx_busy = 0)
2. Transmission of single byte (verify frame format)
3. LSB-first data transmission
4. Busy flag behavior
5. Multiple consecutive transmissions
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.regression import TestFactory

CLK_PERIOD_NS = 14  # 70 MHz


def extract_frame(bits):
    """Extract start, data, stop bits from captured transmission"""
    if len(bits) < 10:
        return None, None, None

    start = bits[0]
    data = bits[1:9]  # 8 data bits
    stop = bits[9]

    return start, data, stop


def bits_to_byte(bits):
    """Convert list of bits to byte value (LSB first)"""
    value = 0
    for i, bit in enumerate(bits):
        if bit:
            value |= 1 << i
    return value


@cocotb.test()
async def test_idle_state(dut):
    """Test idle state behavior"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_tick.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Check idle state
    assert dut.tx_out.value == 1, "tx_out should be HIGH in idle"
    assert dut.tx_busy.value == 0, "tx_busy should be 0 in idle"
    assert int(dut.state.value) == 0, "State should be IDLE (0)"

    dut._log.info("Idle state test passed ✓")


@cocotb.test()
async def test_single_byte_transmission(dut):
    """Test transmission of single byte 0x55 (0b01010101)"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_tick.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Start transmission
    test_data = 0x55
    dut.tx_data.value = test_data
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0

    # Should now be busy
    await RisingEdge(dut.clk)
    assert dut.tx_busy.value == 1, "Should be busy after tx_start"

    # Capture transmission bits
    captured_bits = []

    for bit_num in range(10):  # 1 start + 8 data + 1 stop
        # Sample before baud tick
        captured_bits.append(int(dut.tx_out.value))

        # Generate 16 baud ticks per bit (16x oversampling)
        for _ in range(16):
            dut.baud_tick.value = 1
            await RisingEdge(dut.clk)
            dut.baud_tick.value = 0
            await RisingEdge(dut.clk)

    # Extract frame
    start, data, stop = extract_frame(captured_bits)

    # Verify frame format
    assert start == 0, f"Start bit should be 0, got {start}"
    assert stop == 1, f"Stop bit should be 1, got {stop}"

    # Verify data (LSB first)
    received_byte = bits_to_byte(data)
    assert (
        received_byte == test_data
    ), f"Expected {test_data:#x}, got {received_byte:#x}, bits={data}"

    dut._log.info(f"Transmitted 0x{test_data:02X}, received 0x{received_byte:02X} ✓")

    # Should be idle now
    assert dut.tx_busy.value == 0, "Should be idle after transmission"
    assert dut.tx_out.value == 1, "Should return to idle HIGH"


@cocotb.test()
async def test_lsb_first(dut):
    """Test that data is transmitted LSB first"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.baud_tick.value = 0
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Test with 0x01 (only LSB set)
    dut.tx_data.value = 0x01
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)

    # Capture bits
    captured_bits = []
    for _ in range(10):
        captured_bits.append(int(dut.tx_out.value))
        # Generate 16 baud ticks per bit (16x oversampling)
        for _ in range(16):
            dut.baud_tick.value = 1
            await RisingEdge(dut.clk)
            dut.baud_tick.value = 0
            await RisingEdge(dut.clk)

    # For 0x01, LSB first means: start(0), 1,0,0,0,0,0,0,0, stop(1)
    assert captured_bits[0] == 0, "Start bit"
    assert captured_bits[1] == 1, "D0 (LSB) should be 1"
    assert captured_bits[2] == 0, "D1 should be 0"
    assert captured_bits[9] == 1, "Stop bit"

    dut._log.info("LSB-first transmission verified ✓")


@cocotb.test()
async def test_busy_flag(dut):
    """Test tx_busy flag timing"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.baud_tick.value = 0
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Should be idle
    assert dut.tx_busy.value == 0, "Should be idle initially"

    # Start transmission
    dut.tx_data.value = 0xAA
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)

    # Should be busy immediately
    assert dut.tx_busy.value == 1, "Should be busy after start"

    # Transmit complete frame
    for _ in range(10):
        assert dut.tx_busy.value == 1, "Should stay busy during transmission"
        # Generate 16 baud ticks per bit (16x oversampling)
        for _ in range(16):
            dut.baud_tick.value = 1
            await RisingEdge(dut.clk)
            dut.baud_tick.value = 0
            await RisingEdge(dut.clk)

    # Should be idle after stop bit
    assert dut.tx_busy.value == 0, "Should be idle after complete transmission"

    dut._log.info("Busy flag timing verified ✓")


@cocotb.test()
async def test_multiple_transmissions(dut):
    """Test back-to-back transmissions"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.baud_tick.value = 0
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    test_bytes = [0xAA, 0x55, 0xF0, 0x0F]

    for test_byte in test_bytes:
        # Start transmission
        dut.tx_data.value = test_byte
        dut.tx_start.value = 1
        await RisingEdge(dut.clk)
        dut.tx_start.value = 0
        await RisingEdge(dut.clk)

        # Capture frame
        captured_bits = []
        for _ in range(10):
            captured_bits.append(int(dut.tx_out.value))
            # Generate 16 baud ticks per bit (16x oversampling)
            for _ in range(16):
                dut.baud_tick.value = 1
                await RisingEdge(dut.clk)
                dut.baud_tick.value = 0
                await RisingEdge(dut.clk)

        # Verify
        start, data, stop = extract_frame(captured_bits)
        received_byte = bits_to_byte(data)

        assert start == 0, f"Byte {test_byte:#x}: start bit error"
        assert stop == 1, f"Byte {test_byte:#x}: stop bit error"
        assert (
            received_byte == test_byte
        ), f"Byte {test_byte:#x}: received {received_byte:#x}"

        dut._log.info(f"Byte {test_byte:#02X} transmitted correctly ✓")

    dut._log.info(f"All {len(test_bytes)} bytes transmitted successfully ✓")


@cocotb.test()
async def test_ascii_A(dut):
    """Test transmission of ASCII 'A' (0x41)"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.baud_tick.value = 0
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Transmit 'A' = 0x41 = 0b01000001
    # LSB first: D0=1, D1=0, D2=0, D3=0, D4=0, D5=0, D6=1, D7=0
    dut.tx_data.value = 0x41
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    await RisingEdge(dut.clk)

    # Capture bits
    captured_bits = []
    for _ in range(10):
        captured_bits.append(int(dut.tx_out.value))
        # Generate 16 baud ticks per bit (16x oversampling)
        for _ in range(16):
            dut.baud_tick.value = 1
            await RisingEdge(dut.clk)
            dut.baud_tick.value = 0
            await RisingEdge(dut.clk)

    # Expected: start(0), 1,0,0,0,0,0,1,0, stop(1)
    expected = [0, 1, 0, 0, 0, 0, 0, 1, 0, 1]

    for i, (captured, expected_bit) in enumerate(zip(captured_bits, expected)):
        assert (
            captured == expected_bit
        ), f"Bit {i}: expected {expected_bit}, got {captured}"

    dut._log.info("ASCII 'A' (0x41) transmitted correctly ✓")
    dut._log.info(f"Frame: {captured_bits}")
