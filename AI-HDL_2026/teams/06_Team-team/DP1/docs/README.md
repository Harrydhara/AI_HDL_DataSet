\# \[Team Team] - Challenge \[1] Submission



\## Team Information

\- \*\*Team Name\*\*: \[Team Team]

\- \*\*Institution\*\*: \[KU LEUVEN]

\- \*\*Division\*\*: \[Lower/Upper]?

\- \*\*Team Members\*\*: 

&nbsp; - \[Member A] - \[developer] - \[[email]]

&nbsp; - \[Member B] - \[developer] - \[[email]]

&nbsp; - \[Member C] - \[developer] - \[[email]]

&nbsp; - \[Member D] - \[developer] - \[[email]]


\- \*\*Mentor\*\*: \[Navid Tarighat, github: kgubbi-ucdavis]



\## Challenge Summary

We used Gemini to assist in integrating a RISC-V based TinyQV CPU with a custom VGA signal generator peripheral. This involved creating a memory-mapped I/O (MMIO) bridge that allows the CPU to control video output by writing directly to peripheral registers, bypassing the need for a separate SPI controller for internal communication.


\## Key Features

\- Feature 1: (RISC-V Architecture Integration) The system utilizes the TinyQV CPU, which features a specialized QSPI memory controller for instruction fetching and data access.

\- Feature 2: (Memory-Mapped Peripheral Control) The VGA generator is mapped into the CPU's external data space, allowing 8-bit register access via standard RISC-V store instructions.

\- Feature 3: (Dual-Interface Flexibility) While the peripheral is integrated directly into the CPU bus for high-speed local control, the design maintains a SPI register interface (spi_reg) for external configuration and debugging.



\## AI Tools Used

\- Primary LLM: \[Gemini]

\- Additional tools: \[]

\- Total AI interactions: \[20]



\## Results Summary

\- \*\*Functionality\*\*: \[Success. Intermediate fails for using relative die area and too many more setting in config.json. Also, the code might have [cite:1] following the wire initiation]

\- \*\*FPGA Implementation\*\*: \[Success]

\- \*\*Resource Usage\*\*: \[LUTs : 5207, FFs: 1, DSPs used: 0]

\- \*\*Timing\*\*: \[71.5MHz]



\## Innovation Highlights

The integration achieves a full System-on-Chip (SoC) functionality within a compact 0.18 $mm^2$ die area. It successfully balances the complexity of a RISC-V instruction fetch engine with the real-time timing requirements of VGA signal generation.


\## Team Reflection

AI is very powerful!!!
Logical correctness does not guarantee physical feasibility. Our initial 311% utilization error highlighted the importance of floorplanning and core area allocation when integrating complex CPU cores like
