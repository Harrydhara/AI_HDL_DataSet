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
        sim_mixcolumns

nothing added to commit but untracked files present (use "git add" to track)
remote: Enumerating objects: 13, done.
remote: Counting objects: 100% (13/13), done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 8 (delta 4), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (8/8), 7.47 KiB | 765.00 KiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   ddb0432..7ef7caf  main       -> origin/main
Updating ddb0432..7ef7caf
Fast-forward
 rtl/aes_core.sv   | 368 ++++++++++++++++++++++++++++++++++++++++++++--------
 tb/tb_aes_core.sv | 531 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--------------
 2 files changed, 746 insertions(+), 153 deletions(-)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim_aes_core aes_sbox.sv aes_mixcolumn
s.sv aes_core.sv tb_aes_core.sv && vvp sim_aes_core
aes_sbox.sv: No such file or directory
No top level modules, and no -s option.
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim_aes_core aes_mixcolumns.sv aes_cor
e.sv tb_aes_core.sv && vvp sim_aes_core
aes_mixcolumns.sv: No such file or directory
No top level modules, and no -s option.
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim_aes_core aes_core.sv tb_aes_core.sv && vvp sim_aes_core
aes_core.sv: No such file or directory
No top level modules, and no -s option.
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

iverilog -g2012 -o sim_aes_core \
    rtl/aes_sbox.sv \
    rtl/aes_mixcolumns.sv \
    rtl/aes_core.sv \
    tb/tb_aes_core.sv && vvp sim_aes_core
============================================================
AES-128 Core Testbench
AIHDL 2026 Competition - Team Acona
============================================================

VCD info: dumpfile tb_aes_core.vcd opened for output.
------------------------------------------------------------
TEST 1: NIST FIPS-197 Appendix B Encryption
------------------------------------------------------------
[FAIL] NIST Appendix B Encryption
       Plaintext:  3243f6a8885a308d313198a2e0370734
       Expected:   3925841d02dc09fbdc118597196a0b32
       Got:        e7996e8b18f8a8a07a5a0199d6ff506c

------------------------------------------------------------
TEST 2: NIST FIPS-197 Appendix B Decryption
------------------------------------------------------------
[FAIL] NIST Appendix B Decryption
       Ciphertext: 3925841d02dc09fbdc118597196a0b32
       Expected:   3243f6a8885a308d313198a2e0370734
       Got:        932301f9299a0d2ec0f2ec4548044dcc

------------------------------------------------------------
TEST 3: Round-Trip Verification
------------------------------------------------------------
[FAIL] Round-trip verification
       Original:   deadbeefcafebabe123456789abcdef0
       Encrypted:  1c3b5a02b45d53db8215f1945fd47f1b
       Decrypted:  b513c246e6c6d1d3676364eab9e2a411

------------------------------------------------------------
TEST 4: All Zeros Key and Plaintext
------------------------------------------------------------
[FAIL] All zeros round-trip
       Plaintext:  00000000000000000000000000000000
       Encrypted:  a45982d9aed0a757713ded9189ce2f73
       Decrypted:  b87ccb380591147fafc46834465bf2a8

------------------------------------------------------------
TEST 5: All Ones Plaintext
------------------------------------------------------------
[FAIL] All ones round-trip
       Plaintext:  ffffffffffffffffffffffffffffffff
       Encrypted:  06f00ca4ea6b1639f1b6615e72ca4126
       Decrypted:  1b68239b253e880779b5fb13b6b61175

------------------------------------------------------------
TEST 6: Sequential Pattern
------------------------------------------------------------
[FAIL] Sequential pattern round-trip
       Plaintext:  00112233445566778899aabbccddeeff
       Encrypted:  e4884b82a52b58f1522c006e650866a4
       Decrypted:  215e65a9b97ecb48efcdf16259f9f2ca

============================================================
TEST SUMMARY
============================================================
Total Tests: 6
Passed:      0
Failed:      6

*** SOME TESTS FAILED ***
Please review failed test cases above.
============================================================

