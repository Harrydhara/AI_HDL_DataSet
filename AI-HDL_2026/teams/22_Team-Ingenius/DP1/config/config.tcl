# 1. Design Name
set ::env(DESIGN_NAME) "tt_um_ingenius_crc"

# 2. Reference to the Verilog Files 
set ::env(VERILOG_FILES) [list \
    $::env(DESIGN_DIR)/../rtl/user_peripherals/tqvp_ingenius/tt_um_ingenius_crc.v \
    $::env(DESIGN_DIR)/../rtl/user_peripherals/tqvp_ingenius/crc_datapath.v \
]

# 3. Clock Configuration
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) 20.0

# 4. Basic Setup
set ::env(FP_CORE_UTIL) 40
set ::env(PL_TARGET_DENSITY) 0.5
set ::env(RUN_CTS) 1
set ::env(RUN_ROUTING) 1
