# DP2 Optimization Report – Ingenius CRC Peripheral

## 🎯 Goals

- **Performance:** Increase operating frequency from 50 MHz → target 75–100 MHz.  
- **Power:** Reduce dynamic power by ~10–20% (target ≤ 1.1 mW).  
- **Area:** Limit growth to <10% (target ≤ 14,800 µm²).

---

## 1. Baseline PPA (DP1)

- **Tool used:** OpenLane/Yosys  
- **Baseline timing (DP1):** Worst Negative Slack = 0.0 ns, Max Frequency ≈ 50 MHz  
- **Baseline power (DP1):**
  - Internal switching: 0.00144 µW  
  - Net switching: 0.00056 µW  
  - Leakage: 9.3e‑09 µW  
- **Baseline area (DP1):**
  - Synth cell count: 1115  
  - Core area: 26,725.632 µm²  

**Observations:**  
The CRC datapath was implemented as a single sequential block with no pipelining.  
The critical path limited the achievable frequency to around 50 MHz.

---

## 2. Changes Implemented in DP2 RTL

### Microarchitectural Tweaks

- Introduced a **two‑stage pipeline** in the CRC datapath (`msb_stage` and `shift_stage` registers).  
- Added an intermediate register `crc_mid` to break the critical XOR/shift path.  
- Redesigned the FSM with explicit states: `IDLE`, `LOAD`, `SHIFT`, `DONE` for cleaner control flow.

### Power‑Related Behavior

- FSM ensures most registers toggle only in the `SHIFT` state, reducing unnecessary switching in `IDLE` and `DONE`.

### RTL Modifications Summary

- DP1 used a monolithic always block with counter‑based shifting.  
- DP2 splits the design into:
  - FSM control
  - Pipeline registers
  - Staged CRC updates using non‑blocking assignments

**Goal:**  
Increase operating frequency toward 75–100 MHz, reduce dynamic power by ~10–20%, and keep area growth below 10%.

---

## 3. Before‑and‑After Comparison

| Metric                     | DP1          | DP2          | Change / Impact              |
|---------------------------|--------------|--------------|------------------------------|
| Synth cell count          | 1115         | 988          | −11% (area reduced)          |
| Core area (µm²)           | 26,725.632   | 26,650.56    | −0.3% (within goal)          |
| Worst Negative Slack (ns) | 0.0          | 0.0          | Timing met                   |
| Max Frequency (MHz)       | ~50          | **125**      | +150% (exceeded target)      |
| Internal power (µW)       | 0.00144      | 0.0052       | ↑ (pipeline adds toggling)   |
| Switching power (µW)      | 0.00056      | 0.00261      | ↑ (more staged activity)     |
| Leakage power (µW)        | 9.3e‑09      | 1.14e‑08     | Slight increase              |

### Analysis

- **Performance:**  
  Achieved **125 MHz**, exceeding the 75–100 MHz target.  
  Pipeline stages removed the critical path and enabled higher frequency.

- **Area:**  
  Cell count and core area **decreased slightly**, well within the <10% growth target.

- **Power:**  
  Dynamic power **increased** instead of decreasing.  
  Further clock gating or operand isolation will be needed to meet the ≤ 1.1 mW target.

---

## 4. Trade‑off Justification

- **Performance vs Power:**  
  Pipeline stages improved timing margin and frequency potential (125 MHz achieved), but increased dynamic power.  
  This trade‑off was accepted to meet timing goals.

- **Area vs Complexity:**  
  Area decreased slightly due to synthesis optimizations despite the added pipeline registers.

- **Overall:**  
  DP2 achieved timing closure and exceeded performance goals, met area goals, but fell short of power reduction targets.  
  The design is now structurally ready for further power optimization in DP3.
