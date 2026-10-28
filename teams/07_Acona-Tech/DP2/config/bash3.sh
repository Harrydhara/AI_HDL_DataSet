Microsoft Windows [Version 10.0.26200.7922]
(c) Microsoft Corporation. All rights reserved.

C:\Users\user>wsl
user@host:/mnt/c/Users/user$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ ls
Acona-Tech-AI-HDL-2026  key_expansion_sim  sim_aes_core  tb_baseline.vvp
OpenLane                mixcolumns_sim     sim_mixcolumns  tb_clock_gated.vvp
aes_control_fsm         nano               software  tb_opt.vvp
aes_control_fsm.sv      reg_interface_sim  synth  tb_opt_v2.vvp
aes_core.sv             reports            synth_baseline.ys  tb_riscv_mock.sv
aes_sim                 riscV_mock.sv      synth_opt_v1.ys  tb_tqvp_aes128.vcd
aes_standalone.vcd      rtl                synth_opt_v2.ys  timing_v1.ys
build                   rtl_optimized      tb  timing_v2.ys
control_fsm_sim         run_sim.sh         tb_aes_control_fsm.vcd  venv
debug_sim               sbox_sim           tb_aes_core.vcd
docs                    scripts            tb_aes_mixcolumns.vcd
gate_sim                sim                tb_aes_reg_interface.vcd
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026                                 ls
                                             cd ~/AI-HDL/user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ ls
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

# 1. Download and place all 5 files in rtl_optimized/ and tb/

# 2. Compile v3
iverilog -g2012 -o tb_opt_v3.vvp \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns_fast.sv \
    rtl_optimized/aes_key_expansion_unrolled.sv \
    rtl_optimized/aes_core_fast.sv \
    rtl_optimized/aes_reg_interface.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/tqvp_aes128_opt_v3.sv \
    tb/tb_tqvp_aes128_opt_v3.sv

# 3. Run simulation
vvp tb_opt_v3.vvp

# 4. Run timing analysis
cat > timing_v3.ys << 'EOF'
read_verilog -sv rtl_optimized/aes_sbox.sv
read_verilog -sv rtl_optimized/aes_mixcolumns_fast.sv
read_verilog -sv rtl_optimized/aes_key_expansion_unrolled.sv
read_verilog -sv rtl_optimized/aes_core_fast.sv
read_verilog -sv rtl_optimized/aes_reg_interface.sv
read_verilog -sv rtl_optimized/aes_clock_gate.sv
read_verilog -sv rtl_optimized/tqvp_aes128_opt_v3.sv

synth -top tqvp_aes128_top_opt_v3
flatten
ltp -noff
EOF

yosys -s timing_v3.ys 2>&1 | tail -30
rtl_optimized/aes_mixcolumns_fast.sv: No such file or directory
Preprocessor failed with 1 errors.
tb_opt_v3.vvp: Unable to open input file.

 /----------------------------------------------------------------------------\
 |           |
 |  yosys -- Yosys Open SYnthesis Suite           |
 |           |
 |  Copyright (C) 2012 - 2020  Claire Xenia Wolf <claire@yosyshq.com>         |
 |           |
 |  Permission to use, copy, modify, and/or distribute this software for any  |
 |  purpose with or without fee is hereby granted, provided that the above    |
 |  copyright notice and this permission notice appear in all copies.         |
 |           |
 |  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  |
 |  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF          |
 |  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR   |
 |  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANYDAMAGES    |
 |  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN     |
 |  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF   |
 |  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.           |
 |           |
 \----------------------------------------------------------------------------/

 Yosys 0.33 (git sha1 2584903a060)


