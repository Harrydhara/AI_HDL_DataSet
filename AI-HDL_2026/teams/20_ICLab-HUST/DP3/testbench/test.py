# SPDX-FileCopyrightText: © 2025 ICLab_HUST
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from tqv import TinyQV

# When submitting your design, change this to the peripheral number
# in peripherals.v.  e.g. if your design is i_user_peri05, set this to 5.
PERIPHERAL_NUM = 0

# ---------------------------------------------------------------------------
# Register addresses (byte-addressed, word-aligned)
# ---------------------------------------------------------------------------
CTRL    = 0x00   # [W]  bit0=start, bit1=mode(0=RX/1=TX), bit2=irq_enable
COUNT   = 0x04   # [RW] number of bytes to transfer (1..32)
DIVISOR = 0x08   # [RW] clock divisor: 1 byte every (DIVISOR+1) clocks
STATUS  = 0x0C   # [R]  bit0=busy, bit1=done, bit2=key_valid
CLR_IRQ = 0x10   # [W]  any write clears done and deasserts interrupt
DATA0   = 0x14   # [RW] buffer bytes  3:0
DATA1   = 0x18   # [RW] buffer bytes  7:4
DATA2   = 0x1C   # [RW] buffer bytes 11:8
DATA3   = 0x20   # [RW] buffer bytes 15:12
DATA4   = 0x24   # [RW] buffer bytes 19:16
DATA5   = 0x28   # [RW] buffer bytes 23:20
DATA6   = 0x2C   # [RW] buffer bytes 27:24
DATA7   = 0x30   # [RW] buffer bytes 31:28
SEC_KEY = 0x34   # [W]  Write 0xA5 to arm start-unlock key (SEC-2 countermeasure)

# ---------------------------------------------------------------------------
# CTRL bit masks
# ---------------------------------------------------------------------------
CTRL_START      = 0b001
CTRL_TX         = 0b010   # TX mode (mode=1); RX mode when this bit is 0
CTRL_IRQ_ENABLE = 0b100

# ---------------------------------------------------------------------------
# STATUS bit masks
# ---------------------------------------------------------------------------
STATUS_BUSY      = 0b001
STATUS_DONE      = 0b010
STATUS_KEY_VALID = 0b100  # SEC-2: key armed and ready

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
async def wait_done(tqv, dut, timeout=200):
    """Poll STATUS register until done bit is set, then return status byte."""
    for _ in range(timeout):
        status = await tqv.read_byte_reg(STATUS)
        if status & STATUS_DONE:
            return status
    raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")

async def arm_and_start(tqv, ctrl_val):
    """[SEC-2] Write unlock key 0xA5 to SEC_KEY, then write ctrl_val to CTRL.
    The key is consumed on every CTRL write, so it must be re-armed each time."""
    await tqv.write_byte_reg(SEC_KEY, 0xA5)
    await tqv.write_byte_reg(CTRL, ctrl_val)


# ===========================================================================
# Test 1: Reset default values
# ===========================================================================
@cocotb.test()
async def test_reset_defaults(dut):
    """After reset: STATUS=0 (idle), COUNT=1, DIVISOR=63."""
    dut._log.info("Test 1: reset defaults")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    status = await tqv.read_byte_reg(STATUS)
    assert status == 0, f"STATUS should be 0 after reset, got {status:#04x}"

    divisor = await tqv.read_byte_reg(DIVISOR)
    assert divisor == 63, f"DIVISOR default should be 63, got {divisor}"

    count = await tqv.read_byte_reg(COUNT)
    assert count == 1, f"COUNT default should be 1, got {count}"

    dut._log.info("Test 1 PASSED")


