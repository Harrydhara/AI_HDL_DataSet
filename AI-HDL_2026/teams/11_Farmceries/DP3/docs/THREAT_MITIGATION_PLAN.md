# DP-3 Threat Mitigation Plan

**Team:** Farmceries | **Phase:** DP-3 Security Evaluation
**Design:** `secure_uart_peripheral.v` + AES-128 streaming core

---

## Mitigation Strategy Overview

Three active countermeasures are implemented in RTL. Two threats are explicitly accepted
with documented rationale. This plan maps each identified CWE to a specific fix, the RTL
location, the acceptance criteria, and the verification method.

---

## CM#1 — Two-Stage Authenticated Register Write Lock

| Field | Detail |
|-------|--------|
| **Addresses** | CWE-284 (Improper Access Control) |
| **Threats covered** | T1 (AES key overwrite), T2 (Disable AES_CTRL), E1 (Bypass lock) |
| **DREAD Score (pre-fix)** | 9.2 / 9.0 |
| **Fix Type** | Two-stage magic-word authentication protocol |
| **Sensitive registers protected** | `AES_CTRL (0x20)`, `AES_KEY0–3 (0x28–0x34)` |
| **RTL location** | `secure_uart_peripheral.v` — `sec_sensitive_write` / `sec_write_allowed` signals; `ADDR_SEC_CTRL` case in write FSM |
| **Mechanism** | Write `SEC_CTRL (0x38)` ← `0xC0DEA55A` (stage 1), then ← `0x5AFEF00D` (stage 2) → asserts `sec_unlocked`. Unlocked state auto-expires after 64 clock cycles. Any wrong word increments `sec_violation_count` in `SEC_STATUS (0x3C)`. |
| **Acceptance criteria** | Write to `AES_CTRL` while locked → value unchanged; write after unlock → accepted; violation counter increments on blocked attempt |
| **Verification** | `test_security_lock_blocks_sensitive_writes` in `test_secure_uart.py` |
| **Status** | ✅ Implemented and tested |

```verilog
// RTL key signals
assign sec_sensitive_write = bus_write && (
    address == ADDR_AES_CTRL ||
    address == ADDR_AES_KEY0 || address == ADDR_AES_KEY1 ||
    address == ADDR_AES_KEY2 || address == ADDR_AES_KEY3
);
assign sec_write_allowed = (!sec_sensitive_write) || sec_unlocked;
```

---

## CM#2 — AES Key Read-Back Masking

| Field | Detail |
|-------|--------|
| **Addresses** | CWE-312 (Cleartext Storage of Sensitive Information) |
| **Threats covered** | I1 (AES key read-back in plaintext) |
| **DREAD Score (pre-fix)** | 9.2 |
| **Fix Type** | Conditional read masking |
| **Registers masked** | `AES_KEY0–3 (0x28–0x34)` |
| **RTL location** | `secure_uart_peripheral.v` — register-read `case` block |
| **Mechanism** | When `sec_unlocked == 0`, any read of `AES_KEY*` returns `32'h0000_0000` instead of the stored key. When `sec_unlocked == 1` (i.e., caller has completed the two-stage authentication), the real key value is returned. |
| **Acceptance criteria** | Read `AES_KEY0` while locked → `0x00000000`; read same register within 64 cycles of valid unlock → actual key value |
| **Verification** | `test_aes_key_readback_masked` (negative path) and `test_aes_key_readback_revealed_after_unlock` (positive path) |
| **Status** | ✅ Implemented and tested |

```verilog
// RTL change (register-read case block)
ADDR_AES_KEY0: data_out <= sec_unlocked ? aes_key_reg[127:96] : 32'h0;
ADDR_AES_KEY1: data_out <= sec_unlocked ? aes_key_reg[95:64]  : 32'h0;
ADDR_AES_KEY2: data_out <= sec_unlocked ? aes_key_reg[63:32]  : 32'h0;
ADDR_AES_KEY3: data_out <= sec_unlocked ? aes_key_reg[31:0]   : 32'h0;
```

---

## CM#3 — BAUD_DIV Sanity Clamp (Zero-Divisor Prevention)

| Field | Detail |
|-------|--------|
| **Addresses** | CWE-400 (Uncontrolled Resource Consumption), CWE-20 (Improper Input Validation) |
| **Threats covered** | D1 (Zero baud_sel freezes UART), T3 (baud_sel=0 write) |
| **DREAD Score (pre-fix)** | 8.6 |
| **Fix Type** | Input range validation at register write |
| **Register protected** | `UART_CTRL (0x00)` bits `[3:0]` (`baud_sel`) |
| **RTL location** | `secure_uart_peripheral.v` — `ADDR_UART_CTRL` case in write FSM |
| **Mechanism** | On a write to `UART_CTRL`, if the incoming `data_in[3:0]` (baud_sel) equals `4'h0`, the entire write is silently discarded — the register retains its previous value. Any non-zero `baud_sel` is accepted normally. |
| **Acceptance criteria** | Set `UART_CTRL=0x31` (baud_sel=1), then write `UART_CTRL=0x30` (baud_sel=0) → register remains `0x31` |
| **Verification** | `test_baud_div_clamp` in `test_secure_uart.py` |
| **Status** | ✅ Implemented and tested |

```verilog
// RTL change (write case block)
// CM#3: Reject baud_sel=0 to prevent zero-divisor DoS (CWE-400)
ADDR_UART_CTRL: if (data_in[3:0] != 4'h0) uart_ctrl_reg <= data_in[5:0];
```

---

## Accepted Threats (No RTL Fix)

### CWE-1255 — Power Side-Channel on AES S-box

| Field | Detail |
|-------|--------|
| **Rationale for acceptance** | Power side-channel countermeasures (e.g., boolean masking, dual-rail logic) require cell-library-level or backend implementation. They cannot be meaningfully addressed at the Verilog RTL level in this design flow. The AES core (`aes_sbox.v`) uses combinational LUT-based S-box substitution which will have data-dependent switching; this is an inherent property of standard-cell AES. |
| **Risk level** | Low for the competition context (requires specialized measurement equipment) |
| **Mitigation path** | If taken to physical implementation (DP-4), recommend requesting a masked S-box library cell or adding random clock jitter |

### CWE-20 (partial) — UART Frame Injection (S1)

| Field | Detail |
|-------|--------|
| **Rationale for acceptance** | Standard UART is an unauthenticated, byte-stream protocol. Adding HMAC or packet authentication would require changes to the UART framing protocol itself, breaking compatibility with all standard UART devices. |
| **Risk level** | Medium at protocol level; reduced to Low at system level since the AES encryption layer will render injected bytes cryptographically meaningless (they will be treated as ciphertext and fail decryption) |
| **Mitigation path** | If a trusted-link guarantee is required, the system software should implement a message authentication code (MAC) above the UART layer |

---

## Summary Table

| CWE | DREAD (pre-fix) | Countermeasure | Status |
|-----|-----------------|---------------|--------|
| CWE-284 | 9.2 | CM#1 – Two-stage write lock | ✅ Fixed |
| CWE-312 | 9.2 | CM#2 – Key read-back masking | ✅ Fixed |
| CWE-400 | 8.6 | CM#3 – baud_sel=0 clamp | ✅ Fixed |
| CWE-20 (partial) | 6.6 | CM#3 covers baud_sel; UART protocol injection accepted | ⚠️ Partially accepted |
| CWE-1255 | 5.2 | Accepted — out of RTL scope | ⚠️ Accepted |
| CWE-532 | Low | Accepted — violation count is intentional audit feature | ✅ Accepted by design |
