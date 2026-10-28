## 2. Lessons Learned (Key Insights & Takeaways)

### A. The Value of "Assertion-Based" Design
This process highlighted that in hardware verification, **error messages are specifications**. When documentation is sparse (or when working with a fixed test bench), the assertion failures provide the most accurate map of required behavior. I learned to treat every `AssertionError` not just as a bug, but as a pointer to a missing functional requirement.

### B. AI as a Logic Partner, Not Just a Coder
My interaction with the AI shifted from simply asking "write code" to "analyze this state." The AI was most valuable when I provided it with the specific context of the failure (e.g., input values vs. expected output). This reinforced the idea that **AI tools excel at synthesis and pattern matching**—if I can isolate the variable that is wrong (e.g., "The interrupt won't clear"), the AI can rapidly propose structural RTL changes (e.g., "Add edge detection") that might take a human longer to draft from scratch.

### C. Flexibility in Hardware Definitions
I learned that "Module Names" can be deceptive. Even though the task was to build a "UART Controller," the test bench effectively demanded a hybrid device (UART + Adder + GPIO). This taught me to look past standard definitions and focus strictly on the **I/O constraints and behavioral expectations** of the specific environment I am designing for.
