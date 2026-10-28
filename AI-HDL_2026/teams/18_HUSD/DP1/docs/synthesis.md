# Synthesis Results

## Overview

RTL synthesis was performed using the OpenLane automated digital ASIC flow.  
The purpose of this synthesis stage was to evaluate the design's area, power, and timing characteristics and to verify that the RTL is fully synthesizable under standard-cell constraints.

All synthesis results reported in this section are derived from the OpenLane post-synthesis metrics.

## Synthesis Configuration

- **Synthesis tool**: OpenLane (Yosys-based synthesis)
- **Target technology**: Standard-cell ASIC flow (TinyTapeout-compatible)
- **Clock constraint**: Defined during synthesis
- **Optimization goals**: Timing closure with minimal area overhead

## Area Utilization

The synthesized design successfully maps to standard cells without errors.

Key observations:
- The design fits within the expected area budget for DP1.
- No abnormal cell usage or synthesis warnings were reported.
- Peripheral integration (UART) does not introduce excessive area overhead.

(Refer to `metrics.csv` for detailed cell and area breakdown.)

## Power Estimation

Power estimation was performed as part of the OpenLane synthesis flow.

- **Power estimation type**: Static estimation
- **Observation**:
  - Power consumption remains within acceptable limits for a lightweight RISC-V core with a simple UART peripheral.
  - No excessive switching activity or leakage issues were observed.

Power results are considered preliminary and sufficient for DP1-level evaluation.

## Timing Summary

Timing analysis after synthesis reports:

- **Critical path delay**: 6.83 ns
- **Timing violations**: None (WNS ≥ 0, TNS = 0)

The detailed timing analysis and maximum operating frequency calculation are documented separately in `results/timing/timing.md`.

## Synthesis Artifacts

The following synthesis artifacts were generated and retained:

- OpenLane synthesis metrics:  
  - `results/synthesis/metrics.csv`

These artifacts provide traceability between the reported PPA results and the actual tool outputs.

## Conclusion

The synthesis results confirm that the RTL design is:

- Fully synthesizable under OpenLane
- Free of synthesis and timing violations
- Efficient in terms of area and power for the given functionality

The design satisfies all DP1 synthesis requirements and is suitable for further FPGA implementation or advanced optimization stages.
