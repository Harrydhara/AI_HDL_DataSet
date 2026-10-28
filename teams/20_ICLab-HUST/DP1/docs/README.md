# DP1 Submission

## 1. Tools and Large Language Models (LLMs)

* **Simulation**: Verilator
* **Synthesis**: Yosys
* **Physical Design / PPA Evaluation**: OpenLane2 (base flow)
* **AI Assistance**: Claude, ChatGPT

AI tools were used to generate RTL code and supporting files. The **Claude Code extension** was utilized both in **VS Code** and via the **web interface**. Due to differences in these environments, some generated descriptions may be incomplete or missing.

---

## 2. Documentation

* **SPEC_29_1.docx**
  Provides a comprehensive overview of the CPU architecture, including:

  * Pin diagram and signal descriptions
  * Functional description of each module
  * Design modifications and implementation details when integrating the DMA block
  * Corresponding data flow and system-level interactions

* **prompt.docx**
  Describes the prompt engineering approach and usage methodology when working with AI tools during the design process.

---

## 3. Verilator Simulation Environment

A **Makefile-based flow** is used to manage simulation, linting, and waveform generation.

### Available Commands

```bash
make lint          # Run lint checks on all RTL files
make sim_dma       # Run DMA controller testbench
make sim_dma_top   # Run DMA top-level integration testbench
make sim_arbiter   # Run DMA arbiter testbench
make wave_dma      # View DMA controller waveforms
make wave_dma_top  # View DMA top-level waveforms
make wave_arbiter  # View DMA arbiter waveforms
make clean         # Remove all generated build artifacts
```

This setup enables efficient verification at both module and top-integration levels, with optional waveform inspection for debugging.

---

## 4. Yosys Synthesis

* Synthesis is executed using the following script:

  ```bash
  yosys synth.ys
  ```
* The synthesized netlists and reports are generated in the `/synthesis` directory.

---

## 5. OpenLane2 Flow

* **Configuration file**: `dma_top.json`
* OpenLane2 is used to run the complete RTL-to-GDS base flow and to extract **PPA metrics**.
* Results are summarized in the generated `metrics.csv` file.

Since the OpenLane2 flow and usage are already well understood by the team, AI tools were not used for guidance during this stage.

---

## 6. DMA Reference Documentation

The following external references were used to understand DMA concepts and architecture:

* Direct Memory Access (DMA) Controller in Computer Architecture – GeeksforGeeks
  [https://www.geeksforgeeks.org/computer-organization-architecture/direct-memory-access-dma-controller-in-computer-architecture/](https://www.geeksforgeeks.org/computer-organization-architecture/direct-memory-access-dma-controller-in-computer-architecture/)

* Direct Memory Access (DMA) in Embedded Systems – Open4Tech
  [https://open4tech.com/direct-memory-access-dma-in-embedded-systems/](https://open4tech.com/direct-memory-access-dma-in-embedded-systems/)

These resources provide foundational knowledge supporting the DMA design and integration choices made in this project.
