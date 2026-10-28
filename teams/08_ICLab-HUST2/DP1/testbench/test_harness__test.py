# SPDX-FileCopyrightText: © 2025 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from tqv import TinyQV

PERIPHERAL_NUM = 0

# Byte offset address map 
ADDR_CTRL        = 0x00
ADDR_STATUS      = 0x04
ADDR_CONFIG      = 0x08
ADDR_INPUT_IDX   = 0x0C
ADDR_INPUT_DATA  = 0x10
ADDR_FILTER_IDX  = 0x14
ADDR_FILTER_DATA = 0x18
ADDR_OUTPUT      = [0x1C, 0x20, 0x24, 0x28]
ADDR_ACC         = [0x2C, 0x30, 0x34, 0x38]

CTRL_START     = (1 << 0)
CTRL_ACCUM_EN  = (1 << 3)
CTRL_CLEAR_ACC = (1 << 4)
STATUS_DONE    = (1 << 1)

def to_fixed(x): return int(round(x * (1 << 16))) & 0xFFFFFFFF
def from_fixed(v):
    if v >= (1 << 31): v -= (1 << 32)
    return v / (1 << 16)

async def write_inputs(tqv, values):
    await tqv.write_word_reg(ADDR_INPUT_IDX, 0)
    for v in values:
        await tqv.write_word_reg(ADDR_INPUT_DATA, to_fixed(v))

async def write_filters(tqv, values):
    await tqv.write_word_reg(ADDR_FILTER_IDX, 0)
    for v in values:
        await tqv.write_word_reg(ADDR_FILTER_DATA, to_fixed(v))

async def wait_done(tqv, dut, timeout=3000):
    for i in range(timeout):
        s = await tqv.read_word_reg(ADDR_STATUS)
        if s & STATUS_DONE:
            return True
        await ClockCycles(dut.clk, 5)
    return False

@cocotb.test()
async def test_winograd_all(dut):
    """All Winograd peripheral tests"""
    cocotb.start_soon(Clock(dut.clk, 100, units="ns").start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    # ── Sub-test 0: STATUS=0 after reset ─────────────────────────────────────
    dut._log.info("=== test_address_debug ===")
    status = await tqv.read_word_reg(ADDR_STATUS)
    dut._log.info(f"  STATUS = {status:#010x}")
    assert status == 0, f"STATUS should be 0, got {status:#010x}"

    # Write/read INPUT via IDX+DATA
    await tqv.write_word_reg(ADDR_INPUT_IDX, 0)
    await tqv.write_word_reg(ADDR_INPUT_DATA, 0x12345678)
    await tqv.write_word_reg(ADDR_INPUT_IDX, 0)  # reset index
    val = await tqv.read_word_reg(ADDR_INPUT_DATA)
    dut._log.info(f"  INPUT_BUF[0] = {val:#010x}")
    assert val == 0x12345678, f"Input readback FAIL: {val:#010x}"

    await tqv.write_word_reg(ADDR_FILTER_IDX, 0)
    await tqv.write_word_reg(ADDR_FILTER_DATA, 0x11223344)
    await tqv.write_word_reg(ADDR_FILTER_IDX, 0)
    val = await tqv.read_word_reg(ADDR_FILTER_DATA)
    dut._log.info(f"  FILTER_BUF[0] = {val:#010x}")
    assert val == 0x11223344, f"Filter readback FAIL: {val:#010x}"
    dut._log.info("test_address_debug PASS")

    # ── Sub-test 1: Single channel ────────────────────────────────────────────
    dut._log.info("=== test_single_channel ===")
    await tqv.write_word_reg(ADDR_CTRL, CTRL_CLEAR_ACC)
    await ClockCycles(dut.clk, 2)
    await tqv.write_word_reg(ADDR_STATUS, 0)

    await write_filters(tqv, [1.0]*9)
    await write_inputs(tqv, [float(i+1) for i in range(16)])
    await tqv.write_word_reg(ADDR_CTRL, CTRL_START)

    assert await wait_done(tqv, dut), "TIMEOUT single_channel"
    await tqv.write_word_reg(ADDR_STATUS, 0)

    expected = [54.0, 63.0, 90.0, 99.0]
    for i, exp in enumerate(expected):
        raw = await tqv.read_word_reg(ADDR_OUTPUT[i])
        got = from_fixed(raw)
        dut._log.info(f"  OUTPUT[{i}] = {got:.4f}  (expect {exp})")
        assert abs(got - exp) < 0.5, f"OUTPUT[{i}]: got {got:.4f}"
    dut._log.info("test_single_channel PASS")

    # ── Sub-test 2: Accumulate 3 channels ────────────────────────────────────
    dut._log.info("=== test_accumulate ===")
    await tqv.write_word_reg(ADDR_CTRL, CTRL_CLEAR_ACC)
    await ClockCycles(dut.clk, 2)
    await tqv.write_word_reg(ADDR_STATUS, 0)

    for ch in range(3):
        dut._log.info(f"  Channel {ch}: input={ch+1}.0")
        await write_filters(tqv, [1.0]*9)
        await write_inputs(tqv, [float(ch+1)]*16)
        await tqv.write_word_reg(ADDR_CTRL, CTRL_START | CTRL_ACCUM_EN)
        assert await wait_done(tqv, dut), f"TIMEOUT ch{ch}"
        await tqv.write_word_reg(ADDR_STATUS, 0)

    for i in range(4):
        raw = await tqv.read_word_reg(ADDR_ACC[i])
        got = from_fixed(raw)
        dut._log.info(f"  ACC[{i}] = {got:.4f}  (expect 54.0)")
        assert abs(got - 54.0) < 0.5, f"ACC[{i}]: got {got:.4f}"
    dut._log.info("test_accumulate PASS")

    dut._log.info("=== ALL TESTS PASSED ===")