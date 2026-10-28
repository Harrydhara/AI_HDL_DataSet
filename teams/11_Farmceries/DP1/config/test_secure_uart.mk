TOPLEVEL_LANG = verilog
SIM = icarus

VERILOG_SOURCES += $(PWD)/../src/aes/secure_uart_peripheral.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_uart_streaming.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_core.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_round.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_inv_round.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_key_expansion.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_sbox.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_shift_rows.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_mix_columns.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_add_round_key.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_baud_generator.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_tx.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_rx.v

TOPLEVEL = secure_uart_peripheral
MODULE = test_secure_uart

include $(shell cocotb-config --makefiles)/Makefile.sim
