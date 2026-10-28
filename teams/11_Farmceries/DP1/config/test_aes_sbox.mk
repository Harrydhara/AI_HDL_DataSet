# Makefile for AES S-Box tests
# Uses Icarus Verilog and cocotb

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(PWD)/../src/aes/aes_sbox.v
TOPLEVEL = aes_sbox
MODULE = test_aes_sbox

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean
clean::
	rm -rf sim_build
	rm -f results.xml
	rm -f *.vcd *.fst
