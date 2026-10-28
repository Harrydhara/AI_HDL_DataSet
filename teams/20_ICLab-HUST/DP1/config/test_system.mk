# Makefile for the full-system TinyQV + tqvp_dma testbench.
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

SIM            ?= verilator
TOPLEVEL_LANG  ?= verilog

CPUD = $(PWD)/../src

# All CPU sources EXCEPT peripherals.v (replaced by peripherals_stub.v below)
VERILOG_SOURCES += $(CPUD)/project.v
VERILOG_SOURCES += $(CPUD)/tinyqv.v
VERILOG_SOURCES += $(CPUD)/cpu.v
VERILOG_SOURCES += $(CPUD)/core.v
VERILOG_SOURCES += $(CPUD)/decode.v
VERILOG_SOURCES += $(CPUD)/register.v
VERILOG_SOURCES += $(CPUD)/alu.v
VERILOG_SOURCES += $(CPUD)/counter.v
VERILOG_SOURCES += $(CPUD)/latch_reg.v
VERILOG_SOURCES += $(CPUD)/qspi_ctrl.v
VERILOG_SOURCES += $(CPUD)/qspi_flash.v
VERILOG_SOURCES += $(CPUD)/mem_ctrl.v
VERILOG_SOURCES += $(CPUD)/time.v
VERILOG_SOURCES += $(CPUD)/uart_tx.v
VERILOG_SOURCES += $(CPUD)/tqvp_dma.v

# Test-directory sources
VERILOG_SOURCES += $(PWD)/peripherals_stub.v
VERILOG_SOURCES += $(PWD)/flash_model.v
VERILOG_SOURCES += $(PWD)/tb_system.v

COMPILE_ARGS += -DSIM
COMPILE_ARGS += --timing
COMPILE_ARGS += -Wno-SYMRSVDWORD
COMPILE_ARGS += -Wno-IMPLICIT
COMPILE_ARGS += -Wno-PINMISSING
COMPILE_ARGS += -Wno-WIDTH
COMPILE_ARGS += -Wno-MULTIDRIVEN

SIM_BUILD ?= sim_build/system

# TOPLEVEL is the name of the toplevel module in your Verilog file
TOPLEVEL = tb_system

# MODULE is the basename of the Python test file
MODULE = test_system

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
