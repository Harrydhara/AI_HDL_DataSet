# Makefile for AES Core tests
# Uses Icarus Verilog and cocotb

TOPLEVEL_LANG = verilog

VERILOG_SOURCES = $(PWD)/../src/aes/aes_sbox.v \
                  $(PWD)/../src/aes/aes_shift_rows.v \
                  $(PWD)/../src/aes/aes_mix_columns.v \
                  $(PWD)/../src/aes/aes_add_round_key.v \
                  $(PWD)/../src/aes/aes_key_expansion.v \
                  $(PWD)/../src/aes/aes_round.v \
                  $(PWD)/../src/aes/aes_inv_round.v \
                  $(PWD)/../src/aes/aes_core.v

TOPLEVEL = aes_core
MODULE = test_aes_core

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean
clean::
	rm -rf sim_build
	rm -f results.xml
	rm -f *.vcd *.fst
