# Makefile for UART Baud Rate Generator cocotb test

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Source files
VERILOG_SOURCES = $(PWD)/../src/uart/uart_baud_generator.v

# Testbench
MODULE = test_baud_gen

# DUT (Device Under Test)
TOPLEVEL = uart_baud_generator

# Include cocotb's make rules
include $(shell cocotb-config --makefiles)/Makefile.sim
