# Tiny GPU AI-HDL Accelerator – DP1 Submission

## 1. Project Overview

This repository contains the **DP1 submission for the AI-HDL hardware design project**.
The goal of the project is to demonstrate an **AI-assisted hardware design workflow** where Large Language Models (LLMs) are used to generate hardware modules, testbenches, and assist in debugging during the RTL-to-GDS ASIC design process.

The design flow demonstrates the following pipeline:

```
Architecture → LLM Prompts → RTL Generation → Simulation → OpenLane ASIC Flow → GDS Layout
```

The final output of this process is a **fully synthesized and routed ASIC layout (GDS)** generated using the **SKY130 open-source PDK** and visualized using **KLayout**.

---

## 2. Tools and Technologies Used

| Tool               | Purpose                                      |
| ------------------ | -------------------------------------------- |
| OpenLane           | Automated RTL-to-GDS ASIC flow               |
| SKY130 PDK         | 130nm open-source semiconductor process      |
| KLayout            | Layout visualization and inspection          |
| GitHub             | Version control and project submission       |
| LLM (AI Assistant) | RTL generation, debugging, and documentation |

The design was implemented using the **SKY130 HD standard cell library**.

---

## 3. Project Architecture

The design implements a simplified **GPU-style accelerator module** generated through LLM prompts.

### Main Module

```
accel.v
```

This module represents the **top-level hardware block** synthesized through the ASIC flow.

### Design Characteristics

* Synthesizable Verilog RTL
* Compatible with SKY130 standard cell libraries
* Structured for OpenLane physical design flow

A block diagram of the design architecture is included in:

```
docs/block_diagram.png
```

---

## 4. AI-Driven Hardware Development Workflow

This project follows an **AI-first hardware design methodology**.

The workflow includes:

1. **Design-to-Prompt Translation**

   * High-level architecture was translated into structured LLM prompts.
   * Prompts instructed the LLM to generate synthesizable Verilog modules.

2. **Automated RTL Generation**

   * LLM produced Verilog hardware modules.
   * Generated modules were reviewed and integrated into the project.

3. **Testbench Generation**

   * LLM was used to create standalone simulation testbenches.

4. **Iterative Debugging**

   * Simulation or synthesis issues were fed back to the LLM.
   * Prompts were refined to correct RTL errors.

5. **ASIC Implementation**

   * The design was passed through the OpenLane RTL-to-GDS flow.

All prompts used during development are documented in:

```
docs/llm_prompt_logs.pdf
```

These logs provide **proof of the AI-assisted workflow required for DP1 submission**.

---

## 5. Simulation and Verification

A simulation testbench was generated to verify the behavior of the accelerator module.

Simulation files are located in:

```
sim/
```

Files:

```
sim/accel_tb.v
sim/simulation_results.txt
```

Simulation was used to confirm that the RTL module compiles and behaves as expected before synthesis.

---

## 6. ASIC Implementation Using OpenLane

The RTL design was synthesized and implemented using the **OpenLane automated ASIC flow**.

Stages executed:

1. RTL synthesis
2. Floorplanning
3. Standard cell placement
4. Clock tree synthesis
5. Routing
6. Physical verification
7. GDS generation

The generated layout files and reports are located in:

```
openlane/
```

Key outputs include:

```
openlane/accel.gds
openlane/reports/
```

The reports directory contains results from:

```
synthesis
floorplan
placement
routing
timing
```

These reports provide metrics such as:

* Cell count
* Area utilization
* Routing completion
* Timing slack

---

## 7. Layout Visualization

The final GDS layout was inspected using **KLayout**.

Screenshot of the layout is included in the repository:

```
docs/layout_full_chip.png


The image demonstrate:

* Full chip layout


The layout confirms successful **RTL-to-GDS ASIC generation**.

---

## 8. Repository Structure

```
tiny_gpu_aihdl/
│
├── README.md
│
├── rtl/
│   └── accel.v
│
├── sim/
│   ├── accel_tb.v
│   └── simulation_results.txt
│
├── openlane/
│   ├── accel.gds
│   └── reports/
│
├── docs/
│   ├── architecture.md
│   ├── block_diagram.png
│   ├── layout_full_chip.png
│   ├── layout_routing.png
│   ├── layout_standard_cells.png
│   ├── layout_power_grid.png
│   └── llm_prompt_logs.pdf
│
└── prompts/
    └── prompt_log.md
```

---

## 9. Key Results

| Metric              | Description                     |
| ------------------- | ------------------------------- |
| RTL Module          | AI-generated accelerator module |
| Standard Cells      | SKY130 HD library               |
| Implementation Flow | OpenLane                        |
| Final Output        | GDS layout                      |
| Visualization Tool  | KLayout                         |

The successful generation of the **GDS layout** confirms that the design passed through the complete ASIC physical design flow.

---

## 10. Conclusion

This project demonstrates an **AI-assisted hardware development methodology** where LLMs are used to accelerate hardware design, debugging, and documentation.


```
Concept → Prompt Engineering → RTL Generation → Simulation → ASIC Implementation
```

The final result is a **physically implementable ASIC layout generated using open-source tools and AI-driven development techniques**.

