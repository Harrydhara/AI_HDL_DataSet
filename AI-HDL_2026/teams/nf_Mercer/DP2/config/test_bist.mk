# test_bist.mk  –  Cocotb + standalone Verilog runner for BIST tests
#
# Usage:
#   make -f test_bist.mk              # cocotb tests (test_bist.py)
#   make -f test_bist.mk vlog         # standalone Verilog tb_bist.v only
#   make -f test_bist.mk clean        # remove all build artefacts
#
# Mirrors test_counter.mk / test_alu.mk in this repo.

SIM           ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES  = $(PWD)/pe_macc.v
VERILOG_SOURCES += $(PWD)/pe_activation.v
VERILOG_SOURCES += $(PWD)/vpu.v
VERILOG_SOURCES += $(PWD)/mvu.v
VERILOG_SOURCES += $(PWD)/systolic.v
VERILOG_SOURCES += $(PWD)/bist_ctrl.v
VERILOG_SOURCES += $(PWD)/peripheral.v

TOPLEVEL = tqvp_example
MODULE   = test_bist

EXTRA_ARGS += -g2005-sv


VLOG_SRCS = pe_macc.v pe_activation.v vpu.v mvu.v \
            systolic.v bist_ctrl.v peripheral.v

.PHONY: vlog
vlog: tb_bist.v $(VLOG_SRCS)
	iverilog -g2005-sv -Wall -o tb_bist.out \
	    tb_bist.v $(VLOG_SRCS)
	vvp tb_bist.out

# cocotb's Makefile.sim defines clean:: so we must also use :: here
clean::
	rm -rf sim_build __pycache__ results.xml *.vcd tb_bist.out

include $(shell cocotb-config --makefiles)/Makefile.sim