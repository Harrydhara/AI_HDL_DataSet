# Makefile for tinyQV_peripherals testbench

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

CPUD = $(PWD)/../src
VERILOG_SOURCES += $(CPUD)/tqvp_dma.v
VERILOG_SOURCES += $(CPUD)/peripherals.v
VERILOG_SOURCES += $(PWD)/tb_peripherals.v

COMPILE_ARGS += -DSIM
COMPILE_ARGS += --timing
COMPILE_ARGS += -Wno-SYMRSVDWORD
COMPILE_ARGS += -Wno-IMPLICIT
COMPILE_ARGS += -Wno-PINMISSING
COMPILE_ARGS += -Wno-WIDTH

TOPLEVEL = tb_peripherals
MODULE   = test_peripherals

include $(shell cocotb-config --makefiles)/Makefile.sim
