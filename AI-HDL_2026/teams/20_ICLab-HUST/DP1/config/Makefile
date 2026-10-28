# TinyQV DMA Verilator Simulation Makefile
# Usage:
#   make lint          - Run lint checks on all RTL
#   make sim_dma       - Run DMA controller testbench
#   make sim_dma_top   - Run DMA top integration testbench
#   make sim_arbiter   - Run DMA arbiter testbench
#   make wave_dma      - View DMA waveforms
#   make wave_dma_top  - View DMA top waveforms
#   make wave_arbiter  - View arbiter waveforms
#   make clean         - Clean build artifacts

VERILATOR = verilator
VERILATOR_FLAGS = --binary --trace -Wall -Wno-fatal \
	-Wno-DECLFILENAME \
	-Wno-UNUSEDSIGNAL \
	-Wno-TIMESCALEMOD \
	-Wno-CASEINCOMPLETE \
	-Wno-SYNCASYNCNET

RTL_DIR = rtl
TB_DIR = tb
OBJ_DIR = obj_dir

# ============================================================================
# RTL Source Files (organized by module hierarchy)
# ============================================================================

# All RTL sources
RTL_SRCS = $(wildcard $(RTL_DIR)/*.v)

# Core CPU components
CPU_SRCS = \
	$(RTL_DIR)/cpu.v \
	$(RTL_DIR)/decode.v \
	$(RTL_DIR)/alu.v \
	$(RTL_DIR)/core.v \
	$(RTL_DIR)/register.v \
	$(RTL_DIR)/counter.v \
	$(RTL_DIR)/latch_reg.v \
	$(RTL_DIR)/time.v

# Memory controller components
MEM_CTRL_SRCS = \
	$(RTL_DIR)/mem_ctrl.v \
	$(RTL_DIR)/qspi_ctrl.v

# DMA components
DMA_SRCS = \
	$(RTL_DIR)/tinyqv_dma.v \
	$(RTL_DIR)/dma_arbiter.v

# TinyQV wrapper (original, not used in new design)
TINYQV_WRAPPER = $(RTL_DIR)/tinyqv.v

# Full DMA top module and all dependencies
DMA_TOP_SRCS = \
	$(RTL_DIR)/tinyqv_dma_top.v \
	$(CPU_SRCS) \
	$(MEM_CTRL_SRCS) \
	$(DMA_SRCS)

# ============================================================================
# Default Target
# ============================================================================

.PHONY: all
all: lint

# ============================================================================
# Lint Targets
# ============================================================================

# Lint all RTL files
.PHONY: lint
lint:
	$(VERILATOR) --lint-only -Wall -Wno-DECLFILENAME $(RTL_SRCS)

# Lint only DMA top and dependencies
.PHONY: lint_dma_top
lint_dma_top:
	$(VERILATOR) --lint-only -Wall -Wno-DECLFILENAME -I$(RTL_DIR) $(DMA_TOP_SRCS)

# ============================================================================
# Simulation Targets
# ============================================================================

# DMA controller testbench (standalone)
.PHONY: sim_dma
sim_dma:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		-I$(RTL_DIR) \
		$(RTL_DIR)/tinyqv_dma.v \
		$(TB_DIR)/tb_tinyqv_dma.v \
		--top-module tb_tinyqv_dma \
		-o Vtb_tinyqv_dma
	./$(OBJ_DIR)/Vtb_tinyqv_dma

# DMA top integration testbench (full system)
# Includes: CPU, mem_ctrl, QSPI, DMA, arbiter
.PHONY: sim_dma_top
sim_dma_top:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		-I$(RTL_DIR) \
		$(DMA_TOP_SRCS) \
		$(TB_DIR)/tb_tinyqv_dma_top.v \
		--top-module tb_tinyqv_dma_top \
		-o Vtb_tinyqv_dma_top
	./$(OBJ_DIR)/Vtb_tinyqv_dma_top

# DMA arbiter testbench (standalone)
.PHONY: sim_arbiter
sim_arbiter:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		-I$(RTL_DIR) \
		$(RTL_DIR)/dma_arbiter.v \
		$(TB_DIR)/tb_dma_arbiter.v \
		--top-module tb_dma_arbiter \
		-o Vtb_dma_arbiter
	./$(OBJ_DIR)/Vtb_dma_arbiter

# Run all simulations
.PHONY: sim_all
sim_all: sim_dma sim_arbiter sim_dma_top
	@echo "============================================"
	@echo "All simulations completed!"
	@echo "============================================"

# ============================================================================
# Waveform Viewing
# ============================================================================

.PHONY: wave_dma
wave_dma:
	gtkwave tb_tinyqv_dma.vcd &

.PHONY: wave_dma_top
wave_dma_top:
	gtkwave tb_tinyqv_dma_top.vcd &

.PHONY: wave_arbiter
wave_arbiter:
	gtkwave tb_dma_arbiter.vcd &

# ============================================================================
# Build Only (without running)
# ============================================================================

.PHONY: build_dma
build_dma:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		-I$(RTL_DIR) \
		$(RTL_DIR)/tinyqv_dma.v \
		$(TB_DIR)/tb_tinyqv_dma.v \
		--top-module tb_tinyqv_dma \
		-o Vtb_tinyqv_dma

.PHONY: build_dma_top
build_dma_top:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		-I$(RTL_DIR) \
		$(DMA_TOP_SRCS) \
		$(TB_DIR)/tb_tinyqv_dma_top.v \
		--top-module tb_tinyqv_dma_top \
		-o Vtb_tinyqv_dma_top

.PHONY: build_arbiter
build_arbiter:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		-I$(RTL_DIR) \
		$(RTL_DIR)/dma_arbiter.v \
		$(TB_DIR)/tb_dma_arbiter.v \
		--top-module tb_dma_arbiter \
		-o Vtb_dma_arbiter

# ============================================================================
# Clean
# ============================================================================

.PHONY: clean
clean:
	rm -rf $(OBJ_DIR) *.vcd *.fst

.PHONY: clean_waves
clean_waves:
	rm -f *.vcd *.fst

# ============================================================================
# Help
# ============================================================================

.PHONY: help
help:
	@echo "TinyQV DMA Simulation Makefile"
	@echo "=============================="
	@echo ""
	@echo "Lint targets:"
	@echo "  make lint          - Lint all RTL files"
	@echo "  make lint_dma_top  - Lint DMA top and dependencies only"
	@echo ""
	@echo "Simulation targets:"
	@echo "  make sim_dma       - Run DMA controller testbench"
	@echo "  make sim_dma_top   - Run DMA top integration testbench (full system)"
	@echo "  make sim_arbiter   - Run DMA arbiter testbench"
	@echo "  make sim_all       - Run all simulations"
	@echo ""
	@echo "Build only (no run):"
	@echo "  make build_dma     - Build DMA testbench"
	@echo "  make build_dma_top - Build DMA top testbench"
	@echo "  make build_arbiter - Build arbiter testbench"
	@echo ""
	@echo "Waveform viewing:"
	@echo "  make wave_dma      - View DMA controller waveforms"
	@echo "  make wave_dma_top  - View DMA top waveforms"
	@echo "  make wave_arbiter  - View DMA arbiter waveforms"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean         - Remove all build artifacts and waveforms"
	@echo "  make clean_waves   - Remove waveform files only"
	@echo ""
	@echo "Module hierarchy for sim_dma_top:"
	@echo "  tinyqv_dma_top"
	@echo "  ├── tinyqv_cpu (cpu.v)"
	@echo "  │   ├── tinyqv_decoder (decode.v)"
	@echo "  │   ├── tinyqv_alu (alu.v)"
	@echo "  │   ├── tinyqv_core (core.v)"
	@echo "  │   ├── tinyqv_registers (register.v)"
	@echo "  │   ├── tinyqv_counter (counter.v)"
	@echo "  │   └── tinyqv_latch_reg (latch_reg.v)"
	@echo "  ├── tinyqv_mem_ctrl (mem_ctrl.v)"
	@echo "  │   └── qspi_controller (qspi_ctrl.v)"
	@echo "  ├── tinyqv_dma (tinyqv_dma.v)"
	@echo "  └── dma_arbiter (dma_arbiter.v)"
