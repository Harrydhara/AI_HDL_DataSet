# Makefile for AES AddRoundKey tests

TOPLEVEL_LANG = verilog
SIM = icarus
WAVES = 1

VERILOG_SOURCES = $(PWD)/../src/aes/aes_add_round_key.v
TOPLEVEL = aes_add_round_key
MODULE = test_aes_components

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean
clean::
	rm -rf sim_build
	rm -f results.xml
	rm -f *.vcd *.fst
