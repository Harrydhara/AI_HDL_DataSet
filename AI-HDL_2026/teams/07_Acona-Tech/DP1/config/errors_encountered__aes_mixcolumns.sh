user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd aes_mixcolumns
make sim     # Compile and run
make wave    # View waveforms (requires GTKWave)
-bash: cd: aes_mixcolumns: No such file or directory
make: *** No rule to make target 'sim'.  Stop.
make: *** No rule to make target 'wave'.  Stop.
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ # Compile MixColumns only
iverilog -g2012 -o sim_mixcolumns \
    rtl/aes_mixcolumns.sv \
    tb/tb_aes_mixcolumns.sv

# Run simulation
vvp sim_mixcolumns
============================================================
AES MixColumns/InvMixColumns Testbench
AIHDL 2026 Competition - Team Acona
============================================================

VCD info: dumpfile tb_aes_mixcolumns.vcd opened for output.

------------------------------------------------------------
TEST GROUP 1: NIST FIPS-197 Appendix B
------------------------------------------------------------
[PASS] NIST FIPS-197 Round 1 MixColumns
       Input:    d4bf5d30e0b452aeb84111f11e2798e5
       Output:   046681e5e0cb199a48f8d37a2806264c

------------------------------------------------------------
TEST GROUP 2: NIST FIPS-197 Appendix C.1 (AES-128)
------------------------------------------------------------
[PASS] AES-128 Round 1 MixColumns
       Input:    d4bf5d30e0b452aeb84111f11e2798e5
       Output:   046681e5e0cb199a48f8d37a2806264c
[FAIL] AES-128 Round 2 MixColumns
       Input:    49db873b453953a0cf2c3f77b8db38f0
       Expected: 584dcaf11b4b5aacdb1b760fa9cc4e91
       Got:      584dcaf1326221feb9a104b7d5ad18cb
[FAIL] AES-128 Round 3 MixColumns
       Input:    ac73cffac0965c5b5cde8d522c5a0c6f
       Expected: 75ec0993200b63394fb0ece67c392e09
       Got:      e3fa4fbc3d4803271e257513d5e3dffc
[FAIL] AES-128 Round 4 MixColumns
       Input:    5210f1ece8d5d8e427c3f46c17f72eb6
       Expected: 0fd2ec566c52c0f52b4f3e24a20d07c8
       Got:      899694d493cea1fd88d1a386b4267d97
[FAIL] AES-128 Round 5 MixColumns
       Input:    d653a4163aebb5d3b59e59f4a5b4ca73
       Expected: a3424ee817c1a26b96329fe9c94ef88f
       Got:      f091ecba34e0cead658d9ef02fe00b6c
[FAIL] AES-128 Round 6 MixColumns
       Input:    3bd9276887c9fcd00ab22ec09c9fc0dd
       Expected: f4bcd455dc2cbc6db2a09df892e46a6e
       Got:      4993146379c1c61c37c7bf19843fe441
[FAIL] AES-128 Round 7 MixColumns
       Input:    2db6e50a8fc2a4f68d3e88a5b10ee7a5
       Expected: 91c48e5834a1e7afb4d1e42e4de15e64
       Got:      746454300a111f1b6ed74c6b293a9e70
[FAIL] AES-128 Round 8 MixColumns
       Input:    ba75f47a84a48df32e2bc9f9be01e56e
       Expected: 2199f77ce3c8c1e05c3a6ab8c6f0e3da
       Got:      7e2db2a09aa82f4311c19c79efe6dce1
[FAIL] AES-128 Round 9 MixColumns
       Input:    4b868d6d2c4a8980339df4e837d218de
       Expected: ea835cf00445333d655d98ad8596b0c5
       Got:      e7bd7b0c8fb8f4acc6fd7ef7c57eac34

------------------------------------------------------------
TEST GROUP 3: Inverse MixColumns
------------------------------------------------------------
[PASS] InvMixColumns Round 1 reverse
       Input:    046681e5e0cb199a48f8d37a2806264c
       Output:   d4bf5d30e0b452aeb84111f11e2798e5
[FAIL] InvMixColumns Round 5 reverse
       Input:    a3424ee817c1a26b96329fe9c94ef88f
       Expected: d653a4163aebb5d3b59e59f4a5b4ca73
       Got:      aa8dc9a9a57e2eeaf92a4f4e2921e31b
[FAIL] InvMixColumns Round 9 reverse
       Input:    ea835cf00445333d655d98ad8596b0c5
       Expected: 4b868d6d2c4a8980339df4e837d218de
       Got:      614646a45b53f2b5a9444eae0cf6f569

------------------------------------------------------------
TEST GROUP 4: Round-Trip Verification
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
[PASS] Round-trip: Random pattern 1
       Original:     deadbeefcafebabe12345678abcdef01
       After MC:     1aa93eaf9246826656f802a4ef01a0c6
       After InvMC:  deadbeefcafebabe12345678abcdef01
