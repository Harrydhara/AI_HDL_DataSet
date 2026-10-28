user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ cd rtl
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl$ ls
aes_control_fsm.sv  aes_key_expansion.sv  aes_reg_interface.sv  tqvp_aes128.sv
aes_core.sv         aes_mixcolumns.sv     aes_sbox.sv
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026/rtl$ cd ..
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 \
  -s tb_aes_sbox.sv \
  -o sbox_sim \
  rtl/aes_sbox.sv \
  tb/tb_aes_sbox.sv

vvp sbox_sim
error: Unable to find the root module "tb_aes_sbox.sv" in the Verilog source.
     : Perhaps ``-s tb_aes_sbox.sv'' is incorrect?
1 error(s) during elaboration.
sbox_sim: Unable to open input file.
user@host:~/AI-HDL/Acona-Tech-AI-HDL-2026$ iverilog -g2012 \
  -s tb_aes_sbox \
  -o sbox_sim \
  rtl/aes_sbox.sv \
  tb/tb_aes_sbox.sv

vvp sbox_sim

============================================
  AES S-Box Unit Test
============================================

Test 1: Forward S-Box Known Values
  PASSED: S[0x00] = 0x63
  PASSED: S[0x53] = 0xed
  PASSED: S[0xFF] = 0x16
  PASSED: S[0x2B] = 0xf1

Test 2: Inverse S-Box Known Values
  PASSED: S^-1[0x63] = 0x00
  PASSED: S^-1[0xED] = 0x53
  PASSED: S^-1[0x16] = 0xff

Test 3: S-Box Inverse Property (S^-1[S[x]] = x)
  PASSED: All 256 values satisfy S^-1[S[x]] = x

============================================
  S-Box Unit Test Summary
============================================
  Errors: 0
  *** ALL S-BOX TESTS PASSED ***
============================================
tb/tb_aes_sbox.sv:185: $finish called at 2630000 (1ps)
