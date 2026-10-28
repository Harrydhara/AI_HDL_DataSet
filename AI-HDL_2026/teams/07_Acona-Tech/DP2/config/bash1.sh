Microsoft Windows [Version 10.0.26200.7840]
(c) Microsoft Corporation. All rights reserved.

C:\Users\user> wsl
user@host:/mnt/c/Users/user$ cd ~/AI-HDL
user@host:~/AI-HDL$ cd AI-HDL-Acona-2026
-bash: cd: AI-HDL-Acona-2026: No such file or directory
user@host:~/AI-HDL$ ls
Acona-Tech-AI-HDL-2026
user@host:~/AI-HDL$ cd Acona-Tech-AI-HDL-2026
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ ls
Acona-Tech-AI-HDL-2026  key_expansion_sim  sim_mixcolumns
Makefile                mixcolumns_sim     software
OpenLane                nano               submission-form.md
README.md               prompt_logs        synth
aes_control_fsm         reg_interface_sim  tb
aes_control_fsm.sv      reports            tb_aes_control_fsm.vcd
aes_core.sv             riscV_mock.sv      tb_aes_core.vcd
aes_sim                 rtl                tb_aes_mixcolumns.vcd
aes_standalone.vcd      rtl_optimized      tb_aes_reg_interface.vcd
build                   run_sim.sh         tb_riscv_mock.sv
control_fsm_sim         sbox_sim           tb_tqvp_aes128.vcd
debug_sim               scripts            tiny.qv
docs                    sim                venv
gate_sim                sim_aes_core
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd tb
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ nano tb_aes128_clock_gated.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd dp2
-bash: cd: dp2: No such file or directory
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd docs/dp2
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/docs/dp2$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/docs$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ nano README.md
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ nano README.md
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd docs/dp2
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/docs/dp2$ nano DP2_Step1_Baseline_Analysis.md
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/docs/dp2$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/docs$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd scripts
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ nano run_siulation.sh
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ ls
run_simulation.sh
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ nano run_synthesis.sh
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ nano run_synthesis.sh
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ nano run_synthesis.sh
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ nano run_synthesis.s
                                                     ls
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ chmod +x scripts/run_simulation.sh
chmod +x scripts/run_synthesis.sh
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ # Check the structure
find . -name "*.sv" -o -name "*.sh" -o -name "*.md" | head -30
./tb/tb_aes_standalone.sv
./tb/tb_aes_mixcolumns.sv
./tb/tb_aes_core.sv
./tb/tb_aes_sbox.sv
./tb/tb_aes_debug.sv
./tb/tb_aes128_full.sv
./tb/tb_aes_key_expansion.sv
./tb/tb_aes128_clock_gated.sv
./tb/tb_tqvp_aes128.sv
./tb/tb_aes_reg_interface.sv
./tb/tb_aes_control_fsm.sv
./submission-form.md
./Acona-Tech-AI-HDL-2026/tb/tb_aes_unit.sv
./Acona-Tech-AI-HDL-2026/tb/legacy/tb_hello.sv
./Acona-Tech-AI-HDL-2026/submission-form.md
./Acona-Tech-AI-HDL-2026/rtl/aes_key_expansion.sv
./Acona-Tech-AI-HDL-2026/rtl/aes_control_fsm.sv
./Acona-Tech-AI-HDL-2026/rtl/tqvp_aes128.sv
./Acona-Tech-AI-HDL-2026/rtl/legacy/hello.sv
./Acona-Tech-AI-HDL-2026/rtl/aes_mixcolumns.sv
./Acona-Tech-AI-HDL-2026/rtl/aes_reg_interface.sv
./Acona-Tech-AI-HDL-2026/rtl/aes_core.sv
./Acona-Tech-AI-HDL-2026/rtl/aes_sbox.sv
./Acona-Tech-AI-HDL-2026/prompt_logs/005_tb_vectors.md
./Acona-Tech-AI-HDL-2026/prompt_logs/003_keyexp.md
./Acona-Tech-AI-HDL-2026/prompt_logs/002_fsm.md
./Acona-Tech-AI-HDL-2026/prompt_logs/004_core_rounds.md
./Acona-Tech-AI-HDL-2026/prompt_logs/001_reg_if.md
./Acona-Tech-AI-HDL-2026/prompt_logs/prompt_logs/README.md
./Acona-Tech-AI-HDL-2026/prompt_logs/README.md
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ # Navigate to scripts
cd scripts

# Run simulation (requires Icarus Verilog)
./run_simulation.sh
==============================================
  DP2 Clock-Gated AES-128 Simulation
==============================================

