# Makefile for UART RTS Generator cocotb test

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Source files
VERILOG_SOURCES = $(PWD)/../src/uart/uart_rts_gen.v

# Testbench
COCOTB_TEST_MODULES = test_uart_rts_gen

# DUT (Device Under Test)
TOPLEVEL = uart_rts_gen

# Include cocotb's make rules
include $(shell cocotb-config --makefiles)/Makefile.sim
