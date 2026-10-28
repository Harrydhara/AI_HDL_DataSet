# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

CPUD = $(PWD)/../src
VERILOG_SOURCES += $(CPUD)/decode.v $(PWD)/tb_decode.v
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += --timing
COMPILE_ARGS    += -Wno-SYMRSVDWORD
COMPILE_ARGS    += -Wno-IMPLICIT
COMPILE_ARGS    += -Wno-PINMISSING

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb_decode

# MODULE is the basename of the Python test file
MODULE = test_decode

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
