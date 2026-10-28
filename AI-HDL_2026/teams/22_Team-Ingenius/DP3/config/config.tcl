# DP3 Phase 2: Clock Gating + Multi-Vt Optimization
# Based on DP2 125 MHz baseline with power optimization

# 1. Design Name
set ::env(DESIGN_NAME) "tt_um_ingenius_crc"

# 2. Verilog Files
set ::env(VERILOG_FILES) [list \
    $::env(DESIGN_DIR)/../rtl/user_peripherals/tqvp_ingenius/tt_um_ingenius_crc.v \
    $::env(DESIGN_DIR)/../rtl/user_peripherals/tqvp_ingenius/crc_datapath.v \
]

# 3. Clock Configuration (125 MHz = 8.0 ns period, same as DP2)
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) 8.0

# 4. Core Utilization & Placement
set ::env(FP_CORE_UTIL) 45
set ::env(PL_TARGET_DENSITY) 0.5

# 5. Design Metrics (from DP2)
set ::env(RUN_CTS) 1
set ::env(RUN_ROUTING) 1
set ::env(RUN_POWER_ANALYSIS) 1

# 6. Clock Gating Configuration (NEW for DP3 Phase 2)
# Enable automatic clock gating cells
if {[catch {set ::env(CLOCK_GATING_ENABLED)} result]} {
    set ::env(CLOCK_GATING_ENABLED) 1
}

# Clock gating cell variants available in sky130
set ::env(LATCH_BASED_GATING_CELLS) "sky130_fd_sc_hd__dlclkp_1 sky130_fd_sc_hd__dlclkp_2 sky130_fd_sc_hd__dlclkp_4"

# 7. Timing Configuration for Conservative Optimization
set ::env(STA_PRE_CTS_SLACK) 0.5
set ::env(STA_HOLD_MARGIN) 0.0
set ::env(STA_POST_CTS_SLACK) 0.5

# 8. Synthesis Configuration
set ::env(SYNTH_STRATEGY) "DELAY 2"
set ::env(SYNTH_BUFFERING) 1
set ::env(SYNTH_SIZING) 1

# 9. Multi-Vt Configuration (NEW for DP3 Phase 2)
# Enable cell type variation for power optimization
if {[catch {set ::env(SYNTH_ENABLE_CELL_VT_MULTI)} result]} {
    set ::env(SYNTH_ENABLE_CELL_VT_MULTI) 1
}

# 10. Area Target (from DP2)
set ::env(GRT_ALLOW_CONGESTION) 0
set ::env(GRT_OVERFLOW_ITERS) 50

# 11. Power Analysis Settings
set ::env(POWER_GRID_NET) "VDD"
set ::env(POWER_GROUND_NET) "VSS"
