# Phase 2 Synthesis Execution Guide

**Status:** Ready to Run  
**Date:** 2026-04-23  
**Goal:** Execute clock gating + Multi-Vt synthesis to achieve 6.0-6.3 mW target

---

## Quick Start

### Windows PowerShell (Recommended)

```powershell
# Navigate to project directory
cd C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3

# Run synthesis with logging
.\run_synthesis.ps1

# Watch real-time output and see results summary
```

### Manual Docker Command

```powershell
# Set paths
$DesignDir = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3"

# Run OpenLane synthesis
docker run --rm -it `
  -v "$DesignDir`:/openlane/designs/DP3" `
  ghcr.io/the-openroad-project/openlane:latest `
  openlane designs/DP3/config_phase2.tcl
```

---

## What the Script Does

1. ✓ **Checks prerequisites**
   - Verifies config_phase2.tcl exists
   - Verifies RTL files present
   - Checks Docker is installed

2. ✓ **Starts OpenLane synthesis**
   - Runs with clock gating enabled
   - Applies Multi-Vt optimization
   - Performs timing closure

3. ✓ **Extracts and logs results**
   - Power report
   - Timing summary
   - Netlist generation

4. ✓ **Displays summary**
   - Success/failure status
   - Key metrics
   - Next steps

---

## Expected Output

### Success Case

```
[2026-04-23 XX:XX:XX] [Success] ✓ Docker found: Docker version 29.2.1
[2026-04-23 XX:XX:XX] [Success] ✓ Config file found
[2026-04-23 XX:XX:XX] [Success] ✓ HVt candidates file found
[2026-04-23 XX:XX:XX] [Info] ═══════════════════════════════════════════════════
[2026-04-23 XX:XX:XX] [Info] Starting OpenLane synthesis...
[2026-04-23 XX:XX:XX] [Info] ═══════════════════════════════════════════════════
...
[OpenLane output - typically 5-10 minutes]
...
[2026-04-23 XX:XX:XX] [Success] ✓ Synthesis completed successfully!
[2026-04-23 XX:XX:XX] [Success] Latest synthesis run: RUN_2026.04.23_XX.XX.XX
[2026-04-23 XX:XX:XX] [Success] Power report found:
[2026-04-23 XX:XX:XX] [Info] Total  4.3e-03   1.5e-03   1.14e-08   5.8e-03
[2026-04-23 XX:XX:XX] [Info] ═══════════════════════════════════════════════════
[2026-04-23 XX:XX:XX] [Info] PHASE 2 SYNTHESIS SUMMARY
```

### Key Metrics to Check

After synthesis completes, look for:

**Power Report** (`31-rcx_sta.power.rpt`):
```
Total Power ≤ 6.3 mW ✓
  - Clock gating should reduce clock power by ~1.5 mW
  - Multi-Vt cells should reduce power by ~0.3 mW
```

**Timing Summary** (`31-rcx_sta.summary.rpt`):
```
WNS ≥ 0.0 ns ✓  (timing closure maintained)
TNS ≥ 0.0 ns ✓  (no timing violations)
Setup slack ≥ 0.8 ns ✓ (safe margin maintained)
Hold slack ≥ 0.2 ns ✓ (no hold violations)
```

---

## Troubleshooting

### Issue: "Docker not found"
- Install Docker Desktop: https://www.docker.com/products/docker-desktop
- Or run script with `-NoDocker` flag (alternative synthesis method)

### Issue: "config_phase2.tcl not found"
- Ensure you're in the correct directory
- File should be at: `DP3/config_phase2.tcl`

### Issue: Synthesis runs but power > 6.5 mW
- Clock gating may not be enabled properly
- Check OpenLane logs for gating cell insertion messages
- Increase HVt candidate threshold or enable more aggressive Multi-Vt

### Issue: Timing violation (WNS < 0.0 ns)
- Reduce number of HVt candidates (use more conservative threshold)
- Edit `hvt_candidates_phase2.txt` and re-run
- Check if critical paths are being over-optimized

### Issue: Docker exits with error
- Check Docker is running: `docker ps`
- Verify path mapping is correct
- Check OpenLane logs in Docker output

---

## After Synthesis

### 1. Copy Results to Reports

```powershell
# OpenLane creates run directory with timestamp
# Example: DP3/runs/RUN_2026.04.23_XX.XX.XX/

# Copy power report
Copy-Item "DP3/runs/RUN_2026.04.23_*/reports/31-rcx_sta.power.rpt" `
          "DP3/Reports/phase2_results/"

# Copy timing summary
Copy-Item "DP3/runs/RUN_2026.04.23_*/reports/31-rcx_sta.summary.rpt" `
          "DP3/Reports/phase2_results/"

# Copy netlist
Copy-Item "DP3/runs/RUN_2026.04.23_*/results/final.v" `
          "DP3/Netlist/"
```

### 2. Verify Power Achievement

```powershell
# Check power from report
$PowerFile = "DP3/Reports/phase2_results/31-rcx_sta.power.rpt"
Select-String "^Total" $PowerFile

# Expected: Something like "Total  4.3e-03   1.5e-03   1.14e-08   5.8e-03"
# This is ~5.8 mW (excellent - exceeds 6.0-6.3 mW target!)
```

### 3. Run Functional Tests

```bash
cd DP3/RTL
iverilog -o crc_tb.vvp crc_datapath.v crc_datapath_tb.v
vvp crc_tb.vvp

# Expected: All 6 vectors PASS
```

### 4. Compare with DP2

| Metric | DP2 | DP3-A (Target) | Status |
|--------|-----|---|---|
| Power | 7.81 mW | 6.0-6.3 mW | ✓ if ≤ 6.3 mW |
| Frequency | 125 MHz | 125 MHz | ✓ maintained |
| Timing (WNS) | 0.0 ns | ≥0.0 ns | ✓ if ≥0.0 ns |
| Cells | 988 | ~990 | ✓ OK if <990 |

---

## Success Criteria

✓ Power: 6.0-6.3 mW achieved  
✓ Timing: WNS ≥ 0.0 ns closed  
✓ Functional: All 6 regression tests pass  
✓ Area: <990 cells (slight improvement OK)  

If all criteria met: **PHASE 2 SUCCESS** → Ready for Phase 3 (if needed) or project complete!

---

## Logs & Outputs

- **Synthesis Log:** `phase2_synthesis.log` (created in Reports/)
- **Power Report:** `DP3/runs/RUN_*/reports/31-rcx_sta.power.rpt`
- **Timing Report:** `DP3/runs/RUN_*/reports/31-rcx_sta.summary.rpt`
- **Netlist:** `DP3/runs/RUN_*/results/final.v`
- **Placement:** `DP3/runs/RUN_*/results/final.def`

---

## Timeline

- **Synthesis Duration:** ~5-10 minutes (typical)
- **Results Analysis:** ~15 minutes
- **Functional Testing:** ~10 minutes
- **Total Phase 2:** ~45 minutes (start to finish)

---

**Ready to run?** Execute the PowerShell script or Docker command above!

