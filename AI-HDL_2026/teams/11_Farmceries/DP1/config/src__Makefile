# UART Peripheral - Makefile
# Integrates Verilator linting and Cocotb testing

.PHONY: help lint clean test-all

# Default target
help:
	@echo "UART Peripheral Development Workflow"
	@echo "===================================="
	@echo ""
	@echo "Targets:"
	@echo "  make lint          - Run Verilator linting on all modules"
	@echo "  make test-all      - Run all cocotb tests (Icarus Verilog)"
	@echo "  make clean         - Clean build artifacts"
	@echo ""
	@echo "Recommended workflow:"
	@echo "  1. make lint       - Check code quality"
	@echo "  2. make test-all   - Run functional tests"
	@echo ""

# Run Verilator linting
lint:
	@echo "Running Verilator linting..."
	@cd uart && ./lint.sh

# Run all cocotb tests (will be populated as modules are created)
test-all:
	@echo "Running cocotb tests..."
	@echo "Tests will be added as modules are implemented"
	# Example: cd ../../test && make -f test_baud_gen.mk
	# Example: cd ../../test && make -f test_uart_tx.mk

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@find . -name "*.vcd" -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.pyc" -delete
	@find . -name "sim_build" -type d -exec rm -rf {} + 2>/dev/null || true
	@rm -rf obj_dir/
	@echo "Clean complete"
