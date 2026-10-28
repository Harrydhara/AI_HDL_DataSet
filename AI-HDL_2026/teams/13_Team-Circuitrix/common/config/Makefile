# ====================================================
# Makefile for PWM Generator - AI-HDL 2026
#for simulating the PWM generator using Icarus Verilog
# for building automated testbenches and running simulations
# ====================================================

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Files
RTL_FILES = pwm_generator.v
TB_FILE = tb_pwm_generator.v
VCD_FILE = pwm_generator.vcd
EXECUTABLE = pwm_test

# Simulation
all: compile run

compile:
	@echo "Compiling Verilog files..."
	$(IVERILOG) -o $(EXECUTABLE) $(RTL_FILES) $(TB_FILE)

run:
	@echo "Running simulation..."
	$(VVP) $(EXECUTABLE)

wave:
	@echo "Opening waveform viewer..."
	$(GTKWAVE) $(VCD_FILE) &

clean:
	@echo "Cleaning up..."
	rm -f $(EXECUTABLE) $(VCD_FILE) *.vcd
	rm -f *.o *.out

test: clean compile run

.PHONY: all compile run wave clean test