-- Executing script file `timing_v3.ys' --

1. Executing Verilog-2005 frontend: rtl_optimized/aes_sbox.sv
ERROR: Can't open input file `rtl_optimized/aes_mixcolumns_fast.sv' for reading: No such file or directory
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ git pull
remote: Enumerating objects: 20, done.
remote: Counting objects: 100% (20/20), done.
remote: Compressing objects: 100% (20/20), done.
remote: Total 20 (delta 7), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (20/20), 15.70 KiB | 1.74 MiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   1df60cb..a92c962  DP2        -> origin/DP2
Updating 1df60cb..a92c962
Fast-forward
 rtl_optimized/aes_core_fast.sv             | 272 ++++++++++++
 .../aes_key_expansion_unrolled.sv          | 254 +++++++++++
 rtl_optimized/aes_mixcolumns_fast.sv       | 277 ++++++++++++
 rtl_optimized/tqvp_aes128_opt_v3.sv        | 204 +++++++++
 tb/tb_tqvp_aes128_opt_v3.sv                | 350 ++++++++++++++++
 5 files changed, 1357 insertions(+)
 create mode 100644 rtl_optimized/aes_core_fast.sv
 create mode 100644 rtl_optimized/aes_key_expansion_unrolled.sv
 create mode 100644 rtl_optimized/aes_mixcolumns_fast.sv
 create mode 100644 rtl_optimized/tqvp_aes128_opt_v3.sv
 create mode 100644 tb/tb_tqvp_aes128_opt_v3.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

# 1. Download and place all 5 files in rtl_optimized/ and tb/

# 2. Compile v3
iverilog -g2012 -o tb_opt_v3.vvp \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns_fast.sv \
    rtl_optimized/aes_key_expansion_unrolled.sv \
    rtl_optimized/aes_core_fast.sv \
    rtl_optimized/aes_reg_interface.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/tqvp_aes128_opt_v3.sv \
    tb/tb_tqvp_aes128_opt_v3.sv

# 3. Run simulation
vvp tb_opt_v3.vvp

# 4. Run timing analysis
cat > timing_v3.ys << 'EOF'
read_verilog -sv rtl_optimized/aes_sbox.sv
read_verilog -sv rtl_optimized/aes_mixcolumns_fast.sv
read_verilog -sv rtl_optimized/aes_key_expansion_unrolled.sv
read_verilog -sv rtl_optimized/aes_core_fast.sv
read_verilog -sv rtl_optimized/aes_reg_interface.sv
read_verilog -sv rtl_optimized/aes_clock_gate.sv
read_verilog -sv rtl_optimized/tqvp_aes128_opt_v3.sv

synth -top tqvp_aes128_top_opt_v3
flatten
ltp -noff
EOF

yosys -s timing_v3.ys 2>&1 | tail -30

================================================================
  DP2 v3: Fully Optimized AES-128 Verification
  (Clock Gating + Fast MixColumns + Unrolled Keys)
================================================================

Test 1: Reset Behavior
  STATUS: 0x00000000
  PASSED

Test 2: NIST FIPS-197 Encryption
  Cycles: 19
  FAILED: Ciphertext mismatch
    Expected: 3925841d02dc09fbdc118597196a0b32
    Got:      d6ddd85e3d759b815706038df10a6b4f

Test 3: NIST FIPS-197 Decryption
  Cycles: 19
  FAILED: Plaintext mismatch
    Expected: 3243f6a8885a308d313198a2e0370734
    Got:      641d8cd5e85321e97cd9b6e85dc01900

Test 4: All-Zeros Vector
  FAILED
    Expected: 66e94bd4ef8a2c3b884cfa59ca342b2e
    Got:      8197bbe7a234d30c56fef28d09077860

Test 5: Encrypt-Decrypt Round Trip
  Encrypted: ca2dfdcb657fc6c7efe7de10bca5daba
  Decrypted: 0fedcba9876543210badf00dcafebeef
  PASSED

================================================================
  TEST SUMMARY
================================================================
  Total Tests: 5
  Passed:      2
  Failed:      3
================================================================

  *** TESTS FAILED ***
