# Acona-Tech AI-HDL 2026 Project Plan 

## Team Information
- **Team Name**: Acona-Tech
- **Institution**: Ankara Yildirim Beyazit University
- **Division**: Lower

## Challenge Approach
We are participating in AI-HDL 2026 to learn hardware design with AI assistance and develop practical skills in SystemVerilog and FPGA implementation.
DP1 :To integrate a custom functional module (accelerator, peripheral, or instruction
extension) into the provided base RISC-V core using an "AI-first" design methodology.

## DP1 Status (Current)
- ✅ Repository infrastructure established
- ✅ Toolchain verified (iverilog,gtkwave,yosys)
- ✅ Baseline synthesis pipeline working
- ✅ Git workflow with professional commit history
- ✅ Evidence tracking system implemented

## Technical Stack
- **HDL**: SystemVerilog
- **Simulation**: Icarus Verilog (iverilog)
- **Synthesis**: Yosys
- **Version Control**: Git/GitHub
- **Development Environment**: WSL Ubuntu

## Planned AI Strategy
- **Primary Tool**: Claude Opus 4.5 (Anthropic)
- **Approach**: Iterative design with AI assistance
- **Logging**: All conversations tracked in prompt_logs/
- **Learning Focus**: Understanding fundamentals, not just code generation

## Selection of AES-128 as Functional Module

For our custom functional module, we have selected the AES-128 (Advanced Encryption Standard) algorithm. This choice aligns with our "AI-first" methodology and learning objectives for the following reasons:
1. Architectural Suitability & Parallelism

AES-128 is inherently hardware-friendly. While it is computationally expensive in software due to iterative loops, it allows us to demonstrate the power of Hardware Acceleration. Implementing operations like SubBytes, ShiftRows, and MixColumns in SystemVerilog provides an excellent opportunity to learn about pipelining and parallel data processing.

2. Interfacing with 32-bit RISC-V

Since AES-128 operates on 128-bit data blocks, integrating it with a 32-bit RISC-V core introduces a meaningful challenge in bus interconnect design and Register Map management. This requires us to design efficient data handling logic to move 128-bit blocks across a 32-bit infrastructure.

3. Industry Relevance

Encryption is a cornerstone of modern SoC (System on Chip) design. By implementing the most widely used standard for IoT and embedded security, our team gains hands-on experience with a real-world application that is highly valued in the semiconductor industry.

4. Verification & AI Strategy

The mathematical determinism of AES makes it ideal for an AI-assisted workflow:

 Prompt-based Verification: We can use AI to help generate comprehensive testbenches using standard NIST test vectors.
 Logic Optimization: The structured nature of the algorithm allows us to prompt Claude 4.5 for specific hardware optimizations (e.g., Look-Up Table vs. Combinational S-Box) to understand trade-offs in area and speed.

## KEY RESOURCES
Competition Resources

Competition Website: https://csm.arizona.edu/AIHDL

GitHub Repository: https://github.com/prismlabarizona/AIHDL-2026

TinyQV Core: https://github.com/TinyTapeout/ttsky25a-tinyQV

Peripheral Template: https://github.com/prismlabarizona/AIHDL2026/tree/master/tinyqv-full-peripheral-template

Technical References

NIST AES Standard: FIPS Publication 197

Verilator Documentation: https://verilator.org/guide/latest/

Yosys Documentation: https://yosyshq.net/yosys/

GTKWave: https://gtkwave.sourceforge.net/

Video Tutorials

Yosys Installation: https://www.youtube.com/watch?v=XRexMO1B6s8

Design Phase 1 Example: https://www.youtube.com/watch?v=M20AJiT_ETE

Webinar 3 - Base Design: https://www.youtube.com/watch?v=rOaLiDxNm74



