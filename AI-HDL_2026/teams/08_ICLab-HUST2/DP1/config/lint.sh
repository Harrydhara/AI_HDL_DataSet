#!/bin/bash

verilator --lint-only -DSIM -Wall \
    -Wno-DECLFILENAME \
    -Wno-MULTITOP \
    -Wno-WIDTH \
    -Wno-COMBDLY \
    -Wno-UNDRIVEN \
    project.v \
    tinyqv.v cpu.v core.v decode.v alu.v register.v counter.v \
    mem_ctrl.v qspi_ctrl.v qspi_flash.v \
    peripherals.v uart_tx.v time.v \
    tqvp_winograd.v winograd.v element_wise.v \
    matrix_filter.v matrix_input.v matrix_output.v \
    latch_reg.v interface.v