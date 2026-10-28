# DP3 Security Review Document — tqvp_belllabs_aes128

**Team Bell Labs (#63) | University of Lagos, Nigeria**
**Phase: Security Evaluation and Threat Mitigation**

---

## 1. Executive Summary of Security Posture
The initial DP2 design prioritized PPA and correctness, leaving the secret keys vulnerable to extraction via the memory-mapped bus. Following the DP3 hardening phase, the peripheral has transitioned to a **Hardened (Side-Channel Resistant)** posture. The implementation of **First-Order Boolean Masking** addresses the risk of Power Side-Channel Analysis (DPA), and **Dynamic Key Lockout** prevents unauthorized software readback. The design is now secure against the primary software and physical (passive) threat vectors.

## 2. CIA Analysis Table

| Pillar | Threat | Attack Scenario | Impact | Rating | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Confidentiality** | Key Extraction | Software reads register bank `0x00-0x0C`. | Loss of secret data. | **Critical** | **Mitigated** |
| **Integrity** | Bus Snooping | Malicious write to `PLAIN_W` during encryption. | Result corruption. | **High** | **Mitigated** |
| **Availability** | FSM Hang | Sending `START` bit during active encryption. | Peripheral Lockup. | **Medium** | **Mitigated** |

## 3. STRIDE Threat Model Table

| Category | Hardware Attack Scenario | Feasibility | Status |
| :--- | :--- | :--- | :--- |
| **Spoofing** | N/A (Simple APB peripheral). | Low | Acceptable |
| **Tampering** | Overwriting keys while FSM is in `ST_ENC` state. | **High** | **Mitigated** |
| **Repudiation** | N/A (No access logging). | Low | Acceptable |
| **Info Disclosure** | **Key Register Readback** via memory-mapped bus. | **High** | **Mitigated** |
| **DoS** | **Interrupt Flooding** via continuous start commands. | **Medium** | **Mitigated** |
| **Elev. Privilege** | Stealing OS keys from HW via user-level read. | **High** | **Mitigated** |

## 4. DREAD Scoring (Sorted by Severity)

| Threat | Damage | Repro | Exploit | Affected | Disc | **Total** | Status |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Key Register Readback** | 10 | 10 | 10 | 10 | 10 | **50** | **MITIGATED** |
| **Power Side-Channel (DPA)** | 9 | 5 | 4 | 10 | 7 | **35** | **MITIGATED** |
| **Bus Snooping (Tampering)** | 8 | 10 | 8 | 5 | 8 | **39** | **MITIGATED** |
| **Information Residue** | 7 | 8 | 6 | 5 | 6 | **32** | **MITIGATED** |

## 5. CWE Mapping Table

| CWE ID | Name | Mitigation in tqvp_belllabs_aes128 |
| :--- | :--- | :--- |
| **CWE-1271** | Insecure Register Access | Key lockout returns `0xDEADBEEF` post-start. |
| **CWE-1301** | Insufficient Protection of HW State | Write-enables ignored during `ST_ENC`. |
| **CWE-385** | Timing Side-Channel | Fixed 10-cycle iterative round logic. |
| **CWE-1234** | Improper Power Side-Channel | First-order Boolean Masking active. |
| **CWE-226** | Residual Information Leakage | Ciphertext cleared on new encryption start. |

## 6. Overall Security Risk Rating: LOW
**Justification:** The primary critical vulnerabilities (Key Readback and DPA) have been systematically addressed through architectural hardening and randomization logic. While invasive physical attacks (e.g., silicon probing) remain a residual risk, the peripheral is now highly resilient to the vast majority of software-initiated and physical side-channel attacks.

---
*Team Bell Labs | Final DP3 Security Audit*
