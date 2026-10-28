# Cocotb test for UART TX-RX Loopback

TOPLEVEL_LANG = verilog
SIM = icarus
WAVES = 1

# Verilog source files
VERILOG_SOURCES = \
	$(PWD)/../src/uart/uart_baud_generator.v \
	$(PWD)/../src/uart/uart_tx.v \
	$(PWD)/../src/uart/uart_rx.v \
	$(PWD)/../src/uart/uart_txrx_wrapper.v

# Top-level module
TOPLEVEL = uart_txrx_wrapper

# Test module
MODULE = test_uart_loopback

# Simulation compile arguments
COMPILE_ARGS += -I$(PWD)/../src/uart

# Include cocotb makefiles
include $(shell cocotb-config --makefiles)/Makefile.sim

# Clean target
clean::
	rm -rf __pycache__ sim_build results.xml *.vcd
