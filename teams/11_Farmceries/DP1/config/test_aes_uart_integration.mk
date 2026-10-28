# Makefile for AES-UART Integration tests

TOPLEVEL_LANG = verilog
SIM = icarus
WAVES = 1

VERILOG_SOURCES = $(PWD)/../src/aes/aes_sbox.v \
                  $(PWD)/../src/aes/aes_shift_rows.v \
                  $(PWD)/../src/aes/aes_mix_columns.v \
                  $(PWD)/../src/aes/aes_add_round_key.v \
                  $(PWD)/../src/aes/aes_key_expansion.v \
                  $(PWD)/../src/aes/aes_round.v \
                  $(PWD)/../src/aes/aes_inv_round.v \
                  $(PWD)/../src/aes/aes_core.v \
                  $(PWD)/../src/aes/aes_uart_controller.v

TOPLEVEL = aes_uart_controller
MODULE = test_aes_uart_integration

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean
clean::
	rm -rf sim_build
	rm -f results.xml
	rm -f *.vcd *.fst
