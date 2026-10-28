# DP3 Security Review Document
## Team Acona | AES-128 Crypto Accelerator | AI-HDL 2026

**Design Under Review:** AES-128 Crypto Accelerator (DP2 Optimized v4)  
**Target Platform:** TinyQV RISC-V (RV32EC @ 64 MHz)  
**Peripheral Address Range:** 0x80000000 – 0x800007FF  
**Review Date:** March 2026

---

## 1. CIA Triad Analysis

### 1.1 Confidentiality

**Requirement:** The 128-bit secret key must never leak to unauthorized parties through any channel — software read-back, side-channel emissions, or residual data in registers.

**DP2 Status: VULNERABLE**

- Key registers have no access control; any software on TinyQV can read/write freely
- S-Box lookup creates data-dependent power consumption exploitable via Differential Power Analysis (DPA)
- Key material persists in registers after encryption completes
- No mechanism to erase key data after use
- LFSR seed (if used) has no protection

**DP3 Mitigations Applied:**
- KEY_LOCK register prevents key read-back and overwrite after initial load
- Power-hiding dual S-Box decorrelates power from secret data
- Key zeroization clears all key material on command
- LFSR seed locked after KEY_LOCK is set

### 1.2 Integrity

**Requirement:** Encryption output must exactly match NIST FIPS-197 specification. Fault attacks must not produce exploitable weak ciphertext.

**DP2 Status: PARTIALLY MET**

- AES output verified correct against NIST test vectors
- No fault detection mechanism; clock/voltage glitching can skip rounds undetected
- Weak ciphertext from skipped rounds enables Differential Fault Analysis (DFA) to recover key
- No redundancy in round counting

**DP3 Mitigations Applied:**
- Shadow round counter independently tracks encryption progress
- Mismatch between FSM counter and shadow counter triggers FAULT_DETECTED flag
- Ciphertext output forced to zero when fault detected (prevents DFA)
- DONE signal suppressed during fault condition

### 1.3 Availability

**Requirement:** Accelerator must remain operational under normal and adversarial conditions. No denial-of-service via malformed inputs.

**DP2 Status: ACCEPTABLE**

- FSM handles invalid states with default transitions to IDLE
- Clock gating does not create lockout conditions
- Bounded encryption latency (22 cycles)
- CPU controls request rate

**DP3 Status: MAINTAINED**

- Fault flag is recoverable via ZEROIZE command
- Double-zeroize edge case handled correctly (no lockout)
- Invalid register addresses return zero (no bus errors)
- All security features recoverable via hardware reset

---

## 2. STRIDE Threat Analysis

### 2.1 Spoofing

**Threat:** Unauthorized software impersonates trusted firmware to access crypto registers.

**Attack Vector:** Malicious application on TinyQV reads key registers or initiates unauthorized encryptions.

**DP2 Risk: HIGH** — No authentication on peripheral bus, any code can access all registers.

**DP3 Mitigation:** KEY_LOCK register creates a trust boundary. Trusted firmware writes the key and sets KEY_LOCK; subsequent software (including compromised apps) cannot read or overwrite the key. LFSR seed is also locked.

**Residual Risk: LOW** — Attacker cannot extract or modify the key after lock. Encryption operations remain available (by design — the accelerator is a shared resource).

### 2.2 Tampering

**Threat:** Attacker modifies data or control flow to produce exploitable output.

**Attack Vector:** Voltage glitching or clock manipulation causes FSM to skip AES rounds, producing weak ciphertext for DFA.

**DP2 Risk: HIGH** — No integrity checks on round computation.

**DP3 Mitigation:** Redundant shadow round counter detects round-skip attacks. Ciphertext suppressed to zero on fault. Sticky fault flag prevents subsequent use until explicit recovery.

**Residual Risk: LOW** — Single-fault attacks detected. Multi-fault simultaneous attacks on both counters remain theoretical.

### 2.3 Repudiation

**Threat:** Attacker denies performing an action on the crypto accelerator.

**Attack Vector:** No logging of key load or encryption operations.

**DP2 Risk: LOW** — Not critical for embedded crypto peripheral.

**DP3 Status:** Not addressed (low priority). SECURITY_STATUS register provides current state but not historical audit trail.

### 2.4 Information Disclosure

**Threat:** Secret key leaks through unintended channels.

**Attack Vectors:**
1. Direct register read-back of key
2. DPA/SPA side-channel on S-Box power consumption
3. Key residue in registers after operation
4. Timing variations leaking key-dependent information

**DP2 Risk: CRITICAL** — Primary threat to AES confidentiality.

