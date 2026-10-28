"""
UART Receiver Tests

Tests the uart_rx module by sending UART frames and checking received data.
Uses uart_baud_generator to provide real baud_tick signal.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


class UARTRXTestbench:
    """Testbench for UART receiver with integrated baud generator"""

    def __init__(self, dut):
        self.dut = dut

    async def reset(self):
        """Reset the DUT"""
        self.dut.rst_n.value = 0
        self.dut.rx_in.value = 1  # Idle high
        # Don't override baud_sel here, let test control it
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst_n.value = 1
        await RisingEdge(self.dut.clk)

    async def send_byte(self, data_byte):
        """
        Send a UART byte (8N1 format).
        This is simple - just toggle rx_in at the right times.
        The baud_tick generator handles the actual timing.
        """
        # Calculate bit period in nanoseconds
        # At 70 MHz clock: 14ns period
        # At 9600 baud (default): divisor = 7291
        # Bit period = 7291 * 14ns = 102,074ns = ~102us
        # This is 16x the actual baud period since we're using 16x oversampling
        # Actual baud period = 102074 / 16 = 6379.6ns ~= 104us (close to 1/9600 = 104.17us)

        # For 9600 baud: 104.17us per bit
        # For testing, we'll use the actual divisor value
        divisor = 7291  # For 9600 baud
        clock_period_ns = 14
        bit_period_ns = divisor * clock_period_ns

        print(f"Sending byte: 0x{data_byte:02X} ({data_byte})")

        # Start bit (low)
        self.dut.rx_in.value = 0
        await Timer(bit_period_ns, units="ns")

        # Data bits (LSB first)
        for i in range(8):
            bit = (data_byte >> i) & 1
            self.dut.rx_in.value = bit
            await Timer(bit_period_ns, units="ns")

        # Stop bit (high)
        self.dut.rx_in.value = 1
        await Timer(bit_period_ns, units="ns")

        # Return to idle
        await Timer(bit_period_ns, units="ns")


@cocotb.test()
async def test_rx_single_byte(dut):
    """Test receiving a single byte"""

    # Start clock
    clock = Clock(dut.clk, 14, units="ns")  # 70 MHz
    cocotb.start_soon(clock.start())

    tb = UARTRXTestbench(dut)
    dut.baud_sel.value = 0  # Default 9600
    await tb.reset()

    # Wait for things to settle
    await Timer(1, units="us")

    # Send test byte in parallel
    test_byte = 0x55
    cocotb.start_soon(tb.send_byte(test_byte))

    # Wait for rx_ready pulse
    # Max wait: 1.5ms (enough for 1 byte at 9600 baud)
    try:
        await cocotb.triggers.with_timeout(RisingEdge(dut.rx_ready), 1500, "us")
    except cocotb.result.SimTimeoutError:
        print(
            f"DEBUG: Timeout. rx_error={dut.rx_error.value}, state={dut.rx.state.value if hasattr(dut, 'rx') else '?'}"
        )
        assert False, "Timeout waiting for rx_ready"

    # Debug: Check internal state
    print(
        f"After reception: rx_ready={int(dut.rx_ready.value)}, rx_data=0x{int(dut.rx_data.value):02X}, rx_error={int(dut.rx_error.value)}"
    )

    # Check result
    assert (
        dut.rx_data.value == test_byte
    ), f"Expected 0x{test_byte:02X}, got 0x{int(dut.rx_data.value):02X}"
    assert dut.rx_error.value == 0, "Unexpected frame error"

    print(f"✓ Correctly received 0x{test_byte:02X}")


@cocotb.test()
async def test_rx_multiple_bytes(dut):
    """Test receiving multiple bytes in sequence"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    tb = UARTRXTestbench(dut)
    dut.baud_sel.value = 0  # Default 9600
    await tb.reset()

    await Timer(1, units="us")

    test_bytes = [0x00, 0xFF, 0xAA, 0x55, 0x12, 0x34]

    for test_byte in test_bytes:
        # Clear ready flag (not needed as it is a pulse)
        await RisingEdge(dut.clk)

        # Start sending
        cocotb.start_soon(tb.send_byte(test_byte))

        # Wait for reception
        try:
            await cocotb.triggers.with_timeout(RisingEdge(dut.rx_ready), 2000, "us")
        except cocotb.result.SimTimeoutError:
            assert False, f"Timeout waiting for rx_ready for byte 0x{test_byte:02X}"

        # Check result
        # Check rx_data matches
        assert (
            dut.rx_data.value == test_byte
        ), f"Expected 0x{test_byte:02X}, got 0x{dut.rx_data.value:02X}"
        assert dut.rx_error.value == 0, f"Unexpected frame error for 0x{test_byte:02X}"

        print(f"✓ Correctly received 0x{test_byte:02X}")

        # Wait a bit between bytes
        await Timer(20, units="us")


