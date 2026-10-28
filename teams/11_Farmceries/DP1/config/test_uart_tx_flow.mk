# Makefile for UART Flow Control cocotb test

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Source files - need both TX modules
VERILOG_SOURCES = $(PWD)/../src/uart/uart_tx.v \
                  $(PWD)/../src/uart/uart_tx_flow.v

# Testbench
COCOTB_TEST_MODULES = test_uart_tx_flow

# DUT (Device Under Test)
TOPLEVEL = uart_tx_flow

# Include cocotb's make rules
include $(shell cocotb-config --makefiles)/Makefile.sim
