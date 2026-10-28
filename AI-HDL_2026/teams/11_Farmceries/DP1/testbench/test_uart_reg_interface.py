"""
UART Register Interface Tests

Tests the memory-mapped register interface for UART control.
Verifies CPU can read/write UART control/status/data registers.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_register_write_read(dut):
    """Test basic register write and read operations"""

    clock = Clock(dut.clk, 14, units="ns")  # 70 MHz
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.address.value = 0
    dut.data_in.value = 0
    dut.data_write_n.value = 0b11  # No write
    dut.data_read_n.value = 0b11  # No read
    dut.tx_busy.value = 0
    dut.rx_data.value = 0
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Test 1: Write to CTRL register (addr 0x00)
    print("\nTest 1: Write CTRL register")
    dut.address.value = 0x00
    dut.data_in.value = 0x01  # Set baud_sel=1 (19200 baud)
    dut.data_write_n.value = 0b00  # 8-bit write
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 0b11  # End write
    await RisingEdge(dut.clk)

    # Read back CTRL register
    dut.data_read_n.value = 0b00  # 8-bit read
    await RisingEdge(dut.clk)
    read_value = int(dut.data_out.value)
    print(f"  CTRL read: 0x{read_value:08X}")
    assert (
        read_value & 0x0F
    ) == 0x01, f"CTRL mismatch: expected 0x01, got 0x{read_value & 0x0F:02X}"
    dut.data_read_n.value = 0b11

    # Verify baud_sel output
    assert dut.baud_sel.value == 0x1, f"baud_sel should be 1, got {dut.baud_sel.value}"
    print("  ✓ CTRL register working")

    # Test 2: Write to TX_DATA (addr 0x08)
    print("\nTest 2: Write TX_DATA register")
    dut.address.value = 0x08
    dut.data_in.value = 0x42
    dut.data_write_n.value = 0b00
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 0b11

    # Check tx_start pulse (should be high for 1 cycle after write)
    await RisingEdge(dut.clk)
    assert dut.tx_start.value == 1, "tx_start should pulse high"
    assert (
        dut.tx_data.value == 0x42
    ), f"tx_data should be 0x42, got 0x{int(dut.tx_data.value):02X}"
    print(f"  tx_start pulsed, tx_data=0x{int(dut.tx_data.value):02X}")

    await RisingEdge(dut.clk)

    # tx_start should clear after 1 cycle
    assert dut.tx_start.value == 0, "tx_start should return to 0"
    print("  ✓ TX_DATA write triggers tx_start pulse")

    # Test 3: Read STATUS register (addr 0x04)
    print("\nTest 3: Read STATUS register")
    dut.tx_busy.value = 1  # Simulate TX busy
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    dut.address.value = 0x04
    dut.data_read_n.value = 0b00
    await RisingEdge(dut.clk)

    status = int(dut.data_out.value)
    print(f"  STATUS: 0x{status:08X}")
    assert (status & 0x01) == 1, "STATUS[0] should reflect tx_busy=1"
    assert (status & 0x02) == 0, "STATUS[1] should reflect rx_ready=0"
    print("  ✓ STATUS register reflects hardware state")

    dut.data_read_n.value = 0b11

    # Test 4: RX_DATA read with rx_ready
    print("\nTest 4: RX_DATA read")
    dut.address.value = 0x0C
    dut.rx_data.value = 0xAB
    dut.rx_ready.value = 1

    await RisingEdge(dut.clk)

    # RX data should be latched
    dut.rx_ready.value = 0  # Clear ready
    await RisingEdge(dut.clk)

    # Read RX_DATA
    dut.data_read_n.value = 0b00
    await RisingEdge(dut.clk)

    rx_val = int(dut.data_out.value)
    print(f"  RX_DATA: 0x{rx_val:08X}")
    assert (rx_val & 0xFF) == 0xAB, f"RX_DATA should be 0xAB, got 0x{rx_val & 0xFF:02X}"
    print("  ✓ RX_DATA latches received data")

    print("\n✅ All register interface tests passed!")


@cocotb.test()
async def test_interrupt_generation(dut):
    """Test interrupt enable and status"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.address.value = 0
    dut.data_in.value = 0
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    dut.tx_busy.value = 0
    dut.rx_data.value = 0
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Initially, interrupts should be disabled and no interrupt
    assert dut.uart_interrupt.value == 0, "Interrupt should be 0 initially"

    # Enable RX interrupt (INT_EN[1] = 1)
    print("\nEnabling RX interrupt")
    dut.address.value = 0x10  # INT_EN
    dut.data_in.value = 0x02  # Enable RX ready interrupt
    dut.data_write_n.value = 0b00
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 0b11
    await RisingEdge(dut.clk)

    # Trigger RX ready
    print("Triggering RX ready")
    dut.rx_data.value = 0x55
    dut.rx_ready.value = 1
    await RisingEdge(dut.clk)
    dut.rx_ready.value = 0
    await RisingEdge(dut.clk)

    # Interrupt should now be asserted
    assert dut.uart_interrupt.value == 1, "Interrupt should be asserted after RX ready"
    print("  ✓ Interrupt asserted")

    # Clear interrupt by writing to INT_CLR
    print("Clearing RX interrupt")
    dut.address.value = 0x14  # INT_CLR
    dut.data_in.value = 0x02  # Clear RX interrupt
    dut.data_write_n.value = 0b00
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 0b11
    await RisingEdge(dut.clk)

    # Interrupt should be cleared
    assert dut.uart_interrupt.value == 0, "Interrupt should be cleared"
    print("  ✓ Interrupt cleared")

    print("\n✅ Interrupt test passed!")


