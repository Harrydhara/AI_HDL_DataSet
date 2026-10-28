# Cocotb test for complete UART Peripheral with FIFOs and Flow Control

TOPLEVEL_LANG = verilog
SIM = icarus
WAVES = 1

# Verilog source files (includes FIFOs and flow control modules)
VERILOG_SOURCES = \
	$(PWD)/../src/uart/uart_baud_generator.v \
	$(PWD)/../src/uart/uart_tx.v \
	$(PWD)/../src/uart/uart_rx.v \
	$(PWD)/../src/uart/uart_fifo.v \
	$(PWD)/../src/uart/uart_tx_flow.v \
	$(PWD)/../src/uart/uart_rts_gen.v \
	$(PWD)/../src/uart/uart_register_interface.v \
	$(PWD)/../src/uart/uart_peripheral.v

# Top-level module
TOPLEVEL = uart_peripheral

# Test module
MODULE = test_uart_peripheral

# Simulation compile arguments
COMPILE_ARGS += -g2012

# Include cocotb makefiles
include $(shell cocotb-config --makefiles)/Makefile.sim
