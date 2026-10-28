# Yosys synthesis script for new_dp1/rtl
# Output files will be in output/

set RTL_DIR "rtl"
set OUT_DIR "output"

# Read all Verilog source files
read_verilog -sv \
    $RTL_DIR/project.v \
    $RTL_DIR/tinyqv.v \
    $RTL_DIR/cpu.v \
    $RTL_DIR/core.v \
    $RTL_DIR/alu.v \
    $RTL_DIR/decode.v \
    $RTL_DIR/register.v \
    $RTL_DIR/latch_reg.v \
    $RTL_DIR/counter.v \
    $RTL_DIR/mem_ctrl.v \
    $RTL_DIR/peripherals.v \
    $RTL_DIR/qspi_ctrl.v \
    $RTL_DIR/qspi_flash.v \
    $RTL_DIR/uart_tx.v \
    $RTL_DIR/time.v \
    $RTL_DIR/tqvp_dma.v

# Set top module
hierarchy -check -top tt_um_tt_tinyQV

# Generic synthesis
synth -top tt_um_tt_tinyQV

# Write outputs
write_verilog -noattr $OUT_DIR/synth_netlist.v
write_json $OUT_DIR/synth_netlist.json
stat > $OUT_DIR/synth_stats.txt
