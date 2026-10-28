# How to Run — ICLab_HUST2 (Winograd Convolution Accelerator)



# Required tools

OpenLane v2.3.10

Verilator 4.038 2020-07-11 rev v4.036-114-g0cd4a57ad 

Icarus Verilog Preprocessor version 11.0

cocotb: Version: 1.9.0

Klayout: version 0.30.8
---

## 1. Lint Check


cd src/

bash lint.sh


## 2. Test SPI harness

```bash
cd testbench/tb_main/test_harness

# Install dependencies
pip install -r requirements.txt

# Run simulation
make

View waveform:
```bash
gtkwave tb.vcd
```

---

## 3. Test 2 — TinyQV SoC integration test:
```bash
pip install -r requirements.txt

**Peripheral only (slot 14):** 
cd testbench/tb_main/test_system
make peri_num_14

**Full system test (CPU + peripheral)**
cd testbench/tb_main/test_system/
MODULE=test TESTCASE=test_winograd_system make -f test_basic.mk
---
```
## 4. Custom Testbenches

```bash


# tb_wino — Winograd conv top (7 tests)
iverilog -o sim_wino testbench/tb_custom/tb_wino.v src/*.v  && vvp sim_wino

gtkwave tb_wino.vcd

# tb_interface — Register map (4 tests)
iverilog -o sim_interface testbench/tb_custom/tb_interface.v src/*.v && vvp sim_interface

gtkwave tb_interface.vcd

# tb_filter — Filter transform
iverilog -o sim_filter testbench/tb_custom/tb_filter.v src/*.v && vvp sim_filter

gtkwave tb_filter.vcd

# tb_input — Input transform
iverilog -o sim_input testbench/tb_custom/tb_input.v src/*.v && vvp sim_input
 
gtkwave tb_input.vcd

# tb_output — Output transform
iverilog -o sim_output testbench/tb_custom/tb_output.v src/*.v && vvp sim_output

gtkwave tb_output.vcd

# tb_mult — Element-wise Hadamard
iverilog -o sim_mult testbench/tb_custom/tb_mult.v src/*.v && vvp sim_mult

gtkwave tb_mult.vcd
```

---

## 5. DP3 Security Testbench (CM-1 + CM-2 + CM-3)

Requires: Icarus Verilog (`iverilog` + `vvp`)

```bash
# From repo root:
iverilog -o sim_security testbench/tb_security/tb_security.v src/*.v  && vvp sim_security
```

View waveform (optional):
```bash
gtkwave tb_security.vcd
```

8 test cases covered:
- TEST 1: Normal baseline operation (regression)
- TEST 2: INPUT_DATA write-while-busy blocked (CM-1)
- TEST 3: FILTER_DATA write-while-busy blocked (CM-1)
- TEST 4: CTRL[START] re-trigger blocked (CM-1)
- TEST 5: SEC_VIO clear-on-read (CM-1)
- TEST 6: Debug sentinel removed — 0x0 not 0xDEADBEEF (CM-2)
- TEST 7: Post-attack regression (stability)
- TEST 8: FILTER_IDX out-of-bounds clamped to 8, SEC_VIO set (CM-3)

---

## 6. Synthesis (Yosys — Technology Independent)

```bash
cd results/synthesis

yosys synth.ys
```

---

## 7. Full ASIC Flow (OpenLane2)

Note: Due to the large cell count, the baseline PPA run requires approximately 10 hours, while the optimized RTL run takes around 5 hours.
.
```bash
cd src/


openlane config.json --run-tag <nametag>

example: openlane config.json --run-tag runs
```

View GDS layout:
```bash
klayout runs/*/final/gds/peripheral.gds
```

---