--- Compiling Design ---
aes_clock_gate.sv: No such file or directory
Preprocessor failed with 1 errors.
ERROR: Compilation failed!
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ nano run_simulation.sh
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ nano run_simulation.sh
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/scripts$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026
cd rtl_optimized
../scripts/run_simulation.sh
==============================================
  DP2 Clock-Gated AES-128 Simulation
==============================================
Repository root: /home/user/AI-HDL/Acona-Tech-AI-HDL-2026

--- Compiling Design ---
rtl_optimized/tqvp_aes128_opt.sv: No such file or directory
Preprocessor failed with 1 errors.

ERROR: Compilation failed!

Check that these files exist:
  - rtl_optimized/aes_clock_gate.sv
  - rtl_optimized/tqvp_aes128_opt.sv
  - tb/tb_aes128_clock_gated.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ ls
Acona-Tech-AI-HDL-2026  key_expansion_sim  sim_mixcolumns
Makefile                mixcolumns_sim     software
OpenLane                nano               submission-form.md
README.md               prompt_logs        synth
aes_control_fsm         reg_interface_sim  tb
aes_control_fsm.sv      reports            tb_aes_control_fsm.vcd
aes_core.sv             riscV_mock.sv      tb_aes_core.vcd
aes_sim                 rtl                tb_aes_mixcolumns.vcd
aes_standalone.vcd      rtl_optimized      tb_aes_reg_interface.vcd
build                   run_sim.sh         tb_riscv_mock.sv
control_fsm_sim         sbox_sim           tb_tqvp_aes128.vcd
debug_sim               scripts            tiny.qv
docs                    sim                venv
gate_sim                sim_aes_core
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl_optimized.sv
-bash: cd: rtl_optimized.sv: No such file or directory
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl_optimized
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ ls
aes_clock_gate.sv  aes_key_expansion.sv  aes_reg_interface.sv  tqvp_aes128_top_opt.sv
aes_core.sv        aes_mixcolumns.sv     aes_sbox.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ cd rtl_optimized
../scripts/run_simulation.sh
-bash: cd: rtl_optimized: No such file or directory
==============================================
  DP2 Clock-Gated AES-128 Simulation
==============================================
Repository root: /home/user/AI-HDL/Acona-Tech-AI-HDL-2026

--- Compiling Design ---
rtl_optimized/tqvp_aes128_opt.sv: No such file or directory
Preprocessor failed with 1 errors.

ERROR: Compilation failed!

Check that these files exist:
  - rtl_optimized/aes_clock_gate.sv
  - rtl_optimized/tqvp_aes128_opt.sv
  - tb/tb_aes128_clock_gated.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ nano aes_clock_gate.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ cd..
cd..: command not found
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl_optimized
../scripts/run_simulation.sh
==============================================
  DP2 Clock-Gated AES-128 Simulation
==============================================
Repository root: /home/user/AI-HDL/Acona-Tech-AI-HDL-2026

--- Compiling Design ---
rtl_optimized/tqvp_aes128_opt.sv: No such file or directory
Preprocessor failed with 1 errors.

ERROR: Compilation failed!

Check that these files exist:
  - rtl_optimized/aes_clock_gate.sv
  - rtl_optimized/tqvp_aes128_opt.sv
  - tb/tb_aes128_clock_gated.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd ..
user@host:~/AI-HDL$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

# Compile
iverilog -g2012 -o tb_clock_gated.vvp \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns.sv \
    rtl_optimized/aes_key_expansion.sv \
    rtl_optimized/aes_core.sv \
    rtl_optimized/aes_reg_interface.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/tqvp_aes128_opt.sv \
    tb/tb_aes128_clock_gated.sv

# Run
vvp tb_clock_gated.vvp
rtl_optimized/tqvp_aes128_opt.sv: No such file or directory
Preprocessor failed with 1 errors.
tb_clock_gated.vvp: Unable to open input file.
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl_optimized
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ ls
aes_clock_gate.sv  aes_key_expansion.sv  aes_reg_interface.sv  tqvp_aes128_top_opt.sv
aes_core.sv        aes_mixcolumns.sv     aes_sbox.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

# Compile
iverilog -g2012 -o tb_clock_gated.vvp \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns.sv \
    rtl_optimized/aes_key_expansion.sv \
    rtl_optimized/aes_core.sv \
    rtl_optimized/aes_reg_interface.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/tqvp_aes128_top_opt.sv \
    tb/tb_aes128_clock_gated.sv

# Run
vvp tb_clock_gated.vvp
==========================================================
  DP2 Clock-Gated AES-128 Verification Testbench
==========================================================
  Clock Period: 15.625 ns (64.0 MHz)
==========================================================

