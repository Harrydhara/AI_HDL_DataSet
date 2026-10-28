# Team Submission Form - Acona Tech

- **Team Name:** Acona Tech  
- **Challenge:** AI Hardware Design Language (AI-HDL) 2026  
- **Submission Phase:** DP1 (Design Planning Phase 1)  
- **Submission Date:** 28 January 2026  

---

## Team Information

### Team Members
- **Team Captain:** Member A  
- **Member 2:** Azra Develi  
- **Member 3:** Member B  

### Institution
Ankara Yildirim Beyazit University  

### Contact
- **Email:** [email]  
- **GitHub:** https://github.com/[user]/Acona-Tech-AI-HDL-2026  

---

## Project Overview

### Project Title
**AES-128 Crypto Accelerator (Memory-Mapped Peripheral for TinyQV SoC)**

### Design Summary
This DP1 submission presents our design planning work and development infrastructure for an
**AES-128 cryptographic accelerator** implemented as a **memory-mapped hardware peripheral**.
The repository includes both planning documents and the implementation skeleton needed to support
rapid iteration with verification and synthesis evidence.

**Highlights**
- AES-128 accelerator RTL structure (core rounds, key expansion, S-box, MixColumns, control +
  register interface)
- Memory-mapped register interface suitable for SoC integration
- Verification-first workflow with dedicated testbenches and repeatable `make test`
- Baseline synthesis evidence tracking for DP1 requirements (tracked report)
- AI interaction logs kept as artifacts under `prompt_logs/`

**Current DP1 status**
- Repository contains AES-related RTL modules and an evolving verification suite.
- DP1 evidence and documentation are organized for review and traceability.

---

## Repository Structure Mapping

| Required Directory / File | Our Implementation              | Purpose |
|---|---|---|
| `submission-form.md`        | ✅ `submission-form.md`          | Team and project overview |
| `README.md`                 | ✅ `README.md`                   | Quickstart + repo usage |
| `src/`                      | ✅ `rtl/`                        | Hardware source (SystemVerilog RTL) |
| `testbench/`                | ✅ `tb/`                         | Verification testbenches |
| `ai_logs/`                  | ✅ `prompt_logs/`                | AI interaction records (prompts/iterations) |
| `results/baseline_synth/`   | ✅ `reports/`                    | Tracked baseline synthesis evidence |
| `results/testbench_results/`| ✅ `reports/`                    | Errors encountered and passed testbenches |
| `results/run_sim.sh/`       | ✅ `reports/`                    | Simulation outputs (gitignored) |
| `docs/`                     | ✅ `docs/`                       | Planning + methodology + verification plan |

> Note: We use `rtl/` instead of `src/` to match standard HDL conventions. This is a naming
> difference only; content and intent match the required category.

---

## Toolchain Verification

- ✅ **Icarus Verilog** (simulation)
- ✅ **Yosys** (synthesis)
- ✅ **SystemVerilog** (HDL)
- ✅ **Make** (automation)
- ✅ **Git** (version control)

Evidence:
- `make check_tools` confirms tools are installed and callable.
- `make test` runs the verification flow.
- `make baseline` generates the tracked synthesis report under `reports/baseline_synth/`.

---

## Compliance Notes

This DP1 submission is structured to be review-friendly and reproducible:

- **Traceability:** Planning docs, AI prompt logs, RTL, and verification artifacts are separated and
  clearly named.
- **Reproducibility:** Build, simulation, and synthesis are scriptable via the Makefile.
- **Baseline Evidence:** Official DP1 synthesis evidence is tracked in version control under
  `reports/baseline_synth/`.
- **Clean Repo Policy:** Daily outputs (simulation dumps, run logs, non-baseline synthesis runs)
  go under `reports/runs/` and are ignored via `.gitignore` to keep the repo clean.
- **Design Intent:** Target design is an **AES-128 crypto accelerator** (memory-mapped peripheral)
  intended for SoC integration.

For detailed design methodology, AI strategy, register map, block diagram, and verification plan,
see `docs/`.
