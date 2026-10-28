"""
test_system.py — System-level cocotb test for TinyQV + tqvp_dma.

The CPU boots from QSPI flash, executes a RISC-V program that:
  1. Writes 0x12345678 into DMA DATA0
  2. Sets COUNT = 4, CTRL = 3 (TX mode + start)
  3. Polls STATUS until done

The DMA then outputs the 4 bytes of 0x12345678 (little-endian) on its uo_out:
  byte 0 = 0x78, byte 1 = 0x56, byte 2 = 0x34, byte 3 = 0x12

We monitor the DMA peripheral's uo_out directly via the hierarchy
  dut.i_dut.i_peripherals.i_dma.uo_out
to avoid contamination from project.v routing UART TX onto uo_out[6].
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


EXPECTED_BYTES = [0x78, 0x56, 0x34, 0x12]
MAX_CYCLES = 300_000   # generous budget for boot + flash fetch + DMA transfer


@cocotb.test()
async def test_dma_tx(dut):
    """Full-system DMA TX test: CPU boots from flash and drives DMA."""

    # ------------------------------------------------------------------
    # Clock: 10 ns period (100 MHz — fast enough for simulation)
    # ------------------------------------------------------------------
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # ------------------------------------------------------------------
    # Reset for 20 cycles
    # ------------------------------------------------------------------
    dut.rst_n.value = 0
    for _ in range(20):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    # ------------------------------------------------------------------
    # Locate the DMA uo_out signal in the hierarchy.
    # Path: tb_system → i_dut (tt_um_tt_tinyQV) → i_peripherals
    #       (tinyQV_peripherals/peripherals_stub) → i_dma (tqvp_dma)
    # ------------------------------------------------------------------
    try:
        dma_out = dut.i_dut.i_peripherals.i_dma.uo_out
        use_hierarchy = True
    except AttributeError:
        # Fall back to top-level uo_out if hierarchy is not accessible.
        # Note: uo_out[6] is UART TX (idle=1), so bytes with bit6=0 will
        # appear with bit6 forced to 1. Adjust expected values accordingly.
        dut._log.warning(
            "Hierarchical DMA signal not accessible; falling back to uo_out. "
            "Expected bytes adjusted for UART idle bit."
        )
        dma_out = dut.uo_out
        use_hierarchy = False

    # Adjusted expected values when monitoring top-level uo_out
    # (bit 6 always 1 due to UART TX idle = 1):
    expected_top = [(b | 0x40) for b in EXPECTED_BYTES]

    expected = EXPECTED_BYTES if use_hierarchy else expected_top

    # Diagnostic: log which signal we're monitoring
    dut._log.info(f"use_hierarchy={use_hierarchy}, monitoring signal: {dma_out._name if hasattr(dma_out, '_name') else dma_out}")

    # ------------------------------------------------------------------
    # Monitor: collect up to 4 distinct consecutive non-zero byte values
    # ------------------------------------------------------------------
    collected = []
    prev_val = -1

    for cycle in range(MAX_CYCLES):
        await RisingEdge(dut.clk)
        val = int(dma_out.value)

        if val != 0 and val != prev_val:
            collected.append(val)
            dut._log.info(
                f"cycle {cycle}: DMA output changed → 0x{val:02X} "
                f"(collected {len(collected)}/4)"
            )
            if len(collected) >= 4:
                break

        prev_val = val

        # Periodic diagnostic to check if uo_out is ever non-zero
        if cycle in (100, 1000, 10000, 50000, 100000) or (cycle % 50000 == 0 and cycle > 0):
            top_val = int(dut.uo_out.value)
            dut._log.info(f"cycle {cycle}: dma_out=0x{val:02X} dut.uo_out=0x{top_val:02X}")

    # ------------------------------------------------------------------
    # Assertions
    # ------------------------------------------------------------------
    assert len(collected) >= 4, (
        f"Only captured {len(collected)} distinct DMA byte(s) within "
        f"{MAX_CYCLES} cycles. Got: {[hex(v) for v in collected]}"
    )

    assert collected[:4] == expected, (
        f"DMA TX bytes mismatch!\n"
        f"  Expected: {[hex(v) for v in expected]}\n"
        f"  Got:      {[hex(v) for v in collected[:4]]}"
    )

    dut._log.info(
        "PASS: DMA TX sequence verified: "
        + ", ".join(hex(v) for v in collected[:4])
    )
