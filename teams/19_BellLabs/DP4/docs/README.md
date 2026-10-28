# tqvp_belllabs_aes128
### High-Performance, Clock-Gated AES-128 Peripheral
**Team #63 (Bell Labs) | University of Lagos, Nigeria**

---

## Project Sign-off Status
| Phase | Objective | Status | Sign-off Data |
|-------|-----------|--------|---------------|
| **DP1** | Functional RTL & Synthesis | COMPLETE | NIST Verified |
| **DP2** | PPA Optimization & STA | COMPLETE | 328 MHz Post-Layout |
| **DP3** | Security Evaluation | **COMPLETE** | **SCA Hardened (4/4 PASS)** |
| **DP4** | GDSII Tape-out | **SUCCESS** | **0 DRC / 0 LVS Errors** |

---

## System Specifications
*   Silicon Target: SkyWater Sky130A (130nm)
*   Core Logic: Iterative AES-128 (10 cycles/block)
*   Frequency: 64 MHz (System) / 294 MHz (Silicon Fmax)
*   Power Strategy: Multi-Bank Clock Gating (25% reduction) & Boolean Masking
*   Security Features: 1st-Order Boolean Masking, Key Lockout, Timing Invariance
*   Interface: 32-bit APB-compatible Memory Mapped I/O

**Final deadline:** May 7, 2026

---

## Module: AES-128 Encryption Engine

The `tqvp_belllabs_aes128` module is a fully hardware-implemented AES-128 encryption engine that connects to the TinyQV RISC-V processor as a memory-mapped peripheral.

### What it does

AES-128 (Advanced Encryption Standard, 128-bit key) is the global standard for symmetric encryption. This hardware implementation allows the TinyQV processor to encrypt 128-bit data blocks in **10 clock cycles** (156 ns at 64 MHz) — orders of magnitude faster than software encryption on the RISC-V core.

### Architecture Evolution

- **Type:** Iterative — one complete AES round per clock cycle
- **Latency:** 10 cycles per encryption (one round per cycle × 10 rounds)
- **Operations:** SubBytes (S-box), ShiftRows, MixColumns, AddRoundKey, KeySchedule
- **Interface:** 32-bit memory-mapped peripheral bus (TinyQV template)
- **DP2 Optimization:** Multi-bank clock gating for 25% power reduction.
- **DP3 Hardening:** First-order Boolean masking, Dynamic Key Lockout, and Constant-time execution.

---

## DP1 Results

### Verification

| Test | Status |
|------|--------|
| NIST AES-128 test vector | ✅ PASS |
| Yosys synthesis (no errors) | ✅ PASS |
| Cross-validation vs OpenSSL | ✅ PASS |

**NIST Test Vector:**
- Key: `000102030405060708090a0b0c0d0e0f`
- Plaintext: `00112233445566778899aabbccddeeff`
- Ciphertext: `69c4e0d8 6a7b0430 d8cdb780 70b4c55a` ✅

### Baseline PPA (Yosys, sky130_fd_sc_hd)

| Metric | Value |
|--------|-------|
| Total cells | 12,287 |
| Flip-flops | 816 |
| Total wires | 11,319 |
| Dominant cell | $_MUX_ (7,725 — 62.9%) |

---

## DP2 Results

### PPA Optimization Results (Post-Layout Sign-off)

The DP2 phase focused on aggressive Power, Performance, and Area (PPA) optimization. The design was signed off using the **OpenLane 1.0.2** physical design flow.

| Dimension | Metric | Baseline (DP1) | Optimized (DP2) | Delta |
| :--- | :--- | :--- | :--- | :--- |
| Performance | Fmax | 345 MHz (est) | **328 MHz (RC Extracted)** | Verified |
| Power | Sequential Switching | 1.63 mW | **1.22 mW** | -25.1% |
| Area | Cell Count | 12,287 | **12,303** | +0.1% |
| Reliability | DRC / LVS | N/A | **0 Violations / CLEAN** | Sign-off |

