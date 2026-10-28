# Cocotb Makefile for tqvp_gpio
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES = $(shell pwd)/../src/tqvp_gpio.v
TOPLEVEL = tqvp_gpio
MODULE = test

include $(shell cocotb-config --makefiles)/Makefile.sim
