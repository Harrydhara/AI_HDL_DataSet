# DP-3 Security Evaluation Report

**Team:** Farmceries
**Phase:** DP-3 — Security Evaluation and Threat Mitigation
**Design:** Secure UART + AES-128 Peripheral (`secure_uart_peripheral.v`)
**Submission Branch:** `dp-3`
**Date:** April 2026

---

## 1. Executive Summary

This report documents the security evaluation performed on the Farmceries team's UART peripheral
with integrated AES-128 encryption, submitted as the DP-2 optimized design. Three classes of
vulnerabilities were identified through systematic CIA/STRIDE/DREAD analysis and CWE mapping.
Three countermeasures were designed, implemented in synthesizable RTL, and verified through a
dedicated cocotb test suite (9/9 tests passing). A PPA overhead analysis quantifies the area
and timing cost of the security additions.

**Key outcomes:**
- **3 vulnerabilities fixed** in RTL (CWE-284, CWE-312, CWE-400)
- **9/9 security + regression tests pass** — no functional regression
- **Security test suite: 100% pass rate** — attacker inputs demonstrably blocked
- PPA overhead is minimal (see Section 7)

---

## 2. Design Overview

### Architecture

The design (`secure_uart_peripheral.v`) is a memory-mapped UART peripheral integrated with
AES-128 encryption. It presents a 32-bit register interface to the CPU and drives/receives
physical UART signals.

```
CPU (RISC-V TinyQV) ─── 32-bit register bus ───► secure_uart_peripheral
                                                    │
                                         ┌──────────▼──────────────┐
                                         │  Register File + Lock   │
                                         │  (SEC_CTRL, AES_KEY)    │
                                         └──────────┬──────────────┘
                                                    │
                                         ┌──────────▼──────────────┐
                                         │  aes_uart_streaming     │
                                         │  (TX: AES encrypt→UART) │
                                         │  (RX: UART→AES decrypt) │
                                         └──────────┬──────────────┘
                                                    │
                                            Physical UART pins
                                         (uart_tx_pin / uart_rx_pin)
```

### Register Map (DP-2 Baseline + DP-3 Security Additions)

