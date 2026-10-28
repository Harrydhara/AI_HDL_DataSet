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
        debug_sim
        key_expansion_sim
        mixcolumns_sim
        reg_interface_sim
        rtl/aes_inv_round.sv
        rtl/aes_round.sv
        sbox_sim
        sim
        sim_aes_core
        sim_mixcolumns

nothing added to commit but untracked files present (use "git add" to track)
remote: Enumerating objects: 13, done.
remote: Counting objects: 100% (13/13), done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 8 (delta 6), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (8/8), 3.15 KiB | 322.00 KiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   a055dd5..28cc5e9  main       -> origin/main
Updating a055dd5..28cc5e9
Fast-forward
 rtl/aes_core.sv   | 170 +++++++++++++++++++++++++++++++++++++----------------------------------------
 tb/tb_aes_core.sv |  67 ------------------------------
 2 files changed, 81 insertions(+), 156 deletions(-)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim tb/tb_aes_core.sv rtl/*.sv && vvpsim
============================================================
AES-128 Core Testbench
============================================================

VCD info: dumpfile tb_aes_core.vcd opened for output.
------------------------------------------------------------
TEST 1: NIST FIPS-197 Appendix B Encryption
------------------------------------------------------------
[PASS] NIST Appendix B Encryption

------------------------------------------------------------
TEST 2: NIST FIPS-197 Appendix B Decryption
------------------------------------------------------------
[PASS] NIST Appendix B Decryption

------------------------------------------------------------
TEST 3: Round-Trip Verification
------------------------------------------------------------
[PASS] Round-trip verification

============================================================
TEST SUMMARY
============================================================
Total Tests: 3
Passed:      3
Failed:      0
============================================================
tb/tb_aes_core.sv:197: $finish called at 1248511 (1ps)
