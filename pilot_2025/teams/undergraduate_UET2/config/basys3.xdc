###############################################################################
# Basys 3 Minimal XDC matching your modified top_level
# (Now using 4-bit set_time_data and 2-bit set_time_phase instead of 16-bit set_time)
# Device = xc7a35tcpg236-1  (Board = "Basys 3")
###############################################################################

###############################################################################
# 1) 100 MHz clock on pin W5
###############################################################################
set_property PACKAGE_PIN W5 [get_ports {clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk}]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}]

###############################################################################
# 2) Buttons: button0..button3
# Mapping to the 4 user push buttons on Basys 3:
#   T18 = btnU, U18 = btnC, R18 = btnL, U17 = btnD
###############################################################################
set_property PACKAGE_PIN T18 [get_ports {button0}]
set_property IOSTANDARD LVCMOS33 [get_ports {button0}]

set_property PACKAGE_PIN U18 [get_ports {button1}]
set_property IOSTANDARD LVCMOS33 [get_ports {button1}]

set_property PACKAGE_PIN R18 [get_ports {button2}]
set_property IOSTANDARD LVCMOS33 [get_ports {button2}]

set_property PACKAGE_PIN U17 [get_ports {button3}]
set_property IOSTANDARD LVCMOS33 [get_ports {button3}]

###############################################################################
# 3) alarm_led (mapped to LED0 on Basys 3 at pin U16)
# Reduce drive strength from default (typically 12 mA) down to 8 mA.
###############################################################################
set_property PACKAGE_PIN U16 [get_ports {alarm_led}]
set_property IOSTANDARD LVCMOS33 [get_ports {alarm_led}]
set_property DRIVE 8 [get_ports {alarm_led}]

###############################################################################
# 4) set_time signal replacement:
# Now using a 4-bit bus "set_time_data" plus a 2-bit "set_time_phase".
# This reduces I/O usage to 6 pins total.
###############################################################################
# Mapping for set_time_data[3:0] to switches SW0..SW3:
set_property PACKAGE_PIN V17 [get_ports {set_time_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {set_time_data[0]}]

set_property PACKAGE_PIN V16 [get_ports {set_time_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {set_time_data[1]}]

set_property PACKAGE_PIN W16 [get_ports {set_time_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {set_time_data[2]}]

set_property PACKAGE_PIN W17 [get_ports {set_time_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {set_time_data[3]}]

# Mapping for set_time_phase[1:0] to switches SW4..SW5 (example):
set_property PACKAGE_PIN W15 [get_ports {set_time_phase[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {set_time_phase[0]}]

set_property PACKAGE_PIN V15 [get_ports {set_time_phase[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {set_time_phase[1]}]

###############################################################################
# 5) 7-segment display signals (internal wires, not top-level ports)
# These are commented out to avoid "no object" errors.
# If you wish to route these signals externally, remove comments and add them to top_level.
###############################################################################
# set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
# set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
# set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
# set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
# set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
# set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
# set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]
# set_property PACKAGE_PIN V7 [get_ports {dp}]
# set_property IOSTANDARD LVCMOS33 [get_ports {dp}]
# set_property PACKAGE_PIN U2 [get_ports {an[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
# set_property PACKAGE_PIN U4 [get_ports {an[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
# set_property PACKAGE_PIN V4 [get_ports {an[2]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
# set_property PACKAGE_PIN W4 [get_ports {an[3]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

###############################################################################
# 6) Configuration options
###############################################################################
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
