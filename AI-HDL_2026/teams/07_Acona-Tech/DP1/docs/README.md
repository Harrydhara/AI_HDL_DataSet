# Acona-Tech AI-HDL 2026

**Team:** Acona-Tech  
**Institution:** Ankara Yildirim Beyazit University  
**Division:** Lower  
**Competition:** Arizona University AI Hardware Design League 2026

---


## Current Status: DP1 Infrastructure Complete ✅

This repository demonstrates a professional HDL workflow:
- Clean Git structure with meaningful commits
- Automated testing and synthesis (Makefile)
- Evidence tracking (baseline synthesis reports)
- AI interaction logging system
- Comprehensive documentation structure

**Pipeline Status:**
- ✅ Toolchain verified (iverilog, yosys)
- ✅ Smoke test passing
- ✅ Synthesis baseline established
- 🔄 Awaiting Challenge-1 specification

---
## AES Peripheral Quickstart (DP1)

Top module:
- `tqvp_aes128_top`

Run unit test:
```bash
make test


## DP1 Baseline Evidence Policy

`reports/baseline_synth/yosys_stat.txt` is the official **DP1 baseline synthesis evidence** and is kept **tracked** in the repository.

All other generated artifacts (daily synthesis runs, build outputs, simulation dumps, logs, etc.) are **ignored** via `.gitignore` to keep the repository clean and reviewable.

---

## Quickstart (WSL / Ubuntu) – Recommended

### Prerequisites
```bash
sudo apt update
sudo apt install -y git make iverilog yosys
```
