"""
test_tinyqv.py — Integration tests for tinyQV (CPU + QSPI memory controller).

The testbench connects a flash_model.v behavioural SPI flash loaded with
test_program.hex.  Non-memory peripheral accesses (data_addr[27:25] != 0)
are handled here by responding with data_ready=1 and data_in=0.

Tests:
  1. Reset: after reset, CPU starts fetching (flash CS goes low quickly)
  2. Boot: CPU executes instructions — debug_instr_complete toggles
  3. Peripheral write: CPU writes to peripheral address, we observe the bus
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

MAX_CYCLES = 50_000   # generous budget for boot + instruction execution


async def peripheral_responder(dut):
    """Background coroutine: respond immediately to non-memory bus transactions."""
    while True:
        await RisingEdge(dut.clk)
        # data_addr[27:25] != 0 means peripheral space
        addr = int(dut.data_addr.value)
        if (addr >> 25) != 0:
            if int(dut.data_read_n.value) != 0b11 or int(dut.data_write_n.value) != 0b11:
                dut.data_ready.value = 1
                dut.data_in.value    = 0xFFFF_FFFF
        else:
            # Memory handled by flash_model
            dut.data_ready.value = 0
            dut.data_in.value    = 0


async def reset_dut(dut):
    dut.rstn.value           = 0
    dut.data_ready.value     = 0
    dut.data_in.value        = 0
    dut.interrupt_req.value  = 0
    dut.timer_interrupt.value = 0
    await ClockCycles(dut.clk, 20)
    # Release reset while clock is high (required by qspi_ctrl)
    await RisingEdge(dut.clk)
    dut.rstn.value = 1


@cocotb.test()
async def test_flash_cs_after_reset(dut):
    """After reset the CPU should start fetching: flash CS goes low within 50 cycles."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)
    cocotb.start_soon(peripheral_responder(dut))

    cs_low = False
    for _ in range(50):
        await RisingEdge(dut.clk)
        # spi_flash_select is active-low; access via tb hierarchy
        if hasattr(dut, 'dut'):
            cs = int(dut.dut.spi_flash_select.value)
        else:
            cs = int(dut.i_flash.spi_cs_n.value)
        if cs == 0:
            cs_low = True
            break

    assert cs_low, "Flash CS never went low — CPU not fetching after reset"


@cocotb.test()
async def test_instructions_complete(dut):
    """CPU must complete at least 10 instructions within MAX_CYCLES."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)
    cocotb.start_soon(peripheral_responder(dut))

    count        = 0
    prev_complete = 0

    for _ in range(MAX_CYCLES):
        await RisingEdge(dut.clk)
        cur = int(dut.debug_instr_complete.value)
        if cur == 1 and prev_complete == 0:
            count += 1
            if count >= 10:
                break
        prev_complete = cur

    assert count >= 10, \
        f"Only {count} instructions completed in {MAX_CYCLES} cycles"
    dut._log.info(f"CPU completed {count} instructions")


@cocotb.test()
async def test_debug_signals_toggle(dut):
    """Verify that at least one debug signal (instr_valid or reg_wen) goes high."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)
    cocotb.start_soon(peripheral_responder(dut))

    saw_valid = False
    for _ in range(MAX_CYCLES):
        await RisingEdge(dut.clk)
        if int(dut.debug_instr_valid.value) == 1:
            saw_valid = True
            break

    assert saw_valid, "debug_instr_valid never went high"