[PASS] Round-trip: Alternating bits
       Original:     55555555aaaaaaaa55555555aaaaaaaa
       After MC:     55555555aaaaaaaa55555555aaaaaaaa
       After InvMC:  55555555aaaaaaaa55555555aaaaaaaa

------------------------------------------------------------
TEST GROUP 5: Corner Cases
------------------------------------------------------------
[PASS] All zeros MixColumns
       Input:    00000000000000000000000000000000
       Output:   00000000000000000000000000000000
[PASS] Single byte (s0=0x01)
       Input:    01000000000000000000000000000000
       Output:   02010103000000000000000000000000
[PASS] Single byte (s1=0x01)
       Input:    00010000000000000000000000000000
       Output:   03020101000000000000000000000000
[PASS] Single byte (s2=0x01)
       Input:    00000100000000000000000000000000
       Output:   01030201000000000000000000000000
[PASS] Single byte (s3=0x01)
       Input:    00000001000000000000000000000000
       Output:   01010302000000000000000000000000

------------------------------------------------------------
TEST GROUP 6: GF(2^8) xtime Verification
------------------------------------------------------------
[FAIL] xtime(0x57) verification
       Input:    57000000000000000000000000000000
       Expected: ae575783000000000000000000000000
       Got:      ae5757f9000000000000000000000000
[PASS] xtime(0x80)=0x1B verification
       Input:    80000000000000000000000000000000
       Output:   1b80809b000000000000000000000000
[FAIL] xtime(0xFF)=0xE5 verification
       Input:    ff000000000000000000000000000000
       Expected: e5ff1c1c000000000000000000000000
       Got:      e5ffff1a000000000000000000000000

------------------------------------------------------------
TEST GROUP 7: Column Independence
------------------------------------------------------------
[FAIL] Column 1 only
       Input:    00000000010203040000000000000000
       Expected: 00000000030103050000000000000000
       Got:      000000000304090a0000000000000000
[FAIL] Column 2 only
       Input:    00000000000000000102030400000000
       Expected: 00000000000000000301030500000000
       Got:      00000000000000000304090a00000000
[FAIL] Column 3 only
       Input:    00000000000000000000000001020304
       Expected: 00000000000000000000000003010305
       Got:      0000000000000000000000000304090a

------------------------------------------------------------
TEST GROUP 8: Additional Verification
------------------------------------------------------------
[PASS] Round-trip: Uniform 0x63 pattern
       Original:     63636363636363636363636363636363
       After MC:     63636363636363636363636363636363
       After InvMC:  63636363636363636363636363636363
[PASS] Round-trip: Prime number pattern
       Original:     020305070b0d111317191d1f23252b2f
       After MC:     030c020e03311127071d15032d3b2135
       After InvMC:  020305070b0d111317191d1f23252b2f

============================================================
TEST SUMMARY
============================================================
Total Tests: 32
Passed:      17
Failed:      15

*** SOME TESTS FAILED ***
Please review the failed test cases above.
============================================================

tb/tb_aes_mixcolumns.sv:509: $finish called at 600000 (1ps)
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
remote: Enumerating objects: 8, done.
remote: Counting objects: 100% (8/8), done.
remote: Compressing objects: 100% (5/5), done.
remote: Total 5 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (5/5), 3.82 KiB | 3.82 MiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   57a69c2..a9b11e4  main       -> origin/main
Updating 57a69c2..a9b11e4
Fast-forward
 tb/tb_aes_mixcolumns.sv | 425 ++++++++++++++++++++++++++++++----------------------------------------
 1 file changed, 182 insertions(+), 243 deletions(-)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim_mixcolumns rtl/aes_mixcolumns.v tb/tb_aes_mixcolumns.v && vvp sim_mixcolumns
rtl/aes_mixcolumns.v: No such file or directory
No top level modules, and no -s option.
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 -o sim_mixcolumns rtl/aes_mixcolumns.sv t
b/tb_aes_mixcolumns.sv && vvp sim_mixcolumns
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
[FAIL] Column 1 independence
       Input:    00000000010203040000000000000000
       Expected: 00000000030409050000000000000000
       Got:      000000000304090a0000000000000000
[FAIL] Column 2 independence
       Input:    00000000000000000102030400000000
       Expected: 00000000000000000304090500000000
       Got:      00000000000000000304090a00000000
[FAIL] Column 3 independence
       Input:    00000000000000000000000001020304
       Expected: 00000000000000000000000003040905
       Got:      0000000000000000000000000304090a
[FAIL] All columns identical input
       Input:    01020304010203040102030401020304
       Expected: 03040905030409050304090503040905
       Got:      0304090a0304090a0304090a0304090a

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
Passed:      23
Failed:      4

*** SOME TESTS FAILED ***
Please review failed test cases above.
============================================================

tb/tb_aes_mixcolumns.sv:448: $finish called at 550000 (1ps)
