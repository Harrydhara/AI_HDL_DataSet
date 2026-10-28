# **1. Introduction**



This project implements a digital hardware design named accel using the open-source RTL-to-GDSII flow provided by OpenLane and the SkyWater SKY130 process design kit. The objective is to convert a Verilog RTL design into a manufacturable chip layout through stages such as synthesis, floorplanning, placement, clock tree synthesis, routing, and sign-off verification.



# **2. Design Flow Methodology**



The following stages were executed using OpenLane:



I. RTL Synthesis



The Verilog RTL design is synthesized into a gate-level netlist using Yosys. Input directory: /openlane/designs/accel/src/

Output reports location: /openlane/designs/accel/runs/RUN\_2026.03.07\_22.56.01/reports/synthesis/



II. Floorplanning



Defines the chip layout boundaries, IO placement, and power grid.



Database file used for visualization: /openlane/designs/accel/runs/RUN\_2026.03.07\_22.56.01/results/floorplan/accel.odb



III. Placement



Standard cells are placed within the defined core area.



Placement database file: /openlane/designs/accel/runs/RUN\_2026.03.07\_22.56.01/results/placement/accel.odb





IV. Clock tree synthesis



The clock distribution network is constructed to minimize clock skew.



CTS database file: /openlane/designs/accel/runs/RUN\_2026.03.07\_22.56.01/results/cts/accel.odb



V. Routing



Signal wires are routed between cells while satisfying design rules.



Routing database file: /openlane/designs/accel/runs/RUN\_2026.03.07\_22.56.01/results/routing/accel.odb





VI. Sign-off Verification





Final checks are performed to verify manufacturability and correctness:



Static Timing Analysis



Power analysis



Design Rule Check (DRC)



Layout Versus Schematic (LVS)



Reports directory: /openlane/designs/accel/runs/RUN\_2026.03.07\_22.56.01/reports/signoff/





### **Simple block diagram:**

&nbsp;         +----------------------+

&nbsp;         |      Input Ports     |

&nbsp;         | clk, rst, data\_in    |

&nbsp;         +----------+-----------+

&nbsp;                    |

&nbsp;                    v

&nbsp;         +----------------------+

&nbsp;         |  Combinational Logic |

&nbsp;         |   (AND gates)        |

&nbsp;         +----------+-----------+

&nbsp;                    |

&nbsp;                    v

&nbsp;         +----------------------+

&nbsp;         |  MUX Selection Unit  |

&nbsp;         |   (Data Routing)     |

&nbsp;         +----------+-----------+

&nbsp;                    |

&nbsp;                    v

&nbsp;         +----------------------+

&nbsp;         |    Register Bank     |

&nbsp;         |   (D Flip-Flops)     |

&nbsp;         +----------+-----------+

&nbsp;                    |

&nbsp;                    v

&nbsp;         +----------------------+

&nbsp;         |      Output Unit     |

&nbsp;         |      data\_out        |

&nbsp;         +----------------------+





Accelerator Block Architecture



The accel module implements a small synchronous digital accelerator consisting of combinational logic and sequential storage elements. The architecture is divided into the following functional blocks:



1\. Input Interface



Receives input data and control signals including:



Clock (clk)



Reset (rst)



Input data signals



Control or select signals



These inputs are buffered and distributed to the internal logic blocks.



2\. Combinational Logic Unit



The combinational logic unit performs the core computation of the accelerator using:



AND gates



Multiplexers



The AND gates implement logical operations between input signals, while multiplexers select between intermediate computation paths.



3\. Multiplexer Selection Network



The multiplexer network controls data routing inside the accelerator.

It selects which intermediate values are forwarded to the register bank based on control inputs.



This structure enables flexible data flow and conditional computation within the accelerator.



4\. Register Bank (Sequential Logic)



The register bank consists of D flip-flops (dfxtp) that store intermediate results and synchronize data with the system clock.



Functions of this block:



Pipeline intermediate values



Maintain state across clock cycles



Synchronize computation stages



5\. Output Logic



The output block forwards the final registered results to the module output ports.



Buffers are inserted automatically by the synthesis tool to maintain signal integrity and drive strength.





| \*\*Metric\*\*                 | \*\*Result\*\*                   | \*\*Explanation\*\*                                   |

| -------------------------- | ---------------------------- | ------------------------------------------------- |

| Design Name                | accel                        | Name of the implemented module                    |

| Technology Node            | SKY130 (130 nm)              | Open-source PDK used for implementation           |

| Standard Cell Library      | sky130\_fd\_sc\_hd              | High-density standard cell library                |

| Total Cells                | 134                          | Total number of standard cells used in the design |

| Number of Wires            | 108                          | Net connections in the design                     |

| Wire Bits                  | 201                          | Total signal wire bits after synthesis            |

| Sequential Cells           | 32 (DFXT Flip-Flops)         | Storage elements used for clocked logic           |

| Combinational Cells        | 70 (AND + MUX)               | Logic gates used for computation                  |

| Buffers                    | 38                           | Used for signal strength and clock distribution   |

| Chip Area                  | \*\*1463.904 µm²\*\*             | Physical silicon area occupied by the design      |

| Total Negative Slack (TNS) | \*\*0.00 ns\*\*                  | No timing violations in the design                |

| Worst Negative Slack (WNS) | \*\*0.00 ns\*\*                  | Timing requirements fully satisfied               |

| Worst Setup Slack          | \*\*6.12 ns\*\*                  | Positive slack indicates safe timing margin       |

| Worst Hold Slack           | \*\*0.47 ns\*\*                  | Hold timing also satisfied                        |

| Total Power                | \*\*1.81 × 10⁻⁴ W (0.181 mW)\*\* | Overall power consumption                         |

| Sequential Power           | 1.57 × 10⁻⁴ W                | Majority of power consumed by flip-flops          |

| Combinational Power        | 2.38 × 10⁻⁵ W                | Power consumed by logic gates                     |

| Leakage Power              | 6.01 × 10⁻¹⁰ W               | Static leakage current                            |

| DRC Violations             | \*\*0\*\*                        | Layout satisfies all design rules                 |

| LVS Status                 | \*\*Passed\*\*                   | Layout matches schematic/netlist                  |





Final layout generation: /openlane/designs/accel/runs/RUN\_2026.03.07\_22.56.01/results/final/gds/accel.gds



# 

# **Conclusion**



The accel design was successfully implemented using the OpenLane RTL-to-GDSII flow. The design passed all sign-off verification checks including timing, power, DRC, and LVS. With zero timing violations and zero design rule violations, the generated layout is considered physically valid and suitable for fabrication in the SKY130 technology.

