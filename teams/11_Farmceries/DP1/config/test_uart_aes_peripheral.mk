TOPLEVEL_LANG = verilog
SIM = icarus

VERILOG_SOURCES += $(PWD)/../src/aes/uart_aes_peripheral.v
VERILOG_SOURCES += $(PWD)/../src/aes/aes_register_interface.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_peripheral.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_register_interface.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_baud_generator.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_tx.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_rx.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_fifo.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_tx_flow.v
VERILOG_SOURCES += $(PWD)/../src/uart/uart_rts_gen.v

TOPLEVEL = uart_aes_peripheral
MODULE = test_uart_aes_peripheral

include $(shell cocotb-config --makefiles)/Makefile.sim
