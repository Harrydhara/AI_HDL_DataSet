# DP3 Mitigation Plan
## Team Acona | AES-128 Crypto Accelerator | AI-HDL 2026

**Objective:** Address all CRITICAL and HIGH vulnerabilities identified in the Security Review using targeted hardware countermeasures with minimal PPA impact.

---

## 1. Prioritized Countermeasure Summary

| Priority | Countermeasure | Target CWE | DREAD Score | Target Vulnerability |
|---|---|---|---|---|
| P0 | S-Box Power Hiding | CWE-1300 | 8.4 (CRITICAL) | DPA side-channel on S-Box |
| P1 | Access Control + Key Lock | CWE-1231 | 8.4 (CRITICAL) | Key register read-back |
| P2 | Key Zeroization | CWE-1259 | 7.6 (HIGH) | Key persistence after use |
| P3 | Fault Detection | CWE-1243 | 6.6 (HIGH) | Round-skip glitch attacks |

---

## 2. Countermeasure Details

### 2.1 P0: S-Box Power Hiding (Anti-DPA)

**CWE:** CWE-1300 — Improper Protection of Physical Side Channels in Cryptographic Hardware

**Vulnerability:** The combinational S-Box lookup creates data-dependent switching activity. An attacker measuring power consumption during encryption can use Differential Power Analysis to correlate power traces with key hypotheses, recovering the 128-bit key byte by byte with ~1000 traces.

**Countermeasure:** Dual S-Box architecture. For each of the 16 encryption S-Box instances, we instantiate two S-Boxes in parallel:
- **Real S-Box:** Processes actual AES state byte, produces correct output
- **Dummy S-Box:** Processes randomized input (state XOR LFSR mask), produces unused output

**Implementation:**
- New module: `aes_sbox_masked.sv` — wrapper instantiating real + dummy S-Box pair
- New module: `aes_masking_lfsr.sv` — 32-bit Galois LFSR (polynomial: x^32 + x^22 + x^2 + x^1 + 1)
- Modified: `aes_core_secure.sv` — 16 encrypt S-Boxes replaced with masked versions
- LFSR seeded via `LFSR_SEED` register (0x48), locked after `KEY_LOCK`

**Security Rationale:** The dummy S-Box doubles switching activity on the power rail, making it significantly harder to correlate power with actual data values. The LFSR ensures different random inputs each cycle.

**PPA Cost:**
- Area: +410 cells in core + 101 cells for LFSR = +511 cells total
- Timing: No impact on critical path (dummy S-Box operates in parallel)
- Power: ~2x S-Box dynamic power (16 additional S-Box instances switching)
- Latency: +0 cycles (parallel operation)

**Validation:**
- DPA resistance test: Hamming weight analysis over 32 encryptions (avg HW=63, ideal=64)
- Correlation analysis: 12/31 monotonic transitions (uncorrelated, expected ~15-16)
- Masking consistency: 5 identical encryptions produce identical ciphertext

---

### 2.2 P1: Access Control + Key Lock (Anti-Key-Theft)

**CWE:** CWE-1231 — Improper Prevention of Lock Bit Modification

**Vulnerability:** Any software running on TinyQV can read and write all AES registers including the secret key. A compromised application or software vulnerability can directly exfiltrate the cryptographic key.

**Countermeasure:** Write-once sticky KEY_LOCK bit in SECURITY_CTRL register:
- When KEY_LOCK = 0: Key registers writable, LFSR seed writable
- When KEY_LOCK = 1: Key registers write-protected, reads return zero, LFSR seed locked
- KEY_LOCK can only be set to 1 (sticky); writing 0 has no effect
- Only ZEROIZE or hardware reset clears KEY_LOCK

**Implementation:**
- Modified: `aes_reg_interface_secure.sv`
  - New register: SECURITY_CTRL at offset 0x40 (bit[0] = KEY_LOCK, bit[1] = ZEROIZE)
  - New register: SECURITY_STATUS at offset 0x44 (read-only status bits)
  - New register: LFSR_SEED at offset 0x48 (write-only, locked after KEY_LOCK)
  - Key write logic gated by `!key_lock_reg`
  - Key read always returns zero (write-only by design)

**Secure Usage Protocol:**
1. Trusted firmware writes LFSR seed
2. Trusted firmware writes 128-bit key (4 × 32-bit writes)
3. Trusted firmware sets KEY_LOCK = 1
4. Application code can encrypt but cannot read/overwrite key
5. When finished, ZEROIZE erases all key material

**PPA Cost:**
- Area: +626 cells (expanded register file with security logic)
- Timing: No impact
- Power: Negligible
- Latency: +0 cycles

**Validation:**
- KEY_LOCK enforcement: Overwrite attempt after lock → original key still encrypts correctly
- Lock persistence: Writing 0 to SECURITY_CTRL → lock remains set
- Key read-back: Reading KEY0 returns 0x00000000
- LFSR seed lock: Seed write after KEY_LOCK → ignored, encryption unchanged

---

### 2.3 P2: Key Zeroization (Anti-Key-Persistence)

**CWE:** CWE-1259 — Improper Restriction of Security Token Assignment

**Vulnerability:** After encryption completes, the 128-bit key, all 11 expanded round keys (1,408 bits total), and the AES state register retain their values. If an attacker gains physical access or memory dump capability later, all key material is exposed.

**Countermeasure:** Hardware-enforced key erasure triggered by ZEROIZE bit:
- Setting SECURITY_CTRL bit[1] = 1 immediately clears:
  - Key register (128 bits)
  - All expanded round keys (11 × 128 = 1,408 bits) via reset pulse
  - AES state register (128 bits)
  - Round key pipeline register (128 bits)
  - Output register (128 bits)