# ===========================================================================
# Test 2: Register read/write — COUNT, DIVISOR, DATA buffer
# ===========================================================================
@cocotb.test()
async def test_register_readback(dut):
    """Write and read back COUNT, DIVISOR, and DATA registers."""
    dut._log.info("Test 2: register read/write")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    # --- COUNT ---
    await tqv.write_byte_reg(COUNT, 16)
    assert await tqv.read_byte_reg(COUNT) == 16, "COUNT readback failed"

    # --- DIVISOR ---
    await tqv.write_byte_reg(DIVISOR, 7)
    assert await tqv.read_byte_reg(DIVISOR) == 7, "DIVISOR readback failed"

    # --- DATA registers (all 8 words) ---
    test_words = [
        0x03020100, 0x07060504, 0x0B0A0908, 0x0F0E0D0C,
        0x13121110, 0x17161514, 0x1B1A1918, 0x1F1E1D1C,
    ]
    data_addrs = [DATA0, DATA1, DATA2, DATA3, DATA4, DATA5, DATA6, DATA7]

    for addr, word in zip(data_addrs, test_words):
        await tqv.write_word_reg(addr, word)

    for addr, expected in zip(data_addrs, test_words):
        got = await tqv.read_word_reg(addr)
        assert got == expected, f"DATA@{addr:#04x}: expected {expected:#010x}, got {got:#010x}"

    dut._log.info("Test 2 PASSED")


# ===========================================================================
# Test 3: COUNT clamping (0 → 1, >32 → 32)
# ===========================================================================
@cocotb.test()
async def test_count_clamping(dut):
    """COUNT=0 must clamp to 1; COUNT>32 must clamp to 32."""
    dut._log.info("Test 3: COUNT clamping")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    # 0 → 1
    await tqv.write_byte_reg(COUNT, 0)
    got = await tqv.read_byte_reg(COUNT)
    assert got == 1, f"COUNT=0 should clamp to 1, got {got}"

    # 50 → 32  (50 > 32)
    await tqv.write_byte_reg(COUNT, 50)
    got = await tqv.read_byte_reg(COUNT)
    assert got == 32, f"COUNT=50 should clamp to 32, got {got}"

    # 32 stays 32 (boundary)
    await tqv.write_byte_reg(COUNT, 32)
    got = await tqv.read_byte_reg(COUNT)
    assert got == 32, f"COUNT=32 should stay 32, got {got}"

    # 1 stays 1 (boundary)
    await tqv.write_byte_reg(COUNT, 1)
    got = await tqv.read_byte_reg(COUNT)
    assert got == 1, f"COUNT=1 should stay 1, got {got}"

    dut._log.info("Test 3 PASSED")


# ===========================================================================
# Test 4: TX mode — STATUS[done] is set after transfer
# ===========================================================================
@cocotb.test()
async def test_tx_mode(dut):
    """TX: DMA clocks out buffer bytes and sets STATUS[done]."""
    dut._log.info("Test 4: TX mode")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    # Use small divisor for fast simulation (each byte takes 4 clocks)
    await tqv.write_byte_reg(DIVISOR, 3)

    # Load 4 bytes into DATA0:
    # byte0=0xAA, byte1=0xBB, byte2=0xCC, byte3=0xDD (little-endian word)
    await tqv.write_word_reg(DATA0, 0xDDCCBBAA)
    await tqv.write_byte_reg(COUNT, 4)

    # Start TX (mode=1, start=1) — SEC_KEY must be armed first [SEC-2]
    await arm_and_start(tqv, CTRL_START | CTRL_TX)

    # Wait for DMA to complete
    status = await wait_done(tqv, dut)

    assert status & STATUS_DONE,  "STATUS[done] should be set after TX"
    assert not (status & STATUS_BUSY), "STATUS[busy] should be clear after TX"

    # uo_out should be 0 when DMA is not in ST_RUN
    assert dut.uo_out.value == 0, f"uo_out should be 0 when idle, got {dut.uo_out.value}"

    dut._log.info("Test 4 PASSED")