================================================================
tb/tb_tqvp_aes128_opt_v3.sv:340: $finish called at 6461351 (1ps)
    7: \u_aes128.u_aes_core.round_num [3] (via $flatten\u_aes128.\u_aes_core.$abc$27591$auto$blifparse.cc:386:parse_blif$27903)
    8: $flatten\u_aes128.\u_key_expansion.$abc$29332$new_n7049_ (via $flatten\u_aes128.\u_key_expansion.$abc$29332$auto$blifparse.cc:386:parse_blif$34432)
    9: $flatten\u_aes128.\u_key_expansion.$abc$29332$new_n7050_ (via $flatten\u_aes128.\u_key_expansion.$abc$29332$auto$blifparse.cc:386:parse_blif$34433)
   10: $flatten\u_aes128.\u_key_expansion.$abc$29332$new_n9858_ (via $flatten\u_aes128.\u_key_expansion.$abc$29332$auto$blifparse.cc:386:parse_blif$37241)
   11: $flatten\u_aes128.\u_key_expansion.$abc$29332$new_n9859_ (via $flatten\u_aes128.\u_key_expansion.$abc$29332$auto$blifparse.cc:386:parse_blif$37242)
   12: $flatten\u_aes128.\u_key_expansion.$abc$29332$new_n9860_ (via $flatten\u_aes128.\u_key_expansion.$abc$29332$auto$blifparse.cc:386:parse_blif$37243)
   13: $flatten\u_aes128.\u_key_expansion.$abc$29332$new_n9861_ (via $flatten\u_aes128.\u_key_expansion.$abc$29332$auto$blifparse.cc:386:parse_blif$37244)
   14: $flatten\u_aes128.\u_key_expansion.$abc$29332$new_n9867_ (via $flatten\u_aes128.\u_key_expansion.$abc$29332$auto$blifparse.cc:386:parse_blif$37250)
   15: \u_aes128.u_key_expansion.round_key [127] (via $flatten\u_aes128.\u_key_expansion.$abc$29332$auto$blifparse.cc:386:parse_blif$37251)
   16: $flatten\u_aes128.\u_aes_core.$abc$27591$new_n1458_ (via $flatten\u_aes128.\u_aes_core.$abc$27591$auto$blifparse.cc:386:parse_blif$27870)
   17: \u_aes128.u_aes_core.after_add_key_inv [127] (via $flatten\u_aes128.\u_aes_core.$abc$27591$auto$blifparse.cc:386:parse_blif$27871)
   18: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$new_n1718_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$auto$blifparse.cc:386:parse_blif$38715)
   19: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$new_n1778_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$auto$blifparse.cc:386:parse_blif$38775)
   20: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$new_n1779_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$auto$blifparse.cc:386:parse_blif$38776)
   21: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$new_n1780_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$auto$blifparse.cc:386:parse_blif$38777)
   22: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$new_n1785_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$auto$blifparse.cc:386:parse_blif$38782)
   23: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$new_n1790_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$auto$blifparse.cc:386:parse_blif$38787)
   24: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$new_n1796_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$auto$blifparse.cc:386:parse_blif$38793)
   25: \u_aes128.u_aes_core.u_mixcolumns_dec.state_out [99] (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$37254$auto$blifparse.cc:386:parse_blif$38794)
   26: $flatten\u_aes128.\u_aes_core.$abc$27591$new_n2586_ (via $flatten\u_aes128.\u_aes_core.$abc$27591$auto$blifparse.cc:386:parse_blif$28998)
   27: $flatten\u_aes128.\u_aes_core.$abc$27591$new_n2587_ (via $flatten\u_aes128.\u_aes_core.$abc$27591$auto$blifparse.cc:386:parse_blif$28999)
   28: $flatten\u_aes128.\u_aes_core.$abc$27591$new_n2588_ (via $flatten\u_aes128.\u_aes_core.$abc$27591$auto$blifparse.cc:386:parse_blif$29000)
   29: $flatten\u_aes128.\u_aes_core.$abc$27591$new_n2591_ (via $flatten\u_aes128.\u_aes_core.$abc$27591$auto$blifparse.cc:386:parse_blif$29003)
   30: $flatten\u_aes128.\u_aes_core.$procmux$1227.Y [99] (via $flatten\u_aes128.\u_aes_core.$abc$27591$auto$blifparse.cc:386:parse_blif$29004)
   ff: \u_aes128.u_aes_core.state_reg [99] (via $flatten\u_aes128.\u_aes_core.$auto$ff.cc:266:slice$26034)

