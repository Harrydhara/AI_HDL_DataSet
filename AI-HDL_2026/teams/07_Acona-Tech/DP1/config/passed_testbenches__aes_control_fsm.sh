user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$  git status
git pull
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        Acona-Tech-AI-HDL-2026/
        aes_control_fsm
        aes_sim
        control_fsm_sim
        key_expansion_sim
        mixcolumns_sim
        sbox_sim

nothing added to commit but untracked files present (use "git add" to track)
remote: Enumerating objects: 13, done.
remote: Counting objects: 100% (13/13), done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 8 (delta 6), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (8/8), 3.82 KiB | 1.27 MiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   e5d30b4..395148c  main       -> origin/main
Updating e5d30b4..395148c
Fast-forward
 rtl/aes_control_fsm.sv   | 227 ++++++++++++++++++++++++---------------------------------------------
 tb/tb_aes_control_fsm.sv | 151 +++++++++++++++++++++++++---------------------
 2 files changed, 162 insertions(+), 216 deletions(-)
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
  PASSED: busy asserted
  PASSED: round_init and state_load asserted
  PASSED: Encryption completed in 12 cycles

Test 3: Start with Key Expansion Needed
  PASSED: key_start triggered
  PASSED: Operation completed after key expansion

Test 4: Full Encryption Cycle - Round Counter
  Round progression (encryption):
    Cycle 1: round_count=0, round_init=1, round_main=0, round_final=0
    Cycle 2: round_count=1, init=0, main=1, final=0, done=0
    Cycle 3: round_count=2, init=0, main=1, final=0, done=0
    Cycle 4: round_count=3, init=0, main=1, final=0, done=0
    Cycle 5: round_count=4, init=0, main=1, final=0, done=0
    Cycle 6: round_count=5, init=0, main=1, final=0, done=0
    Cycle 7: round_count=6, init=0, main=1, final=0, done=0
    Cycle 8: round_count=7, init=0, main=1, final=0, done=0
    Cycle 9: round_count=8, init=0, main=1, final=0, done=0
    Cycle 10: round_count=9, init=0, main=1, final=0, done=0
    Cycle 11: round_count=10, init=0, main=0, final=1, done=0
    Cycle 13: round_count=10, init=0, main=0, final=0, done=1

Test 5: Decryption Mode - Round Counter
  Round progression (decryption):
    INIT: round_count=10 (correct for decrypt)
    MAIN: round_count=9
    MAIN: round_count=8
    MAIN: round_count=7
    MAIN: round_count=6
    MAIN: round_count=5
    MAIN: round_count=4
    MAIN: round_count=3
    MAIN: round_count=2
    MAIN: round_count=1
    FINAL: round_count=0
    DONE

Test 6: Control Signal Pulse Behavior
  round_init high on first cycle
  PASSED: round_init cleared, round_main asserted
  PASSED: done is single-cycle pulse

============================================
  AES Control FSM Test Summary
============================================
  Total Tests: 6
  Errors: 0
  *** ALL TESTS PASSED ***
============================================
tb/tb_aes_control_fsm.sv:372: $finish called at 1507909 (1ps)
