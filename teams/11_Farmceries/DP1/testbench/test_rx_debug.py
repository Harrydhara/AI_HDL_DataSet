"""
Simple debug test for UART RX

Monitors internal RX FSM state to understand what's happening.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_rx_debug(dut):
    """Debug RX reception with internal state monitoring"""

    clock = Clock(dut.clk, 14, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.baud_sel.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    await Timer(1, units="us")

    # Send byte 0xAA (alternating bits: easy to see)
    test_byte = 0xAA
    print(f"Sending test byte: 0x{test_byte:02X} = {test_byte:08b}")

    dut.tx_data.value = test_byte
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0

    # Wait for TX to start
    for _ in range(100):
        await RisingEdge(dut.clk)
        if dut.tx_busy.value == 1:
            break

    print("TX started...")

    # Monitor RX state for a while
    # Try to access internal signals
    rx_module = dut.rx

    last_state = None
    last_sample_cnt = None
    last_bit_cnt = None

    for i in range(1500000):  # Increase timeout significantly
        await RisingEdge(dut.clk)

        try:
            state = int(rx_module.state.value)
            sample_cnt = int(rx_module.sample_cnt.value)
            bit_cnt = int(rx_module.bit_cnt.value)
            rx_sync2 = int(rx_module.rx_sync2.value)

            # Only print on changes
            if (
                state != last_state
                or sample_cnt != last_sample_cnt
                or bit_cnt != last_bit_cnt
            ):
                # Map state values: IDLE=0, START=1, DATA=2, STOP=3
                state_names = {0: "IDLE", 1: "START", 2: "DATA", 3: "STOP"}
                state_name = state_names.get(state, f"UNKNOWN({state})")
                print(
                    f"  @ {i}: state={state_name}, sample_cnt={sample_cnt}, bit_cnt={bit_cnt}, rx_sync2={rx_sync2}"
                )
                last_state = state
                last_sample_cnt = sample_cnt
                last_bit_cnt = bit_cnt

        except AttributeError:
            pass

        # Check if done
        if dut.rx_ready.value == 1:
            print(f"✓ RX ready at cycle {i}")
            break

    print(
        f"\nFinal RX state: data=0x{int(dut.rx_data.value):02X}, error={int(dut.rx_error.value)}, ready={int(dut.rx_ready.value)}"
    )

    assert dut.rx_error.value == 0, "Frame error"
    assert dut.rx_data.value == test_byte, f"Data mismatch"
