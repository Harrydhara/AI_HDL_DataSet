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
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 4 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (4/4), 1.20 KiB | 612.00 KiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   a9b11e4..ddb0432  main       -> origin/main
Updating a9b11e4..ddb0432
Fast-forward
 tb/tb_aes_mixcolumns.sv | 16 ++++++++++------
 1 file changed, 10 insertions(+), 6 deletions(-)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim_mixcolumns rtl/aes_mixcolumns.sv t
b/tb_aes_mixcolumns.sv && vvp sim_mixcolumns
t: No such file or directory
Preprocessor failed with 1 errors.
-bash: b/tb_aes_mixcolumns.sv: No such file or directory
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim_mixcolumns rtl/aes_mixcolumns.svtb/tb_aes_mixcolumns.sv && vvp sim_mixcolumns
============================================================
AES MixColumns/InvMixColumns Testbench
AIHDL 2026 Competition - Team Acona
============================================================

VCD info: dumpfile tb_aes_mixcolumns.vcd opened for output.

------------------------------------------------------------
TEST GROUP 1: Single Column MixColumns Verification
------------------------------------------------------------
[PASS] NIST 5.1.3 Column test {db,13,53,45}
       Input:    db135345000000000000000000000000
       Output:   8e4da1bc000000000000000000000000
[PASS] NIST 5.1.3 Column test {f2,0a,22,5c}
       Input:    f20a225c000000000000000000000000
       Output:   9fdc589d000000000000000000000000
[PASS] Uniform 0x01 column
       Input:    01010101000000000000000000000000
       Output:   01010101000000000000000000000000

------------------------------------------------------------
TEST GROUP 2: NIST FIPS-197 Appendix B Full State
------------------------------------------------------------
[PASS] NIST FIPS-197 Appendix B Round 1
       Input:    d4bf5d30e0b452aeb84111f11e2798e5
       Output:   046681e5e0cb199a48f8d37a2806264c

------------------------------------------------------------
TEST GROUP 3: Corner Cases
------------------------------------------------------------
[PASS] All zeros
       Input:    00000000000000000000000000000000
       Output:   00000000000000000000000000000000
[PASS] Single byte s0=0x01
       Input:    01000000000000000000000000000000
       Output:   02010103000000000000000000000000
[PASS] Single byte s1=0x01
       Input:    00010000000000000000000000000000
       Output:   03020101000000000000000000000000
[PASS] Single byte s2=0x01
       Input:    00000100000000000000000000000000
       Output:   01030201000000000000000000000000
[PASS] Single byte s3=0x01
       Input:    00000001000000000000000000000000
       Output:   01010302000000000000000000000000

------------------------------------------------------------
TEST GROUP 4: GF(2^8) Multiplication Verification
------------------------------------------------------------
[PASS] xtime(0x57)=0xAE verification
       Input:    57000000000000000000000000000000
       Output:   ae5757f9000000000000000000000000
[PASS] xtime(0x80)=0x1B verification
       Input:    80000000000000000000000000000000
       Output:   1b80809b000000000000000000000000
[PASS] xtime(0xFF)=0xE5 verification
       Input:    ff000000000000000000000000000000
       Output:   e5ffff1a000000000000000000000000

------------------------------------------------------------
TEST GROUP 5: Column Independence
------------------------------------------------------------
[PASS] Column 1 independence
       Input:    00000000010203040000000000000000
       Output:   000000000304090a0000000000000000
[PASS] Column 2 independence
       Input:    00000000000000000102030400000000
       Output:   00000000000000000304090a00000000
[PASS] Column 3 independence
       Input:    00000000000000000000000001020304
       Output:   0000000000000000000000000304090a
[PASS] All columns identical input
       Input:    01020304010203040102030401020304
       Output:   0304090a0304090a0304090a0304090a

------------------------------------------------------------
TEST GROUP 6: Inverse MixColumns
------------------------------------------------------------
[PASS] InvMixColumns NIST Appendix B
       Input:    046681e5e0cb199a48f8d37a2806264c
       Output:   d4bf5d30e0b452aeb84111f11e2798e5
[PASS] InvMixColumns single column
       Input:    8e4da1bc000000000000000000000000
       Output:   db135345000000000000000000000000

------------------------------------------------------------
TEST GROUP 7: Round-Trip Verification
------------------------------------------------------------
[PASS] Round-trip: NIST Round 1 input
       Original:     d4bf5d30e0b452aeb84111f11e2798e5
       After MC:     046681e5e0cb199a48f8d37a2806264c
       After InvMC:  d4bf5d30e0b452aeb84111f11e2798e5
[PASS] Round-trip: All zeros
       Original:     00000000000000000000000000000000
       After MC:     00000000000000000000000000000000
       After InvMC:  00000000000000000000000000000000
[PASS] Round-trip: All ones
       Original:     ffffffffffffffffffffffffffffffff
       After MC:     ffffffffffffffffffffffffffffffff
       After InvMC:  ffffffffffffffffffffffffffffffff
[PASS] Round-trip: Sequential pattern
       Original:     0123456789abcdeffedcba9876543210
       After MC:     45ef01abcd678923ba10fe54329876dc
       After InvMC:  0123456789abcdeffedcba9876543210
[PASS] Round-trip: Random pattern
       Original:     deadbeefcafebabe12345678abcdef01
       After MC:     1aa93eaf9246826656f802a4ef01a0c6
       After InvMC:  deadbeefcafebabe12345678abcdef01
[PASS] Round-trip: Alternating bits
       Original:     55555555aaaaaaaa55555555aaaaaaaa
       After MC:     55555555aaaaaaaa55555555aaaaaaaa
       After InvMC:  55555555aaaaaaaa55555555aaaaaaaa
[PASS] Round-trip: Mixed columns
       Original:     db135345f20a225c0123456789abcdef
       After MC:     8e4da1bc9fdc589d45ef01abcd678923
       After InvMC:  db135345f20a225c0123456789abcdef

------------------------------------------------------------
TEST GROUP 8: Additional Verification
------------------------------------------------------------
[PASS] Round-trip: Uniform 0x63
       Original:     63636363636363636363636363636363
       After MC:     63636363636363636363636363636363
       After InvMC:  63636363636363636363636363636363
[PASS] Uniform 0x63 stays uniform
       Input:    63636363636363636363636363636363
       Output:   63636363636363636363636363636363

============================================================
TEST SUMMARY
============================================================
Total Tests: 27
Passed:      27
Failed:      0

*** ALL TESTS PASSED ***
AES MixColumns module is verified!
============================================================

tb/tb_aes_mixcolumns.sv:452: $finish called at 550000 (1ps)
