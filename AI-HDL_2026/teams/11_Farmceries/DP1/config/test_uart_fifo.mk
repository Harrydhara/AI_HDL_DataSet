# Makefile for UART FIFO cocotb test

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Source files
VERILOG_SOURCES = $(PWD)/../src/uart/uart_fifo.v

# Testbench
COCOTB_TEST_MODULES = test_uart_fifo

# DUT (Device Under Test)
TOPLEVEL = uart_fifo

# Include cocotb's make rules
include $(shell cocotb-config --makefiles)/Makefile.sim
