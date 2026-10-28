# Team Acona — AES-128 Crypto Accelerator
## AI-HDL 2026 | Design Phase 3: Security Evaluation & Threat Mitigation

---

## Overview

This repository contains Team Acona's AES-128 crypto accelerator for the TinyQV RISC-V processor (RV32EC @ 64 MHz). Design Phase 3 focuses on identifying hardware security vulnerabilities in our PPA-optimized DP2 design and implementing countermeasures to harden it against real-world attacks.

**Key Results:**
- 4 security countermeasures implemented
- 50/50 comprehensive security tests passing
- 3.5% area overhead (37,025 → 38,312 cells)
- Full NIST FIPS-197 compliance maintained
- 22-cycle encryption latency preserved

---

## Security Countermeasures

| # | Countermeasure | Target Attack | CWE | Area Cost |
|---|---|---|---|---|
| 1 | S-Box Power Hiding (dual S-Box + LFSR) | DPA side-channel | CWE-1300 | +511 cells |
| 2 | KEY_LOCK register (sticky write-once) | Key theft via register read | CWE-1231 | +626 cells |
| 3 | Key Zeroization (single-cycle clear) | Key persistence after use | CWE-1259 | included above |
| 4 | Fault Detection (shadow round counter) | Round-skip glitch attacks | CWE-1243 | +27 cells |

---

## Repository Structure

```
Acona-Tech-AI-HDL-2026/
│
├── RTL/                              # DP3 Security-Hardened RTL
│   ├── aes_core_secure.sv            #   Hardened AES core (masked S-Boxes + fault signals)
│   ├── aes_reg_interface_secure.sv   #   Hardened register interface (KEY_LOCK, ZEROIZE)
│   ├── tqvp_aes128_secure.sv         #   Hardened top-level wrapper
│   ├── aes_sbox_masked.sv            #   Power-hiding S-Box wrapper
│   ├── aes_masking_lfsr.sv           #   32-bit Galois LFSR for masking
│   ├── aes_fault_detector.sv         #   Shadow round counter
│   └── aes_sbox.sv                   #   Base S-Box (unchanged)
│
├── rtl_optimized/                    # DP2 Baseline + Shared Modules
│   ├── aes_core_fast_v2.sv           #   DP2 AES core (baseline)
│   ├── aes_reg_interface.sv          #   DP2 register interface (baseline)
│   ├── tqvp_aes128_opt_v4.sv         #   DP2 top-level (baseline)
│   ├── aes_sbox.sv                   #   AES S-Box
│   ├── aes_mixcolumns_fast.sv        #   Fast MixColumns
│   ├── aes_key_expansion_unrolled.sv #   Unrolled key expansion
│   └── aes_clock_gate.sv             #   ICG cells
│
├── Security_Assessment/              # CIA / STRIDE / DREAD Analysis
│   ├── security_review.md            #   Full threat model
│   ├── mitigation_plan.md            #   Countermeasure details + PPA cost
│   └── vulnerability_checklist.md    #   CWE checklist with validation status
│
├── Validation_Testbenches/           # Security Testbenches
│   └── tb_aes128_security.sv         #   16-group testbench (50 checks)
│
├── Synthesize_Compare/               # Yosys Synthesis Reports
│   ├── dp2_baseline_synth.txt        #   DP2 baseline (37,025 cells)
│   └── dp3_secure_synth.txt          #   DP3 secure (38,312 cells)
│
├── Documents/                        # DP3 Documentation
│   ├── security_review.md            #   Security review document
│   ├── mitigation_plan.md            #   Mitigation plan
│   └── vulnerability_checklist.md    #   Vulnerability checklist
│
├── Prompt_Logs/                      # LLM Interaction Logs
│   └── Prompt_Logs_1.png             #Prompt Logs Photo
│   └── Prompt_Logs_2.png             #Prompt Logs Photo
│   └── Prompt_Logs_3.png             #Prompt Logs Photo
│   └── Prompt_Logs_4.png             #Prompt Logs Photo
│
├── .gitignore
└── README.md
```

---

## Building and Testing

### Prerequisites
- Icarus Verilog (`iverilog`) for simulation
- Yosys for synthesis
- Git for version control

### Compile and Run Security Tests

```bash
iverilog -g2012 -o tb_security \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns_fast.sv \
    rtl_optimized/aes_key_expansion_unrolled.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/aes_masking_lfsr.sv \
    rtl_optimized/aes_sbox_masked.sv \
    rtl_optimized/aes_fault_detector.sv \
    rtl_optimized/aes_core_secure.sv \
    rtl_optimized/aes_reg_interface_secure.sv \
    rtl_optimized/tqvp_aes128_secure.sv \
    tb/security/tb_aes128_security.sv

vvp tb_security
```

### Expected Output

