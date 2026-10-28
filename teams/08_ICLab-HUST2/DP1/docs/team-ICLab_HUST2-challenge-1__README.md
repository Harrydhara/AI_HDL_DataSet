# ICLab_HUST2 - DP1 Submission

## Team Information
- **Team Name**: ICLab_HUST2
- **Institution**: Hanoi University of Science and Technology
- **Division**: [Lower]
- **Team Members**: 
  - Member A - RTL Design & Verification Lead - [email]
  - Member B - Specification & Documentation - [email]
  - Member D - Physical Implementation - [email]
  - Member C - Specification & Documentation - [email]
  - Member E - Technical Research & Support - [email]
- **Mentor**: [mentor]

## Challenge Summary
This project implements a high-performance Convolution Accelerator based on the Winograd $F(2 \times 2,3 \times 3)$ algorithm. The accelerator is directly integrated into a System-on-chip (SoC) featuring the TinyQV RISC-V core through a memory-mapped I/O mechanism, which enables the CPU to configure settings, transfer data, and retrieve results via dedicated peripheral registers.
Operating as a specialized coprocessor, the accelerator supports parallel processing and incorporates an interrupt mechanism to notify the CPU immediately upon computation completion. The architecture focuses on optimizing computational intensity by significantly reducing the number of required multiplications, thereby drastically lowering both computational overhead and overall power consumption.

## Key Features

### High-Efficiency Winograd \(F(2\times2,3\times3)\) Engine
The accelerator implements the **Winograd minimal filtering algorithm** to reduce the number of multiplications required for convolution. Compared to direct convolution, the Winograd transformation reduces the number of multiplications from **36 to 16 per \(4\times4\) input tile**, significantly improving computational efficiency for **\(3\times3\)** convolution layers. The transformation matrices \((G, B^T, A^T)\) are implemented using additions and simple arithmetic operations instead of multipliers to reduce hardware complexity and area cost.

- **Seamless Memory-Mapped SoC Integration**
The accelerator is integrated into the **TinyQV system** as a **memory-mapped peripheral** with base address **`0x800_0380`**. The CPU interacts with the accelerator through standard **Load/Store instructions**. A handshake mechanism based on the **`data_ready`** signal ensures proper synchronization between the CPU bus and the accelerator.

- **Interrupt-Driven Coprocessor Architecture**
The accelerator operates as an **independent coprocessor**. Upon completion of the computation, the **`winograd_irq`** signal generates an interrupt to notify the CPU, allowing the processor to perform other tasks while the accelerator is running.

- **Hardware-Accelerated Channel Accumulation**
The architecture supports accumulation of convolution results across multiple input channels using dedicated hardware logic. The computation flow is managed by a centralized **Finite State Machine (FSM)** that coordinates the sequence of **data loading, transformation, element-wise multiplication, and output generation**.

- **Dedicated Data Buffering System**
To maximize data reuse and reduce memory access overhead, the accelerator includes internal buffers for the **input tile (16 elements)**, **convolution filter (9 elements)**, and **output tile (4 elements)**. This buffering scheme ensures continuous data availability for the computational units without saturating the system bus.

## AI Tools Used
- **Primary LLM**:
  - **Claude.ai**: Utilized as the primary tool during the Front-end Design phase to research the Winograd $F(2,3)$ algorithm, convert block diagrams into RTL Verilog code, design the system hierarchy, and develop automated testbenches for the matrix transformation modules.
  - **Gemini Pro**: Utilized as the primary tool during the Physical Design (ASIC Flow) phase to support the OpenLane environment setup on Docker, configure flow execution parameters, analyze PPA metrics from CSV/JSON reports, and propose physical design optimization strategies.
- **Additional tools**:
  - Icarus Verilog & GTKWave: Utilized for functional simulation and signal waveform inspection, leveraging AI-assisted testbenches.
  - OpenLane 2 Stack: Comprises Yosys (Logic Synthesis), Magic VLSI (DRC), Netgen (LVS), and KLayout.
  - Verilator: Employed for linting and source code quality assurance prior to the synthesis stage.