# ===========================================================================
# Test 5: TX mode — 8 bytes from two DATA words
# ===========================================================================
@cocotb.test()
async def test_tx_two_words(dut):
    """TX 8 bytes from DATA0 and DATA1."""
    dut._log.info("Test 5: TX two words")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    await tqv.write_byte_reg(DIVISOR, 3)
    await tqv.write_word_reg(DATA0, 0x04030201)
    await tqv.write_word_reg(DATA1, 0x08070605)
    await tqv.write_byte_reg(COUNT, 8)

    await arm_and_start(tqv, CTRL_START | CTRL_TX)

    status = await wait_done(tqv, dut)
    assert status & STATUS_DONE, "STATUS[done] should be set after 8-byte TX"

    dut._log.info("Test 5 PASSED")


# ===========================================================================
# Test 6: TX mode — full 32-byte buffer
# ===========================================================================
@cocotb.test()
async def test_tx_full_buffer(dut):
    """TX all 32 bytes (8 DATA words)."""
    dut._log.info("Test 6: TX full 32-byte buffer")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    await tqv.write_byte_reg(DIVISOR, 1)   # 2 clocks/byte → 64 clocks total

    data_addrs = [DATA0, DATA1, DATA2, DATA3, DATA4, DATA5, DATA6, DATA7]
    for i, addr in enumerate(data_addrs):
        word = (i * 4 + 3) << 24 | (i * 4 + 2) << 16 | (i * 4 + 1) << 8 | (i * 4)
        await tqv.write_word_reg(addr, word)

    await tqv.write_byte_reg(COUNT, 32)
    await arm_and_start(tqv, CTRL_START | CTRL_TX)

    status = await wait_done(tqv, dut, timeout=500)
    assert status & STATUS_DONE, "STATUS[done] should be set after 32-byte TX"

    dut._log.info("Test 6 PASSED")


# ===========================================================================
# Test 7: RX mode — ui_in bytes are captured into DATA buffer
# ===========================================================================
@cocotb.test()
async def test_rx_mode(dut):
    """RX: DMA samples ui_in and fills DATA0 with captured bytes."""
    dut._log.info("Test 7: RX mode")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    await tqv.write_byte_reg(DIVISOR, 3)
    await tqv.write_byte_reg(COUNT, 4)

    # Drive ui_in before starting — SPI write (~262 clocks) gives the
    # 2-stage synchronizer plenty of time to settle.
    dut.ui_in.value = 0xA5

    # Start RX (mode=0, so only start bit; bit1 stays 0) — arm key first [SEC-2]
    await arm_and_start(tqv, CTRL_START)

    status = await wait_done(tqv, dut)
    assert status & STATUS_DONE, "STATUS[done] should be set after RX"

    # All 4 sampled bytes should equal 0xA5 → DATA0 = 0xA5A5A5A5
    data0 = await tqv.read_word_reg(DATA0)
    assert data0 == 0xA5A5A5A5, f"RX data mismatch: expected 0xA5A5A5A5, got {data0:#010x}"

    dut._log.info("Test 7 PASSED")


# ===========================================================================
# Test 8: RX mode — captured value changes when ui_in changes between transfers
# ===========================================================================
@cocotb.test()
async def test_rx_different_values(dut):
    """Two consecutive RX transfers with different ui_in values."""
    dut._log.info("Test 8: RX different values")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    await tqv.write_byte_reg(DIVISOR, 3)
    await tqv.write_byte_reg(COUNT, 4)

    # First transfer with ui_in = 0x12
    dut.ui_in.value = 0x12
    await arm_and_start(tqv, CTRL_START)
    await wait_done(tqv, dut)

    data0 = await tqv.read_word_reg(DATA0)
    assert data0 == 0x12121212, f"First RX: expected 0x12121212, got {data0:#010x}"

    # Clear done so we can start again
    await tqv.write_byte_reg(CLR_IRQ, 1)

    # Second transfer with ui_in = 0x34
    dut.ui_in.value = 0x34
    await arm_and_start(tqv, CTRL_START)
    await wait_done(tqv, dut)

    data0 = await tqv.read_word_reg(DATA0)
    assert data0 == 0x34343434, f"Second RX: expected 0x34343434, got {data0:#010x}"

    dut._log.info("Test 8 PASSED")


