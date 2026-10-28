# DP1 Report – Team Ingenius

## 1. RTL Package

- **Peripheral Name:** Ingenius CRC Engine
- **Files:**
  - `rtl/user_peripherals/tqvp_ingenius/tt_um_ingenius_crc.v` (top-level wrapper)
  - `rtl/user_peripherals/tqvp_ingenius/crc_datapath.v` (datapath implementation)
- **Integration Slot:** 14
- **Interface:** Memory-mapped I/O (MMIO) with TinyQV bus signals

---

## 2. Design Rationale

- **Choice of Peripheral:** Cyclic Redundancy Check (CRC) engine for error detection in data streams.
- **Why CRC:** Lightweight, widely used in communication protocols, demonstrates datapath design and MMIO integration.
- **Architecture Highlights:**
  - Parallel datapath for efficient CRC computation
  - Configurable polynomial and seed values
  - Interrupt line for signaling completion

---

## 3. Verification

- **Testbench:** Cocotb-based test located at `test/user_peripherals/tqvp_ingenius/test.py`
- **Coverage:**
  - Known CRC vectors
  - Edge cases (zero input, max-length input)
  - Interrupt signaling
- **Results:** All tests passed ✔️ (attach logs/screenshots if available)

---

## 4. AI Prompt Logs

- **Design Prompts:** `prompts/design_prompts.md`
- **Debug Prompts:** `prompts/debug_prompts.md`
- **Summary:** Documented the iterative AI-assisted design process, including datapath refinement and MMIO integration.

---

## 5. Synthesis & PPA Results

- As per Phase 1 requirements, we ran baseline synthesis using OpenLane/Yosys. The design fits within the medium complexity target and meets all timing constraints at 50 MHz.

**Summary of Results:**

| Metric            | Value               | Status   | Notes                        |
| ----------------- | ------------------- | -------- | ---------------------------- |
| **Cell Count**    | 1,115               | -        | Total logic gates used       |
| **Chip Area**     | 13,457.91 $\mu m^2$ | -        | Physical size on Sky130      |
| **WNS**           | 0.00 ns             | **PASS** | No timing violations         |
| **Max Frequency** | 50 MHz              | -        | Target frequency met exactly |

**Detailed Reports:**
For the full logs and breakdown, please refer to the files in the reports directory:

- [Area & Timing Report](../reports/areatimingreport.txt)
- [Power Report](../reports/power_report.txt)

---

## 6. Schematic / Block Diagram

![CRC Peripheral Schematic](../reports/schematic.png)

_Description:_ CRC datapath connected to MMIO wrapper, with bus interface and interrupt line.

---

## 7. Submission Tag

- **Commit Tag:** `DP1-Submission`
- **Repo:** Private team repo `AIHDL-Team_Ingenius-`
