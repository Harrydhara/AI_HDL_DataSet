# Makefile for latch_reg testbench
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

CPUD = $(PWD)/../src
VERILOG_SOURCES += $(CPUD)/latch_reg.v $(PWD)/tb_latch_reg.v

COMPILE_ARGS += -DSIM
COMPILE_ARGS += --timing
COMPILE_ARGS += -Wno-SYMRSVDWORD
COMPILE_ARGS += -Wno-IMPLICIT
COMPILE_ARGS += -Wno-PINMISSING

TOPLEVEL = tb_latch_reg
MODULE   = test_latch_reg

include $(shell cocotb-config --makefiles)/Makefile.sim
