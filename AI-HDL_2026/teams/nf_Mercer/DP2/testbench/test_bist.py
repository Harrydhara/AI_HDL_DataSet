"""
test_bist.py  –  Cocotb tests for bist_ctrl via tqvp_example (peripheral)

Run with:
    make -f test_bist.mk
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

# MMIO address constants  (word addresses, 6-bit)
BIST_MODE   = 0x60
BIST_START  = 0x61
BIST_STATUS = 0x62
BIST_FINFO  = 0x63
BIST_FGOT   = 0x64
BIST_FEXP   = 0x65

SYST_A0     = 0x50
SYST_A1     = 0x51
SYST_A2     = 0x52
SYST_A3     = 0x53
SYST_B0     = 0x54
SYST_B1     = 0x55
SYST_B2     = 0x56
SYST_B3     = 0x57
SYST_START  = 0x58
SYST_DONE   = 0x59
SYST_C00    = 0x5A
SYST_C01    = 0x5B
SYST_C10    = 0x5C
SYST_C11    = 0x5D

MVU_X0      = 0x30
MVU_W00     = 0x34   # w[0][0]; w[row][col] at 0x34 + row*4 + col
MVU_START   = 0x44
MVU_DONE    = 0x45
MVU_Y0      = 0x46

# Bus driver helpers
async def reset(dut):
    """Assert reset for 4 cycles then release."""
    dut.rst_n.value        = 0
    dut.data_write_n.value = 0b11
    dut.data_read_n.value  = 0b11
    dut.address.value      = 0
    dut.data_in.value      = 0
    dut.ui_in.value        = 0
    await ClockCycles(dut.clk, 4)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


async def mmio_write(dut, addr, data):
    """Single-cycle MMIO write."""
    await FallingEdge(dut.clk)
    dut.address.value      = addr
    dut.data_in.value      = data
    dut.data_write_n.value = 0b00
    dut.data_read_n.value  = 0b11
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.data_write_n.value = 0b11


async def mmio_read(dut, addr) -> int:
    """Single-cycle MMIO read; returns data_out value."""
    await FallingEdge(dut.clk)
    dut.address.value      = addr
    dut.data_write_n.value = 0b11
    dut.data_read_n.value  = 0b00
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)   # data_ready is registered +1 cycle
    value = int(dut.data_out.value)
    dut.data_read_n.value  = 0b11
    return value


async def poll(dut, addr, bit, expected, timeout=500):
    """Poll addr until addr[bit] == expected, or timeout."""
    for _ in range(timeout):
        v = await mmio_read(dut, addr)
        if ((v >> bit) & 1) == expected:
            return v
    raise TimeoutError(f"poll timeout: addr=0x{addr:02x} bit={bit} expected={expected}")


async def run_bist(dut, start_bits, timeout=1000):
    """Write start_bits to BIST_START and wait until busy clears."""
    await mmio_write(dut, BIST_START, start_bits)
    await ClockCycles(dut.clk, 2)
    await poll(dut, BIST_STATUS, bit=0, expected=0, timeout=timeout)
    return await mmio_read(dut, BIST_STATUS)


# ---------------------------------------------------------------------------
# Test 1 — FUNCTIONAL mode: systolic works directly
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_functional_systolic(dut):
    """FUNCTIONAL mode: identity × identity = identity via normal MMIO."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    # Confirm we start in FUNCTIONAL mode
    mode = await mmio_read(dut, BIST_MODE)
    assert mode == 0, f"Expected mode=0 after reset, got {mode}"

    # A = I, B = I  →  C = I  (no ReLU clamp needed, all positive)
    await mmio_write(dut, SYST_A0, 1)
    await mmio_write(dut, SYST_A1, 0)
    await mmio_write(dut, SYST_A2, 0)
    await mmio_write(dut, SYST_A3, 1)
    await mmio_write(dut, SYST_B0, 1)
    await mmio_write(dut, SYST_B1, 0)
    await mmio_write(dut, SYST_B2, 0)
    await mmio_write(dut, SYST_B3, 1)
    await mmio_write(dut, SYST_START, 1)

    await poll(dut, SYST_DONE, bit=0, expected=1, timeout=20)

    c00 = await mmio_read(dut, SYST_C00)
    c01 = await mmio_read(dut, SYST_C01)
    c10 = await mmio_read(dut, SYST_C10)
    c11 = await mmio_read(dut, SYST_C11)

    assert c00 == 1, f"c00: got {c00} expected 1"
    assert c01 == 0, f"c01: got {c01} expected 0"
    assert c10 == 0, f"c10: got {c10} expected 0"
    assert c11 == 1, f"c11: got {c11} expected 1"

    dut._log.info("FUNCTIONAL systolic: PASS")


