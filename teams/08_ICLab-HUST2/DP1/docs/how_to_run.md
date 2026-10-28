# How to Run — ICLab_HUST2 (Winograd Convolution Accelerator)

## Prerequisites

```bash
# Required tools
sudo apt install -y iverilog gtkwave yosys verilator
pip install cocotb pytest

# Optional (for OpenLane2)
# OpenLane2 v2.3.10 via Docker: https://openlane2.readthedocs.io
```

---

## 1. Lint Check (Verilator)

```bash
cd src/

verilator --lint-only --top-module tqvp_winograd \
  tqvp_winograd.v interface.v winograd.v \
  matrix_filter.v matrix_input.v matrix_output.v element_wise.v

# Expected: No errors, no warnings
```

---

## 2. Test 1 — Peripheral-Only Test (Provided SPI Harness)

```bash
cd testbench/tb_main/

# Install dependencies
pip install -r requirements.txt

# Run simulation
make

# Expected output:
# ** TESTS=2  PASS=2  FAIL=0  SKIP=0 **
```

View waveform:
```bash
gtkwave tb.vcd
```

---

## 3. Test 2 — Full Integration Test (GitHub Actions CI)

**CI Results:** https://github.com/[user]/ttsky25a-tinyQV/actions

Job `test (peri_num_14)` → Successful ✅

Or run locally (requires cloning ttsky25a-tinyQV):
```bash
git clone https://github.com/[user]/ttsky25a-tinyQV
cd ttsky25a-tinyQV/test
pip install -r requirements.txt
make peri_num_14

# Expected: TESTS=2 PASS=2 FAIL=0
```

---

## 4. Custom Testbenches

```bash
cd src/

# tb_wino — Winograd conv top (7 tests)
iverilog -o sim_wino ../testbench/tb_custom/tb_wino.v \
  winograd.v matrix_input.v matrix_filter.v matrix_output.v element_wise.v \
  && vvp sim_wino
# Expected: Total Tests: 7  Errors: 0  *** ALL TESTS PASSED ***

# tb_interface — Register map (4 tests)
iverilog -o sim_interface ../testbench/tb_custom/tb_interface.v \
  interface.v winograd.v matrix_input.v matrix_filter.v matrix_output.v element_wise.v \
  && vvp sim_interface
# Expected: Tests: 4  Errors: 0  ALL TESTS PASSED

# tb_filter — Filter transform
iverilog -o sim_filter ../testbench/tb_custom/tb_filter.v matrix_filter.v \
  && vvp sim_filter
# Expected: ALL TESTS PASSED!

# tb_input — Input transform
iverilog -o sim_input ../testbench/tb_custom/tb_input.v matrix_input.v \
  && vvp sim_input
# Expected: 2 PASS, 1 known issue (testbench expected value wrong, RTL correct)

# tb_output — Output transform
iverilog -o sim_output ../testbench/tb_custom/tb_output.v matrix_output.v \
  && vvp sim_output
# Expected: ALL TESTS PASSED!

# tb_mult — Element-wise Hadamard
iverilog -o sim_mult ../testbench/tb_custom/tb_mult.v element_wise.v \
  && vvp sim_mult
# Expected: Total Tests: 2  Errors: 0  ALL TESTS PASSED!
```

---

## 5. Synthesis (Yosys — Technology Independent)

```bash
cd src/

yosys -p "
read_verilog peripheral.v interface.v winograd.v \
  matrix_filter.v matrix_input.v matrix_output.v element_wise.v;
hierarchy -top peripheral;
synth -top peripheral;
stat;
"

# Expected:
# Number of cells: ~64,416
# Flip-flops:       ~7,498
# No errors
```

---

## 6. Full ASIC Flow (OpenLane2)

Requires OpenLane2 v2.3.10 installed.

```bash
cd src/

# Create config (if not present)
cat > config.json << 'EOF'
{
    "DESIGN_NAME": "peripheral",
    "VERILOG_FILES": "dir::*.v",
    "CLOCK_PORT": "clk",
    "CLOCK_PERIOD": 15,
    "FP_CORE_UTIL": 40,
    "GRT_ANTENNA_ITERS": 10,
    "RUN_HEURISTIC_DIODE_INSERTION": true,
    "RUN_ANTENNA_REPAIR": true
}
EOF

openlane config.json

# Results will be in: runs/*/final/
# - GDS layout:     runs/*/final/gds/peripheral.gds
# - Timing reports: runs/*/final/reports/timing/
# - Metrics:        runs/*/metrics.csv
```

View GDS layout:
```bash
klayout runs/*/final/gds/peripheral.gds
```

---

## 7. Expected PPA Results

| Metric | Value |
|---|---|
| Die Area | 0.604 mm² |
| Instance Count | 90,130 cells |
| Total Power (TT) | 54.91 mW |
| Setup WNS (TT, 25°C) | +3.271 ns ✅ |
| Hold WNS (TT, 25°C) | +0.315 ns ✅ |
| DRC Errors | 0 ✅ |
| LVS Errors | 0 ✅ |

Full PPA report: `results/synthesis/PPA_result.md`  
Full timing report: `results/timing/timing_rpt.md`
