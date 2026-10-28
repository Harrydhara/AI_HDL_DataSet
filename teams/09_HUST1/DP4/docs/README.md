# AI-HDL 2026 - Design Phase 4: Netlist to Chip Tapeout

**Project:** DMA Controller IP Core (AMBA AXI4/APB) \& Tiny Tapeout Harness  

**Author:** HUST1 team - Hanoi University of Science and Technology (HUST)  

**Completion Date:** April 23, 2026  



## 1. Project Overview

This project marks the final stage (DP4) of a 16-week IC design journey. The primary objective is to transition the optimized RTL design of a DMA Controller IP Core from DP3 into a final physical layout (GDSII) for fabrication via the Tiny Tapeout platform using the Sky130 process node.



### Key Components:

- **DMA IP Core:** High-performance data transfer supporting AMBA AXI4 protocol and APB Slave for register configuration.

- **FIFO Latch:** Integrated storage for data integrity during protocol conversion.

- **Harness:** Standardized wrapper (`tt_um_tqv_peripheral_harness`) for Tiny Tapeout integration.



## 2. Physical Design Implementation Results

The physical design flow was executed using OpenLane on a WSL2/Ubuntu environment.



### Final PPA Metrics

Based on the final Sign-off reports, the design achieved the following metrics:



| Metric | Value | Notes |
| :--- | :--- | :--- |
| **Die Area** | 0.017955 mm² | Fixed per Tiny Tapeout tile specifications |
| **Core Utilization** | 32.37% | Ensures a congestion-clean routing phase |
| **Total Power** | 419 µW | Measured at target operating frequency |
| **WNS / TNS** | 0.00 / 0.00 | Achieved full Timing Closure |
| **Best Setup Slack** | 5.98 ns | Under standard operating conditions |
| **Best Hold Slack** | 0.25 ns | Maintained after buffer insertion optimizations |



### Floorplan Configuration

- **Sizing:** Configured with `FP_SIZING: absolute` to ensure compatibility with the Tiny Tapeout fixed template.

- **Pin Placement:** AXI Master and APB Slave pins were strategically placed on the South and West boundaries to minimize wire-length.

- **PDN:** Power Delivery Network designed using Metal 4 and Metal 5 with a 40µm pitch to minimize IR Drop.



## 3. Security Features

The DMA Controller incorporates hardware-level security mechanisms:

- **Boundary Checking:** Automatic transmission cut-off if memory access exceeds authorized address ranges.

- **Access Control:** Restricted configuration via the APB interface, ensuring only authorized Masters can modify DMA channels.

- **Data Integrity:** FIFO architecture includes basic error-checking to prevent overflow or data corruption during protocol handshakes.



## 4. Sign-off Verification

The design successfully passed all rigorous industry-standard verification steps:

- **DRC (Design Rule Check):** 0 violations (Physically manufacturable).

- **LVS (Layout Vs Schematic):** 0 errors (Physical layout matches Verilog RTL 100%).

- **STA (Static Timing Analysis):** Achieved Timing Closure across all operating corners.



[Image of Integrated circuit physical design flow with synthesis, floorplanning, placement, and routing]



## 5. Reflections & Conclusion

Over the past 16 weeks, the journey from basic Verilog syntax to generating a production-ready GDSII file for a complex DMA IP Core has been transformative. Key takeaways include:

- Proficiency in open-source EDA tools (OpenLane, Magic, KLayout) within a Linux environment.

- Understanding the critical trade-offs between Power, Performance, and Area (PPA) during the RTL-to-GDSII transition.

- Practical experience in debugging LVS mismatches and resolving Timing Slack issues.



This project serves as a cornerstone for my future specialization in IC Design and RISC-V Computer Architecture at Hanoi University of Science and Technology.






---
