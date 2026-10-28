# Makefile for tqvp_dma testbench
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

# tqvp_dma.v lives in ../rtl/
SRC_DIR = $(PWD)/../src

# The peripheral under test
PROJECT_SOURCES = tqvp_dma.v

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD ?= sim_build/dma
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
VERILOG_SOURCES += $(PWD)/tt_wrapper.v
VERILOG_SOURCES += $(wildcard $(PWD)/test_harness/*.sv)

else

# Gate level simulation:
SIM_BUILD ?= sim_build/dma_gl
COMPILE_ARGS += -DGL_TEST
COMPILE_ARGS += -DFUNCTIONAL
COMPILE_ARGS += -DUSE_POWER_PINS
COMPILE_ARGS += -DSIM
COMPILE_ARGS += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Verilator: required for cocotb coroutines (ClockCycles, etc.)
COMPILE_ARGS += --timing

# Allow header sharing
COMPILE_ARGS += -I$(SRC_DIR)
COMPILE_ARGS += -I$(PWD)

# Testbench top
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# Python test module
MODULE = test

# include cocotb's make rules
include $(shell cocotb-config --makefiles)/Makefile.sim
