# test_peripheral_security.mk
# Run with:  make -f test_peripheral_security.mk

SIM     = iverilog
SIMRUN  = vvp
WAVE    = gtkwave

SRCS    = peripheral.v          \
          bist_ctrl.v           \
          systolic.v            \
          pe_macc.v             \
          pe_activation.v       \
          mvu.v                 \
          vpu.v                 \
          tb_peripheral_security.v

OUT     = tb_peripheral_security.out
VCD     = tb_peripheral_security.vcd

.PHONY: all clean wave

all: $(OUT)
	$(SIMRUN) $(OUT)

$(OUT): $(SRCS)
	$(SIM) -o $@ -Wall $(SRCS)

wave: $(VCD)
	$(WAVE) $(VCD) &

clean:
	rm -f $(OUT) $(VCD)