- Zeroization completes in a single clock cycle
- KEY_LOCK is automatically cleared (new key load required)
- ZEROIZED status bit set in SECURITY_STATUS

**Implementation:**
- Modified: `aes_reg_interface_secure.sv` — zeroize_pulse generation
- Modified: `aes_core_secure.sv` — state_reg, round_key_reg, data_out cleared on zeroize
- Modified: `tqvp_aes128_secure.sv` — key expansion reset via `rst_n & ~zeroize_pulse`

**PPA Cost:**
- Area: Included in reg interface overhead (shared logic)
- Timing: No impact
- Power: Negligible
- Latency: +1 cycle (clear operation)

**Validation:**
- Zeroization: After zeroize, ZEROIZED=1, KEY_LOCK cleared
- Re-key after zeroize: New key loads and encrypts correctly
- Double zeroize: Two consecutive zeroize commands handled without fault
- Fault flag cleared by zeroize

---

### 2.4 P3: Fault Detection (Anti-Glitch)

**CWE:** CWE-1243 — Sensitive Non-Volatile Information Not Protected During Debug

**Vulnerability:** Fault injection attacks (voltage glitching, clock manipulation) can cause the AES FSM to skip rounds. A 10-round AES reduced to 8 or fewer rounds produces weak ciphertext analyzable through Differential Fault Analysis (DFA) to recover the key. A single successful fault injection can compromise the entire key.

**Countermeasure:** Independent shadow round counter with completion check:
- Shadow counter increments on `round_start` pulse from AES core FSM
- Resets on `encryption_start`
- At encryption completion, verifies: shadow_count == 9 AND fsm_round_count == 10
- Any mismatch sets sticky FAULT_DETECTED flag
- When fault detected: ciphertext output forced to all zeros, DONE signal suppressed

**Implementation:**
- New module: `aes_fault_detector.sv` — 27 cells
- Modified: `aes_core_secure.sv` — generates round_start and encryption_start pulses
- Modified: `tqvp_aes128_secure.sv` — ciphertext suppression logic:
  ```
  assign dout_to_reg = fault_detected ? 128'h0 : core_dout;
  assign core_done_gated = core_done & ~fault_detected;
  ```

**PPA Cost:**
- Area: +27 cells (shadow counter + comparator) + ~132 cells (suppression logic)
- Timing: No impact on critical path
- Power: Negligible (4-bit counter + comparator)
- Latency: +0 cycles

**Validation:**
- Fault injection: Force shadow_count to wrong value → FAULT_DETECTED=1
- Ciphertext suppression: Output = 0x000...0 during fault
- Sticky flag: Fault persists across subsequent encryption attempts
- Recovery: ZEROIZE clears fault, normal operation resumes
- Clean-then-fault: First encryption correct, second (faulted) detected

---

## 3. Total PPA Overhead

| Metric | DP2 Baseline | DP3 Secure | Delta |
|---|---|---|---|
| Total Cells | 37,025 | 38,312 | +1,287 (+3.5%) |
| Encryption Latency | 22 cycles | 22 cycles | +0 |
| Target Frequency | 64 MHz | 64 MHz | Met |
| Registers (DFF) | 2,274 | 2,350 | +76 (+3.3%) |

**Per-feature cost breakdown:**

| Feature | Cells Added | % of Total Overhead |
|---|---|---|
| S-Box Power Hiding (16 dummy S-Boxes) | 410 | 31.9% |
| Access Control + Key Lock + Zeroize | 626 | 48.6% |
| Fault Detector | 27 | 2.1% |
| LFSR | 101 | 7.8% |
| Top-level suppression logic | 123 | 9.6% |
| **Total** | **1,287** | **100%** |

---

## 4. Residual Risks and Future Work

| Risk | Severity | Mitigation Path |
|---|---|---|
| Higher-order DPA (2nd order+) | MEDIUM | True Boolean masking with masked S-Box ROM |
| Electromagnetic side-channel | LOW | Metal shielding (physical design, DP4) |
| Multi-fault simultaneous attack | LOW | Triple modular redundancy (TMR) on FSM |
| Bus snooping between CPU and peripheral | LOW | Encrypted bus protocol (out of scope) |
| Formal verification of security properties | MEDIUM | SVA assertions on KEY_LOCK invariants |

---

## 5. Secure Register Map

| Offset | Register | Access | Description |
|---|---|---|---|
| 0x00 | CTRL | R/W | [0]=START, [1]=DECRYPT |
| 0x04 | STATUS | R | [0]=BUSY, [1]=DONE, [3]=KEY_VALID, [4]=DIN_VALID |
| 0x08 | INT_EN | R/W | Interrupt enable |
| 0x0C | INT_STAT | R/W1C | Interrupt status |
| 0x10-0x1C | KEY[0:3] | W (locked: none) | 128-bit secret key |
| 0x20-0x2C | DIN[0:3] | W | 128-bit plaintext |
| 0x30-0x3C | DOUT[0:3] | R | 128-bit ciphertext |
| 0x40 | SECURITY_CTRL | R/W | [0]=KEY_LOCK (sticky), [1]=ZEROIZE |
| 0x44 | SECURITY_STATUS | R | [0]=LOCKED, [1]=ZEROIZED, [2]=FAULT, [3]=MASKING |
| 0x48 | LFSR_SEED | W | 32-bit LFSR seed (locked after KEY_LOCK) |
