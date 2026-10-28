# AI Strategy and Usage

This document describes how AI tools were strategically used during the design and implementation of the Winograd F(2×2,3×3) hardware accelerator integrated with TinyQV and implemented using the OpenLane RTL-to-GDSII flow.

AI was used as an engineering assistant to accelerate understanding, architecture exploration, RTL development, verification, and physical design debugging. However, all final design decisions, refinements, and validations were performed manually.

---

## Tool Selection

Two primary large language models were used during development:

- Claude.ai  
- Gemini  

Each tool was selected based on task suitability.

Claude was primarily used for:
- Understanding the Winograd convolution algorithm
- Mapping mathematical transforms to hardware architecture
- Generating structured RTL module skeletons
- Designing memory-mapped interfaces
- Creating initial verification testbenches

Claude was chosen because it provides well-structured explanations and clear algorithm-to-hardware reasoning.

Gemini was primarily used for:
- Understanding the OpenLane RTL-to-GDSII flow
- Docker-based environment setup
- Debugging synthesis and routing errors
- Interpreting timing and area reports
- Assisting with fixed-point arithmetic implementation

Gemini was selected for its strong step-by-step procedural guidance and debugging-oriented responses.

The tool usage was intentionally divided:
- One model focused on architecture and RTL reasoning.
- The other focused on toolchain execution, debugging, and physical design flow.

---

## Prompting Techniques

A structured prompting methodology was applied throughout the project.

### 1. Concept-Oriented Prompting

At the beginning, prompts were designed to build deep understanding of:

- The Winograd F(2×2,3×3) algorithm
- Transform matrices (G, Bᵀ, Aᵀ)
- Reduction in multiplication complexity
- Suitability for ASIC implementation

The focus was on comprehension before implementation.

---

### 2. Architecture-Oriented Prompting

After understanding the algorithm, prompts were structured to:

- Decompose the accelerator into modules
- Define control/data separation
- Establish memory-mapped interfaces
- Outline FSM-based execution flow

Prompts emphasized synthesizable RTL and modular hardware design.

---

### 3. Verification-Oriented Prompting

AI was used to generate:

- Testbench templates
- Functional verification structures
- Self-checking mechanisms

These outputs were used to identify mismatches between algorithmic expectation and RTL behavior.

---

### 4. Toolchain-Oriented Prompting

When moving to implementation:

- Prompts focused on OpenLane flow stages
- Interpretation of metrics reports
- Timing closure understanding
- Physical design debugging
- Layout visualization

Questions were specific and error-driven, based on real synthesis and routing results.

---

### 5. Numerical Optimization Prompting

Since floating-point arithmetic is costly in ASIC design, prompts were structured to:

- Convert fractional constants to fixed-point form
- Replace multiplication by shifts when possible
- Implement rounding logic safely
- Avoid overflow during accumulation

This ensured hardware-efficient implementation.

---

## Iteration Process

AI-generated outputs were never used directly without modification.

1. RTL skeletons were refined:
   - Signal naming standardized
   - FSM redesigned for determinism
   - Dataflow optimized
   - Synthesizability verified

2. Memory-mapped interfaces were customized:
   - Adapted to TinyQV integration
   - Handshake logic adjusted
   - Address map refined

3. Testbench results were manually analyzed:
   - Compared intermediate matrices
   - Validated transform correctness
   - Corrected accumulation logic

4. OpenLane configuration required manual tuning:
   - Core utilization adjusted
   - Floorplan density reduced
   - Power pin placement refined
   - Logs inspected manually

5. Fixed-point arithmetic required validation:
   - Fractional width selected carefully
   - Rounding added
   - Accumulation range checked
   - Overflow risk analyzed

The development process was iterative: AI suggestion → manual refinement → verification → correction.

---

## AI Limitations Encountered

Several limitations were observed during AI-assisted development:

### 1. RTL Generalization

AI-generated RTL often provided structural templates but lacked:

- Sky130-specific considerations
- Timing-aware optimizations
- Deterministic FSM implementation

These aspects required manual redesign.

---

### 2. Hardware Context Awareness

AI did not inherently understand:

- Project-specific integration constraints
- TinyQV system-level behavior
- Physical design trade-offs

Human supervision ensured correct architectural alignment.

---

### 3. Physical Design Debugging Depth

While AI explained timing violations and routing errors conceptually, it could not:

- Inspect actual OpenLane logs dynamically
- Evaluate real congestion maps
- Automatically fix floorplan constraints

Manual debugging and iterative tuning were necessary.

---

### 4. Fixed-Point Precision Risks

AI suggested shift-based implementations, but:

- Quantization effects needed evaluation
- Overflow boundaries required analysis
- Accumulation growth had to be verified

All numerical decisions were validated independently.

---

## Learning from AI

The AI-assisted workflow provided valuable technical insights:

### 1. Algorithm-to-Hardware Mapping

Understanding how Winograd reduces multiplications and increases additions clarified:

- Why it is ASIC-friendly
- How to structure datapath pipelines
- How to minimize multiplier usage

---

### 2. Modular Hardware Design Thinking

AI-assisted decomposition reinforced:

- Clear module separation
- FSM-based control design
- Transform stage isolation

This improved architectural clarity.

---

### 3. RTL-to-GDSII Flow Understanding

Through AI guidance:

- The role of Yosys, OpenROAD, Magic, and KLayout became clearer
- The difference between synthesis and physical design was better understood
- Timing closure concepts (WNS, TNS) were internalized

---

### 4. Hardware-Efficient Arithmetic

Replacing floating-point with fixed-point:

- Reduced hardware complexity
- Lowered area usage
- Improved ASIC feasibility

This was a major design improvement influenced by AI-assisted exploration.

---

## Overall AI Strategy

AI was used as:

- A knowledge accelerator
- A structured reasoning assistant
- A preliminary RTL generator
- A verification helper
- A toolchain debugging guide
- A numerical optimization advisor

However, AI was not treated as an autonomous designer.

All architectural decisions, FSM implementations, interface definitions, OpenLane tuning, and numerical validations were performed manually and verified independently.

AI functioned as a collaborative engineering assistant, while final responsibility and design ownership remained entirely with the author.
