# Makefile for UART Transmitter cocotb test

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Source files
VERILOG_SOURCES = $(PWD)/../src/uart/uart_tx.v

# Testbench
COCOTB_TEST_MODULES = test_uart_tx

# DUT (Device Under Test)
TOPLEVEL = uart_tx

# Include cocotb's make rules
include $(shell cocotb-config --makefiles)/Makefile.sim
