import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from riscvmodel.insn import InstructionSW, InstructionLW, InstructionLUI, InstructionADDI
from riscvmodel.regnames import x0, a0, tp

from test_util import reset, start_read, send_instr, read_reg, load_reg

BASE        = 0x380
CTRL        = BASE + 0x00
STATUS      = BASE + 0x04
INPUT_IDX   = BASE + 0x0C
INPUT_DATA  = BASE + 0x10
FILTER_IDX  = BASE + 0x14
FILTER_DATA = BASE + 0x18
OUTPUT      = [BASE + 0x1C + i*4 for i in range(4)]
ACC         = [BASE + 0x2C + i*4 for i in range(4)]

CTRL_START     = 0x01
CTRL_ACCUM_EN  = 0x08
CTRL_CLEAR_ACC = 0x10
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
    await read_reg(dut, a0)  # re-sync CPU

async def rd(dut, off):
    await send_instr(dut, InstructionLW(a0, tp, off).encode())
    return int(await read_reg(dut, a0)) & 0xFFFFFFFF

async def wait_done(dut, timeout=30):
    await nop(dut, 300)
    for _ in range(timeout):
        s = await rd(dut, STATUS)
        if s & STATUS_DONE:
            return True
        await nop(dut, 50)
    dut._log.error("wait_done: TIMEOUT")
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
    await wr(dut, STATUS, 0)
    return ok

async def peri_clear(dut):
    await wr(dut, CTRL, CTRL_CLEAR_ACC)
    await nop(dut, 5)
    await wr(dut, STATUS, 0)

# ══════════════════════════════════════════════════════════════════════════════
# 1 test duy nhất chứa tất cả sub-tests — tránh vấn đề re-init giữa các tests
# ══════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_winograd_all(dut):
    """All Winograd tests in one session"""
    # ── Init ──────────────────────────────────────────────────────────────────
    cocotb.start_soon(Clock(dut.clk, 15.624, units="ns").start())
    await reset(dut)
    await ClockCycles(dut.clk, 1)
    await start_read(dut, 0)
    await send_instr(dut, InstructionLUI(tp, 0x8000).encode())
    await peri_clear(dut)

    # ── Sub-test 1: Single channel ────────────────────────────────────────────
    dut._log.info("=== test_single_channel ===")
    done = await run_channel(dut, [float(i+1) for i in range(16)], [1.0]*9)
    assert done, "test_single_channel: Timeout"
    expected = [54.0, 63.0, 90.0, 99.0]
    for i, exp in enumerate(expected):
        raw = await rd(dut, OUTPUT[i])
        got = from_fx(raw)
        dut._log.info(f"  OUTPUT[{i}] = {got:.4f}  (expect {exp})")
        assert abs(got - exp) < 0.5, f"OUTPUT[{i}]: got {got:.4f}"
    dut._log.info("test_single_channel PASS")

    # ── Sub-test 2: Zero filter ────────────────────────────────────────────────
    dut._log.info("=== test_zero_filter ===")
    await peri_clear(dut)
    done = await run_channel(dut, [3.0]*16, [0.0]*9)
    assert done, "test_zero_filter: Timeout"
    for i in range(4):
        raw = await rd(dut, OUTPUT[i])
        got = from_fx(raw)
        dut._log.info(f"  OUTPUT[{i}] = {got:.6f}")
        assert abs(got) < 0.01, f"OUTPUT[{i}]={got:.6f}, expected 0"
    dut._log.info("test_zero_filter PASS")

    # ── Sub-test 3: Accumulate 3 channels ────────────────────────────────────
    dut._log.info("=== test_accumulate_3ch ===")
    await peri_clear(dut)
    for ch in range(3):
        dut._log.info(f"  Channel {ch}: input={ch+1}.0")
        done = await run_channel(dut, [float(ch+1)]*16, [1.0]*9, accum=True)
        assert done, f"test_accumulate_3ch: Timeout ch{ch}"
    for i in range(4):
        raw = await rd(dut, ACC[i])
        got = from_fx(raw)
        dut._log.info(f"  ACC[{i}] = {got:.4f}  (expect 54.0)")
        assert abs(got - 54.0) < 0.5, f"ACC[{i}]: got {got:.4f}"
    dut._log.info("test_accumulate_3ch PASS")

    # ── Sub-test 4: Clear acc then accum ─────────────────────────────────────
    dut._log.info("=== test_clear_acc ===")
    await peri_clear(dut)
    done = await run_channel(dut, [2.0]*16, [1.0]*9, accum=True)
    assert done, "test_clear_acc: Timeout"
    for i in range(4):
        out = await rd(dut, OUTPUT[i])
        acc = await rd(dut, ACC[i])
        dut._log.info(f"  [{i}] output={from_fx(out):.4f} acc={from_fx(acc):.4f}")
        assert out == acc, f"[{i}] acc != output"
    dut._log.info("test_clear_acc PASS")

    # ── Sub-test 5: Accumulate math ───────────────────────────────────────────
    dut._log.info("=== test_accumulate_math ===")
    await peri_clear(dut)
    for ch in range(2):
        done = await run_channel(dut, [float(i+1) for i in range(16)], [0.5]*9, accum=True)
        assert done, f"test_accumulate_math: Timeout ch{ch}"
    expected = [54.0, 63.0, 90.0, 99.0]
    for i, exp in enumerate(expected):
        raw = await rd(dut, ACC[i])
        got = from_fx(raw)
        dut._log.info(f"  ACC[{i}] = {got:.4f}  (expect {exp})")
        assert abs(got - exp) < 0.5, f"ACC[{i}]: got {got:.4f}"
    dut._log.info("test_accumulate_math PASS")

    dut._log.info("=== ALL TESTS PASSED ===")