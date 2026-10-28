user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 \
  -s tb_aes_control_fsm \
  -o aes_control_fsm \
  rtl/aes_control_fsm.sv \
  tb/tb_aes_control_fsm.sv

vvp control_fsm_sim
control_fsm_sim: Unable to open input file.
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ ls
Acona-Tech-AI-HDL-2026  aes_control_fsm  key_expansion_sim  reports   scripts
Makefile                aes_sim          mixcolumns_sim     rtl       submission-form.md
README.md               docs             prompt_logs        sbox_sim  tb
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$  git status
git pull
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        Acona-Tech-AI-HDL-2026/
        aes_control_fsm
        aes_sim
        key_expansion_sim
        mixcolumns_sim
        sbox_sim

nothing added to commit but untracked files present (use "git add" to track)
remote: Enumerating objects: 26, done.
remote: Counting objects: 100% (26/26), done.
remote: Compressing objects: 100% (24/24), done.
remote: Total 24 (delta 16), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (24/24), 14.31 KiB | 1.59 MiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   1bd01c2..e5d30b4  main       -> origin/main
Updating 1bd01c2..e5d30b4
Fast-forward
 tb/{tb_aes128_full => tb_aes128_full.sv} |   0
 tb/tb_aes_core.sv                        | 374 +++++++++++++++++++++++++++++++++++
 tb/tb_aes_reg_interface.sv               | 477 ++++++++++++++++++++++++++++++++++++++++++++
 tb/tb_tqvp_aes128.sv                     | 566 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 1417 insertions(+)
 rename tb/{tb_aes128_full => tb_aes128_full.sv} (100%)
 create mode 100644 tb/tb_aes_core.sv
 create mode 100644 tb/tb_aes_reg_interface.sv
 create mode 100644 tb/tb_tqvp_aes128.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -s tb_aes_control_fsm -o control_fsm_sim\
  rtl/aes_control_fsm.sv tb/tb_aes_control_fsm.sv

vvp control_fsm_sim

============================================
  AES Control FSM Testbench
============================================
VCD info: dumpfile tb_aes_control_fsm.vcd opened for output.

Test 1: Reset Behavior
  PASSED: All outputs inactive after reset

Test 2: Start with Key Already Valid (Encryption)
  FAILED: Did not enter INIT_ROUND
    busy=0, round_init=0, state_load=0
  PASSED: Encryption completed in 13 cycles

Test 3: Start with Key Expansion Needed
  FAILED: Key expansion not triggered
  FAILED: Operation did not complete

Test 4: Full Encryption Cycle - Round Counter
  Round progression (encryption):
    INIT: round_count=0, round_init=0
    MAIN: round_count=0, round_main=0
    MAIN: round_count=0, round_main=0
    MAIN: round_count=0, round_main=0
    MAIN: round_count=0, round_main=0
    MAIN: round_count=0, round_main=0
    MAIN: round_count=0, round_main=0
    MAIN: round_count=0, round_main=0
    MAIN: round_count=0, round_main=0
    MAIN: round_count=0, round_main=0
    FINAL: round_count=0, round_final=0
ERROR: Simulation timeout!
tb/tb_aes_control_fsm.sv:364: $finish called at 100000000 (1ps)
