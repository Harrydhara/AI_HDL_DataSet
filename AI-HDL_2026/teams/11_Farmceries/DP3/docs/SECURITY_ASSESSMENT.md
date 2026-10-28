# DP-3 Security Assessment: Secure UART + AES-128 Peripheral

**Team:** Farmceries | **Phase:** DP-3 Security Evaluation
**Design Under Analysis:** `secure_uart_peripheral.v` (top) + `aes_uart_streaming.v` + AES-128 core
**Date:** April 2026

---

## 1. System Description and Threat Boundary

The design is a hardware UART peripheral with integrated AES-128 encryption, connected to the
TinyQV RISC-V CPU core via a 32-bit memory-mapped register bus. The design was submitted and
optimized in DP-1 and DP-2 respectively.

```
[CPU / Software]
      │ 32-bit register bus (address[5:0], data_in[31:0], data_write_n[1:0])
      ▼
 ┌─────────────────────────────────────────┐
 │       secure_uart_peripheral            │
 │  ┌─────────────────────────────────┐   │
 │  │  Register File (AES_KEY, CTRL)  │   │
 │  │  SEC_CTRL unlock FSM            │   │
 │  └───────────────┬─────────────────┘   │
 │                  │                     │
 │  ┌───────────────▼─────────────────┐   │
 │  │  aes_uart_streaming             │   │
 │  │  (TX: plaintext→AES→UART TX)   │   │
 │  │  (RX: UART RX→AES→plaintext)   │   │
 │  └─────────────────────────────────┘   │
 │      │ uart_tx_pin     ▲ uart_rx_pin   │
 └──────┼─────────────────┼───────────────┘
        ▼                 │
    [Physical UART Bus — untrusted medium]
```

**Trust boundaries:**
- **Trusted:** CPU register interface (internal on-chip bus)
- **Untrusted:** Physical UART RX pin (external, attacker-controlled)
- **Sensitive assets:** 128-bit AES key (`aes_key_reg`), AES enable state (`aes_enable_reg`)

---

## 2. CIA Triad Analysis

### Confidentiality
The goal: ensure AES key material and plaintext data remain secret.

| Asset | Confidentiality Risk |
|-------|---------------------|
| `aes_key_reg [127:0]` | **HIGH** — stored in 4× 32-bit registers (`AES_KEY0–3`), directly readable via register bus if no access control |
| `rx_data_buffer [7:0]` | **MEDIUM** — decrypted plaintext sits in a register; any CPU read of `RX_DATA (0x0C)` sees it |
| `tx_plaintext_buf [127:0]` | **LOW** — internal pipeline register, not CPU-accessible |
| UART TX wire (ciphertext) | **LOW** — wire carries AES-128 ciphertext; confidential as long as key is secret |

**Verdict:** Without access control, the AES key can be read back in plaintext by any software that has bus access — the primary confidentiality threat.

### Integrity
The goal: ensure configuration registers cannot be silently altered by an attacker.

| Asset | Integrity Risk |
|-------|---------------|
| `AES_CTRL (0x20)` | **HIGH** — writing AES_EN=0 silently disables encryption; attacker disabling AES means UART transmits unencrypted |
| `AES_KEY[0–3] (0x28–0x34)` | **HIGH** — overwriting key corrupts all future encryption/decryption without visible indication |
| `UART_CTRL (0x00)` baud_sel | **MEDIUM** — setting baud_sel=0 may cause a divide-by-zero hang, disrupting operation |
| UART RX frame data | **MEDIUM** — no UART frame authentication; any device can inject bytes (protocol-level limitation) |

**Verdict:** Without write protection, a compromised software layer or a rogue bus master can corrupt AES state undetected.

### Availability
The goal: ensure the UART peripheral is always ready when needed.

| Attack Vector | Availability Risk |
|---------------|------------------|
| `baud_sel=0` write to `UART_CTRL` | **HIGH** — zero divisor could freeze baud generator FSM |
| Flood RX with bogus frames | **MEDIUM** — no rate limiting; repeated bad frames fill `rx_data_buffer` and block CPU reads |
| Indefinite AES lock (keep sending wrong unlock words) | **LOW** — lock FSM is stateless except `sec_key_stage1_seen`; wrong word just increments counter, no permanent lock-out |
| AES encrypt/decrypt stall | **LOW** — AES core has a `done` signal; no deadlock path identified in RTL review |

**Verdict:** The primary availability threat is the zero-divisor baud rate attack; all other paths are low risk or mitigated by design.

---

## 3. STRIDE Threat Table

