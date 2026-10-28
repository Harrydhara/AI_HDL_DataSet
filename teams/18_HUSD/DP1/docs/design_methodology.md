# Design Methodology

## Overview
This project implements a RISC-V-based TinyQV core integrated with a custom UART peripheral for the AIHDL-2026 challenge. The design follows a modular RTL methodology, separating the system into a top-level wrapper, peripheral logic, and verification components.

## Architecture
- **Top-level core (`tt_wrapper.v`)**
  - Integrates the TinyQV RISC-V core
  - Handles clock, reset, and memory-mapped peripheral interface
- **Peripheral module (`peripheral.v`)**
  - Implements a UART controller
  - Provides register-based access for TX/RX and status
- **Testbench (`testbench/`)**
  - Provided testbench to validate baseline functionality
  - Custom UART-focused testbench for extended verification

## Design Flow
1. Analyze provided TinyTapeout / TinyQV reference design
2. Define the UART peripheral register map
3. Implement synthesizable RTL in Verilog
4. Verify functionality using Python-based testbenches
5. Perform baseline synthesis for PPA estimation
6. Iterate based on verification and synthesis feedback

## Key Design Principles
- Fully synthesizable RTL (no behavioral-only constructs)
- Clear module boundaries
- Deterministic register behavior
- Compatibility with TinyTapeout flow

## DP2 Methodology

The DP2 phase focused on architecture-level optimization based on DP1 implementation feedback.

### Optimization Approach

1. **Combinational Logic Reduction**
   - Simplified data path operations
   - Removed redundant logic
   - Enabled more effective synthesis optimization

2. **Pipeline Insertion**
   - Added additional registers to break long combinational paths
   - Reduced logic depth (13 → 9 levels)
   - Improved placement locality

3. **Area-Oriented Synthesis**
   - Used AREA optimization strategy
   - Allowed the synthesis tool to minimize cell count and logic complexity

4. **Physical Awareness**
   - Optimization decisions were guided by DP1 congestion, routing, and utilization reports
   - Goal: reduce wire length, vias, and routing demand

### Verification Flow

After optimization:
- Functional consistency maintained
- Full OpenLane flow executed
- Verified:
  - Timing (WNS/TNS = 0)
  - DRC clean
  - LVS clean
