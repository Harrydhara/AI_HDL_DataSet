# Makefile for tinyQV (CPU + memory controller) integration testbench

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

CPUD = $(PWD)/../src

VERILOG_SOURCES += $(CPUD)/latch_reg.v
VERILOG_SOURCES += $(CPUD)/counter.v
VERILOG_SOURCES += $(CPUD)/register.v
VERILOG_SOURCES += $(CPUD)/alu.v
VERILOG_SOURCES += $(CPUD)/decode.v
VERILOG_SOURCES += $(CPUD)/core.v
VERILOG_SOURCES += $(CPUD)/cpu.v
VERILOG_SOURCES += $(CPUD)/qspi_ctrl.v
VERILOG_SOURCES += $(CPUD)/mem_ctrl.v
VERILOG_SOURCES += $(CPUD)/tinyqv.v
VERILOG_SOURCES += $(PWD)/flash_model.v
VERILOG_SOURCES += $(PWD)/tb_tinyqv.v

COMPILE_ARGS += -DSIM
COMPILE_ARGS += --timing
COMPILE_ARGS += -Wno-SYMRSVDWORD
COMPILE_ARGS += -Wno-IMPLICIT
COMPILE_ARGS += -Wno-PINMISSING
COMPILE_ARGS += -Wno-WIDTH
COMPILE_ARGS += -Wno-MULTIDRIVEN

TOPLEVEL = tb_tinyqv
MODULE   = test_tinyqv

include $(shell cocotb-config --makefiles)/Makefile.sim
