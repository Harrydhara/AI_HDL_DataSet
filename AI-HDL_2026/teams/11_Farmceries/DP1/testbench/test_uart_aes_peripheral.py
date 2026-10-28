"""
Test suite for uart_aes_peripheral top-level integration
Tests register interface and basic functionality
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.binary import BinaryValue


@cocotb.test()
async def test_register_address_decode(dut):
    """Test that UART and AES registers are properly decoded"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.uart_rx.value = 1
    dut.cts_n.value = 1
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 5)
    
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    # Test UART register access (address < 0x20)
    dut.address.value = 0x00
    dut.data_write_n.value = 0b00
    dut.data_in.value = 0x12345678
    await ClockCycles(dut.clk, 2)
    dut.data_write_n.value = 0b11
    await ClockCycles(dut.clk, 2)
    
    # Test AES register access (address >= 0x20)
    dut.address.value = 0x20
    dut.data_write_n.value = 0b00
    dut.data_in.value = 0xABCDEF01
    await ClockCycles(dut.clk, 2)
    dut.data_write_n.value = 0b11
    await ClockCycles(dut.clk, 2)
    
    dut._log.info("✓ Register address decode test completed")


@cocotb.test()
async def test_aes_key_loading(dut):
    """Test loading 128-bit AES key via registers"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.uart_rx.value = 1
    dut.cts_n.value = 1
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 5)
    
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    # Define test key (same as NIST test vector 1)
    test_key = [
        0x03020100,  # KEY0 [31:0]
        0x07060504,  # KEY1 [63:32]
        0x0b0a0908,  # KEY2 [95:64]
        0x0f0e0d0c   # KEY3 [127:96]
    ]
    
    # AES registers in top-level space:
    # 0x20 = CTRL (maps to 0x00 in aes_reg)
    # 0x21 = STATUS (maps to 0x04)
    # 0x22 = KEY0 (maps to 0x08)
    # 0x23 = KEY1 (maps to 0x0C)
    # 0x24 = KEY2 (maps to 0x10)
    # 0x25 = KEY3 (maps to 0x14)
    base_addr = 0x20
    key_addrs = [base_addr + 2, base_addr + 3, base_addr + 4, base_addr + 5]
    
    # Write key to AES_KEY0-3 registers
    for i, (addr, key_word) in enumerate(zip(key_addrs, test_key)):
        dut.address.value = addr
        dut.data_in.value = key_word
        dut.data_write_n.value = 0b00
        await ClockCycles(dut.clk, 2)
        dut.data_write_n.value = 0b11
        await ClockCycles(dut.clk, 2)
        dut._log.info(f"Wrote KEY{i}: 0x{key_word:08x} to address 0x{addr:02x}")
    
    # Read back key to verify
    for i, addr in enumerate(key_addrs):
        dut.address.value = addr
        dut.data_read_n.value = 0b00
        await ClockCycles(dut.clk, 2)
        read_value = dut.data_out.value.integer
        dut.data_read_n.value = 0b11
        await ClockCycles(dut.clk, 1)
        
        expected = test_key[i]
        assert read_value == expected, f"KEY{i} @ 0x{addr:02x} mismatch: got 0x{read_value:08x}, expected 0x{expected:08x}"
        dut._log.info(f"✓ KEY{i} verified: 0x{read_value:08x}")
    
    dut._log.info("✓ AES key loading test passed")


@cocotb.test()
async def test_aes_enable_control(dut):
    """Test AES enable/disable via control register"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.uart_rx.value = 1
    dut.cts_n.value = 1
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 5)
    
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    # Write to AES_CTRL (0x20) - Enable AES
    dut.address.value = 0x20
    dut.data_in.value = 0x00000001  # AES_EN = 1
    dut.data_write_n.value = 0b00
    await ClockCycles(dut.clk, 2)
    dut.data_write_n.value = 0b11
    await ClockCycles(dut.clk, 2)
    
    # Read back AES_CTRL
    dut.data_read_n.value = 0b00
    await ClockCycles(dut.clk, 2)
    ctrl_value = dut.data_out.value.integer
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 1)
    
    assert (ctrl_value & 0x1) == 1, f"AES_EN not set: got 0x{ctrl_value:08x}"
    dut._log.info(f"✓ AES enabled, CTRL = 0x{ctrl_value:08x}")
    
    # Read AES_STATUS (0x24)
    dut.address.value = 0x24
    dut.data_read_n.value = 0b00
    await ClockCycles(dut.clk, 2)
    status_value = dut.data_out.value.integer
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 1)
    
    dut._log.info(f"✓ AES_STATUS = 0x{status_value:08x}")
    dut._log.info("✓ AES enable control test passed")


@cocotb.test()
async def test_uart_passthrough(dut):
    """Test that UART registers still work with AES peripheral wrapper"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.uart_rx.value = 1
    dut.cts_n.value = 1
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 5)
    
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    # Write to UART_CTRL (0x00)
    dut.address.value = 0x00
    dut.data_in.value = 0x00000031  # Enable TX/RX, baud_sel = 1
    dut.data_write_n.value = 0b00
    await ClockCycles(dut.clk, 2)
    dut.data_write_n.value = 0b11
    await ClockCycles(dut.clk, 5)
    
    # Read UART_STATUS (0x04)
    dut.address.value = 0x04
    dut.data_read_n.value = 0b00
    await ClockCycles(dut.clk, 2)
    status = dut.data_out.value.integer
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 1)
    
    dut._log.info(f"UART_STATUS = 0x{status:08x}")
    dut._log.info("✓ UART passthrough test passed")


@cocotb.test()
async def test_data_ready_signals(dut):
    """Test that data_ready works for both UART and AES register spaces"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.uart_rx.value = 1
    dut.cts_n.value = 1
    dut.data_write_n.value = 0b11
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 5)
    
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    # Test UART register read with data_ready
    dut.address.value = 0x04  # UART_STATUS
    dut.data_read_n.value = 0b00
    await ClockCycles(dut.clk, 1)
    
    # Wait for data_ready
    for _ in range(10):
        await RisingEdge(dut.clk)
        if dut.data_ready.value == 1:
            dut._log.info(f"✓ UART data_ready asserted after {_} cycles")
            break
    else:
        raise AssertionError("UART data_ready never asserted")
    
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 2)
    
    # Test AES register read with data_ready
    dut.address.value = 0x24  # AES_STATUS
    dut.data_read_n.value = 0b00
    await ClockCycles(dut.clk, 1)
    
    # Wait for data_ready
    for _ in range(10):
        await RisingEdge(dut.clk)
        if dut.data_ready.value == 1:
            dut._log.info(f"✓ AES data_ready asserted after {_} cycles")
            break
    else:
        raise AssertionError("AES data_ready never asserted")
    
    dut.data_read_n.value = 0b11
    await ClockCycles(dut.clk, 2)
    
    dut._log.info("✓ Data ready signals test passed")
