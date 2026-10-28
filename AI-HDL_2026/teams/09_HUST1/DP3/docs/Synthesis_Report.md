# AI-HDL 2026: Design Phase 1 (DP1) Report
**Team Name:** HUST1
**Date:** January 31, 2026

---

## 1. Executive Summary
This document serves as the official submission for Design Phase 1. It details the implementation of an AHB-Lite based DMA Controller, the synthesis results using Open Source tools (Yosys/OpenLane), and the verification strategy.

The design successfully meets the functional requirements of moving data between memory locations without CPU intervention, utilizing a modular architecture comprising a Slave Interface, a FIFO buffer, and a Master FSM.

---

## 2. Design Implementation Choices

### 2.1. Architectural Decisions
To ensure scalability and ease of integration with the provided RISC-V core, we adopted the following design choices:

* **AHB-Lite Protocol:** Chosen for its simplicity and low latency compared to full AXI, making it suitable for a lightweight DMA controller.
* **Asynchronous-Ready FIFO:** Although the current implementation is synchronous, the FIFO module is designed with separate read/write pointers to allow for future upgrades to asynchronous clock domains if required.
* **FSM-Based Control:** The Master interface is driven by a Finite State Machine (FSM) to strictly manage bus arbitration and handle `HREADY` wait states correctly.

### 2.2. Block Diagram & Schematics
* **High-Level Architecture:** [Link to Block Diagram](./images/schematic/block_diagram.png)
* **Detailed Logic:** [Link to Logic Diagram](./images/schematic/logic_diagram.png)

---

## 3. Baseline Synthesis Report (PPA)

### 3.1. Toolchain Configuration
* **Synthesis Tool:** Yosys (via OpenLane flow)
* **Technology Node:** SkyWater 130nm (sky130)
* **Target Clock Frequency:** 100 MHz

### 3.2. Synthesis Results
The following metrics were captured after the synthesis run (flow completed successfully):

| Metric | Value | Unit | Status |
| :--- | :--- | :--- | :--- |
| **Total Cell Count** | **426** | cells | Logic usage |
| **Chip Area (Die)** | **0.017955** | mm² | Physical footprint |
| **Utilization** | **32.37** | % | Core utilization |
| **Worst Negative Slack (WNS)** | 0.00 | ns | MET (Timing satisfied) |
| **Total Negative Slack (TNS)** | 0.00 | ns | MET |
| **Max Frequency** | 100 | MHz | Target Achieved |

### 3.3. Synthesis Log Evidence
Below is the screenshot of the final synthesis summary report:

![Synthesis Terminal Output](./images/synthesis.png)

---

## 4. Verification & Testing Strategy
All modules have been verified using SystemVerilog testbenches.

* **Unit Testing:** The FIFO and FSM modules were tested in isolation to verify corner cases (Full/Empty flags, bus wait states).
* **Integration Testing:** The `tb_dma_top.v` successfully simulates a full memory-to-memory transfer sequence initiated by the CPU.

---

## 5. Conclusion & Next Steps
The DP1 baseline design is complete and synthesizable.
* **Current Status:** RTL is frozen; baseline PPA established.
* **Phase 2 Plan:** We aim to optimize the FSM logic to reduce area usage by approximately 10% and explore adding a Scatter-Gather mode.