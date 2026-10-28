# AI Conversation Log - Design Generation Phase

## Overview
This log documents the foundational design phase of the Winograd $F(2,3)$ accelerator, covering the transition from mathematical algorithms to RTL implementation and SoC integration with the TinyQV core.

## Conversation 1: Analysis accelerator
Date: Jan 19, 2026
LLM Tool: Claude.ai
Purpose:
Understand and compare some AI-accelerator modules.
Prompt:
Please read the entire file and identify the AI accelerator modules that have been implemented. Additionally, highlight their key features and notable characteristics.
LLM Output:
The book describes 10 major AI Accelerator modules, summarized as follows:
1.	Module 1 – AI Accelerator Fundamentals
Introduction and overview of AI accelerators, including processor classification (CPU, GPU, FPGA, ASIC, TPU).
2.	Module 2 – Standalone Computing Systems
CPUs and GPUs for personal computers, supporting both AI training and inference.
3.	Module 3 – Cloud and Server Accelerators
Google TPU (v2, v3, Edge TPU) and AWS Inferentia for cloud-scale AI applications.
4.	Module 4 & 5 – Smartphone AI Accelerators
Mobile NPUs (Samsung Exynos, Qualcomm Hexagon) enabling on-device AI processing.
5.	Module 6 – Embedded AI Systems
NVIDIA Jetson, Edge TPU, Graphcore IPU, and other embedded AI platforms.
6.	Module 7 – Reconfigurable Accelerators
FPGA and ASIC-based accelerators, comparing programmable logic and fixed-function designs.
7.	Module 8 – Neuromorphic Hardware
Brain-inspired computing architectures such as IBM TrueNorth, SpiNNaker, and SyNAPSE.
8.	Module 9 – Autonomous Vehicle Accelerators
AI hardware for self-driving cars, including NVIDIA Jetson and Tesla FSD Computer.
9.	Module 10 – Energy-Efficient AI Design
Techniques such as pruning, quantization, model compression, and Processing-In-Memory (PIM).
How the output was used:
Based on the summary, the ideas related to convolution acceleration were identified as relevant and promising. These concepts were noted as potential directions to explore further in the design.
Human Modification:
Relevant technical literature and reference materials were independently searched and studied to further understand and evaluate the identified concepts

## Conversation 2: Winograd F(2×2,3×3) convolution algorithm

Purpose:
Gain a deeper understanding of the mathematical operations and hardware implications of the Winograd convolution algorithm.
Prompt:
Explain the Winograd F(2×2,3×3) convolution algorithm and discuss why it is suitable for hardware acceleration.
LLM Output:
The Winograd F(2×2, 3×3) algorithm is an elegant approach to reducing the computational cost of convolution using a mathematical insight: that convolution can be rewritten as a sequence of transforms and pointwise multiplications, where most of the heavy arithmetic is converted into matrix multiplications.
Here's how it works conceptually. Instead of sliding a 3×3 filter across an image one position at a time (requiring 9 multiplications per output), the algorithm breaks the input into overlapping 4×4 tiles and computes 2×2 output patches from each. The core identity is:
Y = Aᵀ [(GgGᵀ) ⊙ (Bᵀ d B)] A
where G, Bᵀ, and Aᵀ are fixed transform matrices, g is the 3×3 filter, d is the 4×4 input tile, and ⊙ is elementwise multiplication
The key insight is that the transform matrices G, Bᵀ, and Aᵀ contain only additions and multiplications by simple constants (½, ¼, etc.). All 16 actual multiplications happen in the elementwise M = U ⊙ V stage — and these are the only full floating-point multiplications in the entire computation. Direct convolution needs 36 for the same 4 output values. The paper reports a 2.25× arithmetic complexity reduction (36/16).
There's a further efficiency trick: because the filter transform U = GgGᵀ doesn't depend on the input image, it can be precomputed once and reused across the entire minibatch. This amortizes its cost down to near zero in practice.
Now, the reason this algorithm is particularly well-suited to hardware acceleration comes down to three structural properties:
1. The multiply stage is a pure matrix multiplication. After collapsing the image/tile dimensions into a single index, the pointwise products over all channels reduce to M⁽ξ,ν⁾ = U⁽ξ,ν⁾V⁽ξ,ν⁾ — standard GEMM. Hardware has decades of optimized matrix multiply units (tensor cores on NVIDIA GPUs, systolic arrays on TPUs). Essentially the algorithm converts a convolution problem into the problem GPUs are most efficient at.
2. Small tiles mean small workspace memory. Unlike FFT-based convolution, which may require 64×64 tiles and gigabytes of workspace (the paper notes cuDNN used up to 2.6 GB), F(2×2, 3×3) works on 4×4 tiles. The paper's GPU implementation fits the entire workspace — transforms, products, and inverses — in registers and shared memory within a single block. This avoids expensive DRAM round-trips.
3. Efficient at small batch sizes. Conventional FFT convolution needs large batches to generate matrices big enough for efficient GEMM. The Winograd approach builds large matrices by aggregating tiles across the image and channels, so even a single image produces many tiles. The benchmark shows 7× speedup over cuDNN at batch size N=1, shrinking to 1.48× at N=64 — demonstrating it fills the hardware efficiently regardless of batch size.
The tradeoff is numerical precision: the transform matrices for larger tile variants like F(4×4, 3×3) have growing element magnitudes, which amplifies rounding errors. F(2×2, 3×3) avoids this — the paper finds it is actually more accurate than direct convolution in fp32 because its reduction is over fewer elements (C channels rather than R×S×C filter elements).

