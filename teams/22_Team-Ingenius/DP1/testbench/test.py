import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from tqv import TinyQV

@cocotb.test()
async def test_crc(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    tqv = TinyQV(dut, peripheral_num=14)
    await tqv.reset()

    # Define test vectors: (seed, length, data, expected_crc)
    vectors = [
        (0x12345678, 0x20, 0xDEADBEEF, None),   # baseline
        (0xFFFFFFFF, 0x08, 0x00000000, None),   # all ones seed, zero data
        (0x00000000, 0x10, 0xCAFEBABE, None),   # zero seed
    ]

    for seed, length, data, expected in vectors:
        # Write seed
        await tqv.write_word_reg(0x8, seed)
        # Write length
        await tqv.write_word_reg(0xC, length)
        # Write data
        await tqv.write_word_reg(0x10, data)
        # Start CRC
        await tqv.write_word_reg(0x0, 0x1)

        # Wait for interrupt
        for _ in range(1000):
            await RisingEdge(dut.clk)
            if await tqv.is_interrupt_asserted():
                break

        # Read result
        result = await tqv.read_word_reg(0x14)
        dut._log.info(f"CRC test vector: seed={hex(seed)}, data={hex(data)}, result={hex(result)}")

        # Optional check if you know expected CRC values
        if expected is not None:
            assert result == expected, f"CRC mismatch: got {hex(result)}, expected {hex(expected)}"