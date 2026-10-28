# DP3 Security Evaluation Report

**Project:** UART Controller attached to RISC-V Processor
**Phase:** DP3 – Security Analysis & Hardening

---

## 1. Vulnerability Assessment (Week 1)

Based on structured threat modeling using the CIA Triad, STRIDE, and DREAD frameworks, we identified several critical vulnerabilities in the DP2 baseline UART controller design.

### Threat Models Applied

* CIA Triad (Confidentiality, Integrity, Availability)
* STRIDE (Threat classification)
* DREAD (Risk scoring)

---

### Identified Vulnerabilities & CWEs

#### Vulnerability 1: Information Leakage via Output Pins

* **Relevant CWE:** CWE-200 (Information Exposure), CWE-1236 (Improper Data Exposure)

**Description:**
The design exposes internal transmission data (`tx_reg`) directly to external output pins through combinational logic:

```verilog
assign uo_out = tx_reg[7:0] + ui_in;
```

This creates an unintended direct data path from internal processor data to observable I/O pins.

**Impact:**

* Leakage of sensitive data (e.g., keys, commands)
* Bypass of system-level access control

**Severity:** CRITICAL

---

#### Vulnerability 2: Unmasked External Interrupt Injection (DoS)

* **Relevant CWE:** CWE-400 (Resource Exhaustion), CWE-284 (Improper Access Control)

**Description:**
External signal `ui_in[6]` can directly trigger an interrupt without any masking or control:

```verilog
if (ui_in[6]) test_irq_latched <= 1'b1;
```

**Impact:**

* External attacker can generate continuous interrupts
* CPU starvation → Denial of Service

**Severity:** HIGH

---

#### Vulnerability 3: Unsynchronized Asynchronous RX Input (Metastability)

* **Relevant CWE:** CWE-1384 (Improper Handling of Physical Signals)

**Description:**
The RX input (`ui_in[0]`) is asynchronous but directly sampled without synchronization:

```verilog
wire rx_pin = ui_in[0];
```

**Impact:**

* Metastability
* Unpredictable FSM behavior
* Potential system lock-up

**Severity:** MEDIUM

---

### CIA Triad Impact Summary

| Category        | Impact Level | Description                          |
| --------------- | ------------ | ------------------------------------ |
| Confidentiality | HIGH         | Internal data leakage via `uo_out`   |
| Integrity       | MEDIUM       | RX logic vulnerable to metastability |
| Availability    | HIGH         | Interrupt storm can halt CPU         |

---

### STRIDE Mapping

| Threat Type            | Description                                    |
| ---------------------- | ---------------------------------------------- |
| Spoofing               | Not directly applicable                        |
| Tampering              | External inputs manipulate internal states     |
| Repudiation            | Not applicable                                 |
| Information Disclosure | Data leak via `uo_out`                         |
| Denial of Service      | Interrupt flooding                             |
| Elevation of Privilege | Potential indirect exposure of privileged data |

---

### DREAD Risk Assessment

| Vulnerability | Damage | Reproducibility | Exploitability | Affected Users | Discoverability | Score | Severity |
| ------------- | ------ | --------------- | -------------- | -------------- | --------------- | ----- | -------- |
| Info Leak     | 9      | 10              | 10             | 10             | 9               | 48/50 | CRITICAL |
| Interrupt DoS | 8      | 10              | 10             | 10             | 7               | 45/50 | HIGH     |
| Metastability | 6      | 4               | 3              | 10             | 5               | 28/50 | MEDIUM   |

---

## 2. Countermeasure Implementation (Week 2)

To mitigate the identified vulnerabilities, we implemented several hardware-level security enhancements directly in the RTL.

---

### Implemented Feature 1: Hardware Pin Multiplexer (Leak Prevention)

**Objective:** Eliminate unintended data leakage from internal registers.

**Implementation Details:**

* Removed direct combinational assignment from `tx_reg` to `uo_out`
* Introduced a controlled pin multiplexer

```verilog
case(pinmux_sel)
  2'b00: uo_out = 8'b0;
  2'b01: uo_out = {6'b0, tx_busy, rx_valid};
  2'b10: uo_out = ui_in;
  2'b11: uo_out = 8'hFF;
endcase
```

**Effect:**

* Completely removes data leakage path
* Enforces principle of least privilege

---

### Implemented Feature 2: Interrupt Masking

**Objective:** Prevent external interrupt flooding attacks.

**Implementation Details:**

```verilog
if (ui_in[6] && div_reg[31])
    test_irq_latched <= 1'b1;
```

**Effect:**

* External input alone cannot trigger interrupts
* CPU protected from DoS attacks

---

### Implemented Feature 3: RX Input Synchronization

**Objective:** Eliminate metastability from asynchronous input.

**Implementation Details:**

```verilog
rx_sync1 <= ui_in[0];
rx_sync2 <= rx_sync1;
```

**Effect:**

* Ensures stable sampling
* Prevents undefined FSM states

---

## 3. Validation & Hardening ("Proof of Security")

To validate the effectiveness of the implemented countermeasures, targeted security tests were performed.

---

### Security Testing

We simulated an attack scenario using `tb_custom.v`.

**Test Case: Data Leakage Attempt**

* Write known sensitive value (e.g., `0xAB`) to `tx_reg`

**Results:**

* DP2: `uo_out` reflects internal data → leak confirmed
* DP3: `uo_out` remains `0x00` → leak eliminated

---

### Interrupt Attack Simulation

* External signal `ui_in[6]` toggled continuously

**Results:**

* Mask disabled → no interrupt triggered
* Mask enabled → controlled interrupt behavior

---

### Design Stability

All original functional tests were re-executed:

* UART TX/RX operation: PASS
* Bus interface: PASS
* Interrupt handling: PASS

Security enhancements do not affect functional correctness.

---

## 4. PPA Overhead Analysis

| Metric                | DP2 Baseline    | DP3 (Secure RTL) | Overhead / Change |
| --------------------- | --------------- | ---------------- | ----------------- |
| Total Cell Area       | 110,505.984 µm² | 110,505.984 µm²  | 0%                |
| Critical Path (Delay) | 2.56 ns         | 2.42 ns          | -5.47%            |
| Total Power           | 0.001846 µW     | 0.001852 µW      | +0.33%            |

---

### Analysis Results

* Area: No additional hardware footprint required
* Timing: Slight improvement due to structural refinement
* Power: Minimal increase, negligible impact

---

## 5. Conclusion

The DP2 UART controller prioritized PPA optimization but introduced critical security vulnerabilities.

Through DP3:

* All major vulnerabilities were identified and mitigated
* Secure RTL design principles were applied
* System robustness was significantly improved

**Key Takeaway:**
Security must be integrated into hardware design from the beginning, not added as an afterthought.

The final design achieves a strong balance between security, performance, and hardware efficiency.