> [!IMPORTANT]
> **Engineering Decision on Pipelining:**
> A 20-cycle pipelined architecture was evaluated to target 400+ MHz. However, post-routing STA revealed that the physical bottleneck was the APB bus fan-out (address pins), not the AES datapath. We deliberately reverted to the 10-cycle iterative architecture to maximize area-efficiency and latency while maintaining a 5.1x timing safety factor.

---

## DP3 Results

### Security Hardening & PPA Impact

The DP3 phase introduced robust hardware countermeasures against side-channel and architectural attacks while balancing the PPA overhead.

| Security Pillar | Implementation | Status |
| :--- | :--- | :--- |
| **DPA Resistance** | 1st-Order Boolean Masking (LFSR) | ✅ PASS |
| **Key Extraction** | Dynamic Key Lockout (0xDEADBEEF) | ✅ PASS |
| **Timing Attacks** | Constant-Time Execution (12 cycles) | ✅ PASS |
| **Info Residue** | Start-of-Encryption Sanitization | ✅ PASS |

### Hardened PPA Metrics (Post-Security)
Comparison against the DP2 optimized baseline:
- **Total Cells:** 13,361 (**+8.74%** overhead)
- **Flip-Flops:** 753 (**-7.72%** due to logic flattening)
- **Total Wires:** 12,683 (**+12.05%**)

---

## DP4 Results (Final Physical Tape-out)

### Final Phase 4 (PPA) Dashboard
The design has been successfully taped out on the **Sky130 (130nm)** process. The physical deliverables (GDSII, Sign-off Reports) are separated into their respective repository folders as required.

| Metric | Result | Engineering Notes |
| :--- | :--- | :--- |
| **Final Die Area** | **0.5625 mm²** | Optimized 750μm x 750μm for 0-violation routing. |
| **Maximum Silicon Fmax**| **294.1 MHz** | True physical capability (3.40ns critical path). |
| **System Clock Target** | **64.0 MHz** | Cleanly closed timing at 15.62ns to match TinyQV APB bus spec. |
| **Routing Status** | **0 DRC / 0 LVS** | 100% manufacturable GDSII generated. |
| **Workload Log** | ~48h Detailed Routing | Resolved via 750μm Area Pivot & Density Tuning. |

### 🧠 Architectural Trade-offs & Lessons Learned
During the DP4 phase, the design initially hit a "Routing Wall" at a 700μm footprint due to the extreme interconnect density required for **Boolean Masking**. The following strategic decisions were made:
1.  **Area-Power-Time Balance**: We traded 13% of die area (moving to 750μm) to achieve 100% manufacturability and reduce routing time from 48+ hours to 45 minutes.
2.  **Timing Closure at 64MHz**: The design successfully met the 64MHz (15.62ns) system target while maintaining a high-performance 294MHz (3.40ns) silicon Fmax, proving that security hardening on the Sky130 node does not preclude high-speed physical convergence.
3.  **High-Intensity Routing**: Leveraged the `DRT_OPT_ITERS` limit and `PL_TARGET_DENSITY` tuning to force convergence on a complex, security-hardened netlist.

For full details, see the [Final Project Report](docs/dp4/Final_Project_Report.md).

---

## Register Map

| Address | Register | Direction | Description |
|---------|----------|-----------|-------------|
| 0x00–0x0C | KEY_W0..W3 | Write | 128-bit AES key. Returns `0xDEADBEEF` if locked. |
| 0x0E | MASK_SEED | Write | 32-bit LFSR seed for Boolean Masking. |
| 0x10–0x1C | PLAIN_W0..W3 | Write | 128-bit plaintext input. Locked during encryption. |
| 0x20 | CTRL | Write | bit[0] = START encryption (Engages Key Lockout). |
| 0x24 | STATUS | Read | bit[0]=DONE, bit[1]=BUSY, bit[2]=KEY_LOCKED. |
| 0x28–0x34 | CIPHER_W0..W3 | Read | 128-bit ciphertext output. |

---

## Repository Structure