@cocotb.test()
async def test_rx_all_baud_rates(dut):
    """Test receiver at all supported baud rates"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    tb = UARTRXTestbench(dut)

    baud_rates = {
        0: (9600, 7291),
        1: (19200, 3645),
        2: (38400, 1823),
        0xC: (115200, 607),
    }

    test_byte = 0xA5

    for baud_sel, (baud, divisor) in baud_rates.items():
        print(f"\nTesting at {baud} baud (divisor={divisor})")

        # Reset with new baud rate
        tb.dut.baud_sel.value = baud_sel
        await tb.reset()
        await Timer(1, units="us")

        # Calculate bit period for this baud rate
        clock_period_ns = 14
        bit_period_ns = divisor * clock_period_ns

        # Drive RX line manually in separate task context logic
        # Or just simulate sending here

        cocotb.start_soon(drive_rx_byte(dut, test_byte, bit_period_ns))

        # Wait for rx_ready
        try:
            # Scale timeout with baud rate
            timeout_ns = bit_period_ns * 15  # 15 bits duration (generous margin)
            timeout_us = timeout_ns / 1000
            if timeout_us < 2000:
                timeout_us = 2000  # Minimum 2ms

            await cocotb.triggers.with_timeout(
                RisingEdge(dut.rx_ready), timeout_us, "us"
            )
        except cocotb.result.SimTimeoutError:
            assert False, f"Timeout waiting for rx_ready at {baud} baud"

        # Check result
        assert (
            dut.rx_data.value == test_byte
        ), f"At {baud} baud: expected 0x{test_byte:02X}, got 0x{int(dut.rx_data.value):02X}"
        assert dut.rx_error.value == 0, f"Frame error at {baud} baud"

        print(f"✓ {baud} baud: correctly received 0x{test_byte:02X}")


async def drive_rx_byte(dut, byte, bit_period_ns):
    # Start bit
    dut.rx_in.value = 0
    await Timer(bit_period_ns, units="ns")
    # Data bits
    for i in range(8):
        bit = (byte >> i) & 1
        dut.rx_in.value = bit
        await Timer(bit_period_ns, units="ns")
    # Stop bit
    dut.rx_in.value = 1
    await Timer(bit_period_ns, units="ns")


@cocotb.test()
async def test_rx_frame_error(dut):
    """Test frame error detection (invalid stop bit)"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    tb = UARTRXTestbench(dut)
    dut.baud_sel.value = 0
    await tb.reset()

    await Timer(1, units="us")

    # Calculate bit period
    divisor = 7291
    clock_period_ns = 14
    bit_period_ns = divisor * clock_period_ns

    test_byte = 0x42

    print(f"Sending byte with invalid stop bit: 0x{test_byte:02X}")

    # Start bit
    dut.rx_in.value = 0
    await Timer(bit_period_ns, units="ns")

    # Data bits
    for i in range(8):
        bit = (test_byte >> i) & 1
        dut.rx_in.value = bit
        await Timer(bit_period_ns, units="ns")

    # INVALID stop bit (should be high, send low)
    dut.rx_in.value = 0
    await Timer(bit_period_ns, units="ns")

    # Wait for reception
    await Timer(10, units="us")

    # Check that error is flagged
    assert dut.rx_error.value == 1, "Frame error not detected"
    print("✓ Frame error correctly detected")


@cocotb.test()
async def test_rx_false_start(dut):
    """Test rejection of false start bit"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    tb = UARTRXTestbench(dut)
    dut.baud_sel.value = 0
    await tb.reset()

    await Timer(1, units="us")

    # Send a glitch (short low pulse)
    dut.rx_in.value = 0
    await Timer(500, units="ns")  # Very short pulse
    dut.rx_in.value = 1

    # Wait
    await Timer(20, units="us")

    # Should detect error or stay idle
    # rx_ready should NOT be asserted
    if dut.rx_error.value == 1:
        print("✓ False start detected as error")
    else:
        print("✓ False start ignored (still idle)")

    assert dut.rx_ready.value == 0, "Incorrectly received data from false start"
