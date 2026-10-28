# Simulation Report — tqvp_winograd (Winograd Convolution Accelerator)

**Tool:** Icarus Verilog v11/v12 + cocotb v1.9.2 | **Date:** March 2026

---

## Overall Summary

| Phase | Testbench | Tests | Pass | Fail | Status |
|---|---|---|---|---|---|
| Test 1 | test.py (SPI harness) | 2 | 2 | 0 | ✅ ALL PASS |
| Test 2 | peri_num_14  | 2 | 2 | 0 | ✅ ALL PASS |
| Test 2 | full system  | | | 0 | ✅ ALL PASS |

---

## Test 1 — (SPI Harness)
``` bash
user@host:/mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness$ make
rm -f results.xml
"make" -f Makefile results.xml
make[1]: Entering directory '/mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness'
mkdir -p sim_build/rtl
/usr/bin/iverilog -o sim_build/rtl/sim.vvp -D COCOTB_SIM=1 -s tb -g2012 -I/mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src -f sim_build/rtl/cmds.f  /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src/peripheral.v /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src/interface.v /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src/winograd.v /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src/matrix_filter.v /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src/matrix_input.v /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src/matrix_output.v /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src/element_wise.v /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src/tt_wrapper.v /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/src/test_harness/*.sv /mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness/tb.v
rm -f results.xml
MODULE=test TESTCASE= TOPLEVEL=tb TOPLEVEL_LANG=verilog \
         /usr/bin/vvp -M /home/user/.local/lib/python3.10/site-packages/cocotb/libs -m libcocotbvpi_icarus   sim_build/rtl/sim.vvp
     -.--ns INFO     gpi                                ..mbed/gpi_embed.cpp:79   in set_program_name_in_venv        Did not detect Python virtual environment. Using system-wide Python interpreter
     -.--ns INFO     gpi                                ../gpi/GpiCommon.cpp:101  in gpi_print_registered_impl       VPI registered
     0.00ns INFO     cocotb                             Running on Icarus Verilog version 11.0 (stable)
     0.00ns INFO     cocotb                             Running tests with cocotb v1.9.0 from /home/user/.local/lib/python3.10/site-packages/cocotb
     0.00ns INFO     cocotb                             Seeding Python random module with 1773617283
     0.00ns INFO     cocotb.regression                  Found test test.test_winograd_all
     0.00ns INFO     cocotb.regression                  running test_winograd_all (1/1)
                                                          All Winograd peripheral tests
     0.00ns INFO     cocotb.tb                          Reset
VCD info: dumpfile tb.vcd opened for output.
   900.00ns INFO     cocotb.tb                          === test_address_debug ===
 27600.00ns INFO     cocotb.tb                            STATUS = 0x00000000
132900.00ns INFO     cocotb.tb                            INPUT_BUF[0] = 0x12345678
238200.00ns INFO     cocotb.tb                            FILTER_BUF[0] = 0x11223344
238200.00ns INFO     cocotb.tb                          test_address_debug PASS
238200.00ns INFO     cocotb.tb                          === test_single_channel ===
1131200.00ns INFO     cocotb.tb                            OUTPUT[0] = 54.0000  (expect 54.0)
1157900.00ns INFO     cocotb.tb                            OUTPUT[1] = 63.0000  (expect 63.0)
1184600.00ns INFO     cocotb.tb                            OUTPUT[2] = 90.0000  (expect 90.0)
1211300.00ns INFO     cocotb.tb                            OUTPUT[3] = 99.0000  (expect 99.0)
1211300.00ns INFO     cocotb.tb                          test_single_channel PASS
1211300.00ns INFO     cocotb.tb                          === test_accumulate ===
1263900.00ns INFO     cocotb.tb                            Channel 0: input=1.0
2077600.00ns INFO     cocotb.tb                            Channel 1: input=2.0
2891300.00ns INFO     cocotb.tb                            Channel 2: input=3.0
3731700.00ns INFO     cocotb.tb                            ACC[0] = 54.0000  (expect 54.0)
3758400.00ns INFO     cocotb.tb                            ACC[1] = 54.0000  (expect 54.0)
3785100.00ns INFO     cocotb.tb                            ACC[2] = 54.0000  (expect 54.0)
3811800.00ns INFO     cocotb.tb                            ACC[3] = 54.0000  (expect 54.0)
3811800.00ns INFO     cocotb.tb                          test_accumulate PASS
3811800.00ns INFO     cocotb.tb                          === ALL TESTS PASSED ===
3811800.00ns INFO     cocotb.regression                  test_winograd_all passed
3811800.00ns INFO     cocotb.regression                  **************************************************************************************
                                                         ** TEST                          STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                         **************************************************************************************
                                                         ** test.test_winograd_all         PASS     3811800.00          65.16      58497.44  **
                                                         **************************************************************************************
                                                         ** TESTS=1 PASS=1 FAIL=0 SKIP=0            3811800.00          66.45      57360.99  **
                                                         **************************************************************************************

make[1]: Leaving directory '/mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_harness'
```