tb/tb_aes_core.sv:447: $finish called at 3936183 (1ps)
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
        sim_aes_core
        sim_mixcolumns

nothing added to commit but untracked files present (use "git add" to track)
remote: Enumerating objects: 27, done.
remote: Counting objects: 100% (27/27), done.
remote: Compressing objects: 100% (20/20), done.
remote: Total 20 (delta 11), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (20/20), 12.39 KiB | 906.00 KiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   7ef7caf..f5e8820  main       -> origin/main
Updating 7ef7caf..f5e8820
Fast-forward
 prompt_logs/prompt_logs/README.md |   9 -
 rtl/aes_core.sv                   | 543 +++++++++++++++++++++++++++++-------------------------------
 submission-form.md                |  98 ++++++-----
 tb/tb_aes_core.sv                 | 219 +++++++++---------------
 4 files changed, 397 insertions(+), 472 deletions(-)
 delete mode 100644 prompt_logs/prompt_logs/README.md
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

iverilog -g2012 -o sim_aes_core \
    rtl/aes_sbox.sv \
    rtl/aes_mixcolumns.sv \
    rtl/aes_core.sv \
    tb/tb_aes_core.sv && vvp sim_aes_core
============================================================
AES-128 Core Testbench
AIHDL 2026 Competition - Team Acona
============================================================

VCD info: dumpfile tb_aes_core.vcd opened for output.
------------------------------------------------------------
TEST 1: NIST FIPS-197 Appendix B Encryption
------------------------------------------------------------
[PASS] NIST Appendix B Encryption
       Plaintext:  3243f6a8885a308d313198a2e0370734
       Ciphertext: 3925841d02dc09fbdc118597196a0b32

------------------------------------------------------------
TEST 2: NIST FIPS-197 Appendix B Decryption
------------------------------------------------------------
[FAIL] NIST Appendix B Decryption
       Ciphertext: 3925841d02dc09fbdc118597196a0b32
       Expected:   3243f6a8885a308d313198a2e0370734
       Got:        e32b25ff72bdb6a5fdfac97bd82de36c

------------------------------------------------------------
TEST 3: Round-Trip Verification
------------------------------------------------------------
[FAIL] Round-trip verification
       Original:   deadbeefcafebabe123456789abcdef0
       Encrypted:  0ca886c2dae1cbd5c8bf3b2f224b3f91
       Decrypted:  742ca8887d16591b49c5a6446a51fda2

------------------------------------------------------------
TEST 4: All Zeros Key and Plaintext
------------------------------------------------------------
[FAIL] All zeros round-trip
       Plaintext:  00000000000000000000000000000000
       Encrypted:  7be9b9f5644ee5b78a22f68004a1fe80
       Decrypted:  55e56c60f9b3f59bb16f6ee56e59aa68

------------------------------------------------------------
TEST 5: All Ones Plaintext
------------------------------------------------------------
[FAIL] All ones round-trip
       Plaintext:  ffffffffffffffffffffffffffffffff
       Encrypted:  7aa701ba7a59dd52960b18931b2bfbb0
       Decrypted:  c16336e47ab70f8ad796753847f75ffc

------------------------------------------------------------
TEST 6: Sequential Pattern
------------------------------------------------------------
[FAIL] Sequential pattern round-trip
       Plaintext:  00112233445566778899aabbccddeeff
       Encrypted:  d73ea17a9d9d88f958fdb856b58b34b7
       Decrypted:  f04fc1d667f5f80c3214d7fd8ee3860c

============================================================
TEST SUMMARY
============================================================
Total Tests: 6
Passed:      1
Failed:      5

*** SOME TESTS FAILED ***
Please review failed test cases above.
============================================================

tb/tb_aes_core.sv:367: $finish called at 2842363 (1ps)
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
        sim_aes_core
        sim_mixcolumns