How the output was used:
The explanation was used to understand the computational flow of the algorithm and to guide the design of the accelerator pipeline, including the transform stages and dataflow organization.

Human Modification:
Based on the conceptual understanding provided by the LLM, the block diagram of the Winograd accelerator and the overall pipeline structure were independently designed and drawn by the author.


## Conversation 3: Generating verilog code from algorithm
Date: Jan 22, 2026
LLM Tool: Claude.ai
Purpose:
Based on the Winograd F(2×2,3×3) algorithm generate Verilog code
Prompt:
Based on the Winograd F(2×2,3×3) algorithm and document about it, generate Verilog code with 4 module (input, filter, element wise, output)
LLM Output (Summary):
The LLM generated a Verilog code skeleton representing the major functional blocks of the Winograd accelerator, including transform stages, element-wise computation, and control interfaces
How the output was used:
The generated Verilog structure was used as an initial reference to accelerate development. It helped define module boundaries, signal interfaces, and the overall pipeline flow derived from the block diagram.
Human Modification:
The generated code was extensively modified, refined, and verified.


## Conversation 4: Generating Testbenches for Winograd Modules
Date: Jan 24, 2026
LLM Tool: Claude.ai
Purpose:
To generate verification testbenches for the main hardware modules of a Winograd F(2×2, 3×3) convolution accelerator and support early functional validation during RTL development.
Prompt:
Generate synthesizable and self-checking testbenches for all major modules of a Winograd F(2×2,3×3) convolution accelerator.
LLM Output (Summary):
The LLM generated: A top-level testbench for the Winograd convolution core
How the output was used:
By running testbench in simulation, functional mismatches and interface issues were identified, which helped reveal inconsistencies between the intended algorithmic behavior and the initial RTL implementation..
Human Modification:
After observing simulation errors and unexpected results, analyzing both the RTL design and the generated testbench.

## Conversation 5: Understanding the architecture and processing flow of OpenLane

Date: Jan 5, 2026
Tool: Gemini 3.0
Primary Purpose: To understand the overview of the automated RTL-to-GDSII design process and the roles of the component tools.
Prompt: Explain the operation process of OpenLane (Flow overview). Which tools are integrated inside (Yosys, OpenROAD, Magic...) and what roles do they play in each step?
LLM Output: 
OpenLane is an automated RTL-to-GDSII flow — it takes your Verilog code as input and produces a GDSII file ready to send to a chip foundry. It is built on top of several open-source EDA tools, primarily OpenROAD, Yosys, Magic, Netgen, KLayout, and custom scripts, all orchestrated through a single configurable pipeline.