# ---------------------------------------------------------------------------
# Test 2 — FUNCTIONAL mode: mvu works directly
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_functional_mvu(dut):
    """FUNCTIONAL mode: identity W × x=[1 2 3 4] = y=[1 2 3 4]."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    # Identity weight matrix
    for row in range(4):
        for col in range(4):
            await mmio_write(dut, MVU_W00 + row * 4 + col,
                             1 if row == col else 0)

    # Input vector
    for i, val in enumerate([1, 2, 3, 4]):
        await mmio_write(dut, MVU_X0 + i, val)

    await mmio_write(dut, MVU_START, 1)
    await poll(dut, MVU_DONE, bit=0, expected=1, timeout=20)

    for i, expected in enumerate([1, 2, 3, 4]):
        got = await mmio_read(dut, MVU_Y0 + i)
        assert got == expected, f"y[{i}]: got {got} expected {expected}"

    dut._log.info("FUNCTIONAL mvu: PASS")


# ---------------------------------------------------------------------------
# Test 3 — Mode register read/write
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_mode_register(dut):
    """Mode register toggles correctly; bist_active stays 0 when idle."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    mode = await mmio_read(dut, BIST_MODE)
    assert mode == 0, f"mode should be 0 after reset, got {mode}"

    await mmio_write(dut, BIST_MODE, 1)
    mode = await mmio_read(dut, BIST_MODE)
    assert mode == 1, f"mode should read 1 after write, got {mode}"

    # bist_active bit in status should be 0 — no test started
    status = await mmio_read(dut, BIST_STATUS)
    assert (status & 1) == 0, f"bist_active should be 0 when idle, status={status:#010x}"

    # Switch back
    await mmio_write(dut, BIST_MODE, 0)
    mode = await mmio_read(dut, BIST_MODE)
    assert mode == 0, f"mode should be 0 after write-back, got {mode}"

    dut._log.info("Mode register: PASS")


# ---------------------------------------------------------------------------
# Test 4 — BIST systolic-only
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_bist_systolic_only(dut):
    """BIST mode: systolic-only run, expect all 8 vectors to pass."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    await mmio_write(dut, BIST_MODE, 1)

    status = await run_bist(dut, start_bits=0x1)  # bit0 = run_syst

    busy      = (status >> 0) & 1
    syst_done = (status >> 1) & 1
    syst_pass = (status >> 2) & 1
    mvu_done  = (status >> 3) & 1

    assert busy      == 0, f"busy should be 0 after completion, status={status:#010x}"
    assert syst_done == 1, f"syst_done should be 1, status={status:#010x}"
    assert syst_pass == 1, (
        f"syst_pass should be 1.\n"
        f"  fail_info = {await mmio_read(dut, BIST_FINFO):#010x}\n"
        f"  fail_got  = {await mmio_read(dut, BIST_FGOT):#010x}\n"
        f"  fail_exp  = {await mmio_read(dut, BIST_FEXP):#010x}"
    )
    assert mvu_done  == 0, f"mvu_done should be 0 (not run), status={status:#010x}"

    dut._log.info("BIST systolic-only: PASS")


# ---------------------------------------------------------------------------
# Test 5 — BIST mvu-only
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_bist_mvu_only(dut):
    """BIST mode: mvu-only run, expect all 4 vectors to pass."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    await mmio_write(dut, BIST_MODE, 1)

    status = await run_bist(dut, start_bits=0x2)  # bit1 = run_mvu

    busy     = (status >> 0) & 1
    mvu_done = (status >> 3) & 1
    mvu_pass = (status >> 4) & 1
    syst_done = (status >> 1) & 1

    assert busy      == 0, f"busy should be 0, status={status:#010x}"
    assert mvu_done  == 1, f"mvu_done should be 1, status={status:#010x}"
    assert mvu_pass  == 1, (
        f"mvu_pass should be 1.\n"
        f"  fail_info = {await mmio_read(dut, BIST_FINFO):#010x}\n"
        f"  fail_got  = {await mmio_read(dut, BIST_FGOT):#010x}\n"
        f"  fail_exp  = {await mmio_read(dut, BIST_FEXP):#010x}"
    )
    assert syst_done == 0, f"syst_done should be 0 (not run), status={status:#010x}"

    dut._log.info("BIST mvu-only: PASS")


