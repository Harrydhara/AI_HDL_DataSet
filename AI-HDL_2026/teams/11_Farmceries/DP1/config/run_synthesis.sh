#!/bin/bash
# AI-HDL DP#1 Synthesis and PPA Analysis Script
# This script:
# 1. Creates a temporary flat directory with all source files
# 2. Generates synthesis scripts
# 3. Runs Yosys synthesis
# 4. Optionally preps for OpenLANE PPA analysis
# 5. Cleans up temporary files (use --cleanup flag)
#
# Usage: ./run_synthesis.sh [--cleanup]

set -e  # Exit on any error

# Parse arguments
CLEANUP=false
if [[ "$1" == "--cleanup" ]]; then
    CLEANUP=true
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== AI-HDL DP#1 Synthesis Script ===${NC}"
echo ""

# Configuration
WORK_DIR="synthesis-work"
PERIPHERAL_NAME="uart"  # Change this to match your peripheral module name
TOP_MODULE="tt_um_tqv_peripheral_harness"

# Step 1: Create temporary working directory
echo -e "${YELLOW}[1/6] Creating temporary working directory...${NC}"
if [ -d "$WORK_DIR" ]; then
    echo "Removing existing $WORK_DIR directory..."
    rm -rf "$WORK_DIR"
fi
mkdir -p "$WORK_DIR"

# Step 2: Copy all source files to flat directory
echo -e "${YELLOW}[2/6] Copying source files...${NC}"

# Copy peripheral source files
echo "  - Copying peripheral source files..."
cp peripheral/src/peripheral.v "$WORK_DIR/"
cp peripheral/src/tt_wrapper.v "$WORK_DIR/"

