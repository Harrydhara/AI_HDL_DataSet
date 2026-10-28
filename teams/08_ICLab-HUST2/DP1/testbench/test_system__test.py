# SPDX-License-Identifier: Apache-2.0
# System-level test cho tt_um_tt_tinyQV với Winograd peripheral (slot 14)
# Tất cả tests trong 1 @cocotb.test() để tránh vấn đề re-init CPU giữa các tests

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from riscvmodel.insn import (
    InstructionSW, InstructionLW, InstructionADDI, InstructionLUI,
)
from riscvmodel.regnames import x0, a0, tp

from test_util import reset, start_read, send_instr, read_reg, load_reg

# ── Peripheral base (slot 14 × 0x40) ──────────────────────────────────────────
BASE        = 0x380
CTRL        = BASE + 0x00
STATUS      = BASE + 0x04
CONFIG      = BASE + 0x08
INPUT_IDX   = BASE + 0x0C
INPUT_DATA  = BASE + 0x10
FILTER_IDX  = BASE + 0x14
FILTER_DATA = BASE + 0x18
OUTPUT      = [BASE + 0x1C + i*4 for i in range(4)]
ACC         = [BASE + 0x2C + i*4 for i in range(4)]

CTRL_START     = 0x01
CTRL_ACCUM_EN  = 0x08
CTRL_CLEAR_ACC = 0x10
CTRL_IRQ_EN    = 0x20
STATUS_BUSY    = 0x01
STATUS_DONE    = 0x02

def to_fx(v): return int(round(v * (1 << 16))) & 0xFFFFFFFF
def from_fx(r):
    if r & 0x80000000: r -= 0x100000000
    return r / (1 << 16)

async def nop(dut, n=1):
    for _ in range(n):
        await send_instr(dut, InstructionADDI(x0, x0, 0).encode())

async def wr(dut, off, val):
    await load_reg(dut, a0, val & 0xFFFFFFFF)
    await send_instr(dut, InstructionSW(tp, a0, off).encode())
    await read_reg(dut, a0)   # re-sync CPU sau SW

async def rd(dut, off):
    await send_instr(dut, InstructionLW(a0, tp, off).encode())
    return int(await read_reg(dut, a0)) & 0xFFFFFFFF

async def wait_done(dut, timeout=30):
    await nop(dut, 300)       # chờ core tính xong (~200 cycles)
    for _ in range(timeout):
        s = await rd(dut, STATUS)
        if s & STATUS_DONE:
            return True
        await nop(dut, 50)
    dut._log.error("TIMEOUT waiting for done")
    return False

async def load_inputs(dut, values):
    await wr(dut, INPUT_IDX, 0)
    for v in values:
        await wr(dut, INPUT_DATA, to_fx(v))

async def load_filters(dut, values):
    await wr(dut, FILTER_IDX, 0)
    for v in values:
        await wr(dut, FILTER_DATA, to_fx(v))

async def run_channel(dut, inputs, filters, accum=False):
    await load_filters(dut, filters)
    await load_inputs(dut, inputs)
    ctrl = (CTRL_START | CTRL_ACCUM_EN) if accum else CTRL_START
    await wr(dut, CTRL, ctrl)
    ok = await wait_done(dut)
    await wr(dut, STATUS, 0)   # ack DONE
    return ok

async def peri_clear(dut):
    await wr(dut, CTRL, CTRL_CLEAR_ACC)
    await nop(dut, 5)
    await wr(dut, STATUS, 0)

# ══════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_winograd_system(dut):
    """System-level Winograd tests — toàn bộ trong 1 session"""

    # ── Init CPU (1 lần duy nhất) ─────────────────────────────────────────────
    cocotb.start_soon(Clock(dut.clk, 15.624, units="ns").start())
    await reset(dut)
    await ClockCycles(dut.clk, 1)
    await start_read(dut, 0)
    await send_instr(dut, InstructionLUI(tp, 0x8000).encode())
    await peri_clear(dut)

    # ── Sub-test 1: Peripheral reachable ─────────────────────────────────────
    dut._log.info("=== test_peripheral_reachable ===")
    status = await rd(dut, STATUS)
    dut._log.info(f"  STATUS after reset = 0x{status:08X}")
    assert status == 0, f"STATUS should be 0, got 0x{status:08X}"
    await wr(dut, CTRL, 0)
    ctrl = await rd(dut, CTRL)
    dut._log.info(f"  CTRL readback = 0x{ctrl:08X}")
    assert ctrl == 0, f"CTRL readback failed: 0x{ctrl:08X}"
    dut._log.info("test_peripheral_reachable PASS")

    # ── Sub-test 2: Single channel ────────────────────────────────────────────
    dut._log.info("=== test_single_channel ===")
    await peri_clear(dut)
    done = await run_channel(dut, [float(i+1) for i in range(16)], [1.0]*9)
    assert done, "test_single_channel: Timeout"
    expected = [54.0, 63.0, 90.0, 99.0]
    for i, exp in enumerate(expected):
        raw = await rd(dut, OUTPUT[i])
        got = from_fx(raw)
        dut._log.info(f"  OUTPUT[{i}] = {got:.4f}  (expect {exp})")
        assert abs(got - exp) < 0.5, f"OUTPUT[{i}]: got {got:.4f}"
    dut._log.info("test_single_channel PASS")

    # ── Sub-test 3: Accumulate 3 channels ────────────────────────────────────
    dut._log.info("=== test_accumulate ===")
    await peri_clear(dut)
    for ch in range(3):
        dut._log.info(f"  Channel {ch}: input={ch+1}.0")
        done = await run_channel(dut, [float(ch+1)]*16, [1.0]*9, accum=True)
        assert done, f"test_accumulate: Timeout ch{ch}"
    for i in range(4):
        raw = await rd(dut, ACC[i])
        got = from_fx(raw)
        dut._log.info(f"  ACC[{i}] = {got:.4f}  (expect 54.0)")
        assert abs(got - 54.0) < 0.5, f"ACC[{i}]: got {got:.4f}"
    dut._log.info("test_accumulate PASS")

    # ── Sub-test 4: IRQ ───────────────────────────────────────────────────────
    dut._log.info("=== test_irq ===")
    await peri_clear(dut)
    await load_filters(dut, [1.0]*9)
    await load_inputs(dut, [1.0]*16)
    await wr(dut, CTRL, CTRL_START | CTRL_IRQ_EN)
    done = await wait_done(dut)
    assert done, "test_irq: Timeout"
    status = await rd(dut, STATUS)
    dut._log.info(f"  STATUS = 0x{status:08X}")
    assert status & STATUS_DONE, "STATUS_DONE not set"
    dut._log.info("test_irq PASS")

    dut._log.info("=== ALL SYSTEM TESTS PASSED ===")