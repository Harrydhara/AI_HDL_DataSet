# DP2 – Optimization Phase  
Ingenius CRC Peripheral (AI‑HDL Challenge 2026)

Design Phase 2 (DP2) focuses on **optimizing** the CRC peripheral implemented in DP1.  
The goal of this phase is to improve **performance**, **area**, and **power**, while validating the design through updated RTL, reports, and testbenches.

---

## 📌 What Was Done in DP2

### **1. RTL Optimization**
- Introduced a **two‑stage pipeline** in the CRC datapath  
- Added intermediate register `crc_mid` to break the XOR/shift critical path  
- Redesigned FSM with explicit states (`IDLE`, `LOAD`, `SHIFT`, `DONE`)  
- Improved timing margin and maximum achievable frequency  
- Updated wrapper (`tt_um_ingenius_crc.v`) for DP2 synthesis flow  
- Added a standalone regression testbench (`crc_datapath_tb.v`)

### **2. Performance Improvements**
- DP1 max frequency: ~50 MHz  
- DP2 achieved: **~125 MHz**  
- Timing met with positive slack (WNS = 0.00, setup slack = 1.35 ns)

### **3. Area Results**
- DP1 cell count: 1115  
- DP2 cell count: 988  
- Area slightly reduced (−11%)

### **4. Power Results**
- Total power: **7.81e‑03 W**  
- Dynamic power increased due to pipelining  
- Power optimization deferred to DP3

### **5. Signoff**
- CVC report shows no fatal violations  
- STA summary confirms timing closure  
- Power report generated successfully

---

## 📂 Folder Structure

| Folder | Description |
|--------|-------------|
| **RTL/** | Pipelined datapath, wrapper, and testbench |
| **Netlist/** | Gate‑level netlist generated during DP2 |
| **Reports/** | STA, power, and CVC signoff reports |
| **Test/** | Python CRC generators and regression scripts |
| **docs/** | Optimization report and DP2 documentation |

---

## 📘 Key Document
- **docs/optimization_report.md**  
  Detailed analysis of DP2 improvements, before‑and‑after PPA comparison, and trade‑off justification.

---

## ✔ Summary
DP2 successfully:
- Exceeded performance goals  
- Met area goals  
- Validated functionality with updated testbench  
- Completed timing and signoff checks  

Power optimization remains the main target for DP3.

The design is now ready for the next phase.