# ===========================================================================
# Test 9: IRQ is asserted after done when irq_enable=1
# ===========================================================================
@cocotb.test()
async def test_irq_enabled(dut):
    """IRQ is asserted when irq_enable=1 and DMA completes."""
    dut._log.info("Test 9: IRQ enabled")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    await tqv.write_byte_reg(DIVISOR, 3)
    await tqv.write_word_reg(DATA0, 0xCAFEBABE)
    await tqv.write_byte_reg(COUNT, 4)

    # Start TX with IRQ enable — arm key first [SEC-2]
    await arm_and_start(tqv, CTRL_START | CTRL_TX | CTRL_IRQ_ENABLE)

    await wait_done(tqv, dut)

    assert await tqv.is_interrupt_asserted(), "IRQ should be asserted after TX done with irq_enable=1"

    dut._log.info("Test 9 PASSED")


# ===========================================================================
# Test 10: IRQ is NOT asserted when irq_enable=0
# ===========================================================================
@cocotb.test()
async def test_irq_disabled(dut):
    """No IRQ when irq_enable=0, even after transfer completes."""
    dut._log.info("Test 10: IRQ disabled")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    await tqv.write_byte_reg(DIVISOR, 3)
    await tqv.write_byte_reg(COUNT, 4)

    # Start TX without IRQ enable — arm key first [SEC-2]
    await arm_and_start(tqv, CTRL_START | CTRL_TX)

    await wait_done(tqv, dut)

    assert not await tqv.is_interrupt_asserted(), \
        "IRQ should NOT be asserted when irq_enable=0"

    dut._log.info("Test 10 PASSED")


# ===========================================================================
# Test 11: CLR_IRQ clears done bit and deasserts interrupt
# ===========================================================================
@cocotb.test()
async def test_clr_irq(dut):
    """Writing CLR_IRQ clears STATUS[done] and deasserts the interrupt line."""
    dut._log.info("Test 11: CLR_IRQ")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    await tqv.write_byte_reg(DIVISOR, 3)
    await tqv.write_byte_reg(COUNT, 1)

    await arm_and_start(tqv, CTRL_START | CTRL_TX | CTRL_IRQ_ENABLE)

    await wait_done(tqv, dut)

    # Verify done and IRQ are set
    status = await tqv.read_byte_reg(STATUS)
    assert status & STATUS_DONE, "STATUS[done] should be set before clearing"
    assert await tqv.is_interrupt_asserted(), "IRQ should be asserted before clearing"

    # Clear
    await tqv.write_byte_reg(CLR_IRQ, 0xFF)

    # Both should now be clear
    assert not await tqv.is_interrupt_asserted(), "IRQ should be deasserted after CLR_IRQ"

    status = await tqv.read_byte_reg(STATUS)
    assert not (status & STATUS_DONE), "STATUS[done] should be 0 after CLR_IRQ"
    assert not (status & STATUS_BUSY), "STATUS[busy] should be 0 after CLR_IRQ + idle"

    dut._log.info("Test 11 PASSED")


# ===========================================================================
# Test 12: Second transfer can start after CLR_IRQ (DMA returns to ST_IDLE)
# ===========================================================================
@cocotb.test()
async def test_second_transfer(dut):
    """After CLR_IRQ the DMA returns to IDLE and can be restarted."""
    dut._log.info("Test 12: second transfer after CLR_IRQ")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())
    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    await tqv.write_byte_reg(DIVISOR, 3)
    await tqv.write_word_reg(DATA0, 0x11223344)
    await tqv.write_byte_reg(COUNT, 4)

    # First transfer — arm key first [SEC-2]
    await arm_and_start(tqv, CTRL_START | CTRL_TX)
    await wait_done(tqv, dut)
    await tqv.write_byte_reg(CLR_IRQ, 1)

    # Second transfer with different data — key must be re-armed [SEC-2]
    await tqv.write_word_reg(DATA0, 0x55667788)
    await arm_and_start(tqv, CTRL_START | CTRL_TX)
    status = await wait_done(tqv, dut)

    assert status & STATUS_DONE, "STATUS[done] should be set after second TX"

    dut._log.info("Test 12 PASSED")