---

## Test2 — TinyQV SoC integration test:


**Test Peripheral**

``` bash
nt. Using system-wide Python interpreter
     -.--ns INFO     gpi                                ../gpi/GpiCommon.cpp:101  in gpi_print_registered_impl       VPI registered
     0.00ns INFO     cocotb                             Running on Icarus Verilog version 11.0 (stable)
     0.00ns INFO     cocotb                             Running tests with cocotb v1.9.0 from /home/user/.local/lib/python3.10/site-packages/cocotb
     0.00ns INFO     cocotb                             Seeding Python random module with 1773620366
     0.00ns INFO     cocotb.regression                  Found test user_peripherals.winograd.winograd.test_winograd_all
     0.00ns INFO     cocotb.regression                  running test_winograd_all (1/1)
                                                          All Winograd tests in one session
     0.00ns INFO     cocotb.tb                          Reset, latency 1
FST info: dumpfile sim_build/rtl/tb.fst opened for output.
  8569.76ns INFO     cocotb.tb                          === test_single_channel ===
181386.83ns INFO     cocotb.tb                            OUTPUT[0] = 54.0000  (expect 54.0)
183121.09ns INFO     cocotb.tb                            OUTPUT[1] = 63.0000  (expect 63.0)
184886.60ns INFO     cocotb.tb                            OUTPUT[2] = 90.0000  (expect 90.0)
186620.87ns INFO     cocotb.tb                            OUTPUT[3] = 99.0000  (expect 99.0)
186620.87ns INFO     cocotb.tb                          test_single_channel PASS
186620.87ns INFO     cocotb.tb                          === test_zero_filter ===
367109.32ns INFO     cocotb.tb                            OUTPUT[0] = 0.000000
368874.83ns INFO     cocotb.tb                            OUTPUT[1] = 0.000000
370609.09ns INFO     cocotb.tb                            OUTPUT[2] = 0.000000
372374.60ns INFO     cocotb.tb                            OUTPUT[3] = 0.000000
372374.60ns INFO     cocotb.tb                          test_zero_filter PASS
372374.60ns INFO     cocotb.tb                          === test_accumulate_3ch ===
380124.11ns INFO     cocotb.tb                            Channel 0: input=1.0
551113.16ns INFO     cocotb.tb                            Channel 1: input=2.0
722102.22ns INFO     cocotb.tb                            Channel 2: input=3.0
894841.16ns INFO     cocotb.tb                            ACC[0] = 54.0000  (expect 54.0)
896575.43ns INFO     cocotb.tb                            ACC[1] = 54.0000  (expect 54.0)
898340.94ns INFO     cocotb.tb                            ACC[2] = 54.0000  (expect 54.0)
900075.20ns INFO     cocotb.tb                            ACC[3] = 54.0000  (expect 54.0)
900075.20ns INFO     cocotb.tb                          test_accumulate_3ch PASS
900075.20ns INFO     cocotb.tb                          === test_clear_acc ===
1082329.16ns INFO     cocotb.tb                            [0] output=18.0000 acc=18.0000
1085828.94ns INFO     cocotb.tb                            [1] output=18.0000 acc=18.0000
1089328.72ns INFO     cocotb.tb                            [2] output=18.0000 acc=18.0000
1092828.49ns INFO     cocotb.tb                            [3] output=18.0000 acc=18.0000
1092828.49ns INFO     cocotb.tb                          test_clear_acc PASS
1092828.49ns INFO     cocotb.tb                          === test_accumulate_math ===
1444306.00ns INFO     cocotb.tb                            ACC[0] = 54.0000  (expect 54.0)
1446040.26ns INFO     cocotb.tb                            ACC[1] = 63.0000  (expect 63.0)
1447805.77ns INFO     cocotb.tb                            ACC[2] = 90.0000  (expect 90.0)
1449540.04ns INFO     cocotb.tb                            ACC[3] = 99.0000  (expect 99.0)
1449540.04ns INFO     cocotb.tb                          test_accumulate_math PASS
1449540.04ns INFO     cocotb.tb                          === ALL TESTS PASSED ===
1449540.04ns INFO     cocotb.regression                  test_winograd_all passed
1449540.04ns INFO     cocotb.regression                  **************************************************************************************************************
                                                         ** TEST                                                  STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                         **************************************************************************************************************
                                                         ** user_peripherals.winograd.winograd.test_winograd_all   PASS     1449540.04         330.54       4385.41  **
                                                         **************************************************************************************************************
                                                         ** TESTS=1 PASS=1 FAIL=0 SKIP=0                                    1449540.04         334.15       4338.01  **
                                                         **************************************************************************************************************
 
```

