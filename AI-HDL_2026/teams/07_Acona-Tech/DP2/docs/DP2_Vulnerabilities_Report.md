# Team Acona | DP3 Security Report

## AI-HDL 2026  
### Design Phase 3  
### Security Evaluation & Threat Mitigation Report  

**AES-128 Crypto Accelerator**  
for TinyQV RISC-V (RV32EC @ 64 MHz)  

**Team Acona**  

---

## Table of Contents
1. Executive Summary  
2. Design Under Evaluation  
3. Threat Model and Security Assessment  
4. Mitigation Plan  
5. Countermeasure Implementation Details  
6. Secure Register Map  
7. Validation and Hardening Results  
8. PPA Overhead Analysis  
9. Security Posture Summary  
10. Conclusion and Lessons Learned  
Appendix A: Secure Usage Protocol  

---

## 1. Executive Summary

This report presents the security evaluation and threat mitigation work performed on Team Acona's AES-128 crypto accelerator design during Design Phase 3 (DP3) of the AI-HDL 2026 competition.

The accelerator is integrated as a memory-mapped peripheral for the TinyQV RISC-V processor (RV32EC architecture, 64 MHz target frequency).

Starting from our PPA-optimized DP2 design featuring:
- Clock gating  
- Fast MixColumns  
- Unrolled key expansion  
- Pipelined key fetch  

We conducted a comprehensive security audit using:
- CIA Triad  
- STRIDE  
- DREAD  

### Identified Vulnerabilities
Six vulnerability categories were identified.

### Implemented Countermeasures
- S-Box Boolean masking with LFSR-based randomness (anti-DPA)
- Memory-mapped access control with key lock registers
- Automatic and on-demand key zeroization
- Fault detection via redundant round computation

All countermeasures were validated through attack testbenches and NIST FIPS-197 regression testing.

---

## 2. Design Under Evaluation

### 2.1 System Architecture

- Memory-mapped peripheral (0x80000000 – 0x800007FF)
- 128-bit AES encryption (FIPS-197 compliant)

**Key Features:**
- 128-bit datapath with 32-bit interface  
- 10-round iterative AES core  
- Pre-computed round keys  
- Clock gating (88% idle power reduction)  
- Pipelined key fetch  

---

### 2.2 DP2 Baseline Metrics

| Metric | DP2 Value | Target |
|------|--------|--------|
| Total Cells | ~24,775 | Minimize |
| Max Frequency | 64+ MHz | 64 MHz |
| Encryption Cycles | 22 cycles | < 30 |
| Idle Power | ~12% | Minimize |

---

### 2.3 RTL Module Hierarchy

| Module | Function |
|------|--------|
| tqvp_aes128_top_opt | Top-level wrapper |
| aes_reg_interface | Register file |
| aes_core | AES engine |
| aes_sbox | S-Box lookup |
| aes_mixcolumns | MixColumns |
| aes_key_expansion | Key schedule |
| aes_clock_gate | Power gating |

---

## 3. Threat Model and Security Assessment

### 3.1 CIA Triad Analysis

| Principle | Requirement | DP2 Status |
|----------|------------|-----------|
| Confidentiality | Protect key | ❌ Vulnerable |
| Integrity | Correct output | ⚠️ Partial |
| Availability | System operational | ✅ Acceptable |

---

### 3.2 STRIDE Analysis

| Threat | Risk |
|------|------|
| Spoofing | HIGH |
| Tampering | HIGH |
| Repudiation | LOW |
| Info Disclosure | CRITICAL |
| DoS | LOW |
| Privilege Escalation | HIGH |

---

### 3.3 DREAD Scoring

| Vulnerability | Score |
|--------------|------|
| DPA Side-Channel | 8.4 (CRITICAL) |
| Key Read-Back | 8.4 (CRITICAL) |
| No Zeroization | 7.6 (HIGH) |
| Fault Injection | 6.6 (HIGH) |
| Timing Attack | 4.8 (MEDIUM) |

---

### 3.4 CWE Mapping

| CWE | Issue |
|-----|------|
| CWE-1300 | Side-channel leakage |
| CWE-1231 | Key lock weakness |
| CWE-1259 | No key erase |
| CWE-1243 | Fault attack vulnerability |
| CWE-1271 | Reset issues |

---

## 4. Mitigation Plan

| Priority | Countermeasure | Target |
|---------|--------------|--------|
| P0 | S-Box Masking | DPA |
| P1 | Key Lock | Key theft |
| P2 | Zeroization | Key residue |
| P3 | Fault Detection | Glitch attacks |

---

## 5. Countermeasure Implementation

### 5.1 S-Box Masking
- LFSR-generated masks  
- XOR masking before/after S-Box  
- Protects against DPA  

---

### 5.2 Access Control & Key Lock
- Write-once KEY_LOCK  
- Prevents read-back  
- Enforces privilege  

---

### 5.3 Key Zeroization
- Clears all key material instantly  
- Triggered automatically or manually  

---

### 5.4 Fault Detection
- Shadow round counter  
- Detects skipped rounds  
- Suppresses faulty output  

---

## 6. Secure Register Map

| Offset | Register | Description |
|-------|--------|------------|
| 0x00–0x0F | KEY | AES key |
| 0x10–0x1F | PLAINTEXT | Input |
| 0x20–0x2F | CIPHERTEXT | Output |
| 0x30 | SECURITY_CTRL | Control |
| 0x34 | SECURITY_STATUS | Status |
| 0x38 | LFSR_SEED | Mask seed |
| 0x3C | CTRL/STATUS | Control |

---

## 7. Validation Results

| Test | Result |
|-----|------|
| DPA Resistance | PASS |
| Key Lock | PASS |
| Zeroization | PASS |
| Fault Injection | PASS |
| NIST Tests | PASS |

---

## 8. PPA Overhead Analysis

| Feature | Area | Power | Latency |
|--------|------|------|--------|
| Masking | +8–12% | +5–8% | 0 |
| Lock | +1–2% | negligible | 0 |
| Zeroization | <1% | negligible | +1 cycle |
| Fault Detection | +2–3% | +1–2% | 0 |

**Total Overhead:**  
- Area: +12–18%  
- Power: +6–10%  
- Latency: +1 cycle  

---

## 9. Security Posture Summary

| CWE | Status |
|-----|------|
| Side-channel | ✅ Mitigated |
| Key exposure | ✅ Mitigated |
| Key persistence | ✅ Mitigated |
| Fault attacks | ✅ Mitigated |

---

## 10. Conclusion

DP3 successfully transformed the AES accelerator into a **secure cryptographic engine**.

### Key Lessons:
- Structured frameworks (STRIDE, DREAD) are essential  
- Masking is powerful but costly  
- Key management is low-cost, high-impact  
- Fault detection adds strong defense  

The design:
- Meets 64 MHz target  
- Maintains full correctness  
- Adds only ~12–18% area overhead  

---

## Appendix A: Secure Usage Protocol

1. Write LFSR seed  
2. Load key  
3. Set KEY_LOCK  
4. Verify lock  
5. Load plaintext  
6. Start encryption  
7. Wait for DONE  
8. Read ciphertext  
9. Trigger ZEROIZE  

---
**Team Acona | AI-HDL 2026 | March 2026**