| Address | Register | Description |
|---------|----------|-------------|
| `0x00` | `UART_CTRL` | `[3:0]` baud_sel, `[4]` tx_en, `[5]` rx_en |
| `0x04` | `UART_STATUS` | `[0]` tx_busy, `[1]` rx_ready, `[2]` rx_error |
| `0x08` | `TX_DATA` | Write plaintext byte |
| `0x0C` | `RX_DATA` | Read decrypted byte |
| `0x10` | `INT_EN` | `[0]` tx_done, `[1]` rx_ready interrupt enables |
| `0x14` | `INT_CLR` | Interrupt clear |
| `0x20` | `AES_CTRL` | `[0]` AES_EN (write-protected by CM#1) |
| `0x24` | `AES_STATUS` | `[0]` tx_encrypting, `[1]` rx_decrypting, `[2]` key_ready |
| `0x28–0x34` | `AES_KEY[0–3]` | 128-bit key (write-protected CM#1; read-masked CM#2) |
| **`0x38`** | **`SEC_CTRL`** | **Two-stage unlock protocol (DP-3 addition)** |
| **`0x3C`** | **`SEC_STATUS`** | **`[0]` unlocked, `[1]` stage1_seen, `[9:2]` violation_count (DP-3)** |

### Key Design Parameters

- **AES mode:** AES-128 ECB (16-byte block streaming)
- **UART:** Standard async, configurable baud rate via `baud_sel[3:0]`
- **Clock:** 50–100 MHz target (SkyWater 130nm)
- **Technology:** SKY130 HD standard cell library
- **Top module:** `tt_um_tqv_peripheral_harness` (tt_wrapper)

---

## 3. Vulnerability Assessment (Week 1 — Security Review)

The full assessment is in `dp-3/reports/SECURITY_ASSESSMENT.md`. Summary of top findings:

### 3.1 CIA Triad Summary

| Axis | Finding |
|------|---------|
| **Confidentiality** | AES key (`aes_key_reg[127:0]`) stored in 4× 32-bit readable registers — any software with bus access can exfiltrate the 128-bit key without authentication |
| **Integrity** | `AES_CTRL` (enable/disable AES) and `AES_KEY[0–3]` writable without authentication — attacker can disable encryption or substitute their own key silently |
| **Availability** | `UART_CTRL.baud_sel=0` accepted without validation — zero divisor in baud generator can freeze UART operation |

### 3.2 STRIDE Top Threats

| Category | Threat | DREAD Score |
|----------|--------|-------------|
| Tampering | AES key overwrite without auth (T1) | **9.2** |
| Info Disclosure | AES key read-back in plaintext (I1) | **9.2** |
| Tampering | Disable encryption silently (T2) | **9.0** |
| Denial of Service | Zero baud_sel freezes UART (D1) | **8.6** |

### 3.3 CWE Mapping

| CWE ID | Name | Severity |
|--------|------|----------|
| CWE-284 | Improper Access Control | 🔴 Critical |
| CWE-312 | Cleartext Storage of Sensitive Information | 🔴 Critical |
| CWE-400 | Uncontrolled Resource Consumption | 🟠 High |
| CWE-20 | Improper Input Validation (UART frame injection) | 🟡 Medium (accepted) |
| CWE-1255 | Hardware Power Side-Channel | 🟢 Low (accepted) |

---

## 4. Countermeasures Implemented (Week 2 — Hardening)

All three countermeasures are in `dp-1/peripheral/src/aes/secure_uart_peripheral.v`.

### CM#1 — Two-Stage Authenticated Register Write Lock (CWE-284)

**What it protects:** `AES_CTRL (0x20)` and `AES_KEY[0–3] (0x28–0x34)`

**How it works:** A finite-state unlock protocol requires the CPU to write two specific
magic words to `SEC_CTRL (0x38)` in sequence:
1. Write `0xC0DEA55A` → sets `sec_key_stage1_seen`
2. Write `0x5AFEF00D` → asserts `sec_unlocked`, starts 64-cycle countdown timer

While `sec_unlocked == 0`, any write to `AES_CTRL` or `AES_KEY*` is silently dropped and
`sec_violation_count` in `SEC_STATUS (0x3C)` increments. The unlock state auto-expires
after 64 clock cycles, enforcing a time-limited access window.

```verilog
assign sec_sensitive_write = bus_write && (
    address == ADDR_AES_CTRL ||
    address == ADDR_AES_KEY0 || ... || address == ADDR_AES_KEY3
);
assign sec_write_allowed = (!sec_sensitive_write) || sec_unlocked;
```

### CM#2 — AES Key Read-Back Masking (CWE-312)

**What it protects:** `AES_KEY[0–3] (0x28–0x34)` read path

**How it works:** In the register-read `case` block, all four `AES_KEY*` cases are
guarded by `sec_unlocked`. While locked, reads return `32'h0000_0000`. While unlocked
(within 64-cycle window), reads return the actual stored key value.

```verilog
ADDR_AES_KEY0: data_out <= sec_unlocked ? aes_key_reg[127:96] : 32'h0;
ADDR_AES_KEY1: data_out <= sec_unlocked ? aes_key_reg[95:64]  : 32'h0;
ADDR_AES_KEY2: data_out <= sec_unlocked ? aes_key_reg[63:32]  : 32'h0;
ADDR_AES_KEY3: data_out <= sec_unlocked ? aes_key_reg[31:0]   : 32'h0;
```

### CM#3 — BAUD_DIV Sanity Clamp (CWE-400 / CWE-20)

**What it protects:** UART availability against zero-divisor DoS

**How it works:** On a write to `UART_CTRL`, `data_in[3:0]` (baud_sel field) is validated
before the register is updated. If `baud_sel == 4'h0`, the write is discarded entirely
and the register retains its previous value, preventing the baud generator from receiving
a zero divisor.

```verilog
// CM#3: Reject baud_sel=0 to prevent zero-divisor DoS (CWE-400)
ADDR_UART_CTRL: if (data_in[3:0] != 4'h0) uart_ctrl_reg <= data_in[5:0];
```

---

## 5. Proof of Security — "Breaking" Our Own Design

All security tests are in `dp-1/peripheral/test/test_secure_uart.py`.

### 5.1 Attacker Scenario: Write AES_CTRL While Locked (CM#1)

**Test:** `test_security_lock_blocks_sensitive_writes`

Attack sequence:
1. After reset (`sec_unlocked == 0`), write `AES_CTRL = 0x1` (enable AES)
2. Read back `AES_CTRL` — must remain `0x0`
3. Read `SEC_STATUS[9:2]` — violation counter must be ≥ 1

**Result:** ✅ PASS — write rejected, counter incremented, AES stayed disabled

Positive path:
4. Send correct two-stage unlock sequence
5. Write `AES_CTRL = 0x1` — this time accepted
6. Read back — must be `0x1`

**Result:** ✅ PASS — write accepted after unlock

### 5.2 Attacker Scenario: Read AES Key While Locked (CM#2)

**Test:** `test_aes_key_readback_masked`

Attack sequence:
1. Write known key via unlock window
2. Wait 70 cycles (unlock timer expires — returns to locked)
3. Read `AES_KEY0–3` — must all return `0x00000000`

**Result:** ✅ PASS — all 4 key words returned 0x00000000 while locked

Positive path (`test_aes_key_readback_revealed_after_unlock`):
1. Unlock and write key
2. Immediately read back key (within unlock window)
3. Must return actual values

**Result:** ✅ PASS — actual key values readable during unlock window

### 5.3 Attacker Scenario: Zero Baud-Sel DoS (CM#3)

**Test:** `test_baud_div_clamp`

Attack sequence:
1. Set `UART_CTRL = 0x31` (baud_sel=1, TX+RX enabled)
2. Write `UART_CTRL = 0x30` (baud_sel=0 — DoS attempt)
3. Read back `UART_CTRL` — must remain `0x31`

**Result:** ✅ PASS — `UART_CTRL=0x00000031` unchanged; DoS write rejected

---

## 6. Regression Results — Design Stability

All **9 tests** in `test_secure_uart.py` passed after DP-3 hardening changes:

| Test | Status | Sim Time (ns) |
|------|--------|--------------|
| `test_plaintext_bypass_mode` | ✅ PASS | 280 |
| `test_aes_key_configuration` | ✅ PASS | 420 |
| `test_encrypted_transmission` | ✅ PASS | 4160 |
| `test_encrypted_loopback` | ✅ PASS | 360 |
| `test_bypass_vs_encrypted_modes` | ✅ PASS | 600 |
| `test_security_lock_blocks_sensitive_writes` | ✅ PASS | 330 |
| `test_aes_key_readback_masked` | ✅ PASS | 1360 |
| `test_aes_key_readback_revealed_after_unlock` | ✅ PASS | 400 |
| `test_baud_div_clamp` | ✅ PASS | 240 |
| **TOTAL** | **9/9 PASS** | **8150** |

**Simulator:** Icarus Verilog via cocotb
**Command:** `make -f test_secure_uart.mk` from `dp-1/peripheral/test/`

---

## 7. PPA Overhead Analysis

See `dp-3/reports/PPA_OVERHEAD.md` for the detailed before/after table.

The DP-3 hardening adds the following logic to `secure_uart_peripheral.v`:
- **CM#1:** 2× state flip-flops (`sec_key_stage1_seen`, `sec_unlocked`), 8-bit timer
  (`sec_unlock_timer`), 8-bit violation counter (`sec_violation_count`), combinational
  `sec_sensitive_write` / `sec_write_allowed` compare/AND gates
- **CM#2:** 4× 32-bit 2-to-1 multiplexers on key read paths
- **CM#3:** 4-bit comparator on `UART_CTRL` write path

The expected overhead is **< 1% area** — these are small control logic additions on top
of the dominant AES-128 datapath (which contains the key expansion, 11-round SPN, and
dual TX/RX streaming cores).

---

## 8. Conclusion

The DP-3 security evaluation identified three actionable hardware vulnerabilities in the
DP-2 Secure UART design (CWE-284, CWE-312, CWE-400). All three were mitigated with
synthesizable RTL countermeasures:

1. **CM#1** (two-stage authenticated write lock) prevents unauthorized modification of
   the AES key and control registers — the most critical threat to design integrity.
2. **CM#2** (key read-back masking) eliminates key exfiltration via the register bus —
   the most critical threat to confidentiality.
3. **CM#3** (baud_sel=0 clamp) prevents a trivial availability attack against the UART.

All original functionality is preserved (9/9 tests pass). PPA overhead is minimal.
Two threats (power side-channel, UART frame injection) are accepted with documented
rationale — they cannot be addressed at RTL level without protocol changes or
cell-library-level masking.

The design is submitted on branch `dp-3` under tag `DP3-Submission`.
