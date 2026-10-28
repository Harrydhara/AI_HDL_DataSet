# Cocotb test for UART Register Interface

TOPLEVEL_LANG = verilog
SIM = icarus
WAVES = 1

# Verilog source files
VERILOG_SOURCES = \
	$(PWD)/../src/uart/uart_register_interface.v

# Top-level module
TOPLEVEL = uart_register_interface

# Test module
MODULE = test_uart_reg_interface

# Simulation compile arguments
COMPILE_ARGS += -g2012

# Include cocotb makefiles
include $(shell cocotb-config --makefiles)/Makefile.sim
