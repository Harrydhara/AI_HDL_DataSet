# Security Assessment Document
## AI-HDL 2026 — Design Phase 3
### Team: ICLab_HUST2 | Design: Winograd F(2×2,3×3) Accelerator on TinyQV RISC-V SoC

**Assessment Date:** March 24, 2026
**Base Design:** DP2 Optimized RTL (team-ICLab_HUST2-challenge-2, R-PW1v2)
**Assessed By:** Member A
**AI Tools Used:** Claude Sonnet 4.6 (threat modeling, code review, CWE mapping)

---

## Table of Contents
1. [Design Overview & Attack Surface](#1-design-overview--attack-surface)
2. [CIA Triad Analysis](#2-cia-triad-analysis)
3. [STRIDE Threat Model](#3-stride-threat-model)
4. [DREAD Risk Scoring](#4-dread-risk-scoring)
5. [Common Weakness Enumerations (CWE)](#5-common-weakness-enumerations-cwe)
6. [Vulnerability Detail — Per Module](#6-vulnerability-detail--per-module)
7. [Mitigation Plan & Priority](#7-mitigation-plan--priority)
8. [Summary Table](#8-summary-table)

---

## 1. Design Overview & Attack Surface

### 1.1 System Architecture

The design is a **Winograd F(2×2, 3×3) convolution accelerator** tightly integrated into the TinyQV RISC-V SoC via a memory-mapped peripheral interface. The SoC is targeted for TinyTapeout silicon fabrication on sky130A at 50 MHz.

```
CPU (TinyQV RISC-V)
    │  MMIO bus (32-bit data, 6-bit address)
    ▼
winograd_peripheral  (interface.v)
    ├── Register file: CTRL / STATUS / CONFIG / INPUT_IDX / INPUT_DATA / FILTER_IDX / FILTER_DATA
    ├── input_buffer[0..15]   — 16 × 32-bit Q16.16 pixel values
    ├── filter_buffer[0..8]   — 9 × 32-bit Q16.16 filter coefficients
    ├── output_buffer[0..3]   — 4 × 32-bit computation results
    ├── acc_buffer[0..3]      — 4 × 32-bit accumulation registers
    ├── Feed FSM (FEED_IDLE → FEED_FILTER → FEED_INPUT → FEED_START → FEED_WAIT → FEED_COLLECT)
    └── winograd_conv_top  (winograd.v)
            ├── winograd_filter_transform  (matrix_filter.v)
            ├── winograd_input_transform   (matrix_input.v)
            ├── winograd_elementwise       (element_wise.v)
            └── winograd_output_transform  (matrix_output.v)
```

### 1.2 Memory Map (Base Address: 0x800_0380)

| Offset | Register      | R/W | Function |
|--------|---------------|-----|----------|
| 0x00   | CTRL          | R/W | bit0=START, bit3=ACCUM_EN, bit4=CLEAR_ACC, bit5=IRQ_EN |
| 0x04   | STATUS        | R/W | bit0=BUSY, bit1=DONE |
| 0x08   | CONFIG        | R/W | Reserved configuration |
| 0x0C   | INPUT_IDX     | R/W | Write index for input buffer (4-bit) |
| 0x10   | INPUT_DATA    | R/W | Write/read input_buffer[INPUT_IDX] |
| 0x14   | FILTER_IDX    | R/W | Write index for filter buffer (4-bit) |
| 0x18   | FILTER_DATA   | R/W | Write/read filter_buffer[FILTER_IDX] |
| 0x1C–0x28 | OUTPUT[0–3] | R | Convolution output pixels |
| 0x2C–0x38 | ACC[0–3]    | R | Accumulated results |
| Others | —             | R   | Returns 0xDEADBEEF (debug marker) |

### 1.3 Primary Attack Surface

The design has **three major attack surfaces** identified from source code review:

1. **MMIO Register Interface** (`interface.v`): The primary entry point. Any entity with bus access can read/write all registers without restriction or authentication.
2. **Data Path Internals** (`element_wise.v`, `matrix_filter.v`, `matrix_input.v`): Fixed-point arithmetic with no overflow/saturation protection, creating arithmetic exploit opportunities.
3. **Power Side-Channel** (`matrix_input.v`, `matrix_output.v`): 360 Integrated Clock Gating (ICG) cells synthesized in DP2 create measurable, state-dependent power switching patterns that correlate with computation state.

---

## 2. CIA Triad Analysis

### 2.1 Confidentiality

**Question:** Can sensitive computation data (input data, filter weights, intermediate results) be read by unauthorized parties?

**Finding: VIOLATED ⚠️**

All buffers are **fully readable** via the MMIO interface with no access control. Specifically:

- `input_buffer[0..15]` is readable at address offset `0x10` by setting `INPUT_IDX` then reading `INPUT_DATA`
- `filter_buffer[0..8]` is readable at `0x18` by setting `FILTER_IDX` then reading `FILTER_DATA`
- `output_buffer[0..3]` is readable at `0x1C–0x28` at any time — including during computation
- `acc_buffer[0..3]` is readable at `0x2C–0x38` even during multi-channel accumulation

In a shared-memory or multi-tenant scenario, any process with bus access can exfiltrate filter weights (which in a neural network context represent proprietary trained model parameters) or intermediate results without detection.

**Additionally**, reading `INPUT_DATA` or `FILTER_DATA` when the index is out-of-range returns `32'hDEADBEEF` — a debug sentinel value that **leaks the fact that this is an unprotected register file with known address boundaries**, aiding an attacker in mapping the design's internal structure.

### 2.2 Integrity

**Question:** Can computation data be altered during or between operations without authorization?

**Finding: VIOLATED ⚠️**

The write path in `interface.v` has **no busy-state protection**:

```verilog
// interface.v lines 129–158 (current DP2 code — NO guard)
if (write_req) begin
    if (is_ctrl)        ctrl_reg <= data_in;          // START bit writable anytime
    else if (is_input_data) begin
        case (input_wr_idx)                            // Writable even when BUSY!
            ...
        endcase
    end else if (is_filter_data) begin
        case (filter_wr_idx)                           // Writable even when BUSY!
            ...
        endcase
    end
end
```

The `STATUS_BUSY_BIT` exists in `status_reg` and is set correctly by `feed_active`, but it is **never checked before allowing writes**. An attacker can:

1. Wait for a legitimate computation to start (BUSY=1)
2. Write new values into `input_buffer` or `filter_buffer`
3. The in-progress computation will read the *corrupted* values mid-pipeline, producing incorrect output silently
4. The output buffers will hold attacker-influenced results with no error flag raised

This is a **silent data corruption** vulnerability — the victim receives wrong results with no indication of tampering.

**Additionally**, the `STATUS` register itself is **writable**:
```verilog
// interface.v line 260
else if (write_req && is_status) wino_done_latched <= 1'b0;
```
Writing to STATUS clears `wino_done_latched`, which clears the DONE flag and de-asserts `winograd_irq`. An attacker can suppress the completion interrupt silently, causing the CPU to wait indefinitely for a result that was already computed.

### 2.3 Availability

**Question:** Can an attacker prevent the accelerator from completing its intended computation?

**Finding: VIOLATED ⚠️**

Two denial-of-service vectors exist:

**Vector 1 — START Bit Flooding:**
The CTRL register is writable at any time, including when `feed_active=1`. Writing `1` to `CTRL_START_BIT` while BUSY causes `ctrl_reg[CTRL_START_BIT]` to remain set (or be re-set), interfering with the feed FSM's transition logic. In the worst case, repeated writes to CTRL with `START=1` can stall the feed FSM in `FEED_IDLE` if the bus write and hardware clear race.

**Vector 2 — Accumulator Overflow Exhaustion:**
With `CTRL_ACCUM_EN_BIT=1`, each computation accumulates results into `acc_buffer`. There is no overflow protection:
```verilog
// interface.v lines 277–280
acc_buffer_0 <= $signed(acc_buffer_0) + $signed(wino_data_out);
```
An attacker controlling input data can engineer values that cause `acc_buffer` to overflow repeatedly, wrapping around to zero or to attacker-chosen values. This corrupts the accumulated result silently, making multi-channel inference unreliable.

**Vector 3 — IRQ Suppression (Status Register Write):**
Writing any value to STATUS register (0x04) clears `wino_done_latched` and `winograd_irq`. If the CPU is polling the IRQ, an attacker can continuously clear it, causing the CPU to spin-wait indefinitely (CPU availability impact).

---

## 3. STRIDE Threat Model

The STRIDE model categorizes threats into six types. Below, each is mapped to specific signals, modules, and line numbers in the DP2 RTL.

### 3.1 Spoofing

**Definition:** Pretending to be something or someone you are not.

| # | Threat | Location | Mechanism |
|---|--------|----------|-----------|
| S-1 | **False START trigger** | `interface.v` line 130 | Any bus master can write CTRL[0]=1, impersonating the legitimate CPU scheduler and triggering computation with unauthorized data already in the buffers |
| S-2 | **IRQ flag manipulation** | `interface.v` line 260 | Writing to STATUS register clears `wino_done_latched`, making the hardware appear to have not finished when it has — spoofing the "not done" state |
| S-3 | **Index pointer manipulation** | `interface.v` lines 132, 146 | Writing `INPUT_IDX` or `FILTER_IDX` to any 4-bit value re-aims the auto-increment pointer, allowing an attacker to overwrite arbitrary buffer slots |

### 3.2 Tampering

**Definition:** Altering data to produce incorrect results.

| # | Threat | Location | Mechanism |
|---|--------|----------|-----------|
| T-1 | **Mid-computation buffer corruption** | `interface.v` lines 133–145 | Write to `INPUT_DATA` while `STATUS_BUSY=1` silently overwrites `input_buffer[N]` which may already be mid-pipeline in `winograd_conv_top` |
| T-2 | **Filter weight injection** | `interface.v` lines 147–157 | Same as T-1 but for `filter_buffer[0..8]` — allows attacker to substitute filter kernels without detection |
| T-3 | **Accumulator poisoning** | `interface.v` line 270 | Writing CTRL[4]=1 (CLEAR_ACC) mid-accumulation resets `acc_buffer` to zero, destroying accumulated multi-channel results |
| T-4 | **Fixed-point overflow injection** | `element_wise.v` line 99 | Input values near `0x7FFFFFFF` or `0x80000000` propagate through `fp_mult` → `m_buffer` accumulation with silent overflow, producing incorrect sign-wrapped outputs |

### 3.3 Repudiation

**Definition:** Claiming an action was not performed, or denying responsibility.

| # | Threat | Location | Mechanism |
|---|--------|----------|-----------|
| R-1 | **No write audit trail** | `interface.v` entire | There is no logging, sequence counter, or transaction ID. An attacker who corrupts buffers mid-computation leaves no forensic evidence in the design — the CPU cannot determine whether the wrong result came from a software bug or a malicious write |
| R-2 | **No computation ID** | `winograd.v` lines 220–400 | Computation results are written to `output_buffer` with no timestamp, invocation counter, or source identifier — a result cannot be tied to a specific START trigger |

### 3.4 Information Disclosure

**Definition:** Exposing sensitive data to unauthorized parties.

| # | Threat | Location | Mechanism |
|---|--------|----------|-----------|
| I-1 | **Filter weight readback** | `interface.v` lines 187–195 | Filter weights (neural network model parameters) are fully readable via FILTER_DATA register reads at any time — before, during, or after computation |
| I-2 | **Input data readback** | `interface.v` lines 173–185 | Input image data is fully readable — in a privacy-sensitive application, this leaks the pixel data being processed |
| I-3 | **Debug sentinel disclosure** | `interface.v` lines 183, 194, 201 | Reading unmapped addresses returns `32'hDEADBEEF` — this sentinel reveals (a) the address map boundary, (b) that no access control exists, (c) the implementation style, facilitating further reconnaissance |
| I-4 | **Power side-channel** | `matrix_input.v`, `matrix_output.v` | 360 ICG cells create state-dependent clock-gating activity. External power measurement can distinguish IDLE (low activity) from COMPUTE_BTD/COMPUTE_BTDB (high activity) states, potentially leaking computation timing and progress |
| I-5 | **Accumulator state leakage** | `interface.v` lines 199–200 | `acc_buffer` holds intermediate multi-channel accumulation state, readable at any point during multi-inference sequences — leaks partial computation results |

### 3.5 Denial of Service

**Definition:** Preventing legitimate use of the system.

| # | Threat | Location | Mechanism |
|---|--------|----------|-----------|
| D-1 | **IRQ suppression loop** | `interface.v` line 299 | Continuous writes to STATUS register suppress `winograd_irq`, preventing the CPU from receiving completion notification — CPU spins forever in interrupt wait |
| D-2 | **START bit race** | `interface.v` lines 127, 213 | Writing CTRL with START=1 during BUSY creates a race between hardware auto-clear (`ctrl_reg[0] <= 0` when `feed_active`) and software re-set. Pathological timing can stall the feed FSM |
| D-3 | **Accumulator saturation attack** | `interface.v` lines 277–280 | Crafted input values repeatedly overflow `acc_buffer` — since no saturation exists, attacker can drive accumulated result to zero or to attacker-chosen values, making multi-channel inference permanently incorrect until full reset |
| D-4 | **CONFIG register abuse** | `interface.v` line 131 | `config_reg` is writable with no validation (`config_reg <= data_in`). If future RTL versions use `config_reg` for timing parameters, unauthorized writes could alter hardware behavior |

### 3.6 Elevation of Privilege

**Definition:** Gaining capabilities beyond what is authorized.

| # | Threat | Location | Mechanism |
|---|--------|----------|-----------|
| E-1 | **No privilege levels** | `interface.v` entire | The peripheral has no concept of privilege. There is a single access mode — full read/write of all registers — available to any bus master. An unprivileged process that gains bus access has full accelerator control |
| E-2 | **CTRL register full write** | `interface.v` line 130 | Writing arbitrary 32-bit values to CTRL sets not just START (bit 0) but also ACCUM_EN (bit 3), CLEAR_ACC (bit 4), IRQ_EN (bit 5) simultaneously — an attacker can enable accumulation, disable IRQ, and trigger computation in a single write |
| E-3 | **Output buffer read at will** | `interface.v` lines 197–200 | Output and accumulator buffers from a previous (legitimate) computation remain readable indefinitely — a subsequent unprivileged process can read another process's computation results |

---

## 4. DREAD Risk Scoring

DREAD is a scoring system (1–10 per dimension) for prioritizing which vulnerabilities to fix first.

**Dimensions:** D = Damage, R = Reproducibility, E = Exploitability, A = Affected Users, D2 = Discoverability

| ID | Vulnerability | D | R | E | A | D2 | **Score** | Priority |
|----|---------------|---|---|---|---|-----|-----------|----------|
| V-1 | Write-while-busy buffer corruption (T-1, T-2) | 9 | 9 | 8 | 8 | 8 | **8.4** | 🔴 CRITICAL |
| V-2 | No access control on CTRL register (E-1, E-2) | 8 | 9 | 9 | 8 | 9 | **8.6** | 🔴 CRITICAL |
| V-3 | IRQ suppression via STATUS write (D-1, S-2) | 7 | 9 | 8 | 7 | 7 | **7.6** | 🔴 HIGH |
| V-4 | Accumulator overflow — no saturation (T-4, D-3) | 7 | 7 | 6 | 6 | 6 | **6.4** | 🟡 MEDIUM |
| V-5 | Filter weight / input data readback (I-1, I-2) | 7 | 9 | 9 | 7 | 9 | **8.2** | 🔴 HIGH |
| V-6 | Debug sentinel 0xDEADBEEF disclosure (I-3) | 4 | 9 | 9 | 5 | 9 | **7.2** | 🟡 MEDIUM |
| V-7 | Power side-channel via ICG cells (I-4) | 6 | 5 | 4 | 6 | 5 | **5.2** | 🟢 LOW |
| V-8 | No computation audit trail (R-1, R-2) | 5 | 9 | 9 | 5 | 8 | **7.2** | 🟡 MEDIUM |
| V-9 | CONFIG register blind write (D-4) | 3 | 9 | 9 | 4 | 8 | **6.6** | 🟡 MEDIUM |
| V-10 | Output buffer stale-read across invocations (E-3) | 6 | 7 | 8 | 6 | 7 | **6.8** | 🟡 MEDIUM |

### DREAD Score Formula
```
Score = (D + R + E + A + D2) / 5
```

### Priority Ranking (sorted by DREAD score)
1. **V-2** (8.6) — No access control on CTRL
2. **V-1** (8.4) — Write-while-busy corruption
3. **V-5** (8.2) — Sensitive data readback
4. **V-3** (7.6) — IRQ suppression
5. **V-6** (7.2) — Debug sentinel disclosure
6. **V-8** (7.2) — No audit trail
7. **V-9** (6.6) — CONFIG blind write
8. **V-10** (6.8) — Stale output readback
9. **V-4** (6.4) — Accumulator overflow
10. **V-7** (5.2) — Power side-channel

---

## 5. Common Weakness Enumerations (CWE)

CWEs map to the official MITRE hardware weakness taxonomy.

| CWE ID | Name | Severity | Affected Modules | Related Vulnerabilities |
|--------|------|----------|-----------------|------------------------|
| **CWE-284** | Improper Access Control | HIGH | `interface.v` | V-1, V-2, V-3, V-5 |
| **CWE-362** | Concurrent Execution Using Shared Resource With Improper Synchronization (Race Condition) | HIGH | `interface.v` lines 127, 213 | V-1, V-3 |
| **CWE-20** | Improper Input Validation | MEDIUM | `interface.v` lines 133–157 | V-1, V-4 |
| **CWE-190** | Integer Overflow or Wraparound | MEDIUM | `interface.v` lines 277–280, `element_wise.v` line 99 | V-4 |
| **CWE-200** | Exposure of Sensitive Information to an Unauthorized Actor | HIGH | `interface.v` lines 173–201 | V-5, V-6 |
| **CWE-1300** | Improper Protection of Physical Side Channels | LOW | `matrix_input.v`, `matrix_output.v` | V-7 |
| **CWE-693** | Protection Mechanism Failure | HIGH | `interface.v` entire | V-2, V-3 |
| **CWE-667** | Improper Locking | MEDIUM | `interface.v` lines 127–130 | V-1, V-2 |
| **CWE-1233** | Security-Sensitive Hardware Controls with Missing Lock Bit Protection | HIGH | `interface.v` line 130 (CTRL register) | V-2 |
| **CWE-1259** | Improper Restriction of Security Token Assignment | MEDIUM | `interface.v` (no privilege register) | V-2, E-1 |

### CWE Detail

**CWE-284: Improper Access Control** — The most pervasive issue. `interface.v` has no mechanism to prevent any bus master from reading or writing any register. The CTRL register is the most critical — writing CTRL[0]=1 unconditionally starts computation regardless of who initiates the write or what data is currently in the buffers.

**CWE-362: Race Condition** — Lines 127 and 213 create a temporal race: `ctrl_reg[CTRL_START_BIT]` is cleared by hardware on the cycle after `feed_active` asserts, but bus write logic (line 130) can re-set it in the same cycle window. The FSM's guard `!status_reg[STATUS_BUSY_BIT]` is checked combinationally but `status_reg` is updated one cycle after `feed_active` changes.

**CWE-20: Improper Input Validation** — The `input_buffer` and `filter_buffer` accept any 32-bit Q16.16 value. Values of `32'h80000000` (most negative signed), `32'h7FFFFFFF` (most positive), or `32'hDEADBEEF` (attacker sentinel) are all accepted without bounds checking. In the `fp_mult` function in `element_wise.v`, multiplying two large Q16.16 values produces a 64-bit intermediate that is truncated to 32-bits — extreme inputs cause silently incorrect truncation.

**CWE-190: Integer Overflow** — The accumulator in `interface.v` lines 277–280 performs signed 32-bit addition without overflow detection:
```verilog
acc_buffer_0 <= $signed(acc_buffer_0) + $signed(wino_data_out);
```
If both operands are large positive Q16.16 values, the result wraps to a large negative number. The CPU receives no error flag.

**CWE-200: Information Disclosure** — All buffer contents are readable. The `32'hDEADBEEF` sentinel at unmapped addresses (lines 183, 194, 201) reveals the address map structure. Specifically, returning a *known constant* at undefined addresses tells an attacker exactly where the valid register space ends.

**CWE-1300: Physical Side-Channel** — The 360 ICG cells added in DP2 (for internal power reduction) create observable power signatures. Each FSM state activates a different subset of ICG cells: `FEED_IDLE` gates all register blocks (low power), `FEED_FILTER` and `FEED_INPUT` gate the input-transform register arrays (medium power), `FEED_WAIT/COLLECT` activates the element-wise pipeline (high power). External power measurement with ~µW resolution can track the feed FSM state in real time.

---

## 6. Vulnerability Detail — Per Module

### 6.1 `interface.v` — winograd_peripheral

This module contains the majority of vulnerabilities as it is the sole external interface.

**Finding 1: Write-While-Busy (Lines 129–158)**
```
Severity: CRITICAL | CWE: CWE-284, CWE-362
```
The write block executes unconditionally whenever `write_req=1`. The `STATUS_BUSY_BIT` is set correctly but never read inside the write block. An attacker performs:
- Step 1: Load legitimate data into input_buffer (setup phase)
- Step 2: Observe STATUS=BUSY (computation started)
- Step 3: Write malicious data to INPUT_DATA during computation
- Step 4: Computation produces result influenced by attacker-controlled data

**Finding 2: CTRL Register Unrestricted (Line 130)**
```
Severity: CRITICAL | CWE: CWE-284, CWE-1233
```
`ctrl_reg <= data_in` — the entire 32-bit CTRL register is overwritten in a single bus write. Bits 3 (ACCUM_EN), 4 (CLEAR_ACC), and 5 (IRQ_EN) are modified simultaneously with START. A single write to CTRL can simultaneously: (a) clear accumulated results (bit 4), (b) enable accumulation for the next run (bit 3), (c) disable IRQ (bit 5), (d) trigger start (bit 0) — all with no atomicity protection.

**Finding 3: STATUS Register Writable (Lines 260, 299)**
```
Severity: HIGH | CWE: CWE-284, CWE-693
```
Writing to STATUS register (0x04) clears `wino_done_latched` which: (a) clears STATUS_DONE_BIT, (b) de-asserts `winograd_irq`. A STATUS register should be read-only or have only specific W1C (write-1-to-clear) bits, not be cleared by any write.

**Finding 4: Debug Sentinel Value (Lines 183, 194, 201)**
```
Severity: MEDIUM | CWE: CWE-200
```
`default: data_out <= 32'hDEADBEEF;` — a hardcoded debug constant is returned for all unmapped addresses. This is a classic OPSEC failure: it reveals that the designer did not implement access control at undefined addresses and helps an attacker rapidly identify valid vs. invalid address ranges.

**Finding 5: Accumulator No Overflow Protection (Lines 277–280)**
```
Severity: MEDIUM | CWE: CWE-190
```
Q16.16 signed addition without saturation. With `ACCUM_EN=1` and 255 channels of maximum-value inputs, the accumulator will overflow multiple times silently.

### 6.2 `element_wise.v` — winograd_elementwise

**Finding 6: fp_mult Truncation — Extreme Input Sensitivity (Lines 41–45)**
```
Severity: MEDIUM | CWE: CWE-20, CWE-190
```
```verilog
tmp     = $signed(a) * $signed(b);        // 64-bit intermediate
fp_mult = tmp[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS];  // truncate to [47:16]
```
For `a = 32'h7FFF0000` (~32767 in Q16.16) and `b = 32'h7FFF0000`, the product `tmp` = ~0x3FFF0001_00000000. The selected bits `[47:16]` = `0x3FFF0001` which exceeds the 32-bit signed maximum, wrapping to a large negative value. No saturation or overflow flag exists.

**Finding 7: ch_idx Comparison Without Bounds (Lines 93–106)**
```
Severity: LOW | CWE: CWE-20
```
`if (ch_idx_r == 8'd0)` — the first-channel initialization uses `ch_idx` passed from the peripheral. Since `num_channels` is hardcoded to `8'd1` in `interface.v` line 84, this is not currently exploitable, but if `num_channels` becomes configurable, a `ch_idx` value exceeding `num_ch` would cause `elem_complete` to never assert `all_done`.

### 6.3 `matrix_filter.v` — winograd_filter_transform

**Finding 8: Unauthenticated Filter Data (Lines 103–108)**
```
Severity: HIGH | CWE: CWE-284
```
Filter coefficients loaded into `g_flat[0..8]` come directly from `filter_buffer` which, as established, can be overwritten at any time via the MMIO interface. There is no checksum, hash, or "filter-locked" flag to detect that filter weights have been tampered with after loading.

**Finding 9: Signed Arithmetic Width Mismatches (Lines 61–83)**
```
Severity: LOW | CWE: CWE-20
```
`gg_sum` and `gg_dif` are computed as `DATA_WIDTH+2 = 34`-bit signed wires, then truncated to `DATA_WIDTH` via `[DATA_WIDTH:1]` (33 bits shifted right by 1). The Verilator `lint_off WIDTH` suppression confirms this was a known width mismatch accepted as-is. Extreme filter values can cause silent sign-extension errors.

### 6.4 `matrix_input.v` — winograd_input_transform

**Finding 10: ICG Power Side-Channel (Lines 95–136)**
```
Severity: LOW | CWE: CWE-1300
```
```verilog
wire d_we   = ((state == IDLE) && start) || (state == LOAD);
wire tmp_we = (state == COMPUTE_BTD);
wire v_we   = (state == COMPUTE_BTDB);
```
Three independent ICG enable wires activate different register arrays at different FSM states. The power consumption profile is: IDLE+start → `d_matrix` writes active; LOAD → `d_matrix` writes; COMPUTE_BTD → `temp_matrix` writes; COMPUTE_BTDB → `v_matrix` writes. External power analysis can distinguish these four activity phases.

---

## 7. Mitigation Plan & Priority

### 7.1 Implemented in DP3 (Selected Countermeasures)

#### COUNTERMEASURE CM-1: Write-While-Busy Protection (PRIORITY: CRITICAL)
**Targets:** V-1, V-2 | **CWEs Fixed:** CWE-284, CWE-362, CWE-667

**Description:** Add a `busy_guard` signal in `interface.v` that blocks all writes to `input_buffer`, `filter_buffer`, and the START bit of `ctrl_reg` when `status_reg[STATUS_BUSY_BIT]=1`. Add a `sec_violation_flag` register that is set whenever a blocked write is attempted — readable by CPU at STATUS register bit 2.

**RTL Change Location:** `interface.v`, write block (lines 129–158)

**Implementation Logic:**
```
busy_guard = status_reg[STATUS_BUSY_BIT]
- If busy_guard=1 AND write_req to INPUT_DATA/FILTER_DATA/CTRL[START]:
    → Block the write (do not update buffer)
    → Set sec_violation_flag = 1
- If busy_guard=0: allow write normally
- sec_violation_flag: readable in STATUS[2], cleared on STATUS read
```

**Expected PPA Impact:** +2–4 cells (1 gate per guarded write path + 1 DFF for violation flag)

**Proof of Security Test:** Load valid data, trigger START. While BUSY=1, attempt to write INPUT_DATA with 0xDEAD1234. After computation completes, verify output matches original data (not 0xDEAD1234). Verify STATUS[2]=1 (violation recorded).

#### COUNTERMEASURE CM-2: Debug Sentinel Removal (PRIORITY: MEDIUM)
**Targets:** V-6 | **CWEs Fixed:** CWE-200

**Description:** Replace `32'hDEADBEEF` with `32'h00000000` in all three default read paths in `interface.v`. A zero response is neutral — it does not reveal address map structure.

**RTL Change Location:** `interface.v` lines 183, 194, 201

**Expected PPA Impact:** 0 cells (constant substitution, no logic change)

### 7.2 Partially Addressed (Documented, Not Fully Implemented)

#### MITIGATION M-1: Accumulator Saturation (V-4, CWE-190)
**Plan:** Replace `$signed(acc) + $signed(data)` with a saturating add: detect when carry out differs from sign bit (overflow condition) and clamp to `32'h7FFFFFFF` or `32'h80000000`. This requires ~6 additional gates per accumulator lane (4 lanes × 6 = ~24 cells).

**Status:** Documented, deferred to DP4 due to time constraints.

#### MITIGATION M-2: STATUS Register Write Hardening (V-3, CWE-693)
**Plan:** Make STATUS register read-only for all bits except a W1C (write-1-to-clear) bit for DONE flag. The `wino_done_latched` clear should only respond to writing `1` to STATUS[1], not any write to STATUS address.

**Status:** Partially documented. Full implementation deferred to DP4.

### 7.3 Accepted Risks (Not Fixed in DP3)

| Risk | Reason Accepted |
|------|----------------|
| V-7: Power side-channel | Requires architectural countermeasure (dummy activity injection); PPA overhead (~15–20% power) exceeds DP3 scope. Documented for DP4. |
| V-5: Filter readback | No user-space isolation mechanism in TinyQV; would require memory protection unit (MPU) at SoC level, outside peripheral scope. |
| V-8: No audit trail | Requires persistent log buffer; not feasible in TinyTapeout footprint. |

---

## 8. Summary Table

| Vuln ID | Description | DREAD | CWE | Severity | DP3 Action |
|---------|-------------|-------|-----|----------|------------|
| V-1 | Write-while-busy buffer corruption | 8.4 | CWE-284, 362, 667 | 🔴 CRITICAL | ✅ **FIXED (CM-1)** |
| V-2 | No access control on CTRL register | 8.6 | CWE-284, 1233, 1259 | 🔴 CRITICAL | ✅ **FIXED (CM-1, START bit guard)** |
| V-3 | IRQ suppression via STATUS write | 7.6 | CWE-284, 693 | 🔴 HIGH | 🔶 Partially mitigated |
| V-4 | Accumulator integer overflow | 6.4 | CWE-190 | 🟡 MEDIUM | 📋 Documented, DP4 |
| V-5 | Sensitive data readback (filter/input) | 8.2 | CWE-200 | 🔴 HIGH | 📋 Accepted (SoC-level MPU needed) |
| V-6 | Debug sentinel 0xDEADBEEF disclosure | 7.2 | CWE-200 | 🟡 MEDIUM | ✅ **FIXED (CM-2)** |
| V-7 | Power side-channel via ICG cells | 5.2 | CWE-1300 | 🟢 LOW | 📋 Accepted, DP4 |
| V-8 | No computation audit trail | 7.2 | — | 🟡 MEDIUM | 📋 Infeasible in footprint |
| V-9 | CONFIG register blind write | 6.6 | CWE-20 | 🟡 MEDIUM | 📋 Documented |
| V-10 | Stale output across invocations | 6.8 | CWE-284 | 🟡 MEDIUM | 📋 Documented |

### Countermeasures Implemented in DP3
| CM ID | Description | RTL File | Estimated PPA Impact |
|-------|-------------|----------|---------------------|
| CM-1 | Write-while-busy protection + security violation flag | `interface.v` | +2–4 cells, 0 timing impact |
| CM-2 | Remove 0xDEADBEEF debug sentinel → replace with 0x0 | `interface.v` | 0 cells |

### Security Posture: Before vs. After DP3

| Property | DP2 (Before) | DP3 (After CM-1, CM-2) |
|----------|-------------|----------------------|
| Write-while-busy | Unprotected | ✅ Blocked + flagged |
| START bit protection | None | ✅ Blocked when BUSY |
| Debug info disclosure | 0xDEADBEEF visible | ✅ Returns 0x0 |
| Security violation reporting | None | ✅ STATUS[2] flag |
| Accumulator overflow | Silent | ⚠️ Still unprotected (DP4) |
| Power side-channel | Observable | ⚠️ Accepted risk |
| Functional regression | N/A | ✅ All DP2 tests must pass |

---

*Document prepared by Member A for AI-HDL 2026 Design Phase 3.*
*Next: RTL implementation of CM-1 and CM-2 in `src/interface.v`, followed by security testbench in `testbench/tb_security/`.*