Architecture overview
OpenLane is not a single tool but a flow controller that sequences multiple EDA tools. The two major phases are:
Front-end (logic): converts HDL into a technology-mapped gate-level netlist. This is handled mostly by Yosys.
Back-end (physical): converts the netlist into a placed-and-routed layout. This is handled mostly by OpenROAD, which internally runs several sub-tools for floorplanning, placement, CTS, and routing.

Processing flow: RTL to GDSII
Stage 1 — RTL Synthesis (Yosys + OpenSTA)
Yosys reads the Verilog and synthesizes it into a gate-level netlist using cells from the PDK's standard cell library. OpenSTA then runs Static Timing Analysis on the result to check setup and hold violations. Optionally, Synthesis Exploration can sweep different strategies to find the best area/timing tradeoff.
Stage 2 — Floorplanning (OpenROAD)
Sets the die area, places I/O pins around the boundary, and builds the Power Delivery Network (PDN). The PDN consists of a power ring encircling the core and local power stripes connecting to each standard cell row. Pre-placed macros (like SRAM blocks) are also fixed at this stage.
Stage 3 — Placement (OpenROAD)
Places all standard cells inside the floorplan. This runs in two passes: global placement finds approximate positions to minimize wirelength, then detailed placement legalizes positions so no cells overlap and all cells snap to the placement grid.
Stage 4 — Clock Tree Synthesis / CTS (TritonCTS via OpenROAD)
Builds the clock distribution tree to deliver the clock signal to every sequential element (flip-flop) with minimal skew. TritonCTS inserts clock buffers and inverters along the tree. Because CTS modifies the netlist, OpenLane runs a Logic Equivalence Check (LEC) using Yosys afterward to confirm the new netlist is still functionally identical to the original.
Stage 5 — Routing (FastRoute + TritonRoute via OpenROAD)
FastRoute performs global routing, assigning nets to routing regions. TritonRoute then performs detailed routing, placing actual metal wires on the routing grid. During this stage, OpenLane also handles the antenna effect — long metal wires that act as antennas and accumulate charge during fabrication can damage transistor gates. OpenLane inserts antenna diode cells next to affected input pins to safely drain the charge.
Stage 6 — Physical Verification / Signoff
Several checks run on the finished layout before it is accepted for fabrication:

DRC (Design Rule Check) via Magic and KLayout — verifies the layout obeys all foundry geometry rules (minimum spacing, width, enclosure, etc.)
LVS (Layout vs. Schematic) via Netgen — compares the extracted netlist from the layout against the gate-level netlist to confirm they match
STA via OpenSTA — reruns timing analysis using parasitics extracted from the actual routed wires (SPEF file), which are more accurate than the estimated values used earlier
Antenna check via OpenROAD — final verification that no antenna violations remain

If all checks pass, the output is a GDSII file that can be submitted to a foundry for fabrication.

Key design choices
OpenLane uses a "configuration file" approach — a single config.json (or config.tcl) controls every tool's parameters. This makes the entire flow reproducible and scriptable. It also supports interactive mode, where you can pause after any step, inspect intermediate results, and resume.
For your Winograd accelerator project, OpenLane with the SkyWater SKY130 PDK gives you a complete open-source path from Verilog all the way to a tapeout-ready GDSII file.
	
Usage: Used to write the "Theoretical Basis" section and draw the process block diagram in the report.
	
Modification: Self-researched additional documentation about the SkyWater 130nm PDK.

  
## Summary of AI-Human Collaboration
| Design Aspect | AI Contribution | Human Modification/Refinement | 
|---------------|-----------------|-------------------------------|
| Winograd F(2×2,3×3) algorithm explanation| Explained the full mathematical formulation (Y = Aᵀ[(GgGᵀ) ⊙ (BᵀdB)]A) | Selected this algorithm specifically for the Winograd accelerator project; directed the level of detail needed for hardware context |
| Verilog code generation | Generated 4 Verilog modules: input data transform, filter transform, elementwise multiply, and output inverse transform, based on the algorithm's matrix pipeline | Reviewed module interfaces and signal naming; verified functional correctness; adjusted pipeline structure to match the target accelerator block diagram |
| OpenLane flow explanation | Described all 6 stages of the RTL-to-GDSII flow  | Determined the scope of explanation needed (architecture + processing flow); adapted the output for use as a prompt log entry in the project report