**DP3 Mitigations:**
1. KEY_LOCK prevents read-back (returns zero)
2. Dual S-Box power-hiding decorrelates power from data
3. Key zeroization erases all key material
4. Constant-time design verified (all encryptions take same cycle count)

**Residual Risk: MEDIUM** — Power-hiding is not provably secure against higher-order DPA. True Boolean masking would provide stronger guarantees.

### 2.5 Denial of Service

**Threat:** Attacker prevents normal operation of the accelerator.

**Attack Vector:** Repeated encryption requests blocking CPU; FSM stall.

**DP2 Risk: LOW** — Bounded latency; CPU controls request rate.

**DP3 Status:** Maintained. Fault condition is recoverable via ZEROIZE.

### 2.6 Elevation of Privilege

**Threat:** Attacker gains higher access than authorized.

**Attack Vector:** Any code on TinyQV can read/write all crypto registers equally; no privilege levels.

**DP2 Risk: HIGH** — No privilege differentiation.

**DP3 Mitigation:** KEY_LOCK creates a one-way privilege boundary. Before lock: full access (trusted firmware). After lock: key protected, encryption available, seed locked.

**Residual Risk: LOW** — Lock is hardware-enforced and cannot be bypassed by software.

---

## 3. DREAD Risk Scoring

Scale: 1 (lowest) to 10 (highest risk)

| Vulnerability | Damage | Reproducibility | Exploitability | Affected Users | Discoverability | Average | Priority |
|---|---|---|---|---|---|---|---|
| DPA Side-Channel on S-Box | 9 | 9 | 7 | 8 | 9 | **8.4** | CRITICAL |
| Key Register Read-Back | 9 | 9 | 9 | 7 | 8 | **8.4** | CRITICAL |
| No Key Zeroization | 8 | 8 | 8 | 6 | 8 | **7.6** | HIGH |
| Round-Skip Fault Injection | 8 | 7 | 6 | 5 | 7 | **6.6** | HIGH |
| Timing Side-Channel | 5 | 6 | 4 | 4 | 5 | **4.8** | MEDIUM |
| FSM State Manipulation | 4 | 5 | 3 | 3 | 4 | **3.8** | LOW |

**DREAD Legend:**
- D = Damage potential (how bad if exploited)
- R = Reproducibility (how easy to reproduce)
- E = Exploitability (how easy to launch attack)
- A = Affected users (how many impacted)
- D = Discoverability (how easy to find the vulnerability)

---

## 4. Security Architecture (DP3 Hardened)

```
TinyQV CPU
    |
    | Peripheral Bus (7-bit address)
    v
+--------------------------------------------------+
| tqvp_aes128_secure (Top Level)                   |
|                                                    |
| +------------------+    +----------------------+  |
| | aes_masking_lfsr |    | aes_fault_detector   |  |
| | (32-bit Galois)  |    | (shadow round cnt)   |  |
| +--------+---------+    +----------+-----------+  |
|          |                          |              |
| +--------v--------------------------v-----------+ |
| | aes_core_secure                                | |
| |  - 16x aes_sbox_masked (power hiding)         | |
| |  - 16x aes_sbox (decrypt, unmasked)            | |
| |  - 2x aes_mixcolumns_fast                      | |
| |  - Pipelined key fetch (22 cycles)              | |
| |  - Zeroize support on all state registers       | |
| +------------------------------------------------+ |
|                                                    |
| +------------------------------------------------+ |
| | aes_reg_interface_secure                        | |
| |  - KEY_LOCK (sticky write-once)                 | |
| |  - ZEROIZE (single-cycle clear)                 | |
| |  - LFSR_SEED (locked after KEY_LOCK)            | |
| |  - SECURITY_STATUS (read-only)                  | |
| +------------------------------------------------+ |
|                                                    |
| +------------------------------------------------+ |
| | aes_key_expansion_unrolled (unchanged)          | |
| | 2x aes_clock_gate (unchanged)                  | |
| +------------------------------------------------+ |
|                                                    |
| Ciphertext suppression: output = fault ? 0 : ct   |
| Done gating: done = core_done & ~fault_detected    |
+--------------------------------------------------+
```

---

## 5. Conclusion

The DP2 AES-128 design had four CRITICAL/HIGH vulnerabilities in its security posture. Through systematic CIA, STRIDE, and DREAD analysis, we identified and prioritized these threats, then implemented four targeted countermeasures. The DP3 hardened design reduces all identified risks to LOW/MEDIUM levels while maintaining full NIST FIPS-197 compliance and adding only 3.5% area overhead.
