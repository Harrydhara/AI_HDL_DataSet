#!/bin/bash
# Initialize OpenLane and download PDK, then run synthesis

set -e  # Exit on error

echo "=========================================="
echo "DP3 Phase 2 Synthesis - Full Setup"
echo "=========================================="
echo ""
echo "Step 1: Fetching sky130A PDK via Volare..."

# Try to fetch PDK
if command -v volare &> /dev/null; then
    volare fetch sky130 --latest || true
else
    echo "Volare not found, proceeding anyway..."
fi

echo ""
echo "Step 2: Running OpenLane synthesis..."
echo ""

cd /openlane/designs/DP3

# Create minimal run script if needed
flow.tcl -design . -tag phase2_synthesis

echo ""
echo "=========================================="
echo "Synthesis completed!"
echo "=========================================="
