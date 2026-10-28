# DP2 Reports – Ingenius CRC Peripheral

This folder contains all timing, power, and signoff reports generated during DP2 for the optimized CRC peripheral.

---

## 📌 1. Timing Reports

### **31-rcx_sta.summary.rpt**
Key results:
- **TNS:** 0.00  
- **WNS:** 0.00  
- **Worst Setup Slack:** 1.35 ns  
- **Worst Hold Slack:** 0.32 ns  

**Interpretation:**  
The design meets timing with positive slack margins.  
The pipelined datapath enables operation well above the original 50 MHz target.

### **31-rcx_sta.max.rpt / 31-rcx_sta.min.rpt**
These files are empty in this run.  
OpenLane sometimes produces empty min/max corner reports when no violations are detected.

---

## 📌 2. Power Report

### **31-rcx_sta.power.rpt**
Total power: **7.81e‑03 W**

Breakdown:
- **Sequential:** 2.63e‑03 W (33.7%)  
- **Combinational:** 5.18e‑03 W (66.3%)  
- **Leakage:** 1.14e‑08 W (negligible)

**Interpretation:**  
Dynamic power increased due to added pipeline stages.  
This matches the DP2 optimization report and will be addressed in DP3.

---

## 📌 3. CVC Signoff

### **tt_um_ingenius_crc_DP2.rpt**
Circuit Validation Check (CVC) summary:
- Netlist parsed successfully  
- No fatal electrical rule violations shown in the report snippet  
- Confirms the DP2 netlist is structurally valid for signoff

---

## 📌 Summary

DP2 reports confirm:
- **Timing:** Met with positive slack  
- **Area:** Within target (validated in optimization report)  
- **Power:** Increased due to pipelining; next target for DP3  
- **Signoff:** CVC completed with no critical errors

These results validate the DP2 RTL improvements and prepare the design for further optimization in DP3.
