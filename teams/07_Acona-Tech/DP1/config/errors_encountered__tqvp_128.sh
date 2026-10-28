user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ ls
Acona-Tech-AI-HDL-2026  debug_sim          rtl                 tb
Makefile                docs               sbox_sim            tb_aes_control_fsm.vcd
README.md               key_expansion_sim  scripts             tb_aes_core.vcd
aes_control_fsm         mixcolumns_sim     sim                 tb_aes_mixcolumns.vcd
aes_sim                 prompt_logs        sim_aes_core        tb_aes_reg_interface.vcd
build                   reg_interface_sim  sim_mixcolumns
control_fsm_sim         reports            submission-form.md
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl$ ls
aes_control_fsm.sv  aes_inv_round.sv      aes_mixcolumns.sv     aes_round.sv  tqvp_aes128.sv
aes_core.sv         aes_key_expansion.sv  aes_reg_interface.sv  aes_sbox.sv   tqvp_aes128_top.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$  iverilog -g2012 -o sim tb/tb_tqvp_aes128.sv rtl/*.sv &&v
vp sim

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
  FAILED: NIST decryption mismatch
    Expected: 3243f6a8885a308d313198a2e0370734
    Got:      57c2c49254271f375409c2a51bcbab98

Test 4: All-Zeros Test Vector
  PASSED: All-zeros encryption correct
  FAILED: All-zeros decryption mismatch

Test 5: All-Ones Test Vector
  FAILED: All-ones encryption mismatch
    Expected: a1f6258c877d5fcd8964484538bfc92c
    Got:      bcbf217cb280cf30b2517052193ab979

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
  Decrypted:  7bbd9c0874b2709f0a4ebb4124f8f763
  FAILED: Round trip mismatch

================================================================
  TEST SUMMARY
================================================================
  Total Tests: 9
  Passed:      5
  Failed:      4
  *** TESTS FAILED - REVIEW ERRORS ABOVE ***
================================================================
tb/tb_tqvp_aes128.sv:502: $finish called at 14618123 (1ps)
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
Unpacking objects: 100% (4/4), 1.48 KiB | 168.00 KiB/s, done.
remote: Total 4 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
From github.com:[user]/Acona-Tech-AI-HDL-2026
   28cc5e9..b83b50b  main       -> origin/main
Updating 28cc5e9..b83b50b
Fast-forward
 rtl/tqvp_aes128.sv | 110 ++++++++++++++++++++++++---------------------------------------------------
 1 file changed, 35 insertions(+), 75 deletions(-)
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
  FAILED: NIST encryption mismatch
    Expected: 3925841d02dc09fbdc118597196a0b32
    Got:      b97bf8f55e155deed361390cf8672e81

Test 3: NIST FIPS-197 Decryption
  PASSED: NIST decryption correct

Test 4: All-Zeros Test Vector
  FAILED: All-zeros encryption mismatch
    Expected: 66e94bd4ef8a2c3b884cfa59ca342b2e
    Got:      f494d832311dcf9f8356b8a99563d405
  PASSED: All-zeros decryption correct

Test 5: All-Ones Test Vector
  FAILED: All-ones encryption mismatch
    Expected: a1f6258c877d5fcd8964484538bfc92c
    Got:      12fe8a4d3ca2d86447ebc62ec7268e3e

Test 6: Back-to-Back Operations
  Block 1: 1c3fc1027994aacfe62143716a9c1f62
  Block 2: c17d180a6ec8322c077cb5a4ca1bad3a
  PASSED: Back-to-back operations completed

Test 7: Key Change Between Operations
  Key1 result: f494d832311dcf9f8356b8a99563d405
  Key2 result: 63ccc74291de16392e624088130b985c
  PASSED: Different key produces different result

Test 8: Interrupt Functionality
  PASSED: Interrupt asserted on completion
  PASSED: Interrupt cleared

Test 9: Encrypt-Decrypt Round Trip
  Original:   0fedcba9876543210badf00dcafebeef
  Encrypted:  e331eea5483577d5db67d3ffdfa2cc48
  Decrypted:  7a55c6e7738188f4f0053cb22f92eae0
  FAILED: Round trip mismatch

================================================================
  TEST SUMMARY
================================================================
  Total Tests: 9
  Passed:      5
  Failed:      4
  *** TESTS FAILED - REVIEW ERRORS ABOVE ***
================================================================
tb/tb_tqvp_aes128.sv:502: $finish called at 14618123 (1ps)
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
remote: Enumerating objects: 12, done.
remote: Counting objects: 100% (8/8), done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 12 (delta 4), reused 4 (delta 4), pack-reused 4 (from 1)
Unpacking objects: 100% (12/12), 5.29 KiB | 451.00 KiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   b83b50b..c951717  main       -> origin/main
Updating b83b50b..c951717
Fast-forward
 docs/ai_strategy.md |  4 ++--
 rtl/tqvp_aes128.sv  | 46 ++++++++++++++++++++++++++++------------------
 2 files changed, 30 insertions(+), 20 deletions(-)
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
  FAILED: All-ones encryption mismatch
    Expected: a1f6258c877d5fcd8964484538bfc92c
    Got:      bcbf217cb280cf30b2517052193ab979

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
  Passed:      8
  Failed:      1
  *** TESTS FAILED - REVIEW ERRORS ABOVE ***
================================================================
tb/tb_tqvp_aes128.sv:502: $finish called at 14618123 (1ps)
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
remote: Enumerating objects: 17, done.
remote: Counting objects: 100% (17/17), done.
remote: Compressing objects: 100% (12/12), done.
remote: Total 12 (delta 9), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (12/12), 3.10 KiB | 793.00 KiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   c951717..d326a94  main       -> origin/main
Updating c951717..d326a94
Fast-forward
 docs/plan.md         | 6 ++++--
 tb/tb_tqvp_aes128.sv | 6 ++++--
 2 files changed, 8 insertions(+), 4 deletions(-)
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
  FAILED: All-ones encryption mismatch
    Expected: bcbf217cb28cf3db2517052193ab9779
    Got:      bcbf217cb280cf30b2517052193ab979

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
  Passed:      8
  Failed:      1
  *** TESTS FAILED - REVIEW ERRORS ABOVE ***
================================================================
tb/tb_tqvp_aes128.sv:504: $finish called at 14618123 (1ps)