Warnings: 1 unique messages, 1 total
End of script. Logfile hash: 87650f507d, CPU: user 4.01s system 0.10s, MEM: 183.75 MB peak
Yosys 0.33 (git sha1 2584903a060)
Time spent: 21% 24x opt_expr (0 sec), 13% 1x abc (0 sec), ...
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ git pull
remote: Enumerating objects: 4, done.
remote: Counting objects: 100% (4/4), done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 4 (delta 0), reused 0 (delta 0), pack-reused 0 (from0)
Unpacking objects: 100% (4/4), 4.32 KiB | 2.16 MiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   a92c962..ce3549c  DP2        -> origin/DP2
Updating a92c962..ce3549c
Fast-forward
 .../aes_key_expansion_unrolled.sv          | 235 +++++++++-------
 1 file changed, 134 insertions(+), 101 deletions(-)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

# 1. Download aes_key_expansion_unrolled_fixed.sv
#    Save as: rtl_optimized/aes_key_expansion_unrolled.sv (replaceold one)

# 2. Re-compile
iverilog -g2012 -o tb_opt_v3.vvp \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns_fast.sv \
    rtl_optimized/aes_key_expansion_unrolled.sv \
    rtl_optimized/aes_core_fast.sv \
    rtl_optimized/aes_reg_interface.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/tqvp_aes128_opt_v3.sv \
    tb/tb_tqvp_aes128_opt_v3.sv

# 3. Run
vvp tb_opt_v3.vvp

================================================================
  DP2 v3: Fully Optimized AES-128 Verification
  (Clock Gating + Fast MixColumns + Unrolled Keys)
================================================================

Test 1: Reset Behavior
  STATUS: 0x00000000
  PASSED

Test 2: NIST FIPS-197 Encryption
  Cycles: 19
  PASSED: Ciphertext matches
    Result: 3925841d02dc09fbdc118597196a0b32

Test 3: NIST FIPS-197 Decryption
  Cycles: 19
  PASSED: Plaintext matches
    Result: 3243f6a8885a308d313198a2e0370734

Test 4: All-Zeros Vector
  PASSED

Test 5: Encrypt-Decrypt Round Trip
  Encrypted: 1f936dbf2ccf81f28c04dfe4a7406f81
  Decrypted: 0fedcba9876543210badf00dcafebeef
  PASSED

================================================================
  TEST SUMMARY
================================================================
  Total Tests: 5
  Passed:      5
  Failed:      0
================================================================

  *** ALL TESTS PASSED ***
  v3 Optimizations Verified!
  - Clock Gating: OK
  - Fast MixColumns: OK
  - Unrolled Keys: OK
================================================================
tb/tb_tqvp_aes128_opt_v3.sv:340: $finish called at 6461351 (1ps)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd ~/AI-HDL/Acona-Tech-AI-HDL-2026

# Run timing analysis for v3
cat > timing_v3.ys << 'EOF'
read_verilog -sv rtl_optimized/aes_sbox.sv
read_verilog -sv rtl_optimized/aes_mixcolumns_fast.sv
read_verilog -sv rtl_optimized/aes_key_expansion_unrolled.sv
read_verilog -sv rtl_optimized/aes_core_fast.sv
read_verilog -sv rtl_optimized/aes_reg_interface.sv
read_verilog -sv rtl_optimized/aes_clock_gate.sv
read_verilog -sv rtl_optimized/tqvp_aes128_opt_v3.sv

synth -top tqvp_aes128_top_opt_v3
flatten
ltp -noff
EOF

yosys -s timing_v3.ys 2>&1 | tail -40

10. Executing LTP pass (find longest path).

