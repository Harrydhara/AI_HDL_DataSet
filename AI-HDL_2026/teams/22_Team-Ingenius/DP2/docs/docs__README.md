# DP2 Documentation – Ingenius CRC Peripheral

This folder contains all documentation for Design Phase 2 (DP2) of the Arizona AI‑HDL Challenge 2026.  
DP2 focuses on **optimizing** the CRC peripheral implemented in DP1, improving performance, area, and power.

---

## 📘 Contents

### **1. optimization_report.md**
A detailed analysis of the improvements made in DP2, including:

- Baseline PPA from DP1  
- Microarchitectural changes (pipeline stages, FSM redesign)  
- Before‑and‑after comparison of timing, area, and power  
- Trade‑off justification and next‑step recommendations  

This report summarizes the engineering decisions behind the DP2 RTL and the resulting performance gains.

---

## 📌 Summary of DP2 Goals

- Increase operating frequency from 50 MHz toward 75–100 MHz  
- Reduce dynamic power by ~10–20%  
- Keep area growth under 10%  

DP2 successfully exceeded timing and area goals, while power optimization remains a target for DP3.

---

## 📂 Related Folders

- **../RTL/** – Updated pipelined CRC datapath and testbench  
- **../Reports/** – STA, power, and CVC signoff results  
- **../Test/** – Python CRC generators and regression test scripts  

All DP2 artifacts work together to validate the improved CRC design.
