# DP1 OpenLane Run – Ingenius CRC Peripheral

This folder contains the OpenLane configuration and run files used to synthesize and analyze our CRC peripheral for DP1.

## 📄 Files

- **config.tcl**  
  OpenLane configuration file specifying:
  - Top module: `tt_um_ingenius_crc`
  - RTL files:
    - `tt_um_ingenius_crc.v`
    - `crc_datapath.v`
  - Clock port: `clk`
  - Clock period: `20.0 ns` (50 MHz target)
  - Placement density and CTS settings

## 📌 Purpose of This Folder
This folder is used to:
- Run synthesis
- Perform floorplanning, placement, and routing
- Generate timing, area, and power reports
- Validate that the design meets DP1 constraints

## ✔ Results Summary
The OpenLane run confirms:
- Timing met at 50 MHz (WNS = 0.00 ns)
- Area fits within Sky130 limits
- No routing or synthesis errors

These results match the reports stored in the `DP1/reports/` folder.