Longest topological path in tqvp_aes128_top_opt_v3 (length=30):
    0: \u_aes128.u_aes_core.round_cnt [2]
    1: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n1475_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$24373)
    2: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n1486_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$24384)
    3: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n1487_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$24385)
    4: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n1488_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$24386)
    5: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n1489_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$24387)
    6: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n1490_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$24388)
    7: \u_aes128.u_aes_core.round_num [3] (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$24389)
    8: $flatten\u_aes128.\u_key_expansion.$abc$25818$new_n4227_ (via $flatten\u_aes128.\u_key_expansion.$abc$25818$auto$blifparse.cc:386:parse_blif$27948)
    9: $flatten\u_aes128.\u_key_expansion.$abc$25818$new_n4228_ (via $flatten\u_aes128.\u_key_expansion.$abc$25818$auto$blifparse.cc:386:parse_blif$27949)
   10: $flatten\u_aes128.\u_key_expansion.$abc$25818$new_n7036_ (via $flatten\u_aes128.\u_key_expansion.$abc$25818$auto$blifparse.cc:386:parse_blif$30757)
   11: $flatten\u_aes128.\u_key_expansion.$abc$25818$new_n7037_ (via $flatten\u_aes128.\u_key_expansion.$abc$25818$auto$blifparse.cc:386:parse_blif$30758)
   12: $flatten\u_aes128.\u_key_expansion.$abc$25818$new_n7038_ (via $flatten\u_aes128.\u_key_expansion.$abc$25818$auto$blifparse.cc:386:parse_blif$30759)
   13: $flatten\u_aes128.\u_key_expansion.$abc$25818$new_n7039_ (via $flatten\u_aes128.\u_key_expansion.$abc$25818$auto$blifparse.cc:386:parse_blif$30760)
   14: $flatten\u_aes128.\u_key_expansion.$abc$25818$new_n7045_ (via $flatten\u_aes128.\u_key_expansion.$abc$25818$auto$blifparse.cc:386:parse_blif$30766)
   15: \u_aes128.u_key_expansion.round_key [127] (via $flatten\u_aes128.\u_key_expansion.$abc$25818$auto$blifparse.cc:386:parse_blif$30767)
   16: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n1458_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$24356)
   17: \u_aes128.u_aes_core.after_add_key_inv [127] (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$24357)
   18: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$new_n1719_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$auto$blifparse.cc:386:parse_blif$32232)
   19: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$new_n1779_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$auto$blifparse.cc:386:parse_blif$32292)
   20: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$new_n1780_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$auto$blifparse.cc:386:parse_blif$32293)
   21: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$new_n1781_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$auto$blifparse.cc:386:parse_blif$32294)
   22: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$new_n1786_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$auto$blifparse.cc:386:parse_blif$32299)
   23: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$new_n1791_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$auto$blifparse.cc:386:parse_blif$32304)
   24: $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$new_n1797_ (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$auto$blifparse.cc:386:parse_blif$32310)
   25: \u_aes128.u_aes_core.u_mixcolumns_dec.state_out [99] (via $flatten\u_aes128.\u_aes_core.\u_mixcolumns_dec.$abc$30770$auto$blifparse.cc:386:parse_blif$32311)
   26: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n2586_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$25484)
   27: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n2587_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$25485)
   28: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n2588_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$25486)
   29: $flatten\u_aes128.\u_aes_core.$abc$24077$new_n2591_ (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$25489)
   30: $flatten\u_aes128.\u_aes_core.$procmux$1207.Y [99] (via $flatten\u_aes128.\u_aes_core.$abc$24077$auto$blifparse.cc:386:parse_blif$25490)
   ff: \u_aes128.u_aes_core.state_reg [99] (via $flatten\u_aes128.\u_aes_core.$auto$ff.cc:266:slice$22600)

End of script. Logfile hash: 6eb07ab2bc, CPU: user 3.47s system 0.07s, MEM: 171.11 MB peak
Yosys 0.33 (git sha1 2584903a060)
Time spent: 21% 21x opt_expr (0 sec), 13% 20x opt_clean (0 sec), ...
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ abc -liberty your_tech.lib
stat -liberty your_tech.lib
Command 'abc' not found, but there are 16 similar ones.
stat: invalid option -- 'l'
Try 'stat --help' for more information.
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$