@cocotb.test()
async def test_baud_rate_selection(dut):
    """Test all baud rate selections"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.address.value = 0
    dut.data_in.value = 0
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    dut.tx_busy.value = 0
    dut.rx_data.value = 0
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    baud_configs = {0x0: "9600", 0x1: "19200", 0x2: "38400", 0xC: "115200"}

    for sel, baud_name in baud_configs.items():
        print(f"\nTesting baud_sel={sel} ({baud_name} baud)")

        # Write to CTRL register
        dut.address.value = 0x00
        dut.data_in.value = sel
        dut.data_write_n.value = 0b00
        await RisingEdge(dut.clk)
        dut.data_write_n.value = 0b11
        await RisingEdge(dut.clk)

        # Verify baud_sel output
        assert (
            dut.baud_sel.value == sel
        ), f"baud_sel should be {sel}, got {dut.baud_sel.value}"
        print(f"  ✓ baud_sel={sel} set correctly")

    print("\n✅ All baud rates tested!")


@cocotb.test()
async def test_tx_busy_blocking(dut):
    """Test that multiple TX writes while busy are handled correctly"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.address.value = 0
    dut.data_in.value = 0
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    dut.tx_busy.value = 0
    dut.rx_data.value = 0
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    print("\nTest: Write TX_DATA then simulate busy")

    # Write first byte
    dut.address.value = 0x08
    dut.data_in.value = 0x11
    dut.data_write_n.value = 0b00
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 0b11
    await RisingEdge(dut.clk)

    assert dut.tx_start.value == 1, "First tx_start should pulse"
    await RisingEdge(dut.clk)

    # Simulate TX becomes busy
    dut.tx_busy.value = 1
    await RisingEdge(dut.clk)

    # Try to write second byte while busy
    dut.data_in.value = 0x22
    dut.data_write_n.value = 0b00
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 0b11
    await RisingEdge(dut.clk)

    # tx_start should still pulse (CPU can write, TX module handles busy)
    assert dut.tx_start.value == 1, "tx_start pulses even if busy"
    assert dut.tx_data.value == 0x22, "tx_data updated to new value"
    print("  ✓ TX writes accepted (TX module handles busy)")

    await RisingEdge(dut.clk)
    dut.tx_busy.value = 0

    print("✅ TX busy handling verified")


@cocotb.test()
async def test_rx_data_overrun(dut):
    """Test RX data overrun - new data arrives before old is read"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.address.value = 0
    dut.data_in.value = 0
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    dut.tx_busy.value = 0
    dut.rx_data.value = 0
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    print("\nTest: RX data overrun")

    # First RX byte
    dut.rx_data.value = 0xAA
    dut.rx_ready.value = 1
    await RisingEdge(dut.clk)
    dut.rx_ready.value = 0
    await RisingEdge(dut.clk)

    # Second RX byte arrives before first is read
    dut.rx_data.value = 0xBB
    dut.rx_ready.value = 1
    await RisingEdge(dut.clk)
    dut.rx_ready.value = 0
    await RisingEdge(dut.clk)

    # Read RX_DATA - should get most recent (0xBB)
    dut.address.value = 0x0C
    dut.data_read_n.value = 0b00
    await RisingEdge(dut.clk)

    rx_val = int(dut.data_out.value) & 0xFF
    print(f"  RX_DATA after overrun: 0x{rx_val:02X}")
    assert rx_val == 0xBB, f"Should get most recent data (0xBB), got 0x{rx_val:02X}"
    print("  ✓ RX overrun: latest data preserved")

    print("✅ RX overrun test passed")


@cocotb.test()
async def test_error_flag_propagation(dut):
    """Test that RX error flag propagates to STATUS register"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.address.value = 0
    dut.data_in.value = 0
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    dut.tx_busy.value = 0
    dut.rx_data.value = 0
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    print("\nTest: RX error flag in STATUS")

    # Simulate RX error
    dut.rx_error.value = 1
    await RisingEdge(dut.clk)

    # Read STATUS register
    dut.address.value = 0x04
    dut.data_read_n.value = 0b00
    await RisingEdge(dut.clk)

    status = int(dut.data_out.value)
    print(f"  STATUS with rx_error: 0x{status:08X}")
    assert (status & 0x04) != 0, "STATUS[2] should reflect rx_error=1"
    print("  ✓ RX error flag visible in STATUS")

    # Clear error
    dut.rx_error.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    status = int(dut.data_out.value)
    assert (status & 0x04) == 0, "STATUS[2] should clear when rx_error=0"
    print("  ✓ RX error flag cleared")

    print("✅ Error flag propagation verified")


