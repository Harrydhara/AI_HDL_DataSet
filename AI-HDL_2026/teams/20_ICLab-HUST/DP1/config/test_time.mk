# Makefile for tinyQV_time testbench

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

CPUD = $(PWD)/../src
VERILOG_SOURCES += $(CPUD)/latch_reg.v
VERILOG_SOURCES += $(CPUD)/time.v
VERILOG_SOURCES += $(PWD)/tb_time.v

COMPILE_ARGS += -DSIM
COMPILE_ARGS += --timing
COMPILE_ARGS += -Wno-SYMRSVDWORD
COMPILE_ARGS += -Wno-IMPLICIT
COMPILE_ARGS += -Wno-PINMISSING

TOPLEVEL = tb_time
MODULE   = test_time

include $(shell cocotb-config --makefiles)/Makefile.sim