--- Test 1: Encryption (All Zeros) ---
ERROR: Testbench timeout!
tb/tb_aes128_clock_gated.sv:380: $finish called at 78125000 (1ps)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl_optimized/tqvp_aes128_top_opt.sv
-bash: cd: rtl_optimized/tqvp_aes128_top_opt.sv: Not a directory
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl_optimized
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ nano tqvp_aes128_top_opt.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

# Recompile
iverilog -g2012 -o tb_clock_gated.vvp \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns.sv \
    rtl_optimized/aes_key_expansion.sv \
    rtl_optimized/aes_core.sv \
    rtl_optimized/aes_reg_interface.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/tqvp_aes128_top_opt.sv \
    tb/tb_aes128_clock_gated.sv

# Run
vvp tb_clock_gated.vvp
==========================================================
  DP2 Clock-Gated AES-128 Verification Testbench
==========================================================
  Clock Period: 15.625 ns (64.0 MHz)
==========================================================

--- Test 1: Encryption (All Zeros) ---
ERROR: Testbench timeout!
tb/tb_aes128_clock_gated.sv:380: $finish called at 78125000 (1ps)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd tb
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ ls
tb_aes128_clock_gated.sv  tb_aes_debug.sv          tb_aes_sbox.sv
tb_aes128_full.sv         tb_aes_key_expansion.sv  tb_aes_standalone.sv
tb_aes_control_fsm.sv     tb_aes_mixcolumns.sv     tb_tqvp_aes128.sv
tb_aes_core.sv            tb_aes_reg_interface.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ nano tb_tqvp_aes128
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ nano tb_tqvp_aes128.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ nano tb_aes128_clock_gated.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ nano tb_aes128_clock_gated.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

# Replace the testbench file
# Download tb_aes128_clock_gated_fixed.sv and save as:
# tb/tb_aes128_clock_gated.sv

# Then recompile and run:
iverilog -g2012 -o tb_clock_gated.vvp \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns.sv \
    rtl_optimized/aes_key_expansion.sv \
    rtl_optimized/aes_core.sv \
    rtl_optimized/aes_reg_interface.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/tqvp_aes128_opt.sv \
    tb/tb_aes128_clock_gated.sv

vvp tb_clock_gated.vvp
rtl_optimized/tqvp_aes128_opt.sv: No such file or directory
Preprocessor failed with 1 errors.
==========================================================
  DP2 Clock-Gated AES-128 Verification Testbench
==========================================================
  Clock Period: 15.625 ns (64.0 MHz)
==========================================================

--- Test 1: Encryption (All Zeros) ---
ERROR: Testbench timeout!
tb/tb_aes128_clock_gated.sv:380: $finish called at 78125000 (1ps)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$






Microsoft Windows [Version 10.0.26200.7840]
(c) Microsoft Corporation. All rights reserved.

C:\Users\user>wsl
user@host:/mnt/c/Users/user$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ ls
Acona-Tech-AI-HDL-2026  build              reg_interface_sim  sim_aes_core  tb_aes_reg_interface.vcd
Makefile                control_fsm_sim    reports            sim_mixcolumns  tb_clock_gated.vvp
OpenLane                debug_sim          riscV_mock.sv      software  tb_riscv_mock.sv
README.md               docs               rtl                submission-form.md  tb_tqvp_aes128.vcd
aes_control_fsm         gate_sim           rtl_optimized      synth  tiny.qv
aes_control_fsm.sv      key_expansion_sim  run_sim.sh         tb  venv
aes_core.sv             mixcolumns_sim     sbox_sim           tb_aes_control_fsm.vcd
aes_sim                 nano               scripts            tb_aes_core.vcd
aes_standalone.vcd      prompt_logs        sim                tb_aes_mixcolumns.vcd
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl_optimized
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ ls
aes_clock_gate.sv     aes_mixcolumns.sv     tqvp_aes128_top_opt.sv
aes_core.sv           aes_reg_interface.sv
aes_key_expansion.sv  aes_sbox.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd tb
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ ls
tb_aes128_clock_gated.sv  tb_aes_debug.sv          tb_aes_sbox.sv
tb_aes128_full.sv         tb_aes_key_expansion.sv  tb_aes_standalone.sv
tb_aes_control_fsm.sv     tb_aes_mixcolumns.sv     tb_tqvp_aes128.sv
tb_aes_core.sv            tb_aes_reg_interface.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ nano tb_aes128_clock_gated.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ cd..
cd..: command not found
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o tb_baseline.vvp \
    rtl/aes_sbox.sv \
    rtl/aes_mixcolumns.sv \
    rtl/aes_key_expansion.sv \
    rtl/aes_core.sv \
    rtl/aes_reg_interface.sv \
    rtl/tqvp_aes128.sv \
    tb/tb_tqvp_aes128.sv