**Full system test**
``` bash
user@host:/mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_system$ MODULE=test TESTCASE=test_winograd_system make -f test_basic.mk
rm -f results.xml
"make" -f test_basic.mk results.xml
make[1]: Entering directory '/mnt/c/Users/user/Downloads/ICLab_HUST2-main3/ICLab_HUST2-main/testbench/tb_main/test_system'
rm -f results.xml
MODULE=test TESTCASE=test_winograd_system TOPLEVEL=tb TOPLEVEL_LANG=verilog \
         /usr/bin/vvp -M /home/user/.local/lib/python3.10/site-packages/cocotb/libs -m libcocotbvpi_icarus   sim_build/rtl/sim.vvp -fst
     -.--ns INFO     gpi                                ..mbed/gpi_embed.cpp:79   in set_program_name_in_venv        Did not detect Python virtual environment. Using system-wide Python interpreter
     -.--ns INFO     gpi                                ../gpi/GpiCommon.cpp:101  in gpi_print_registered_impl       VPI registered
     0.00ns INFO     cocotb                             Running on Icarus Verilog version 11.0 (stable)
     0.00ns INFO     cocotb                             Running tests with cocotb v1.9.0 from /home/user/.local/lib/python3.10/site-packages/cocotb
     0.00ns INFO     cocotb                             Seeding Python random module with 1773621764
     0.00ns INFO     cocotb.regression                  Found test test.test_winograd_system
     0.00ns INFO     cocotb.regression                  running test_winograd_system (1/1)
                                                          System-level Winograd tests — toàn bộ trong 1 session
     0.00ns INFO     cocotb.tb                          Reset, latency 1
FST info: dumpfile sim_build/rtl/tb.fst opened for output.
  8569.76ns INFO     cocotb.tb                          === test_peripheral_reachable ===
 10397.77ns INFO     cocotb.tb                            STATUS after reset = 0x00000000
 15397.45ns INFO     cocotb.tb                            CTRL readback = 0x00000000
 15397.45ns INFO     cocotb.tb                          test_peripheral_reachable PASS
 15397.45ns INFO     cocotb.tb                          === test_single_channel ===
195885.90ns INFO     cocotb.tb                            OUTPUT[0] = 54.0000  (expect 54.0)
197620.16ns INFO     cocotb.tb                            OUTPUT[1] = 63.0000  (expect 63.0)
199385.68ns INFO     cocotb.tb                            OUTPUT[2] = 90.0000  (expect 90.0)
201119.94ns INFO     cocotb.tb                            OUTPUT[3] = 99.0000  (expect 99.0)
201119.94ns INFO     cocotb.tb                          test_single_channel PASS
201119.94ns INFO     cocotb.tb                          === test_accumulate ===
208869.44ns INFO     cocotb.tb                            Channel 0: input=1.0
379858.50ns INFO     cocotb.tb                            Channel 1: input=2.0
550847.56ns INFO     cocotb.tb                            Channel 2: input=3.0
723586.50ns INFO     cocotb.tb                            ACC[0] = 54.0000  (expect 54.0)
725352.01ns INFO     cocotb.tb                            ACC[1] = 54.0000  (expect 54.0)
727086.28ns INFO     cocotb.tb                            ACC[2] = 54.0000  (expect 54.0)
728851.79ns INFO     cocotb.tb                            ACC[3] = 54.0000  (expect 54.0)
728851.79ns INFO     cocotb.tb                          test_accumulate PASS
728851.79ns INFO     cocotb.tb                          === test_irq ===
906074.82ns INFO     cocotb.tb                            STATUS = 0x00000002
906074.82ns INFO     cocotb.tb                          test_irq PASS
906074.82ns INFO     cocotb.tb                          === ALL SYSTEM TESTS PASSED ===
906074.82ns INFO     cocotb.regression                  test_winograd_system passed
906074.82ns INFO     cocotb.regression                  **************************************************************************************
                                                        ** TEST                          STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                        **************************************************************************************
                                                        ** test.test_winograd_system      PASS      906074.82         212.01       4273.64  **
                                                        **************************************************************************************
                                                        ** TESTS=1 PASS=1 FAIL=0 SKIP=0             906074.82         214.77       4218.73  **
                                                        **************************************************************************************
```