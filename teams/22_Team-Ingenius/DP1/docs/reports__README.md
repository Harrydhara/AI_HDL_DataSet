# DP1 Reports – Ingenius CRC Peripheral

This folder contains the synthesis, timing, and power reports generated for our CRC peripheral during DP1.

## 📄 Report Files

- **areatimingreport.txt**  
  Contains area and timing results from OpenLane/Yosys.  
  - Cell Count: 1115  
  - Chip Area: 13,457.91 µm²  
  - WNS: 0.00 ns (PASS)  
  - Target Clock: 20 ns (50 MHz)

- **powerreport.txt**  
  Contains power analysis results.  
  - Total Power: 1.39e-03 W  
  - Sequential Power: 43.1%  
  - Combinational Power: 56.9%

- **schematic.png**  
  Visual schematic of the CRC peripheral generated during synthesis.

## 📌 Summary
The CRC peripheral meets all DP1 requirements:
- Fits within area limits  
- Meets timing at 50 MHz  
- Has clean power characteristics  
- Synthesizes without errors

These reports confirm that our design is valid and ready for DP2.
