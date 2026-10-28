#!/bin/bash
# Quick test runner for the brute force engine

echo "=========================================="
echo "Testing Hardware Brute Force Engine"
echo "=========================================="

# Check if we're in WSL
if grep -qi microsoft /proc/version; then
    echo "✓ Running in WSL"
fi

# Install dependencies if needed
echo ""
echo "Installing Python dependencies..."
pip install -q -r requirements.txt

# Run the tests
echo ""
echo "Running cocotb tests..."
make -B

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ All tests passed!"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "✗ Tests failed!"
    echo "=========================================="
    exit 1
fi

# View waveform (optional)
echo ""
echo "To view waveforms, run:"
echo "  gtkwave tb.vcd tb.gtkw"