```
============================================================
  DP3 COMPREHENSIVE SECURITY VALIDATION
  Team Acona | AES-128 | TinyQV 64MHz
  16 Test Groups | DPA + Fault + Adversarial
============================================================

--- TEST 1: NIST FIPS-197 Regression (Design Stability) ---
  [PASS] NIST App.B
  [PASS] NIST App.C.1
  [PASS] Zero key+pt
  ...
--- TEST 13: DPA Resistance Measurement ---
  Hamming weight stats over 32 encryptions:
    Average HW: 63 (ideal=64)
    Min HW: 54  Max HW: 74  Range: 20
  [PASS] Average HW in expected range (44-84)
  [PASS] HW range=20 shows good diffusion
  [PASS] No significant input-output HW correlation
  ...
============================================================
  RESULTS: 50/50 passed
  STATUS: ALL TESTS PASSED
============================================================
```

---

## PPA Overhead Analysis

| Metric | DP2 Baseline | DP3 Secure | Overhead |
|---|---|---|---|
| Total Cells | 37,025 | 38,312 | +1,287 (+3.5%) |
| Registers (DFF) | 2,274 | 2,350 | +76 (+3.3%) |
| Encryption Latency | 22 cycles | 22 cycles | +0 |
| Target Frequency | 64 MHz | 64 MHz | Met |

### Per-Module Comparison

| Module | DP2 Cells | DP3 Cells | Delta |
|---|---|---|---|
| aes_core | 2,183 | 2,593 | +410 (masked S-Boxes) |
| aes_reg_interface | 819 | 1,445 | +626 (security regs) |
| aes_fault_detector | — | 27 | +27 (new) |
| aes_masking_lfsr | — | 101 | +101 (new) |
| Top wrapper | 18 | 150 | +132 (suppression) |
| Key expansion | 6,458 | 6,455 | -3 (unchanged) |

---

## Secure Register Map

| Offset | Register | Access | Description |
|---|---|---|---|
| 0x00 | CTRL | R/W | [0]=START, [1]=DECRYPT |
| 0x04 | STATUS | R | [0]=BUSY, [1]=DONE, [3]=KEY_VALID |
| 0x10-0x1C | KEY[0:3] | W (locked: none) | 128-bit secret key |
| 0x20-0x2C | DIN[0:3] | W | 128-bit plaintext input |
| 0x30-0x3C | DOUT[0:3] | R | 128-bit ciphertext output |
| 0x40 | SECURITY_CTRL | R/W | [0]=KEY_LOCK, [1]=ZEROIZE |
| 0x44 | SECURITY_STATUS | R | [0]=LOCKED, [1]=ZEROIZED, [2]=FAULT, [3]=MASKING |
| 0x48 | LFSR_SEED | W | LFSR seed (locked after KEY_LOCK) |

---

## Secure Usage Protocol

```c
// 1. Seed the masking LFSR
write_reg(LFSR_SEED, random_seed);

// 2. Load secret key
write_reg(KEY0, key_word_0);
write_reg(KEY1, key_word_1);
write_reg(KEY2, key_word_2);
write_reg(KEY3, key_word_3);
wait_for(KEY_VALID);

// 3. Lock the key
write_reg(SECURITY_CTRL, 0x01);

// 4. Encrypt
write_reg(DIN0..DIN3, plaintext);
write_reg(CTRL, 0x01);
wait_for(DONE);
assert(!(read_reg(SECURITY_STATUS) & 0x04));  // No fault
ciphertext = read_reg(DOUT0..DOUT3);

// 5. Zeroize when finished
write_reg(SECURITY_CTRL, 0x02);
```

---

## Test Groups (16 Total, 50 Checks)

| # | Test Group | Checks | Target |
|---|---|---|---|
| 1 | NIST FIPS-197 Regression | 3 | Design stability |
| 2 | Key Lock Enforcement | 3 | CWE-1231 |
| 3 | Key Lock Persistence | 2 | CWE-1231 |
| 4 | Key Zeroization | 3 | CWE-1259 |
| 5 | Double Zeroize Edge Case | 3 | CWE-1259 |
| 6 | Masking Active | 1 | CWE-1300 |
| 7 | Masking Consistency | 5 | CWE-1300 |
| 8 | Multiple Plaintexts | 3 | Diffusion |
| 9 | LFSR Seed Lock | 1 | CWE-1231 |
| 10 | Fault Injection Detection | 5 | CWE-1243 |
| 11 | Reset Security State | 3 | CWE-1271 |
| 12 | Full Secure Protocol | 5 | End-to-end |
| 13 | DPA Resistance (Hamming Weight) | 3 | CWE-1300 |
| 14 | Timing Consistency | 1 | Constant-time |
| 15 | Adversarial Inputs | 5 | Robustness |
| 16 | Multiple Fault Attempts | 4 | CWE-1243 |

---

## Design Phase History

| Phase | Date | Focus | Key Achievement |
|---|---|---|---|
| DP1 | Jan 2026 | Base Design | NIST FIPS-197 compliant AES-128 |
| DP2 | Feb 2026 | PPA Optimization | Clock gating (88% idle savings), pipelined key fetch, 64 MHz |
| DP3 | Mar 2026 | Security Hardening | 4 countermeasures, 50/50 tests, +3.5% area |
| DP4 | Apr 2026 | Netlist to Tapeout | Upcoming |

---

## Team

**Team Acona**   
AI-HDL 2026 Competition  
University of Arizona Center for Semiconductor Manufacturing

---

## License

This project is part of the AI-HDL 2026 competition. See the competition repository for licensing terms.