- **Total AI interactions**: Approximately 100+ chat sessions (distilled into 11 primary Prompt Logs), accounting for roughly 30-40% of the total workload, primarily focusing on source code scaffolding and troubleshooting tool configuration.

## Results Summary

- **Functionality**: PASS. The design successfully passed all functional RTL simulations using Icarus Verilog and Verilator. It also achieved full physical sign-off with 0 DRC violations (via Magic VLSI) and 0 LVS errors (via Netgen).
- **Implementation**: SUCCESS. The accelerator was fully implemented through the OpenLane2 ASIC Flow targeting the SkyWater 130nm (Sky130 HD) technology node.
- **Resource Usage**:
  - Instance Count (post-synthesis): 63,311 cells | (post-route): 70,981 cells (including antenna cells)
  - Die Area: 577,152 µm² (~0.577 mm²) | Core Area: 564,481 µm² (~0.564 mm²)
  - Standard Cell Area: 508,056 µm² | Core Utilization: 90.0%
  - Power Consumption (TT corner): 30.95 mW total (Internal: 23.08 mW, Switching: 7.87 mW, Leakage: 0.40 µW)
- **Timing**:
  - Clock Period: 15 ns (~66.7 MHz)
  - TT Corner (nom_tt_025C_1v80): Setup WNS = **+2.448 ns**, TNS = 0.0 ns — **timing clean** 
  - SS Worst Case (nom_ss_100C_1v60): Setup WNS = **-2.478 ns**, TNS = -622.68 ns — optimization target for DP2
  - FF Best Case (nom_ff_n40C_1v95): Setup WNS = **+3.109 ns**, TNS = 0.0 ns 
- **Physical Sign-off**: DRC Errors = 0  | LVS Errors = 0 
- **Lint**: 0 errors, 0 inferred latches, 3 warnings

## Innovation Highlights
- **Zero-Multiplier Transformation Logic**: A standout innovation of this design is the complete elimination of hardware multipliers within the Winograd transformation blocks ($G, B^T,$ and $A^T$). By mathematically decomposing the $F(2\times2, 3\times3)$ algorithm, we implemented these stages using only hard-wired additions and bit-shifts, optimizing area efficiency for resource-constrained Edge AI applications.
- **Intelligent 9-State FSM Controller**: The processing core is governed by a 9-state FSM designed to automate complex nested loops in multi-channel convolutions. This FSM autonomously manages data loading, performs pipelined transformations, and handles multi-channel accumulation, minimizing software overhead on the TinyQV CPU.
- **Precision PPA Balancing on SkyWater 130nm**: Through iterative physical design tuning (adjusting `PL_TARGET_DENSITY` and `CLOCK_PERIOD` in OpenLane2), we achieved timing closure at TT corner with +2.448 ns setup slack. The SS corner timing failure (959 setup violations, fanout 1334 on critical nets) has been identified as the primary DP2 optimization target.

## Team Reflection
Upon the conclusion of Phase 1 (DP1), the team has successfully implemented and verified the Winograd accelerator:
- **Algorithm Implementation**: Translating the Winograd $F(2x2,3x3)$ algorithm from abstract mathematical formulas into concrete Verilog modules was the primary challenge. We learned to optimize hardware at the architectural level — replacing multipliers with bit-shifts to minimize area.
- **ASIC Flow Mastery**: Successfully implementing a design on the SkyWater 130nm process node via OpenLane2, achieving 0 DRC/LVS violations and timing closure at TT corner.
- **AI-Enhanced Collaboration**: Claude.ai and Gemini 2.5 Pro acted as powerful assistants for RTL design and physical implementation respectively. Human oversight and foundational engineering knowledge remained decisive for accuracy and reliability.