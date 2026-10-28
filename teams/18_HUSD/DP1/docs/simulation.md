# Simulation Results

## Overview
Simulation was performed using both the provided testbench and a custom UART-focused testbench to validate the functional correctness of the design.

## Testbenches Used
- **Provided testbench**: `testbench/test.py`
- **Custom testbench**: `testbench/additional_test.py`

## Test Coverage
The simulations verified:
- Correct instruction execution in the TinyQV RISC-V core
- Proper memory-mapped access to the UART peripheral
- UART transmit and receive behavior
- Reset and initialization behavior

## Results Summary
- All provided testbench cases passed successfully
- Custom UART testbench passed without errors
- No simulation warnings or fatal errors observed

## Artifacts
- Console logs generated during simulation
- Waveform inspection used during debugging

## Conclusion
The simulation results confirm that the RTL implementation is functionally correct and ready for synthesis.
