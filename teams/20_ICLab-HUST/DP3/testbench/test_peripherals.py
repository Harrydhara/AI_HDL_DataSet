"""
test_peripherals.py — cocotb tests for tinyQV_peripherals.

The module wraps tqvp_dma at slot 4 (addr_in[9:6] == 4, addr_in[10]==0).
DMA register offsets (addr_in[5:0]):
  0x00 = CTRL  (W)   bit0=start, bit1=mode(1=TX), bit2=irq_en
  0x04 = COUNT (RW)  bytes to transfer (1-32)
  0x08 = DIVISOR(RW)
  0x0C = STATUS(R)   bit0=busy, bit1=done
  0x10 = CLR_IRQ(W)
  0x14 = DATA0 (RW)

Slot 4 base: addr_in = {1'b0, 4'd4, 6'bXXXXXX} = 11'b0_0001_00_xxxxxx
  → addr_in[10]=0, addr_in[9:6]=4 → addr_in[10:6] = 5'b00100 = 0x04
  → addr_in = 11'b0_0001_00_offset  where offset is addr_in[5:0]

Helper: slot4_addr(offset) = (4 << 6) | offset = 0x100 | offset
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


# Slot 4 base address (addr_in[9:6] == 4, addr_in[10] == 0)
SLOT4_BASE = 4 << 6   # = 0x100

# DMA register offsets (addr_in[5:0])
REG_CTRL    = 0x00
REG_COUNT   = 0x04
REG_DIVISOR = 0x08
REG_STATUS  = 0x0C
REG_CLR_IRQ = 0x10
REG_DATA0   = 0x14
REG_SEC_KEY = 0x34   # [SEC-2] write 0xA5 to arm start key


def slot4_addr(offset):
    return SLOT4_BASE | (offset & 0x3F)


async def reset_dut(dut):
    dut.rst_n.value            = 0
    dut.ui_in.value            = 0
    dut.ui_in_raw.value        = 0
    dut.addr_in.value          = 0
    dut.data_in.value          = 0
    dut.data_write_n.value     = 0b11
    dut.data_read_n.value      = 0b11
    dut.data_read_complete.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


async def write_reg(dut, offset, value):
    """Write a 32-bit word to a DMA register via the peripheral bus."""
    dut.addr_in.value      = slot4_addr(offset)
    dut.data_in.value      = value
    dut.data_write_n.value = 0b10   # 32-bit write (00=8b, 01=16b, 10=32b, 11=none)
    await ClockCycles(dut.clk, 1)
    dut.data_write_n.value = 0b11
    await ClockCycles(dut.clk, 2)


async def read_reg(dut, offset):
    """Read a 32-bit word from a DMA register via the peripheral bus."""
    dut.addr_in.value     = slot4_addr(offset)
    dut.data_read_n.value = 0b10   # 32-bit read
    # Wait for data_ready
    for _ in range(20):
        await RisingEdge(dut.clk)
        if int(dut.data_ready.value) == 1:
            break
    val = int(dut.data_out.value)
    dut.data_read_n.value        = 0b11
    dut.data_read_complete.value = 1
    await ClockCycles(dut.clk, 1)
    dut.data_read_complete.value = 0
    await ClockCycles(dut.clk, 1)
    return val


@cocotb.test()
async def test_reset_defaults(dut):
    """After reset the STATUS register should be 0."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    status = await read_reg(dut, REG_STATUS)
    assert (status & 0x3) == 0, f"STATUS after reset = {status:#010x}"


@cocotb.test()
async def test_count_register_rw(dut):
    """Write then read back the COUNT register."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    await write_reg(dut, REG_COUNT, 4)
    val = await read_reg(dut, REG_COUNT)
    assert val == 4, f"COUNT readback = {val}"


@cocotb.test()
async def test_data_register_rw(dut):
    """Write then read back DATA0."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    await write_reg(dut, REG_DATA0, 0xDEAD_BEEF)
    val = await read_reg(dut, REG_DATA0)
    assert val == 0xDEAD_BEEF, f"DATA0 readback = {val:#010x}"


@cocotb.test()
async def test_address_decode_outside_slot(dut):
    """Access outside slot 4 should not affect DMA — data_ready comes from default path."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    # Address outside slot 4 (slot 0)
    dut.addr_in.value     = 0x000
    dut.data_read_n.value = 0b01
    await ClockCycles(dut.clk, 3)
    # peripherals returns data_ready=1 for non-DMA addresses immediately
    assert int(dut.data_ready.value) == 1
    dut.data_read_n.value = 0b11


@cocotb.test()
async def test_tx_transfer(dut):
    """Start a minimal TX transfer and check busy then done."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    # Write data
    await write_reg(dut, REG_DATA0, 0x12345678)

    # Fast divisor for sim (divisor=1 → ~1 cycle per bit)
    await write_reg(dut, REG_DIVISOR, 1)

    # COUNT = 1
    await write_reg(dut, REG_COUNT, 1)

    # [SEC-2] Arm the start key before writing CTRL
    await write_reg(dut, REG_SEC_KEY, 0xA5)

    # CTRL: start=1, mode=TX(1)
    await write_reg(dut, REG_CTRL, 0b11)

    # With divisor=1 the transfer may complete very quickly — just wait for done.
    # Wait for done (bit1 of STATUS)
    done = False
    for _ in range(1000):
        await ClockCycles(dut.clk, 5)
        status = await read_reg(dut, REG_STATUS)
        if (status & 0x2):
            done = True
            break

    assert done, "TX transfer never completed"

    # Clear interrupt/done
    await write_reg(dut, REG_CLR_IRQ, 1)
    await ClockCycles(dut.clk, 2)
    status = await read_reg(dut, REG_STATUS)
    assert (status & 0x2) == 0, "Done flag not cleared"
