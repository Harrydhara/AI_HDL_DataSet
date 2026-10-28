# Challenges Faced and Solutions

## DP1 Phase Challenges

### 

### 1. AI Token Limitations
Challange: Even if we paid off a Claude Opus 4.5, it has a token limitations each day and week. RTL's and testbenchs are so long and they consumed so much token. Sometimes we just waited 4 hours for a day token limitations...

Solution: We decided one more LLM which is Gpt 5.2 Thinking.

Outcome: Gain some time and become much more rapid.

### 2. Design Selection Paralysis

Challenge: DP1 deadline approaching, but our final exam didn't finish yet.

Decision Made: Whatever it takes we want to build a complex design. Then we chose AES-128 Crypto Accelerator.

### 3. SystemVerilog vs Verilog Syntax

Challenge: Claude Opus 4.5 and Icarus Verilog SystemVerilog support has limitations

Issue: Claude Opus 4.5 gave us Verilog code in spite of our feedback which is SystemVerilog syntax

Solution: Generally handmade write file extension.

Outcome: No syntax issues encountered

### 4.Resources

Challange: The competition is new, and the resources provided by people who have done specific designs in the past are very limited. Finding videos, written materials, and repositories is difficult.

Solution: Although we have become more dependent on artificial intelligence and our own knowledge, the process has taught us a great deal.

## Anticipated Future Challenges

- Design Complexity Management: Risk of complex RTL becoming unmanageable, mitigated by modular design and thorough documentation
- Timing Closure: Design may not meet clock frequency targets, mitigated by early synthesis and iterative optimization
- Verification Coverage: Bugs missed in testbench, mitigated by systematic test case development and corner case analysis

Document Status: DP1 preliminary version
Last Updated: January 2026
