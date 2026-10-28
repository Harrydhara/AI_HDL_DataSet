"""
test_time.py — cocotb tests for tinyQV_time.

Module behaviour:
  - mtime increments by 1 on every posedge clk when time_pulse is high
  - set_mtime  loads data_in into mtime on the next posedge
  - set_mtimecmp loads data_in into mtimecmp (via latch_reg32_p) on next posedge
  - timer_interrupt is high when 0 <= (mtime - mtimecmp) < 2^30
    i.e. when mtime >= mtimecmp (roughly, ignoring the 2^30 upper bound)
  - data_out = mtimecmp when read_mtimecmp=1, else mtime
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


async def reset_dut(dut):
    dut.rstn.value         = 0
    dut.time_pulse.value   = 0
    dut.set_mtime.value    = 0
    dut.set_mtimecmp.value = 0
    dut.data_in.value      = 0
    dut.read_mtimecmp.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rstn.value = 1
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def test_reset_values(dut):
    """After reset mtime=0 and timer_interrupt should be low."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    dut.read_mtimecmp.value = 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.data_out.value) == 0, \
        f"mtime after reset = {int(dut.data_out.value)}"


@cocotb.test()
async def test_mtime_increment(dut):
    """mtime increments by 1 each time time_pulse is asserted for one cycle."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)
    dut.read_mtimecmp.value = 0

    for expected in range(1, 11):
        dut.time_pulse.value = 1
        await ClockCycles(dut.clk, 1)
        dut.time_pulse.value = 0
        await ClockCycles(dut.clk, 1)   # let output settle
        assert int(dut.data_out.value) == expected, \
            f"mtime={int(dut.data_out.value)}, expected {expected}"


@cocotb.test()
async def test_set_mtime(dut):
    """set_mtime loads data_in into mtime."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)
    dut.read_mtimecmp.value = 0

    dut.set_mtime.value = 1
    dut.data_in.value   = 0xDEAD_BEEF
    await ClockCycles(dut.clk, 1)
    dut.set_mtime.value = 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.data_out.value) == 0xDEAD_BEEF, \
        f"mtime={int(dut.data_out.value):#010x}"


@cocotb.test()
async def test_set_mtimecmp(dut):
    """set_mtimecmp stores into mtimecmp; read back via read_mtimecmp."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    dut.set_mtimecmp.value  = 1
    dut.data_in.value       = 0x1234_5678
    await ClockCycles(dut.clk, 2)
    dut.set_mtimecmp.value  = 0

    dut.read_mtimecmp.value = 1
    await ClockCycles(dut.clk, 1)
    assert int(dut.data_out.value) == 0x1234_5678, \
        f"mtimecmp={int(dut.data_out.value):#010x}"


@cocotb.test()
async def test_timer_interrupt_triggered(dut):
    """timer_interrupt goes high when mtime >= mtimecmp.

    latch_reg_p is level-sensitive in SIM mode: state tracks data_in whenever
    clk=HIGH and latched_wen=1.  latched_wen is captured at the falling edge.
    After de-asserting set_mtimecmp we wait 2 extra clock cycles so the next
    falling edge clears latched_wen before we change data_in for set_mtime,
    preventing data_in corruption of mtimecmp.
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    # Set mtimecmp = 10
    dut.set_mtimecmp.value = 1
    dut.data_in.value      = 10
    await ClockCycles(dut.clk, 2)
    dut.set_mtimecmp.value = 0
    # Extra cycles so the falling edge clears latched_wen before data_in changes
    await ClockCycles(dut.clk, 2)

    # mtime is already 0 after reset; comparison = 0-10 = 0xFFFFFFF6, [31:30]=11 → low
    await ClockCycles(dut.clk, 2)
    assert int(dut.timer_interrupt.value) == 0, \
        "Interrupt should be low when mtime(0) < mtimecmp(10)"

    # Pulse mtime up to 10
    for _ in range(10):
        dut.time_pulse.value = 1
        await ClockCycles(dut.clk, 1)
        dut.time_pulse.value = 0
        await ClockCycles(dut.clk, 1)

    # mtime == mtimecmp == 10 → comparison = 0, [31:30]=00 → interrupt fires
    await ClockCycles(dut.clk, 2)
    assert int(dut.timer_interrupt.value) == 1, \
        "Interrupt expected high when mtime == mtimecmp == 10"


@cocotb.test()
async def test_timer_interrupt_cleared_by_updating_mtimecmp(dut):
    """Moving mtimecmp ahead of mtime clears the interrupt.

    Interrupt condition: 0 <= (mtime - mtimecmp) mod 2^32 < 2^30.
    So 0xFFFFFFFF is NOT a safe "far ahead" value: mtime=10 - mtimecmp=0xFFFFFFFF
    = 11 (wraps), which is in [0, 2^30) → interrupt stays high.
    Use mtimecmp = 100: comparison = 10-100 = 0xFFFFFFA6, [31:30]=11 → low.

    Same latch-corruption protection: wait 2 cycles after de-asserting
    set_mtime before asserting set_mtimecmp.
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    # Force mtime=10
    dut.set_mtime.value = 1
    dut.data_in.value   = 10
    await ClockCycles(dut.clk, 1)
    dut.set_mtime.value = 0
    await ClockCycles(dut.clk, 2)   # let latched_wen clear before changing data_in

    # Set mtimecmp = 5 → mtime(10) > mtimecmp(5) → interrupt fires
    dut.set_mtimecmp.value = 1
    dut.data_in.value      = 5
    await ClockCycles(dut.clk, 2)
    dut.set_mtimecmp.value = 0
    await ClockCycles(dut.clk, 2)
    assert int(dut.timer_interrupt.value) == 1, \
        "Interrupt expected high when mtime(10) >= mtimecmp(5)"

    # Move mtimecmp = 100 → comparison = 10-100 = 0xFFFFFFA6, [31:30]=11 → low
    dut.set_mtimecmp.value = 1
    dut.data_in.value      = 100
    await ClockCycles(dut.clk, 2)
    dut.set_mtimecmp.value = 0
    await ClockCycles(dut.clk, 2)
    assert int(dut.timer_interrupt.value) == 0, \
        "Interrupt should clear when mtimecmp(100) > mtime(10)"