# Copy UART peripheral modules
echo "  - Copying UART peripheral modules..."
cp peripheral/src/uart/*.v "$WORK_DIR/"

# Copy AES peripheral modules (Phase 2)
echo "  - Copying AES peripheral modules..."
cp peripheral/src/aes/*.v "$WORK_DIR/" 2>/dev/null || echo "    (No AES modules found - Phase 1 only)"

# Copy test harness files
echo "  - Copying test harness files..."
cp peripheral/src/test_harness/*.sv "$WORK_DIR/"

# Copy CPU core files
echo "  - Copying CPU core files..."
cp cpu/src/*.v "$WORK_DIR/"

echo -e "${GREEN}  ✓ All files copied${NC}"

# Step 3: Generate Yosys synthesis script
echo -e "${YELLOW}[3/6] Generating Yosys synthesis script...${NC}"

cat > "$WORK_DIR/synth.ys" << 'EOF'
# synth.ys - Yosys Synthesis Script for AI-HDL DP#1

# 1. Read SystemVerilog files (test harness)
read_verilog -sv reclocking.sv
read_verilog -sv rising_edge_detector.sv
read_verilog -sv falling_edge_detector.sv
read_verilog -sv spi_reg.sv
read_verilog -sv synchronizer.sv

# 2. Read Verilog files (CPU core - order generally doesn't matter in Yosys, but bottom-up is safer)
read_verilog alu.v
read_verilog core.v
read_verilog counter.v
read_verilog cpu.v
read_verilog decode.v
read_verilog latch_reg.v
read_verilog mem_ctrl.v
read_verilog qspi_ctrl.v
read_verilog qspi_flash.v
read_verilog register.v
read_verilog time.v

# 3. Read UART peripheral modules
read_verilog uart_baud_generator.v
read_verilog uart_tx.v
read_verilog uart_rx.v
read_verilog uart_register_interface.v
read_verilog uart_peripheral.v

# 3b. Read AES peripheral modules (Phase 2 - in dependency order)
read_verilog -defer aes_sbox.v
read_verilog -defer aes_add_round_key.v
read_verilog -defer aes_shift_rows.v
read_verilog -defer aes_mix_columns.v
read_verilog -defer aes_round.v
read_verilog -defer aes_inv_round.v
read_verilog -defer aes_key_expansion.v
read_verilog -defer aes_core.v
read_verilog -defer aes_uart_streaming.v
read_verilog -defer aes_uart_controller.v
read_verilog -defer secure_uart_peripheral.v

# 4. Read top-level peripheral and wrapper
read_verilog peripheral.v
read_verilog tinyqv.v
read_verilog tt_wrapper.v

# 5. Check hierarchy and synthesize
# Replace 'tt_um_tqv_peripheral_harness' with your actual top module name
hierarchy -top tt_um_tqv_peripheral_harness
synth -top tt_um_tqv_peripheral_harness

# 6. Generate statistics and cleanup
opt
clean
stat

# 5. (Optional) Write synthesized netlist
# Uncomment the line below if you want to see the gate-level netlist
# write_verilog synth_netlist.v
EOF

echo -e "${GREEN}  ✓ synth.ys created${NC}"

# Step 4: Run Yosys synthesis
echo -e "${YELLOW}[4/6] Running Yosys synthesis...${NC}"
echo "  This may take a few moments..."
echo ""

cd "$WORK_DIR"

if yosys synth.ys > synthesis.log 2>&1; then
    echo -e "${GREEN}  ✓ Synthesis completed successfully!${NC}"
    echo ""
    echo "=== Synthesis Statistics ==="
    grep -A 20 "Printing statistics" synthesis.log || echo "Statistics not found in log"
    echo ""
else
    echo -e "${RED}  ✗ Synthesis failed!${NC}"
    echo "Check $WORK_DIR/synthesis.log for details"
    cd ..
    exit 1
fi

cd ..

# Step 5: Generate OpenLANE config.json
echo -e "${YELLOW}[5/6] Generating OpenLANE config.json...${NC}"

# Copy and modify the base config from peripheral/src/config.json
# Remove JSON comment entries (keys that are "//") and add our specific fields
python3 << PYTHON_CONFIG
import json

# Load the base config
with open('peripheral/src/config.json', 'r') as f:
    config = json.load(f)

# Remove comment keys
config = {k: v for k, v in config.items() if k != '//'}

# Override/add our specific fields
config['DESIGN_NAME'] = '$TOP_MODULE'
config['VERILOG_FILES'] = [
    'dir::reclocking.sv',
    'dir::synchronizer.sv',
    'dir::rising_edge_detector.sv',
    'dir::falling_edge_detector.sv',
    'dir::spi_reg.sv',
    'dir::alu.v',
    'dir::core.v',
    'dir::decode.v',
    'dir::cpu.v',
    'dir::register.v',
    'dir::latch_reg.v',
    'dir::mem_ctrl.v',
    'dir::qspi_ctrl.v',
    'dir::qspi_flash.v',
    'dir::uart_baud_generator.v',
    'dir::uart_tx.v',
    'dir::uart_rx.v',
    'dir::uart_register_interface.v',
    'dir::uart_peripheral.v',
    'dir::peripheral.v',
    'dir::counter.v',
    'dir::time.v',
    'dir::tinyqv.v',
    'dir::tt_wrapper.v'
]
config['DIE_AREA'] = '0 0 161.00 111.52'

# Write to synthesis-work
with open('$WORK_DIR/config.json', 'w') as f:
    json.dump(config, f, indent=2)
PYTHON_CONFIG

echo -e "${GREEN}  ✓ config.json created${NC}"

# Step 6: Summary and next steps
echo ""
echo -e "${GREEN}=== Synthesis Complete! ===${NC}"
echo ""
echo "Working directory: $WORK_DIR/"
echo "  - synthesis.log     : Full Yosys output"
echo "  - synth.ys          : Synthesis script"
echo "  - config.json       : OpenLANE configuration"
echo "  - All source files  : Ready for OpenLANE"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Review synthesis.log for any warnings"
echo "  2. To run OpenLANE PPA analysis:"
echo "     a. Copy $WORK_DIR to your OpenLane/designs/ directory"
echo "     b. Run: cd OpenLane && make mount"
echo "     c. Run: ./flow.tcl -design $WORK_DIR"
echo ""
echo "  3. To clean up this temporary directory:"
echo "     Run: rm -rf $WORK_DIR  OR  ./run_synthesis.sh --cleanup"
echo ""

# Cleanup based on flag
if [ "$CLEANUP" = true ]; then
    echo -e "${YELLOW}Cleaning up temporary files...${NC}"
    rm -rf "$WORK_DIR"
    echo -e "${GREEN}✓ Cleanup complete${NC}"
else
    echo -e "${GREEN}✓ Files preserved in $WORK_DIR/${NC}"
    echo -e "${YELLOW}  (Use --cleanup flag to auto-remove next time)${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
