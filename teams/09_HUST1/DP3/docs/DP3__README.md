# RISC-V DMA Controller - Design Phase 3 (DP3) Documentation

## 1. Overview
This report details the security evaluation, threat mitigation, and hardware hardening of the `dma_top` (Direct Memory Access) module as part of Design Phase 3 (DP3). Initial security audits revealed critical vulnerabilities in the baseline design, specifically allowing unauthorized out-of-bounds memory access (CWE-119) and privilege escalation via a Confused Deputy attack (CWE-1280). 

To secure the SoC, we successfully designed and integrated a hardware-level **Address Boundary Filtering System** directly into the RTL. This mitigation acts as a lightweight Memory Protection Unit (MPU), employing a 33-bit addition logic to strictly enforce safe memory sandboxes and completely neutralize integer overflow attacks. Post-implementation validation and OpenLane PPA analysis confirm that the security patch is highly effective, incurring only a negligible area overhead (~3.2%) while surprisingly improving the critical path timing to 0.07 ns.

---

## 2. Vulnerability Assessment

During Week 1 of DP3, a comprehensive security audit was conducted on the baseline DMA design from DP2. We utilized standard threat modeling frameworks to identify critical hardware vulnerabilities.

### 2.1. CIA Triad & STRIDE Analysis
* **Confidentiality & Integrity (Information Disclosure & Tampering):** The baseline DMA design lacked access control. A malicious actor could program the `cfg_src_addr` to point to a secure memory region and set `cfg_dst_addr` to a public peripheral (leaking data) or overwrite critical system memory.
* **Availability (Denial of Service):** An attacker could program an infinitely large `cfg_byte_len`, causing the AXI bus to hang or flooding the CPU with `dma_irq` signals.
* **Spoofing & Elevation of Privilege:** The DMA acts as a "Confused Deputy," performing transactions on behalf of an initiator without validating the initiator's privilege level, effectively granting an attacker the highest system memory access privileges.

### 2.2. Identified Common Weakness Enumerations (CWE)
* **CWE-1280:** Access Control Bypass through Confused Deputy.
* **CWE-119:** Improper Restriction of Operations within Bounds.

### 2.3. Risk Evaluation (DREAD Model)
The "Unrestricted Memory Access" flaw (CWE-119/1280) received the highest DREAD score **(9.4/10 - CRITICAL)** due to its high exploitability, maximum damage potential, and broad discoverability. This vulnerability was prioritized for immediate mitigation.

---

## 3. Mitigation Strategy

To address the critical CWEs identified, we chose to implement a hardware-level **Address Boundary/Range Filtering System** (acting as a lightweight Memory Protection Unit - MPU) directly within the `dma_top` RTL. 

**Strategic Goals:**
1.  **Enforce a Safe Sandbox:** Restrict DMA operations strictly to a designated safe memory region (`SAFE_BASE_ADDR` to `SAFE_BOUND_ADDR`).
2.  **Prevent Integer Overflows:** Ensure that maliciously large payload lengths (`cfg_byte_len`) cannot cause the end-address calculation to wrap around and bypass boundary checks.
3.  **Proactive Interception:** Block illicit AXI transactions *before* they are issued to the bus and trigger a hardware security alarm (`security_violation`).

---

## 4. Implementation Details

The security features were integrated into the `dma_top.v` module using parameterized boundaries and combinational safety logic.

* **Hard-coded Security Parameters:** The sandbox is defined using parameters `SAFE_BASE_ADDR` (`32'h8000_0000`) and `SAFE_BOUND_ADDR` (`32'h80FF_FFFF`).
* **33-bit Addition for Overflow Protection:**
  To evaluate if a transfer exceeds the safe boundary, the hardware calculates the end address. To prevent integer overflow attacks (where a 32-bit sum wraps around to a small valid address), we implemented a 33-bit zero-extended addition:
  `({1'b0, cfg_src_addr} + {1'b0, cfg_byte_len} <= {1'b0, SAFE_BOUND_ADDR})`
* **Safe Configuration Logic:**
  Signals `is_src_safe` and `is_dst_safe` continuously monitor the APB configuration registers. The underlying AXI Master is only triggered via a localized `secure_cfg_start` signal, which requires both the source and destination addresses to be fully within the sandbox.
* **Security Alarm System:**
  If `cfg_start` is asserted while `is_config_safe` is low, the hardware suppresses the AXI transaction and immediately asserts `security_violation <= 1'b1`, which drives the `dma_irq` high to alert the CPU.

---

## 5. Validation & Proof of Security

To prove the effectiveness of the implemented MPU and ensure original functionality is preserved, we executed the following testbench scenarios:

1.  **Normal Operation (Functionality Preserved):** * *Action:* Configured transfer from `0x8000_1000` to `0x8000_2000` (Length: 256 bytes). 
    * *Result:* `secure_cfg_start` successfully asserted. Normal AXI transactions proceeded without triggering the security alarm.
2.  **Out-of-Bounds Attack (Targeting Protected OS Memory):** * *Action:* Configured `cfg_dst_addr` to `0x9000_0000` (outside `SAFE_BOUND_ADDR`).
    * *Result:* `is_dst_safe` evaluated to `1'b0`. The transaction was completely blocked from the AXI bus, and `security_violation` successfully triggered the interrupt.
3.  **Integer Overflow Attack (Bypass Attempt):** * *Action:* Configured `cfg_src_addr` = `0x80FF_FFF0` with a malicious `cfg_byte_len` = `0xFFFF_FFFF`.
    * *Result:* The 33-bit addition correctly identified the true sum exceeding the boundary limit. The attack was thwarted, and the alarm was triggered, proving the robustness of the 33-bit overflow countermeasure.

---

## 6. PPA Overhead Analysis

Adding security logic inherently incurs physical and operational costs. We synthesized both the baseline (DP2) and secure (DP3) RTL using OpenLane with the `sky130_fd_sc_hd` library to analyze the Area, Power, and Timing trade-offs.

* **Area Overhead:** The total cell count increased from 1931 (DP2) to 1993 (DP3), representing a minimal **~3.2% increase** in area. Total wire length increased by ~6.2%. The `PL_TARGET_DENSITY` was relaxed from 0.75 to 0.45 to accommodate routing the new 33-bit adders without congestion.
* **Power Overhead:** Due to the increased physical footprint, the typical switching power increased slightly from `0.000205 µW` to `0.000214 µW`, and internal power rose by ~7%. This is a highly acceptable trade-off for critical memory protection.
* **Timing / Performance:** Surprisingly, the critical path delay actually improved, dropping from `0.08 ns` (DP2) to **`0.07 ns` (DP3)**. The reduction in placement density provided the routing engine with more flexibility, allowing the secure design to maintain, and even slightly exceed, the operational frequency of the baseline chip.

**Conclusion:** The implemented Address Boundary Filtering successfully mitigates critical vulnerabilities (CWE-119, CWE-1280) with negligible area and power overhead, while maintaining excellent timing performance.
