# Makefile for AES MixColumns tests

TOPLEVEL_LANG = verilog
SIM = icarus
WAVES = 1

VERILOG_SOURCES = $(PWD)/../src/aes/aes_mix_columns.v
TOPLEVEL = aes_mix_columns
MODULE = test_aes_components

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean
clean::
	rm -rf sim_build
	rm -f results.xml
	rm -f *.vcd *.fst
