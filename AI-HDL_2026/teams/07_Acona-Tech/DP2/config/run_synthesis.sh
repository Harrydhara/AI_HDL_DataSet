#!/bin/bash
#============================================================================
# DP2 Synthesis Scripts for Clock-Gated AES-128
# 
# This script runs synthesis on both baseline and optimized designs
# to compare area metrics.
#
# Usage:
#   ./run_synthesis.sh
#
# Output:
#   - baseline_synth.log   : Baseline synthesis report
#   - optimized_synth.log  : Optimized synthesis report
#   - comparison.txt       : Side-by-side comparison
#============================================================================

echo "=============================================="
echo "  DP2 Synthesis Comparison"
echo "  Baseline vs Clock-Gated AES-128"
echo "=============================================="

#--------------------------------------------------------------------
# Step 1: Synthesize Baseline Design
#--------------------------------------------------------------------
echo ""
echo "--- Synthesizing Baseline Design ---"

yosys -p "
# Read baseline RTL files
read_verilog -sv ../rtl/aes_sbox.sv
read_verilog -sv ../rtl/aes_mixcolumns.sv
read_verilog -sv ../rtl/aes_key_expansion.sv
read_verilog -sv ../rtl/aes_core.sv
read_verilog -sv ../rtl/aes_control_fsm.sv
read_verilog -sv ../rtl/aes_reg_interface.sv
read_verilog -sv ../rtl/tqvp_aes128.sv
read_verilog -sv ../rtl/tqvp_aes128_top.sv

# Elaborate
hierarchy -top tqvp_aes128_top

# Synthesize
proc; opt; fsm; opt; memory; opt
techmap; opt

# Report
stat

# Write netlist
write_verilog baseline_netlist.v
" > baseline_synth.log 2>&1

echo "Baseline synthesis complete. See baseline_synth.log"

#--------------------------------------------------------------------
# Step 2: Synthesize Optimized Design
#--------------------------------------------------------------------
echo ""
echo "--- Synthesizing Optimized Design (Clock Gated) ---"

yosys -p "
# Read baseline RTL files (unchanged modules)
read_verilog -sv ../rtl/aes_sbox.sv
read_verilog -sv ../rtl/aes_mixcolumns.sv
read_verilog -sv ../rtl/aes_key_expansion.sv
read_verilog -sv ../rtl/aes_core.sv
read_verilog -sv ../rtl/aes_control_fsm.sv
read_verilog -sv ../rtl/aes_reg_interface.sv

# Read optimized RTL files
read_verilog -sv aes_clock_gate.sv
read_verilog -sv tqvp_aes128_opt.sv

# Elaborate
hierarchy -top tqvp_aes128_top_opt

# Synthesize
proc; opt; fsm; opt; memory; opt
techmap; opt

# Report
stat

# Write netlist
write_verilog optimized_netlist.v
" > optimized_synth.log 2>&1

echo "Optimized synthesis complete. See optimized_synth.log"

#--------------------------------------------------------------------
# Step 3: Extract and Compare Statistics
#--------------------------------------------------------------------
echo ""
echo "--- Generating Comparison Report ---"

cat > comparison.txt << 'EOF'
============================================================
  DP2 Synthesis Comparison: Baseline vs Clock-Gated
============================================================

BASELINE DESIGN (tqvp_aes128_top):
----------------------------------
EOF

grep -A 20 "=== tqvp_aes128_top ===" baseline_synth.log >> comparison.txt 2>/dev/null || echo "  (extract stats manually from baseline_synth.log)" >> comparison.txt

cat >> comparison.txt << 'EOF'

OPTIMIZED DESIGN (tqvp_aes128_top_opt):
---------------------------------------
EOF

grep -A 20 "=== tqvp_aes128_top_opt ===" optimized_synth.log >> comparison.txt 2>/dev/null || echo "  (extract stats manually from optimized_synth.log)" >> comparison.txt

cat >> comparison.txt << 'EOF'

============================================================
  EXPECTED CHANGES
============================================================
  - Area:  Slight increase (~2-5%) due to clock gate cells
  - Power: Significant decrease (~15-25%) when idle
  - Timing: No change (same critical path)
  
  NOTE: Power savings are realized during operation when
        modules are idle. This cannot be measured by synthesis
        alone - requires simulation with activity analysis.
============================================================
EOF

echo ""
echo "Comparison saved to comparison.txt"

#--------------------------------------------------------------------
# Summary
#--------------------------------------------------------------------
echo ""
echo "=============================================="
echo "  Synthesis Complete!"
echo "=============================================="
echo "  Files generated:"
echo "    - baseline_synth.log"
echo "    - optimized_synth.log"
echo "    - baseline_netlist.v"
echo "    - optimized_netlist.v"
echo "    - comparison.txt"
echo "=============================================="
