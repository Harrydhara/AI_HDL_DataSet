user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$  iverilog -g2012 -s tb_aes_reg_interface -o reg_interface_sim \
  rtl/aes_reg_interface.sv tb/tb_aes_reg_interface.sv

vvp reg_interface_sim

============================================
  AES Register Interface Testbench
============================================
VCD info: dumpfile tb_aes_reg_interface.vcd opened for output.

Test 1: Reset Behavior
  PASSED: CTRL register reset to 0

Test 2: Control Register Write/Read
  PASSED: MODE bit writable and readable
  PASSED: decrypt output reflects MODE bit

Test 3: Status Register Read
  STATUS: BUSY=1, DONE=0, KEY_VALID=1
  PASSED: Status register reflects inputs

Test 4: Key Register Write-Only Security
  PASSED: Key written correctly to output
  PASSED: Key register is write-only (reads as 0)

Test 5: Data Input Register Write
  PASSED: Data input written correctly

Test 6: Data Output Register Read
  PASSED: DOUT0 read correctly
  PASSED: DOUT3 read correctly

Test 7: Start Pulse Generation
  FAILED: Start pulse not generated

Test 8: Interrupt Enable Register
  PASSED: Interrupt enable bits set

Test 9: Interrupt Generation
  PASSED: Interrupt generated on done
  PASSED: DONE interrupt flag set

Test 10: Interrupt Clear (W1C)
  PASSED: Interrupt cleared by W1C
  PASSED: Interrupt output deasserted

============================================
  AES Register Interface Test Summary
============================================
  Total Tests: 10
  Errors: 1
  *** TESTS FAILED ***
============================================
tb/tb_aes_reg_interface.sv:472: $finish called at 1664169 (1ps)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$   git status
git pull
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        Acona-Tech-AI-HDL-2026/
        aes_control_fsm
        aes_sim
        control_fsm_sim
        core_sim
        key_expansion_sim
        mixcolumns_sim
        reg_interface_sim
        sbox_sim

nothing added to commit but untracked files present (use "git add" to track)
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 4 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (4/4), 2.02 KiB | 2.02 MiB/s, done.
From github.com:[user]/Acona-Tech-AI-HDL-2026
   9306ef5..b1cb7f7  main       -> origin/main
Updating 9306ef5..b1cb7f7
Fast-forward
 tb/tb_aes_reg_interface.sv | 157 +++++++++++++++++++++++++++++++++++++------------------------------
 1 file changed, 86 insertions(+), 71 deletions(-)
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$  iverilog -g2012 -s tb_aes_reg_interface -o reg_interface_sim \
  rtl/aes_reg_interface.sv tb/tb_aes_reg_interface.sv

vvp reg_interface_sim
