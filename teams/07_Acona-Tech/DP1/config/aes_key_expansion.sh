user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$  git status
git pull
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        Acona-Tech-AI-HDL-2026/
        aes_sim
        mixcolumns_sim
        sbox_sim

nothing added to commit but untracked files present (use "git add" to track)
remote: Enumerating objects: 6, done.
remote: Counting objects: 100% (6/6), done.
remote: Compressing objects: 100% (4/4), done.
Unpacking objects: 100% (4/4), 3.04 KiB | 1.52 MiB/s, done.
remote: Total 4 (delta 2), reused 0 (delta 0), pack-reused 0 (from 0)
From github.com:[user]/Acona-Tech-AI-HDL-2026
   08fcaa3..eb5d3d2  main       -> origin/main
Updating 08fcaa3..eb5d3d2
Fast-forward
 tb/tb_aes_key_expansion.sv | 284 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 284 insertions(+)
 create mode 100644 tb/tb_aes_key_expansion.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 \
  -s tb_aes_key_expansion \
  -o key_expansion_sim \
  rtl/aes_key_expansion.sv \
  tb/tb_aes_key_expansion.sv

vvp key_expansion_sim

============================================
  AES Key Expansion Unit Test
============================================

Test 1: Key Expansion (NIST FIPS-197 Appendix A.1)
  Key: 2b7e151628aed2a6abf7158809cf4f3c
  Key expansion complete in 20 cycles

  Verifying Round Keys:
    Round  0: PASSED - 2b7e151628aed2a6abf7158809cf4f3c
    Round  1: PASSED - a0fafe1788542cb123a339392a6c7605
    Round  2: PASSED - f2c295f27a96b9435935807a7359f67f
    Round  3: PASSED - 3d80477d4716fe3e1e237e446d7a883b
    Round  4: PASSED - ef44a541a8525b7fb671253bdb0bad00
    Round  5: PASSED - d4d1c6f87c839d87caf2b8bc11f915bc
    Round  6: PASSED - 6d88a37a110b3efddbf98641ca0093fd
    Round  7: PASSED - 4e54f70e5f5fc9f384a64fb24ea6dc4f
    Round  8: PASSED - ead27321b58dbad2312bf5607f8d292f
    Round  9: PASSED - ac7766f319fadc2128d12941575c006e
    Round 10: PASSED - d014f9a8c9ee2589e13f0cc8b6630ca6

Test 2: Decrypt Mode Key Order (Reversed)
    Decrypt Round  0: PASSED - maps to Enc Round 10
    Decrypt Round  1: PASSED - maps to Enc Round  9
    Decrypt Round  2: PASSED - maps to Enc Round  8
    Decrypt Round  3: PASSED - maps to Enc Round  7
    Decrypt Round  4: PASSED - maps to Enc Round  6
    Decrypt Round  5: PASSED - maps to Enc Round  5
    Decrypt Round  6: PASSED - maps to Enc Round  4
    Decrypt Round  7: PASSED - maps to Enc Round  3
    Decrypt Round  8: PASSED - maps to Enc Round  2
    Decrypt Round  9: PASSED - maps to Enc Round  1
    Decrypt Round 10: PASSED - maps to Enc Round  0

Test 3: All-Zeros Key Expansion
  PASSED: Round 0 key is all zeros
  PASSED: Round 1 key correct for all-zeros input

Test 4: Key Busy Signal During Expansion
  PASSED: key_busy asserted during expansion
  PASSED: key_busy deasserted after completion

============================================
  Key Expansion Unit Test Summary
============================================
  Errors: 0
  *** ALL KEY EXPANSION TESTS PASSED ***
============================================
tb/tb_aes_key_expansion.sv:272: $finish called at 775000 (1ps)