nothing added to commit but untracked files present (use "git add" to track)
remote: Enumerating objects: 12, done.
remote: Counting objects: 100% (12/12), done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 8 (delta 6), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (8/8), 3.58 KiB | 1.19 MiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   f5e8820..db31f00  main       -> origin/main
Updating f5e8820..db31f00
Fast-forward
 tb/tb_aes_core.sv    | 146 ++++++++++++++++----------------------
 tb/tb_tqvp_aes128.sv | 278 +++++++++++++++++++++++++++++++------------------------------------------
 2 files changed, 178 insertions(+), 246 deletions(-)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim tb/tb_aes_core.sv rtl/*.sv && vvpsim
============================================================
AES-128 Core Testbench
AIHDL 2026 Competition - Team Acona
============================================================

VCD info: dumpfile tb_aes_core.vcd opened for output.
------------------------------------------------------------
TEST 1: NIST FIPS-197 Appendix B Encryption
------------------------------------------------------------
[PASS] NIST Appendix B Encryption
       Plaintext:  3243f6a8885a308d313198a2e0370734
       Ciphertext: 3925841d02dc09fbdc118597196a0b32

------------------------------------------------------------
TEST 2: NIST FIPS-197 Appendix B Decryption
------------------------------------------------------------
[FAIL] NIST Appendix B Decryption
       Ciphertext: 3925841d02dc09fbdc118597196a0b32
       Expected:   3243f6a8885a308d313198a2e0370734
       Got:        9293c547620cc43716281a7427f48125

------------------------------------------------------------
TEST 3: Round-Trip Verification
------------------------------------------------------------
[FAIL] Round-trip verification
       Original:   deadbeefcafebabe123456789abcdef0
       Encrypted:  0ca886c2dae1cbd5c8bf3b2f224b3f91
       Decrypted:  e42cf3b8d98bd582dcfd9a96cd7d752c

------------------------------------------------------------
TEST 4: All Zeros Key and Plaintext
------------------------------------------------------------
[FAIL] All zeros round-trip
       Plaintext:  00000000000000000000000000000000
       Encrypted:  7be9b9f5644ee5b78a22f68004a1fe80
       Decrypted:  9f1d07df52dcacdc3a2f312147efbcce

------------------------------------------------------------
TEST 5: All Ones Plaintext
------------------------------------------------------------
[FAIL] All ones round-trip
       Plaintext:  ffffffffffffffffffffffffffffffff
       Encrypted:  7aa701ba7a59dd52960b18931b2bfbb0
       Decrypted:  bfd1c606c9112cc4db280c9f8697078a

------------------------------------------------------------
TEST 6: Sequential Pattern
------------------------------------------------------------
[FAIL] Sequential pattern round-trip
       Plaintext:  00112233445566778899aabbccddeeff
       Encrypted:  d73ea17a9d9d88f958fdb856b58b34b7
       Decrypted:  4691d59c658f44f28943cec12ce76d4f

============================================================
TEST SUMMARY
============================================================
Total Tests: 6
Passed:      1
Failed:      5

*** SOME TESTS FAILED ***
Please review failed test cases above.
============================================================

tb/tb_aes_core.sv:352: $finish called at 2842363 (1ps)
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
Unpacking objects: 100% (4/4), 1.49 KiB | 760.00 KiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   db31f00..cb65e81  main       -> origin/main
Updating db31f00..cb65e81
Fast-forward
 tb/tb_aes_core.sv | 57 +++++++++++++++++++++++++++++++++++++++++++--------------
 1 file changed, 43 insertions(+), 14 deletions(-)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim tb/tb_aes_core.sv rtl/*.sv && vvpsim
============================================================
AES-128 Core Testbench
AIHDL 2026 Competition - Team Acona
============================================================

VCD info: dumpfile tb_aes_core.vcd opened for output.
------------------------------------------------------------
TEST 1: NIST FIPS-197 Appendix B Encryption
------------------------------------------------------------
[PASS] NIST Appendix B Encryption
       Plaintext:  3243f6a8885a308d313198a2e0370734
       Ciphertext: 3925841d02dc09fbdc118597196a0b32

------------------------------------------------------------
TEST 2: NIST FIPS-197 Appendix B Decryption
------------------------------------------------------------
[FAIL] NIST Appendix B Decryption
       Ciphertext: 3925841d02dc09fbdc118597196a0b32
       Expected:   3243f6a8885a308d313198a2e0370734
       Got:        9293c547620cc43716281a7427f48125

------------------------------------------------------------
TEST 3: Round-Trip Verification
------------------------------------------------------------
[FAIL] Round-trip verification
       Original:   deadbeefcafebabe123456789abcdef0
       Encrypted:  0ca886c2dae1cbd5c8bf3b2f224b3f91
       Decrypted:  e42cf3b8d98bd582dcfd9a96cd7d752c

------------------------------------------------------------
TEST 4: All Zeros Key and Plaintext
------------------------------------------------------------
[FAIL] All zeros round-trip
       Plaintext:  00000000000000000000000000000000
       Encrypted:  7be9b9f5644ee5b78a22f68004a1fe80
       Decrypted:  9f1d07df52dcacdc3a2f312147efbcce

------------------------------------------------------------
TEST 5: All Ones Plaintext
------------------------------------------------------------
[FAIL] All ones round-trip
       Plaintext:  ffffffffffffffffffffffffffffffff
       Encrypted:  7aa701ba7a59dd52960b18931b2bfbb0
       Decrypted:  bfd1c606c9112cc4db280c9f8697078a

------------------------------------------------------------
TEST 6: Sequential Pattern
------------------------------------------------------------
[FAIL] Sequential pattern round-trip
       Plaintext:  00112233445566778899aabbccddeeff
       Encrypted:  d73ea17a9d9d88f958fdb856b58b34b7
       Decrypted:  4691d59c658f44f28943cec12ce76d4f

============================================================
TEST SUMMARY
============================================================
Total Tests: 6
Passed:      1
Failed:      5

*** SOME TESTS FAILED ***
Please review failed test cases above.
============================================================

tb/tb_aes_core.sv:381: $finish called at 2842363 (1ps)
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
Already up to date.
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
Already up to date.
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
Already up to date.
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
remote: Enumerating objects: 23, done.
remote: Counting objects: 100% (23/23), done.
remote: Compressing objects: 100% (16/16), done.
remote: Total 16 (delta 12), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (16/16), 6.16 KiB | 525.00 KiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   cb65e81..a055dd5  main       -> origin/main
Updating cb65e81..a055dd5
Fast-forward
 docs/ai_strategy.md |   3 +-
 rtl/aes_core.sv     | 348 ++++++++++++++++++++++++++++++++++++---------------------------------------
 tb/tb_aes_core.sv   | 199 +++++++++----------------------------------
 3 files changed, 209 insertions(+), 341 deletions(-)
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
[FAIL] NIST Appendix B Decryption
       Expected: 3243f6a8885a308d313198a2e0370734
       Got:      858ea4521bd5cf67413d13231d6ede97

------------------------------------------------------------
TEST 3: Round-Trip Verification
------------------------------------------------------------
[FAIL] Round-trip verification
       Encrypted: f861b200bbd9d74b0fbe57f8657578b1
       Decrypted: 74e250b3fee1ba7907253df0cef0ebe4

------------------------------------------------------------
TEST 4: All Zeros Key and Plaintext
------------------------------------------------------------
[FAIL] All zeros round-trip
       Encrypted: 7df76b0c1ab899b33e42f047b91b546f
       Decrypted: f5abedfb930a49f02702a6867fae1ecf

------------------------------------------------------------
TEST 5: All Ones Plaintext
------------------------------------------------------------
[FAIL] All ones round-trip
       Encrypted: 8af2860142f786f409307c1a3f7eaaac
       Decrypted: 9efc07d5ddc39fe2794b3add40406350

------------------------------------------------------------
TEST 6: Sequential Pattern
------------------------------------------------------------
[FAIL] Sequential pattern round-trip
       Encrypted: 8df4e9aac5c7573a27d8d055d6e4d64b
       Decrypted: b81f2a24ce978abed8150f676014bc7a

============================================================
TEST SUMMARY
============================================================
Total Tests: 6
Passed:      1
Failed:      5
============================================================
tb/tb_aes_core.sv:264: $finish called at 2842363 (1ps)