```
├── constraints/
│   └── tqvp_belllabs_aes128.sdc
├── docs/
│   ├── dp1/
│   │   └── DP1_Report.md
│   ├── dp2/
│   │   ├── DP2_Baseline_Analysis.md
│   │   ├── DP2_Comparison_Report.md
│   │   ├── DP2_Report.md
│   │   ├── DP2_STA_Report.md
│   │   └── DP2_Tradeoff_Analysis.md
│   ├── dp3/
│   │   ├── DP3_Security_Evaluation_Report.md
│   │   ├── DP3_Security_Review.md
│   │   ├── DP3_Mitigation_Plan.md
│   │   └── DP3_Timing_Analysis.md
│   └── dp4/
│       └── Final_Project_Report.md
├── logs/
│   ├── dp1/
│   │   └── dp1_prompts.txt
│   ├── dp2/
│   │   └── dp2_prompts.txt
│   ├── dp3/
│   │   └── dp3_prompts.txt
│   └── dp4/
│       ├── dp4_prompts.txt
│       └── openlane.log
├── reports/
│   ├── dp1/
│   │   ├── ppa_baseline.txt
│   │   └── synthesis_log.txt
│   ├── dp2/
│   │   ├── dp2_final_metrics.txt
│   │   ├── final_power.rpt
│   │   └── post_opt_synthesis.txt
│   ├── dp3/
│   │   ├── synthesis_results.txt
│   │   └── sta_results.txt
│   └── dp4/
│       └── Sign-off_Reports/
│           ├── manufacturability.rpt (0 DRC Proof)
│           └── metrics.csv           (PPA Final)
├── src/
│   └── aes128/
│       └── aes128_peripheral.v
├── test/
│   └── aes128/
│       ├── tb_aes128.v          (Regression)
│       └── tb_aes128_security.v (Security Suite)
├── .gitignore
├── LICENSE
└── README.md
```

---

## How to Simulate

### Regression Suite
```bash
# Run Standard Regression (NIST Vectors)
iverilog -o sim_aes128 \
  src/aes128/aes128_peripheral.v \
  test/aes128/tb_aes128.v -s tb_aes128
vvp sim_aes128
```

### Security Suite
```bash
# Run Security Validation (Masking, Lockout, Timing)
iverilog -o sim_security \
  src/aes128/aes128_peripheral.v \
  test/aes128/tb_aes128_security.v
vvp sim_security
```

---

## How to Synthesize & Route

```bash
# Run DP1 Baseline Synthesis
yosys scripts/synth_dp1.ys 2>&1 | tee reports/dp1/synthesis_log.txt

# Run DP2 Optimization & STA Analysis
yosys scripts/synth_dp2_sta.ys 2>&1 | tee reports/dp2/openlane_run.txt

# Run DP3 Security Synthesis
yosys scripts/synth_dp3.ys 2>&1 | tee reports/dp3/synthesis_results.txt

# Run DP4 Final Physical Design Tape-out (OpenLane)
./flow.tcl -design . -tag FINAL_SIGN_OFF
```

---

## Tools Used

| Tool | Version | Purpose |
|------|---------|---------|
| Yosys | 0.62+9 | Logic synthesis |
| Icarus Verilog | — | RTL simulation |
| OpenLane | 1.0.2 | Physical design flow |
| Sky130 PDK | — | Standard cell library |
| Antigravity (Gemini+GPT) | — | AI-Agentic Coding & Security Hardening |
| Claude (Anthropic) | Sonnet 4 | PPA Optimization & Architectural Design |

---

## Key Resources

- [AI-HDL Official Website](https://csm.arizona.edu/AIHDL)
- [Competition GitHub](https://github.com/prismlabarizona/AIHDL-2026)
- [TinyQV RISC-V Base Core](https://github.com/TinyTapeout/ttsky25a-tinyQV)

---

## Submission Tags

| Tag | Phase | Description |
|-----|-------|-------------|
| `DP1-Submission` | Design Phase 1 | AES-128 module synthesized and verified |
| `DP2-Submission` | Design Phase 2 | PPA optimized with clock-gating & sign-off reports |
| `DP3-Submission` | Design Phase 3 | SCA Hardened & Timing Invariant Release |
| `DP4-Submission` | Design Phase 4 | Final GDSII Tape-out (0 DRC / 0 LVS) |

---

*Team Bell Labs — University of Lagos, Nigeria — AI-HDL 2026*
