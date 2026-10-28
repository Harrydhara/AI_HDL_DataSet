# Makefile for uart_tx testbench

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

CPUD = $(PWD)/../src
VERILOG_SOURCES += $(CPUD)/uart_tx.v $(PWD)/tb_uart_tx.v

COMPILE_ARGS += -DSIM
COMPILE_ARGS += --timing
COMPILE_ARGS += -Wno-SYMRSVDWORD
COMPILE_ARGS += -Wno-IMPLICIT
COMPILE_ARGS += -Wno-PINMISSING

TOPLEVEL = tb_uart_tx
MODULE   = test_uart_tx

include $(shell cocotb-config --makefiles)/Makefile.sim
