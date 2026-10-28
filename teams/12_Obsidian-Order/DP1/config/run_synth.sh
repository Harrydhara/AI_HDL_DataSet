#!/bin/bash
# Run Yosys synthesis for tqvp_gpio
# AI-HDL 2026 DP1

echo "=== Running Yosys synthesis for tqvp_gpio ==="
echo ""

# Check if yosys is installed
if ! command -v yosys &> /dev/null; then
    echo "ERROR: Yosys not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y yosys
fi

# Run synthesis
yosys synth.ys

echo ""
echo "=== Synthesis complete! ==="
echo "Results saved to synth_stats.txt"
echo ""

# Display key metrics
if [ -f synth_stats.txt ]; then
    echo "=== Key Metrics ==="
    grep -A 20 "Number of cells:" synth_stats.txt || grep -A 10 "Printing statistics" synth_stats.txt
fi
