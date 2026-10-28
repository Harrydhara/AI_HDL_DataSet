# Design Project 1 (DP1)

## Complete RTL-to-GDS ASIC Implementation

### Using OpenLane and SKY130 Process Design Kit

---

# Abstract

This project demonstrates the implementation of a complete digital ASIC design flow from Register Transfer Level (RTL) to final GDSII layout using the OpenLane open-source ASIC toolchain and the SKY130 Process Design Kit.

The objective is to design a synthesizable hardware module, implement the ASIC physical design flow, verify the layout, and generate a manufacturable chip design.

---

# 1. Introduction

Application-specific integrated circuits (ASICs) are chips designed to perform specialized computational tasks efficiently.

Traditional ASIC development requires expensive proprietary tools. However, modern open-source frameworks such as **OpenLane** allow students and researchers to design chips using freely available tools.

This project demonstrates a simplified ASIC implementation pipeline using:

* Verilog RTL design
* OpenLane automated flow
* SKY130 fabrication technology

The final output is a **GDSII layout file**, which represents the physical chip design.

---

# 2. Project Objectives

The objectives of this project include:

• Implementing a synthesizable hardware module using Verilog
• Running RTL synthesis using Yosys
• Performing floorplanning and placement
• Executing routing and clock tree synthesis
• Running verification checks (DRC and LVS)
• Generating a final GDS layout

---

# 3. Design Tools

The following tools were used:

| Tool      | Purpose                   |
| --------- | ------------------------- |
| OpenLane  | RTL-to-GDS automated flow |
| Yosys     | RTL synthesis             |
| OpenROAD  | Physical design engine    |
| Magic     | Layout verification       |
| KLayout   | Layout visualization      |
| Verilator | RTL simulation            |

These tools collectively enable the **complete ASIC design pipeline**.

---

# 4. Design Architecture

The implemented design is a simple hardware accelerator performing an arithmetic operation.

The module includes:

• synchronous clock operation
• reset initialization
• 8-bit input operands
• registered output

Example Verilog structure:

```verilog
module accel(
 input clk,
 input rst,
 input [7:0] a,
 input [7:0] b,
 output reg [7:0] y
);

always @(posedge clk or posedge rst)
begin
 if (rst)
   y <= 0;
 else
   y <= a + b;
end

endmodule
```

---

# 5. Project Directory Structure

The design repository was organized as follows:

```
AI-HDL/
│
├── designs/
│   └── accel/
│       ├── accel.v
│       └── config.json
│
├── scripts/
├── reports/
└── README.md
```

This structure simplifies debugging and version control.

---

# 6. OpenLane Configuration

OpenLane requires a configuration file that defines key design parameters.

Example configuration file:

```json
{
 "DESIGN_NAME": "accel",
 "VERILOG_FILES": "dir::accel.v",
 "CLOCK_PORT": "clk",
 "CLOCK_PERIOD": 10,
 "FP_CORE_UTIL": 40,
 "PL_TARGET_DENSITY": 0.5
}
```

These parameters define:

• clock frequency
• design source files
• floorplan utilization
• placement density

---

# 7. RTL-to-GDS Flow

The OpenLane automated flow performs the following stages:

1. RTL synthesis
2. Floorplanning
3. Power planning
4. Standard cell placement
5. Clock Tree Synthesis
6. Global routing
7. Detailed routing
8. Static timing analysis
9. GDS generation

Each stage converts the design from a logical description to a physical layout.

---

# 8. Running the Flow

The flow was executed using:

```
./flow.tcl -design accel
```

This command automatically runs the complete ASIC pipeline.

All intermediate results are stored in:

```
OpenLane/designs/accel/runs/
```

---

# 9. Design Verification

Two major verification checks are performed.

## Design Rule Check (DRC)

Ensures the layout obeys fabrication rules such as spacing and metal width.

## Layout vs Schematic (LVS)

Confirms that the layout corresponds to the synthesized circuit netlist.

Passing both checks confirms that the chip is manufacturable.

---

# 10. Layout Visualization

The final layout was inspected using **KLayout**.

Command used:

```
klayout accel.gds
```

The layout inspection verified:

• standard cell placement
• metal routing layers
• power grid distribution
• input/output pin placement

---

# 11. Results

The OpenLane flow successfully produced:

• synthesized netlist
• timing reports
• placement and routing reports
• parasitic extraction data
• final GDSII layout file

The design passed timing constraints and verification checks.

---

# 12. Future Improvements

Possible improvements include:

• larger accelerator designs
• pipelined architectures
• AI inference accelerators
• SRAM integration
• higher clock frequency optimization

---

# 13. Conclusion

This project successfully demonstrated a complete open-source ASIC design flow from RTL design to final chip layout using OpenLane and the SKY130 PDK.

The design successfully passed synthesis, placement, routing, and verification stages and produced a manufacturable GDS layout.

This workflow provides a powerful foundation for developing advanced digital hardware systems.

---

# Appendix

Recommended screenshots for the final submission:

1. RTL code
2. OpenLane synthesis log
3. Placement stage visualization
4. Routing stage visualization
5. Final layout in KLayout
6. Timing report