@cocotb.test()
async def test_all_register_addresses(dut):
    """Comprehensive test of all register addresses"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.address.value = 0
    dut.data_in.value = 0
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    dut.tx_busy.value = 0
    dut.rx_data.value = 0
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    print("\nTest: All register addresses")

    # Test each defined register
    registers = {
        0x00: "CTRL",
        0x04: "STATUS",
        0x08: "TX_DATA",
        0x0C: "RX_DATA",
        0x10: "INT_EN",
        0x14: "INT_CLR",
    }

    for addr, name in registers.items():
        dut.address.value = addr
        dut.data_read_n.value = 0b00
        await RisingEdge(dut.clk)

        data = int(dut.data_out.value)
        print(f"  {name} (0x{addr:02X}): 0x{data:08X}")

        dut.data_read_n.value = 0b11
        await RisingEdge(dut.clk)

    # Test unmapped address (should return 0)
    print("\n  Testing unmapped address 0x20:")
    dut.address.value = 0x20
    dut.data_read_n.value = 0b00
    await RisingEdge(dut.clk)

    data = int(dut.data_out.value)
    print(f"  Unmapped (0x20): 0x{data:08X}")
    assert data == 0, "Unmapped address should return 0"
    print("  ✓ Unmapped addresses return 0")

    print("\n✅ All register addresses verified")


@cocotb.test()
async def test_reset_state(dut):
    """Test that all registers reset to correct initial values"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.address.value = 0
    dut.data_in.value = 0
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    dut.tx_busy.value = 0
    dut.rx_data.value = 0
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    # Assert reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    print("\nTest: Reset state verification")

    # Check outputs during reset
    assert dut.tx_start.value == 0, "tx_start should be 0 after reset"
    assert dut.baud_sel.value == 0, "baud_sel should be 0 after reset"
    assert dut.uart_interrupt.value == 0, "interrupt should be 0 after reset"
    print("  ✓ Control signals cleared")

    # Release reset
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Read CTRL register (should be 0)
    dut.address.value = 0x00
    dut.data_read_n.value = 0b00
    await RisingEdge(dut.clk)
    assert (int(dut.data_out.value) & 0xFF) == 0, "CTRL should reset to 0"
    print("  ✓ CTRL register = 0x00")

    # Read INT_EN register (should be 0)
    dut.address.value = 0x10
    await RisingEdge(dut.clk)
    assert (int(dut.data_out.value) & 0xFF) == 0, "INT_EN should reset to 0"
    print("  ✓ INT_EN register = 0x00")

    print("\n✅ Reset state verified")


@cocotb.test()
async def test_write_sizes(dut):
    """Test different write sizes (8-bit, 16-bit, 32-bit)"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.address.value = 0
    dut.data_in.value = 0
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    dut.tx_busy.value = 0
    dut.rx_data.value = 0
    dut.rx_ready.value = 0
    dut.rx_error.value = 0

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    print("\nTest: Different write sizes")

    # 8-bit write to CTRL
    print("  Testing 8-bit write...")
    dut.address.value = 0x00
    dut.data_in.value = 0xDEADBEEF
    dut.data_write_n.value = 0b00  # 8-bit
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 0b11
    await RisingEdge(dut.clk)

    dut.data_read_n.value = 0b00
    await RisingEdge(dut.clk)
    ctrl_val = int(dut.data_out.value) & 0xFF
    print(f"  8-bit write result: 0x{ctrl_val:02X}")
    assert ctrl_val == 0xEF, f"Should only write low byte, got 0x{ctrl_val:02X}"
    print("  ✓ 8-bit write works")

    # 16-bit write
    print("  Testing 16-bit write...")
    dut.data_in.value = 0x1234
    dut.data_write_n.value = 0b01  # 16-bit
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 0b11
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    ctrl_val = int(dut.data_out.value) & 0xFF
    print(f"  16-bit write result: 0x{ctrl_val:02X}")
    # For 8-bit register, still only low byte
    assert ctrl_val == 0x34, f"Should write low byte, got 0x{ctrl_val:02X}"
    print("  ✓ 16-bit write works")

    # 32-bit write
    print("  Testing 32-bit write...")
    dut.data_in.value = 0xAB
    dut.data_write_n.value = 0b10  # 32-bit
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 0b11
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    ctrl_val = int(dut.data_out.value) & 0xFF
    print(f"  32-bit write result: 0x{ctrl_val:02X}")
    assert ctrl_val == 0xAB, f"Should write low byte, got 0x{ctrl_val:02X}"
    print("  ✓ 32-bit write works")

    print("\n✅ All write sizes verified")
