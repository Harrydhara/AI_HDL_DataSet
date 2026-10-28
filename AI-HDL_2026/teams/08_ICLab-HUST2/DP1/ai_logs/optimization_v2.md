# AI Interaction: Optimization Discussions

## Overview
This log focuses on the iterative process of balancing Power, Performance, and Area (PPA) and enhancing computational accuracy. We utilized Gemini 3.0 as a diagnostic assistant to interpret complex tool reports (such as metrics.csv and timing reports) and Claude.ai to refine the mathematical precision of the hardware modules.
    - Primary Goal: Achieve Timing Closure at 50 MHz while minimizing the silicon footprint on the SkyWater 130nm process.
    - Key Tools: Gemini 3.0 (Data Analysis), Claude.ai (Logic Refinement).

## Conversation 1: Syntax for Synthesis
LLM Tool: Claude.ai
Purpose:
How to run file.ys and get synthesis report
Prompt:

Please give me the syntax to run the .ys file for synthesis first.
Here is the path to the RTL:
C:\Users\user\Downloads\OL2_RTL\RTL
And here is the path to the .ys file:
C:\Users\user\Downloads\OL2_RTL\synth.ys

LLM output:
Check project Verilog files
Here is the step-by-step guide:
Step 1 — Check the contents of the synth.ys file first
In the WSL terminal, run:
cat /mnt/c/Users/user/Downloads/OL2_RTL/synth.ys
Step 2 — Run Yosys synthesis
cd /mnt/c/Users/user/Downloads/OL2_RTL
yosys synth.ys
If the .ys file does not exist yet, here is the standard template for this project.
Based on the Verilog project tt_um_tt_tinyQV, the synth.ys file should look like this:
 Read all RTL files
read_verilog -sv RTL/alu.v
read_verilog -sv RTL/core.v
read_verilog -sv RTL/counter.v
read_verilog -sv RTL/cpu.v
read_verilog -sv RTL/decode.v
read_verilog -sv RTL/element_wise.v
read_verilog -sv RTL/interface.v
read_verilog -sv RTL/latch_reg.v
read_verilog -sv RTL/matrix_filter.v
read_verilog -sv RTL/matrix_input.v
read_verilog -sv RTL/matrix_output.v
read_verilog -sv RTL/mem_ctrl.v
read_verilog -sv RTL/peripherals.v
read_verilog -sv RTL/project.v
read_verilog -sv RTL/qspi_ctrl.v
read_verilog -sv RTL/qspi_flash.v
read_verilog -sv RTL/register.v
read_verilog -sv RTL/time.v
read_verilog -sv RTL/tinyqv.v
read_verilog -sv RTL/tqvp_winograd.v
read_verilog -sv RTL/winograd.v

Synthesize with top module
synth -top tt_um_tt_tinyQV -flatten
Map to sky130 standard cells
dfflibmap -liberty /path/to/sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty /path/to/sky130_fd_sc_hd__tt_025C_1v80.lib
Export netlist
write_verilog -noattr synth_out.v
stat

## Conversation 2: Understand about systhesis file for config.json
LLM Tool: Claude.ai
Purpose:
Know synthesis results have relations with the config file and the .sdc file
Prompt:
Do the synthesis results have any use related to the config file and the .sdc file?

LLM output:

The synthesis results are very important! There is some information that should be used to adjust the configuration. Here is the analysis:

 Synthesis Results — Important Numbers
Parameter	Value
Total cells	70,981
DFF (Flip-flops)	~8,602 (total $_DFF_*)
MUX	28,924 — very large number
Top module	tt_um_tt_tinyQV ✅
⚠️ Configuration Adjustments Needed
1. The design is too large → PL_TARGET_DENSITY_PCT may need to be reduced

70k cells is very large for a TinyTapeout slot.
With the current density of 64.1, there is a high risk of GPL-0302 placement failure.

It is recommended to try:

"PL_TARGET_DENSITY_PCT": 55
2. Winograd occupies ~30k cells — timing may be tight

The modules winograd_conv_top and winograd_elementwise together occupy nearly 20k cells with many $_OAI4_ and $_AOI4_ gates → deep logic → the clock period may need to be increased.

"CLOCK_PERIOD": 20.0

(instead of 14.8 ns, which effectively reduces the clock frequency to about 50 MHz)

3. .sdc file — no modification needed from the netlist

The base.sdc file uses CLOCK_PERIOD from an environment variable, so it will automatically pick up the new value if you modify config.json.

✅ Recommended config.json Update
"PL_TARGET_DENSITY_PCT": 55,
"CLOCK_PERIOD": 20.0,
"PL_RESIZER_HOLD_SLACK_MARGIN": 0.2,
"GRT_RESIZER_HOLD_SLACK_MARGIN": 0.15


## Conversation 3: Summary synthesis results
LLM Tool: Claude.ai
Purpose:
Summary synthesis results
Prompt:
Summary of the synthesis results for my report

LLM output: 

Design hierarchy — you write the complete module tree in ASCII tree format
Top-level cell count — 70,981 cells, 8,602 DFF, 0 latch, 0 error
Per-module breakdown — a table of 13 modules with cell count + DFF count + notes
Synthesis quality — explanation of latch warnings (expected, not an error), and unused modules being removed
MUX trees — explanation of why 40.7% of the design consists of MUX, which is important for the Code Quality section of DP1
Observations for DP2 — a table of 4 issues with corresponding fixes, which can be used directly in the Trade-off Justification section.