# ---------------------------------------------------------------------------
# Test 6 — BIST both (start_both, bit2)
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_bist_both(dut):
    """BIST mode: run_both — systolic then mvu, both must pass."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    await mmio_write(dut, BIST_MODE, 1)

    status = await run_bist(dut, start_bits=0x4, timeout=2000)  # bit2

    syst_done = (status >> 1) & 1
    syst_pass = (status >> 2) & 1
    mvu_done  = (status >> 3) & 1
    mvu_pass  = (status >> 4) & 1

    fail_info = await mmio_read(dut, BIST_FINFO)
    fail_got  = await mmio_read(dut, BIST_FGOT)
    fail_exp  = await mmio_read(dut, BIST_FEXP)

    assert syst_done == 1, f"syst_done should be 1, status={status:#010x}"
    assert mvu_done  == 1, f"mvu_done should be 1, status={status:#010x}"
    assert syst_pass == 1, (
        f"syst_pass=0: info={fail_info:#010x} got={fail_got:#010x} exp={fail_exp:#010x}"
    )
    assert mvu_pass  == 1, (
        f"mvu_pass=0:  info={fail_info:#010x} got={fail_got:#010x} exp={fail_exp:#010x}"
    )

    dut._log.info("BIST both: PASS")


# ---------------------------------------------------------------------------
# Test 7 — Bus lockout: CPU write ignored during BIST
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_bist_bus_lockout(dut):
    """CPU writes to systolic during BIST are silently blocked."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    await mmio_write(dut, BIST_MODE, 1)

    # Kick off BIST (systolic)
    await mmio_write(dut, BIST_START, 0x1)
    await ClockCycles(dut.clk, 1)

    # Attempt to corrupt systolic a0 while BIST is active
    status_mid = await mmio_read(dut, BIST_STATUS)
    if (status_mid & 1):  # only attempt write if still busy
        await mmio_write(dut, SYST_A0, 0xDEADBEEF)

    # Wait for BIST to finish
    await poll(dut, BIST_STATUS, bit=0, expected=0, timeout=500)
    status = await mmio_read(dut, BIST_STATUS)

    syst_pass = (status >> 2) & 1
    assert syst_pass == 1, (
        f"syst_pass=0 after lockout test — CPU write leaked through.\n"
        f"  fail_info={await mmio_read(dut, BIST_FINFO):#010x}\n"
        f"  fail_got ={await mmio_read(dut, BIST_FGOT):#010x}\n"
        f"  fail_exp ={await mmio_read(dut, BIST_FEXP):#010x}"
    )

    dut._log.info("Bus lockout: PASS")


# ---------------------------------------------------------------------------
# Test 8 — Return to FUNCTIONAL, DUT still works
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_return_to_functional(dut):
    """After BIST, mode=0 restores normal systolic access."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    # Run BIST first
    await mmio_write(dut, BIST_MODE, 1)
    await run_bist(dut, start_bits=0x4)

    # Return to FUNCTIONAL
    await mmio_write(dut, BIST_MODE, 0)
    mode = await mmio_read(dut, BIST_MODE)
    assert mode == 0, f"mode should be 0, got {mode}"

    # Systolic: [2 0/0 2] × [3 0/0 3] = [6 0/0 6]
    await mmio_write(dut, SYST_A0, 2)
    await mmio_write(dut, SYST_A1, 0)
    await mmio_write(dut, SYST_A2, 0)
    await mmio_write(dut, SYST_A3, 2)
    await mmio_write(dut, SYST_B0, 3)
    await mmio_write(dut, SYST_B1, 0)
    await mmio_write(dut, SYST_B2, 0)
    await mmio_write(dut, SYST_B3, 3)
    await mmio_write(dut, SYST_START, 1)
    await poll(dut, SYST_DONE, bit=0, expected=1, timeout=20)

    c00 = await mmio_read(dut, SYST_C00)
    c11 = await mmio_read(dut, SYST_C11)
    assert c00 == 6, f"post-BIST c00: got {c00} expected 6"
    assert c11 == 6, f"post-BIST c11: got {c11} expected 6"

    dut._log.info("Return to FUNCTIONAL: PASS")


# ---------------------------------------------------------------------------
# Test 9 — BIST start ignored in FUNCTIONAL mode
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_bist_start_ignored_in_functional(dut):
    """Writing BIST_START while mode=0 should do nothing."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    # Confirm FUNCTIONAL
    mode = await mmio_read(dut, BIST_MODE)
    assert mode == 0

    await mmio_write(dut, BIST_START, 0x7)   # all bits set — should be ignored
    await ClockCycles(dut.clk, 6)

    status = await mmio_read(dut, BIST_STATUS)
    assert (status & 1) == 0, (
        f"bist_active should remain 0 in FUNCTIONAL mode, status={status:#010x}"
    )

    dut._log.info("Start ignored in FUNCTIONAL mode: PASS")
