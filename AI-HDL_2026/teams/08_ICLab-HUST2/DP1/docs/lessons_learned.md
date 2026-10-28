# Lessons Learned

## 1. Technical & ASIC Flow Insights
- The process of implementing the Winograd accelerator on the SkyWater 130nm node provided the team with profound practical knowledge:
  - **The Criticality of Design for PPA:** We realized that writing "functional" Verilog code is not enough. To achieve an area of 0.176 $mm^2$ and a frequency of 50 MHz, the decision to replace standard multipliers with multiplier-less logic (hard-wired shifts and adds) was the turning point in overcoming path delay constraints.
  - **Mastering the Physical Flow:** Through resolving over 100 DRC and LVS violations, the team gained a clear understanding of how tools like Magic and Netgen interpret design rules. The biggest lesson was how the Power Delivery Network (PDN) structure and cell density (FP_CORE_UTIL) directly impact the routability and timing of the chip.
  - **Arithmetic Error Management:** Transitioning from a mathematical model to fixed-point hardware requires careful calculation of error compensation. The rounding-bit technique learned during optimization significantly improved accuracy for Edge AI applications without excessive hardware overhead.
  
## 2. AI Collaboration Strategy
- Using Claude.ai and Gemini 3.0 has completely transformed our approach to hardware design:
  - **The "Garbage In, Garbage Out" Principle:** AI is only as effective as the context provided. Supplying detailed bus addresses (0x9000_0000) and the TinyQV pinout was a prerequisite for the AI to generate code that was ready for immediate integration.
  - **Human-in-the-loop Critical Thinking:** We learned never to fully trust AI-generated code without auditing. AI may suggest resource-heavy solutions (like default multipliers); the human role is to refine and optimize these suggestions to fit the project's physical constraints.
  - **Error Diagnostic Skills:** Instead of asking generic questions, providing raw metrics.csv files or error logs to Gemini reduced the time spent finding the root cause of timing violations by approximately 70%.
  
## 3. Project Management & System Thinking
- **Embracing Trade-offs:** The most significant lesson in SoC design is balance. We learned to accept lower cell density to ensure routing stability and meet timing requirements.
- **The Value of Logging:** Recording every AI interaction (per BTC requirements) was not just a formality; it allowed the team to trace our thought process, making it easier to debug when new changes caused system conflicts.
  
## 4. Future Outlook
- The skills acquired during this AI-HDL challenge will serve as a foundation for our team to:
  - Research more complex AI acceleration architectures on smaller technology nodes.
  - Develop a more highly automated hardware design flow supported by Large Language Models (LLMs).