vvp tb_baseline.vvp

================================================================
  AES-128 Crypto Accelerator - Top-Level Integration Test
================================================================
  ADDR_MODE_WORDS = 0 (0=byte offsets, 1=word offsets)
================================================================
VCD info: dumpfile tb_tqvp_aes128.vcd opened for output.

Test 1: Reset Behavior
  STATUS after reset: 0x00000000
    BUSY=0, DONE=0, ERROR=0, KEY_VALID=0
  PASSED: Not busy after reset

Test 2: NIST FIPS-197 Appendix B Encryption
  PASSED: NIST encryption correct

Test 3: NIST FIPS-197 Decryption
  PASSED: NIST decryption correct

Test 4: All-Zeros Test Vector
  PASSED: All-zeros encryption correct
  PASSED: All-zeros decryption correct

Test 5: All-Ones Test Vector
  PASSED: All-ones encryption correct

Test 6: Back-to-Back Operations
  Block 1: 3ad77bb40d7a3660a89ecaf32466ef97
  Block 2: f5d3d58503b9699de785895a96fdbaaf
  PASSED: Back-to-back operations completed

Test 7: Key Change Between Operations
  Key1 result: 66e94bd4ef8a2c3b884cfa59ca342b2e
  Key2 result: a1f6258c877d5fcd8964484538bfc92c
  PASSED: Different key produces different result

Test 8: Interrupt Functionality
  PASSED: Interrupt asserted on completion
  PASSED: Interrupt cleared

Test 9: Encrypt-Decrypt Round Trip
  Original:   0fedcba9876543210badf00dcafebeef
  Encrypted:  1f936dbf2ccf81f28c04dfe4a7406f81
  Decrypted:  0fedcba9876543210badf00dcafebeef
  PASSED: Round trip successful

================================================================
  TEST SUMMARY
================================================================
  Total Tests: 9
  Passed:      9
  Failed:      0
  *** ALL TESTS PASSED ***
================================================================
tb/tb_tqvp_aes128.sv:504: $finish called at 14618123 (1ps)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl_optimized
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ nano tqvp_aes128_opt
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ ls
aes_clock_gate.sv     aes_mixcolumns.sv     tqvp_aes128_top_opt.sv
aes_core.sv           aes_reg_interface.sv
aes_key_expansion.sv  aes_sbox.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ nano tqvp_aes128_top_opt.
sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl_optimized$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd tb
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ ls
tb_aes128_clock_gated.sv  tb_aes_debug.sv          tb_aes_sbox.sv
tb_aes128_full.sv         tb_aes_key_expansion.sv  tb_aes_standalone.sv
tb_aes_control_fsm.sv     tb_aes_mixcolumns.sv     tb_tqvp_aes128.sv
tb_aes_core.sv            tb_aes_reg_interface.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ cd tb_tqvp_aes128.sv
-bash: cd: tb_tqvp_aes128.sv: Not a directory
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ nano tb_tqvp_aes128.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/tb$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o tb_opt.vvp \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns.sv \
    rtl_optimized/aes_key_expansion.sv \
    rtl_optimized/aes_core.sv \
    rtl_optimized/aes_reg_interface.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/tqvp_aes128_opt.sv \
    tb/tb_tqvp_aes128_opt.sv

# 4. Run
vvp tb_opt.vvp

================================================================
  DP2 Clock-Gated AES-128 - Verification Test
================================================================

Test 1: Reset Behavior
  STATUS after reset: 0x00000000
  PASSED: Not busy after reset

Test 2: NIST FIPS-197 Appendix B Encryption
  PASSED: NIST encryption correct

Test 3: NIST FIPS-197 Decryption
  PASSED: NIST decryption correct

Test 4: All-Zeros Test Vector
  PASSED: All-zeros encryption correct

Test 5: Encrypt-Decrypt Round Trip
  Encrypted:  1f936dbf2ccf81f28c04dfe4a7406f81
  Decrypted:  0fedcba9876543210badf00dcafebeef
  PASSED: Round trip successful

--- Idle Period (200 cycles) ---

================================================================
  TEST SUMMARY
================================================================
  Total Tests: 5
  Passed:      5
  Failed:      0
================================================================

================================================================
  CLOCK GATING STATISTICS
================================================================
  Total Cycles:              594
  Core Clock Active:         70 (11.8%)
  Key Exp Clock Active:      140 (23.6%)
  Power Saved (Core Gated):  88.2%
================================================================

  *** ALL TESTS PASSED - Clock Gating Verified! ***
================================================================
tb/tb_tqvp_aes128_opt.sv:428: $finish called at 9586551 (1ps)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$
