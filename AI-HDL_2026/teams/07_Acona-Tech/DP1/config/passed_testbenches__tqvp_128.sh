user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ git status
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
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 4 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (4/4), 1.08 KiB | 275.00 KiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   d326a94..efbf7ec  main       -> origin/main
Updating d326a94..efbf7ec
Fast-forward
 tb/tb_tqvp_aes128.sv | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim tb/tb_tqvp_aes128.sv rtl/*.sv &&
vvp sim

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
