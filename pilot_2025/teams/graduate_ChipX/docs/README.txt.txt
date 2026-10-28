# README - Stopwatch and Digital Clock System

## Overview
This project implements a **Stopwatch and Digital Clock System** on an FPGA using Verilog in **Vivado 2024.2**. The design includes a digital clock, stopwatch, alarm, and security mechanism with optimized power consumption.

## Features
- **Digital Clock:** Supports 12-hour and 24-hour formats.
- **Stopwatch:** Start/Stop toggle with reset functionality.
- **Alarm System:** Allows users to set and acknowledge alarms.
- **Security Lock:** Requires a code to unlock certain functionalities.
- **Power Optimization:** Implements clock gating to reduce dynamic power consumption.

## Files Overview
| File Name           | Description |
|---------------------|-------------|
| `stopwatch_top.v`  | Top-level module integrating all components. |
| `stopwatch.v`      | Stopwatch logic with minute, second, and tenths counter. |
| `digital_clock.v`  | Digital clock logic supporting 12/24-hour mode. |
| `alarm_clock.v`    | Alarm system with enable and acknowledgment feature. |
| `button_debouncer.v` | Debounces push-button inputs to avoid spurious signals. |
| `clock_divider.v`  | Generates slower clock signals (1Hz, 10Hz) from FPGA system clock. |
| `security_module.v`| Security lock feature requiring unlock code. |
| `seven_segment_display.v` | Drives a 4-digit seven-segment display. |

## Design Flow
1. **Simulation**
   - Run behavioral simulation in Vivado.
   - Verify waveforms using testbench.
   
2. **Synthesis & Implementation**
   - Open synthesized design to check RTL schematic.
   - Run `Report Utilization` to verify resource usage.
   - Run `Report Timing` to ensure no setup/hold violations.
   
3. **Power Optimization**
   - Uses clock gating to reduce unnecessary toggling.
   - Run `Report Power` to validate power reduction.

4. **Bitstream Generation & FPGA Programming**
   - Generate `.bit` file in Vivado.
   - Program FPGA and validate functionality on hardware.

## Power Optimization Techniques Used
- **Clock Gating:** Disables unused modules to reduce switching activity.
- **Optimized Display Updates:** Updates only when needed to reduce dynamic power.
- **Selective Module Activation:** Security module activates only when unlock button is pressed.

## Running the Project in Vivado
1. Open Vivado 2024.2 and create a new project.
2. Add all Verilog source files.
3. Set `stopwatch_top.v` as the top module.
4. Run behavioral simulation.
5. Click `Synthesize` → `Implement Design`.
6. Run `Generate Bitstream`.
7. Load the `.bit` file onto the FPGA.

## Expected FPGA Resource Utilization
- **LUTs**: ~X%
- **Flip-Flops**: ~Y%
- **Power Consumption**: Reduced from ~5.9W to ~0.068W

## Authors
- Member A

