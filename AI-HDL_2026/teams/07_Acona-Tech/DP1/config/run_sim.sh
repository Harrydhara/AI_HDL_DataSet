Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\Users\user> wsl
user@host:/mnt/c/Users/user$  cd ~/AI-HDL
user@host:~/AI-HDL$ cd Acona-Tech-AI-HDL-2026
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ ls
Acona-Tech-AI-HDL-2026  control_fsm_sim    riscV_mock.sv       synth
Makefile                debug_sim          rtl                 tb
OpenLane                docs               run_sim.sh          tb_aes_control_fsm.vcd
README.md               gate_sim           sbox_sim            tb_aes_core.vcd
aes_control_fsm         key_expansion_sim  scripts             tb_aes_mixcolumns.vcd
aes_control_fsm.sv      mixcolumns_sim     sim                 tb_aes_reg_interface.vcd
aes_core.sv             nano               sim_aes_core        tb_riscv_mock.sv
aes_sim                 prompt_logs        sim_mixcolumns      tb_tqvp_aes128.vcd
aes_standalone.vcd      reg_interface_sim  software            tiny.qv
build                   reports            submission-form.md
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$  bash run_sim.sh
1. Compiling (Icarus Verilog)...
2. Running simulation...
=== STEP 1: (ENCRYPTION) ===
Ciphertext saved: 3ad77bb4 0d7a3660 a89ecaf3 2466ef97

=== STEP 2:(DECRYPTION) ===
Feed Back DOUT0: 6bc1bee2 (Expected: 6bc1bee2)
Feed Back DOUT1: 2e409f96 (Expected: 2e409f96)

CONGRATULATIONS: The hardware is consistent within itself!

tb_riscv_mock.sv:80: $finish called at 1856000 (1ps)
