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
- **High-Efficiency Winograd $F(2 \times 2, 3 \times 3)$ Engine**: Mathematically optimized to reduce the number of multiplications from 36 down to 16 per $4 \times 4$ tile, significantly increasing computational throughput for 3×3 convolutional layers. Matrix transformations ($G, B^T, A^T$) are implemented using additions and bit-shifts instead of complex multipliers to optimize area efficiency.
- **Seamless Memory-Mapped SoC Integration**: The accelerator utilizes the base address `0x9000_0000`, enabling the TinyQV core to access and orchestrate operations through standard Load/Store instructions. The system employs a handshake mechanism via the `data_ready` signal to ensure precise data synchronization between the CPU bus and the peripheral.
- **Interrupt-Driven Coprocessor Architecture**: The accelerator operates as an independent coprocessor, freeing up CPU resources by utilizing the `winograd_irq` interrupt signal to notify the system upon the completion of computations.
- **Hardware-Accelerated Multi-channel Accumulation**: Integrates dedicated hardware logic to automatically accumulate results across multiple data channels based on the `num_ch` configuration value. This process is orchestrated by a centralized 9-state Finite State Machine (FSM) that seamlessly manages the sequence of data loading, transformation, and element-wise multiplication.
- **Robust Data Buffering System**: Employs a dedicated internal buffering system for the Filter (9 elements), Input (16 elements), and Output (4 elements) to ensure high data availability for the computational blocks without congesting the system bus.

## AI Tools Used
- **Primary LLM**:
  - **Claude.ai**: Utilized as the primary tool during the Front-end Design phase to research the Winograd $F(2,3)$ algorithm, convert block diagrams into RTL Verilog code, design the system hierarchy, and develop automated testbenches for the matrix transformation modules.
  - **Gemini 3.0**: Utilized as the primary tool during the Physical Design (ASIC Flow) phase to support the OpenLane environment setup on Docker, configure flow execution parameters, analyze PPA metrics from CSV/JSON reports, and propose physical design optimization strategies.
- **Additional tools**:
  - Icarus Verilog & GTKWave: Utilized for functional simulation and signal waveform inspection, leveraging AI-assisted testbenches.
  - OpenLane 2 Stack: Comprises Yosys (Logic Synthesis), Magic VLSI (DRC), Netgen (LVS), and KLayout.
  - Verilator: Employed for linting and source code quality assurance prior to the synthesis stage.
- **Total AI interactions**: Approximately 100+ chat sessions (distilled into 11 primary Prompt Logs), accounting for roughly 30-40% of the total workload, primarily focusing on source code scaffolding and troubleshooting tool configuration.

## Results Summary

- **Functionality**: PASS. The design successfully passed all functional RTL simulations using Icarus Verilog and Verilator. It also achieved full physical sign-off with 0 DRC violations (via Magic VLSI) and 0 LVS errors (via Netgen).
- **Implementation**: SUCCESS. The accelerator was fully implemented through the OpenLane2 ASIC Flow targeting the SkyWater 130nm (Sky130 HD) technology node.
- **Resource Usage**:
  - Instance Count: 90,130 standard cells
  - Instance Area: 604,184 µm² (~0.604 mm²)
  - Power Consumption: 54.91 mW total (Internal: 37.89 mW, Switching: 17.02 mW, Leakage: 0.66 µW)
- **Timing**:
  - Clock Period: 15 ns (~66.7 MHz)
  - TT Corner (nom_tt_025C_1v80): Setup WNS = **+3.271 ns**, TNS = 0.0 ns — **timing clean** ✅
  - SS Worst Case (nom_ss_100C_1v60): Setup WNS = -7.038 ns — optimization target for DP2
- **Physical Sign-off**: DRC Errors = 0 ✅ | LVS Errors = 0 ✅

## Innovation Highlights
- **Zero-Multiplier Transformation Logic**: A standout innovation of this design is the complete elimination of hardware multipliers within the Winograd transformation blocks ($G, B^T,$ and $A^T$). By mathematically decomposing the $F(2,3)$ algorithm, we implemented these stages using only hard-wired additions and bit-shifts, optimizing area efficiency for resource-constrained Edge AI applications.
- **Intelligent 9-State FSM Controller**: The processing core is governed by a 9-state FSM designed to automate complex nested loops in multi-channel convolutions. This FSM autonomously manages data loading, performs pipelined transformations, and handles multi-channel accumulation, minimizing software overhead on the TinyQV CPU.
- **Precision PPA Balancing on SkyWater 130nm**: Through iterative physical design tuning (adjusting `PL_TARGET_DENSITY` and `CLOCK_PERIOD` in OpenLane2), we achieved timing closure at TT corner with +3.271 ns setup slack. The SS corner timing failure (fanout 3832 on `rst_n`) has been identified as the primary DP2 optimization target.

## Team Reflection
Upon the conclusion of Phase 1 (DP1), the team has successfully implemented and verified the Winograd accelerator:
- **Algorithm Implementation**: Translating the Winograd $F(2,3)$ algorithm from abstract mathematical formulas into concrete Verilog modules was the primary challenge. We learned to optimize hardware at the architectural level — replacing multipliers with bit-shifts to minimize area.
- **ASIC Flow Mastery**: Successfully implementing a design on the SkyWater 130nm process node via OpenLane2, achieving 0 DRC/LVS violations and timing closure at TT corner.
- **AI-Enhanced Collaboration**: Claude.ai and Gemini 3.0 acted as powerful assistants for RTL design and physical implementation respectively. Human oversight and foundational engineering knowledge remained decisive for accuracy and reliability.
- **Foundation for DP2**: Key bottlenecks identified — SS corner timing failure (rst_n fanout 3832) and large fanout violations (3,328 nets) — serve as the optimization roadmap for Phase 2.