## Conversation 4: Get ideas about optimization
LLM Tool: Claude.ai
Purpose:
Get ideas about optimization

Prompt:
Read DP2 docs carefully. To achieve the highest score, please give me ideas for optimization.

LLM output: 
After carefully reviewing DP2, to achieve the highest possible score, the following optimization strategy is proposed.
DP2 is graded based on four categories:
Performance: 25%
Power: 25%
Results & Reporting: 20%
Trade-off Justification: 15%
In total, 85% of the score can be maximized through RTL and configuration optimization.
Area is not included in the rubric, so there is no need to optimize area specifically.
Optimization priority based on impact vs. effort
Case 1 — Fix power (easiest, configuration change first)
Disable USE_LIGHTER = 0 and add manual RTL clock gating in winograd.v and interface.v.
Target:
Switching power < 7.87 mW (baseline).
Case 2 — Fix timing at the ss corner (requires RTL modification)
Pipeline matrix_filter.v and add a register to fp_mult in element_wise.v.
Target:
WNS at ss corner ≥ 0 and 0 timing violations.
Case 3 — Write the Optimization Report (20% + 15% = 35%)
This is the second largest scoring component, and it does not require additional runs.
Start with Case 1 immediately by modifying the configuration and adding RTL clock gating.
After reviewing all related source code, the files will be modified according to the scoring priorities.
Case order based on DP2 scoring
Case 1 — Power (25%)
Disable USE_LIGHTER and add manual clock gating in winograd.v for u_buffer and v_buffer.
Case 2 — Performance (25%)
Pipeline matrix_filter.v and add a registered fp_mult output in element_wise.v.
Case 3 — Configuration (supporting both optimizations)
Update config.json.
Case order based on optimization impact
Case 1 — Power (25%) — easiest, implement first
Add manual RTL clock gating in winograd.v for u_buffer and v_buffer.
Disable USE_LIGHTER = 0 in the configuration to prevent the tool from automatically generating a clock buffer tree, which is the cause of the +145% switching power increase.
Case 2 — Performance (25%) — RTL modification required
Pipeline matrix_filter.v by adding one state PIPELINE_WAIT between COMPUTE_GG and COMPUTE_GGGT, and register the output of fp_mult in element_wise.v.
Target:
Improve WNS (ss corner) from −1.73 ns to ≥ 0.
Case 3 — Results & Reporting (20%) + Trade-off Justification (15%)
Write this section after Run 3, when the complete before/after comparison table, regression test logs, and explanation of design trade-offs are available.
This section contributes 35% of the total score.


## Optimization Techniques
- **PPA Tuning & Timing Closure**
  - Initial synthesis runs resulted in congestion and negative slack, preventing the design from meeting the 50 MHz target.
  - AI Interaction: We uploaded the metrics.csv and timing analysis logs to Gemini 3.0.
  - Diagnostic Process:
    - The AI identified that a high PL_TARGET_DENSITY was causing "routing congestion," leading to long wire delays and timing violations (WNS < 0).
    - Gemini suggested a trade-off: decreasing the core utilization to allow more room for routing.
  - Manual Adjustment: Based on the AI's feedback, we manually tuned the OpenLane configuration:
    - Adjusted FP_CORE_UTIL to 40%.
    - Refined the Clock Tree Synthesis (CTS) parameters.
  - Result: Achieved Timing Clean status with a WNS of +0.270 ns and a final Core Area of 0.176 $mm^2$.
- **Fixed-Point Precision Optimization**
  - During multi-channel accumulation, the cumulative truncation error in the 32-bit fixed-point arithmetic began to impact the fidelity of the convolution results.
  - AI Interaction: We consulted Claude.ai regarding hardware-efficient ways to improve accuracy without switching to Floating-Point units (FPU).
  - Discussion: The AI proposed several schemes, including stochastic rounding and simple truncation.
  - Strategic Enhancement: We decided to implement a rounding-bit logic in the final stage of the element_wise and accumulator modules.
  - Implementation: This manual logic ensures that when bits are discarded during scaling, the result is rounded to the nearest value rather than always floored.
  - Result: Significant improvement in the accuracy of the Winograd output, making it suitable for deep learning inference tasks.
- **Power Profile Analysis**
  - Understanding where the 20.3 mW of power was being dissipated.
  - AI Interaction: Gemini analyzed the power reports generated by OpenLane.
  - Key Finding: The AI pointed out that Internal Power (14.23 mW) was the dominant factor, driven by the high switching activity of the input/filter buffer registers.
  - Action Taken: Stabilized the register-to-register paths and verified that the switching power remained within acceptable limits for an Edge AI peripheral.

## Summary of Optimization Collaboration
| Optimization Task | AI Diagnostic/Suggestion | Human Implementation | Impact |
|------|------|-------|----------------|
| Timing (WNS) | Identified critical paths in element_wise logic. | Refactored combinational logic and adjusted CLK_PERIOD. | Achieved +0.270 ns slack @ 50 MHz. |
| Area/Congestion | Suggested reducing PL_TARGET_DENSITY. | Manually tuned FP_CORE_UTIL to 40%. | Optimized Area to 0.176 $mm^2$ |
| Accuracy | Proposed fixed-point rounding schemes. | Integrated rounding-bit logic in the accumulator. | Reduced cumulative truncation errors.|
| Power | Classified power consumption by type (Internal/Switching). | Verified buffer register activity and stabilized paths. | Total power kept at 20.3 mW. |