| # | Category | Threat | Attack Surface | Severity |
|---|----------|--------|---------------|----------|
| S1 | **Spoofing** | Attacker injects UART frames pretending to be a trusted sender | `uart_rx_pin` | Medium |
| S2 | **Spoofing** | Rogue bus master impersonates CPU to write AES key | Register bus | High |
| T1 | **Tampering** | Overwrite `AES_KEY` registers to corrupt future ciphertext silently | `AES_KEY0–3` registers | High |
| T2 | **Tampering** | Write `AES_CTRL.AES_EN=0` to disable encryption | `AES_CTRL` register | High |
| T3 | **Tampering** | Write `baud_sel=0` to freeze baud generator (DoS) | `UART_CTRL` register | Medium |
| R1 | **Repudiation** | No logging of register write attempts; violation counter is the only audit trail | `SEC_STATUS` | Low |
| I1 | **Information Disclosure** | Read `AES_KEY[0–3]` registers in plaintext while unlocked | `AES_KEY0–3` registers | High |
| I2 | **Information Disclosure** | Read `RX_DATA` register containing last decrypted byte | `RX_DATA` register | Medium |
| I3 | **Information Disclosure** | Side-channel power analysis on AES S-box operations | Physical implementation | Medium |
| D1 | **Denial of Service** | Zero baud_sel value freezes UART timing | `UART_CTRL.baud_sel` | High |
| D2 | **Denial of Service** | Repeated wrong unlock words flood violation counter to `0xFF` | `SEC_CTRL` | Low |
| E1 | **Elevation of Privilege** | Software bypasses register lock to write AES key | `SEC_CTRL` FSM | High |
| E2 | **Elevation of Privilege** | Replay attack: replay previously captured unlock sequence | `SEC_CTRL` sequence | Medium |

---

## 4. DREAD Scoring

Scale: 1 (low) – 10 (high). Score = average of 5 dimensions.

| Threat | Damage | Reproducibility | Exploitability | Affected Users | Discoverability | **Score** | Priority |
|--------|--------|-----------------|----------------|---------------|-----------------|-----------|----------|
| T1 – AES key overwrite | 9 | 10 | 9 | 10 | 8 | **9.2** | 🔴 Critical |
| I1 – AES key read-back | 10 | 10 | 9 | 10 | 7 | **9.2** | 🔴 Critical |
| T2 – Disable encryption | 9 | 10 | 9 | 10 | 7 | **9.0** | 🔴 Critical |
| E1 – Bypass register lock | 9 | 8 | 7 | 10 | 6 | **8.0** | 🟠 High |
| D1 – Zero baud_sel DoS | 7 | 10 | 9 | 9 | 8 | **8.6** | 🟠 High |
| S2 – Rogue bus master | 8 | 5 | 5 | 9 | 5 | **6.4** | 🟡 Medium |
| E2 – Replay unlock seq | 6 | 6 | 5 | 8 | 5 | **6.0** | 🟡 Medium |
| S1 – UART frame inject | 5 | 7 | 7 | 6 | 8 | **6.6** | 🟡 Medium |
| I2 – RX data register | 5 | 7 | 7 | 6 | 8 | **6.6** | 🟡 Medium |
| T3 – baud_sel=0 | 7 | 10 | 9 | 9 | 8 | **8.6** | 🟠 High |
| I3 – Power side-channel | 8 | 4 | 4 | 7 | 3 | **5.2** | 🟢 Low |
| D2 – Violation counter flood | 2 | 8 | 8 | 4 | 7 | **5.8** | 🟢 Low |
| R1 – No audit log | 3 | 10 | 10 | 5 | 9 | **7.4** | 🟡 Medium |

---

## 5. Common Weakness Enumerations (CWE)

Identified CWEs relevant to this DP-2 UART+AES-128 design:

| CWE ID | Name | Where in Design | Severity |
|--------|------|----------------|----------|
| **CWE-284** | Improper Access Control | `AES_CTRL`, `AES_KEY[0–3]` writable without authentication | 🔴 Critical |
| **CWE-312** | Cleartext Storage of Sensitive Information | `AES_KEY[0–3]` readable from register bus in plaintext | 🔴 Critical |
| **CWE-400** | Uncontrolled Resource Consumption | `UART_CTRL.baud_sel=0` → potential zero-divisor hang | 🟠 High |
| **CWE-20**  | Improper Input Validation | No range/sanity checking on `baud_sel` field; no frame auth on UART RX | 🟡 Medium |
| **CWE-1255** | Insufficient Control of Hardware Power Behavior | AES S-box has data-dependent switching activity (power side-channel) | 🟢 Low |
| **CWE-362** | Concurrent Execution using Shared Resource without Proper Synchronization | Potential race between SEC_CTRL unlock timer expiry and a register write; analyzed — no actual race in synchronous RTL | 🟢 Analyzed/Not Applicable |
| **CWE-532** | Insertion of Sensitive Information into Log File | Violation count stored in readable `SEC_STATUS` register; exposes attack attempt frequency | 🟢 Low |

---

## 6. Summary: Top-Priority Threats

| Priority | Threat | CWE | Fix |
|----------|--------|-----|-----|
| 1 | AES key overwrite without auth | CWE-284 | Two-stage authenticated write lock (CM#1) |
| 2 | AES key readable in plaintext | CWE-312 | Key read-back masking while locked (CM#2) |
| 3 | Zero baud_sel DoS | CWE-400 + CWE-20 | Reject baud_sel=0 writes (CM#3) |
| 4 | AES encryption silently disabled | CWE-284 | Covered by CM#1 (AES_CTRL is a sensitive register) |
| 5 | Power side-channel on AES | CWE-1255 | Accepted — out-of-scope for RTL-level DP-3 |
| 6 | UART frame injection | CWE-20 | Accepted — UART is an unauthenticated protocol by standard |
