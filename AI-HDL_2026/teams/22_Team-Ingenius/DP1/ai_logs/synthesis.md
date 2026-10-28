# Synthesis Prompts – Ingenius CRC Peripheral

This file contains the AI prompts and notes used during the synthesis stage of DP1.  
All entries reflect the real workflow we followed when generating timing, area, and power reports.

## 1. OpenLane Configuration Assistance
**Prompt:**  
“Help me write a minimal OpenLane config.tcl for a small CRC peripheral with top module `tt_um_ingenius_crc`.”

**AI Output Used:**  
- Clock period suggestion (20 ns for 50 MHz)
- File list structure
- Basic placement and CTS defaults

**Team Edits:**  
- Corrected RTL file paths  
- Ensured only `tt_um_ingenius_crc.v` and `crc_datapath.v` were included  
- Verified clock port name (`clk`)

---

## 2. Understanding Synthesis Reports
**Prompt:**  
“Explain how to interpret WNS, TNS, cell count, and area in OpenLane reports.”

**AI Output Used:**  
- Definitions of WNS/TNS  
- Explanation of cell count and area  
- How to confirm timing closure

**Team Edits:**  
- Applied explanations to our actual reports  
- Verified that our WNS = 0.00 ns meets timing  
- Confirmed area fits within Sky130 limits

---

## 3. Power Report Interpretation
**Prompt:**  
“What does sequential vs combinational power mean in a small digital block?”

**AI Output Used:**  
- High-level explanation of power categories  
- How switching activity affects power

**Team Edits:**  
- Applied the explanation to our `powerreport.txt`  
- Noted that our design is mostly combinational

---

## 4. Final Synthesis Validation
**Prompt:**  
“How do I confirm that my design is ready for DP2 after synthesis?”

**AI Output Used:**  
- Checklist for timing, area, and errors  
- Reminder to verify top module and file paths

**Team Edits:**  
- Confirmed our design meets all DP1 requirements  
- Added notes to `reports/README.md`
