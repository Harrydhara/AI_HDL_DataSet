# Mercer Team - Challenge [1]

## Team Information

- **Team Name**: Mercer Team
- **Institution**: Mercer County Community College
- **Division**: Lower
- **Team Members**:
  - Member A - Design Lead - [email]
  - Member B - [Role] - [email]
  - Member C - Verification - [email]
- **Mentor**: [mentor] - [email]

## Challenge Summary

For this challenge we extended the TinyQV based RISC-V SoC adding Matrix-Vector Engine(MVU) that uses the Multiply-Accumulate (MACC) and a Vector Processing Unit (VPU), also 2x2 Systolic Array using Compute and Activation Processing Element(PE). Modules were implemented as memory-mapped peripherals in "tqvp_example".

## Key Features

### 32-bit Multiply-Accumulate Engine (MACC)

![MACC Diagram](https://github.com/[user]/MercerTeamAIHDL/blob/main/DP_1/img/MACCdigram.png)

- Arithmetic accelerator that performs DSP operations
- Takes 32-bit operands (A and B), multiplies them then product into 32-bit accumulator register
- acc←acc+(𝑎⋅𝑏)
- 0x30 - MACC_A (operand A)
- 0x34 - MACC_B (operand B)
- 0x34 - MACC_ACC (accumulated results)
- 0x36 - MACC_CTRL
  - bit 0: start
  - bit 1: clear
  - bit 8: done

![MACC Logic](https://github.com/[user]/MercerTeamAIHDL/blob/main/DP_1/img/MACCSynthLogic.png)

### 4-Element Vecor Dot-Product Unit (VPU)

![VPU Diagram](https://github.com/[user]/MercerTeamAIHDL/blob/main/DP_1/img/VPUdiagram.png)

- Computes 4-element dot product
- Takes 8 32-bit inputs (A0-A3 and B0-B3), multiplies each pair and sums all 4 products into 32-bit result
- result = 3 ∑ 𝑖=0 𝐴𝑖⋅𝐵𝑖
- 0x24 -> VPU_A0
- 0x24 -> VPU_A1
- 0x2C -> VPU_A2
- 0x30 -> VPU_A3
- 0x34 -> VPU_B0
- 0x38 -> VPU_B1
- 0x3C -> VPU_B2
- 0x40 -> VPU_B3
- 0x44 -> VPU_RESULT
- 0x48 -> VPU_CTRL
  - bit 0: start
  - bit 1: clear

![VPU Logic](https://github.com/[user]/MercerTeamAIHDL/blob/main/DP_1/img/VPUSynthLogic.png)

### Matrix-Vector Unit(MVU)

![MVU Diagram](https://github.com/[user]/MercerTeamAIHDL/blob/main/DP_1/img/MVUdiagram.png)

- 4x4 Matrix-Vector Multiplication Accelerator takes a 4-element input vector and multiplies it with a 4x4 weight matrix to produce a 4-element output vector. Uses 4 VPU blocks each with 4 MACC units for neural layers.
- y = W(4x4 Matrix)\*x(4-Vector)
- 0x30 -> x0
- 0x31 -> x1
- 0x32 -> x2
- 0x33 -> x3
- 0x34-0x43 -> Weight matrix W
- 0x44 -> MVU_CTRL
  - bit 0: start
- 0x45 -> MVU_DONE
- 0x46 -> y0
- 0x49 -> y1
- 0x47 -> y2
- ox48 -> y3

### Systolic Array

![Systolic Array Diagram](https://github.com/[user]/MercerTeamAIHDL/blob/main/DP_1/img/SYSdiagram.png)

- Matrix compute engine built from two Processing Element MACC blocks. Compute PE's Perform 2x2 matrix multiplication-accumulate. Activaation PR's apply ReLU to final output. Using systolic dataflow activations are horizontal, weights are vertical, and partial sums accumulate thorughout the grid
- C = A(2x2) \* B(2x2)
- Matrix A inputs:
  - 0x50 -> A00
  - 0x51 -> A10
  - 0x52 -> A01
  - 0x53 -> A11

- Matrix B inputs
  - 0x54 -> B00
  - 0x55 -> B10
  - 0x56 -> B01
  - 0x57 -> B11

- 0x58 -> SYSTOLIC_CTRL
  - bit 0: start
- 0x59 -> SYSTOLIC_DONE
- 0x5A-0x5D -> Outputs C00-C11

- Output
  - 0x5A -> C00(raw MAC output)
  - 0x5b -> C01(activation PE Output)
  - ox5c -> C10(raw MAC output)
  - 0x5D -> C11(activation PE output)

## AI Tools Used

- Primary LLM: ChatGPT-5-nano
- Additional tools: ChatGPT-4
- Total AI interactions (appx): 9

## Results Summary

- **Functionality**:
  - MACC Accelerator performs 32-bit multiply accumulate operations
  - VPU executes vector arithmatic on 4x32-bit inputs,
  - Systolic Array 2x2 Matrix Multiply Engine, using Compute and activation processing elements
  - MVU 4x4 matric vector multiply using array of MACC and VPU
  - Accessible through register mapped interface allowing CPU to start operations
- **Timing**: Max frequency achieved: 71.43MHz

## Innovation Highlights

Integrated two custom acceleerator modules (MACC + VPU) through MMIO.

## Team Reflection
