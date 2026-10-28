#!/bin/bash
# DP1 Quick Improvements Script
# Run in WSL: bash improvements.sh

echo "=== AI-HDL 2026 DP1 Improvements ==="
echo ""

# Improvement 1: Run Synthesis
echo "1. Running synthesis with Yosys..."
cd synth
if ! command -v yosys &> /dev/null; then
    echo "Installing Yosys..."
    sudo apt-get update && sudo apt-get install -y yosys
fi

yosys synth.ys 2>&1 | tee synth_run.log

if [ -f synth_stats.txt ]; then
    echo ""
    echo "✅ Synthesis complete! Key metrics:"
    grep "Number of cells:" synth_stats.txt | head -5
    echo ""
fi

# Improvement 2: Add edge case test
echo "2. Creating additional edge case test..."
cd ../test

cat >> test.py << 'EOF'


@cocotb.test()
async def test_gpio_edge_cases(dut):
    """Test invalid addresses and read-only register writes"""
    
    # Start clock
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_dut(dut)
    dut._log.info("Testing edge cases...")
    
    # Test 1: Invalid address read returns 0
    dut._log.info("Test: Invalid address (0x3F)")
    await RisingEdge(dut.clk)
    dut.address.value = 0x3F
    dut.data_read_n.value = 0
    await RisingEdge(dut.clk)
    read_val = int(dut.data_out.value)
    dut.data_read_n.value = 1
    await RisingEdge(dut.clk)
    assert read_val == 0, f"Invalid address should return 0, got 0x{read_val:08X}"
    dut._log.info("✓ Invalid address returns 0")
    
    # Test 2: Write to INPUT_REG (read-only) is ignored
    dut._log.info("Test: Write to read-only INPUT_REG")
    dut.ui_in.value = 0x00
    await write_reg(dut, ADDR_DIRECTION, 0x00)  # All inputs
    await write_reg(dut, ADDR_INPUT, 0xFF)  # Try to write (should be ignored)
    await Timer(10, units='ns')
    read_val = await read_reg(dut, ADDR_INPUT)
    assert (read_val & 0xFF) == 0x00, f"INPUT_REG write should be ignored, got 0x{read_val:02X}"
    dut._log.info("✓ Read-only register protected")
    
    dut._log.info("=== Edge case tests PASSED ===")
EOF

echo "✅ Added test_gpio_edge_cases to test.py"
echo ""

# Improvement 3: Run all tests
echo "3. Running full test suite (now 4 tests)..."
make clean
make

echo ""
echo "=== IMPROVEMENTS COMPLETE ==="
echo ""
echo "Next steps:"
echo "1. Check synth/synth_stats.txt for PPA metrics"
echo "2. Review test output (should show 4/4 PASS)"
echo "3. Commit: git add -A && git commit -m 'Add synthesis results and edge case tests'"
echo "4. Push: git push origin main"
