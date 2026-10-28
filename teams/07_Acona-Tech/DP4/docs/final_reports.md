# FINAL PROJECT REPORT
## AI-HDL 2026 Hardware Design Competition
**Design Phases 1 through 4**
**Team:** Acona-Tech
**Design:** AES-128 Secure Accelerator on TinyQV RISC-V SoC
**Target PDK:** SkyWater Sky130 (sky130_fd_sc_hd)
**Target Frequency:** 64 MHz | **Die Area:** 1500 × 1500 µm
**Date:** April 27, 2026

---

## Table of Contents
*(Belge içindeki başlık hiyerarşisi kullanılarak otomatik oluşturulabilir)*

---

## 1. Executive Summary
This report documents the complete 16-week journey of Team Acona-Tech in the AI-HDL 2026 Hardware Design Competition, from initial AES-128 implementation (DP1) through security hardening (DP3) to final chip tapeout (DP4). Our design is a security-hardened AES-128 encryption accelerator integrated as a peripheral on the TinyQV RISC-V SoC, targeting the SkyWater Sky130 process node. The final tapeout achieved all critical milestones: timing closure at the target 64 MHz frequency with +3.73 ns positive setup slack, zero DRC violations, clean LVS verification ("Circuits match uniquely"), and full retention of all security countermeasures including masked S-Box side-channel protection, LFSR-based masking, and fault injection detection.

### 1.1 Final Metrics Summary

The following table summarizes our final metrics:

| Metric | Target | Achieved |
|---|---|---|
| Clock Frequency | 64 MHz | 64 MHz ✓ |
| Setup Slack (WNS) | ≥ 0 ns | +3.73 ns ✓ |
| Hold Slack | ≥ 0 ns | +0.07 ns ✓ |
| TNS | 0 ns | 0.00 ns ✓ |
| DRC Violations | 0 | 0 ✓ |
| LVS | Clean | Circuits match uniquely ✓ |
| Total Devices | — | 45,702 |
| Total Nets | — | 45,414 |
| Die Size | ≤ 1500 µm | 1488.56 × 1476.96 µm ✓ |
| Core Utilization | 40–50% | ~45% |
| Security Features | Retained | All 5 countermeasures ✓ |

---

## 2. Design Phase 1: Base AES-128 Implementation

### 2.1 Objective
Implement a functionally correct AES-128 encryption/decryption engine in SystemVerilog, validated against NIST test vectors, with clean synthesis through Yosys targeting Sky130.

### 2.2 Architecture
The DP1 baseline design implemented a standard iterative AES-128 architecture performing one round per clock cycle across 10 encryption rounds (12 total cycles including key loading and output). The design featured a 256-entry lookup-table S-Box, standard MixColumns using xtime multiplication, and sequential key expansion.

### 2.3 Results

| Metric | DP1 Result |
|---|---|
| Functionality | NIST FIPS-197 test vectors passing |
| Logic Depth | ~36 levels |
| Estimated Fmax | ~55 MHz |
| Latency | 12 clock cycles per block |
| Competition Score | 88/100 (8th place) |

### 2.4 DP1 Scorecard Analysis

| Category | Weight | Our Score | Top Score |
|---|---|---|---|
| Implementation | 30% | 25/30 | 29/30 |
| Verification | 25% | 22/25 | 25/25 |
| Documentation | 25% | 23/25 | 24/25 |
| Code Quality | 20% | 18/20 | 20/20 |

> **Key takeaway:** Implementation and verification were identified as primary improvement areas for subsequent phases.

---

## 3. Design Phase 2: PPA Optimization

### 3.1 Objective
Optimize the AES-128 design for improved Performance, Power, and Area (PPA) metrics while maintaining functional correctness. Target: achieve 64 MHz timing closure on Sky130.

### 3.2 Optimizations Implemented
Four major architectural optimizations were applied to create the v4 AES accelerator:

#### 3.2.1 Clock Gating (ICG)
Integrated clock gating cells were added to gate the AES core and key expansion clocks when not actively processing. This reduces dynamic power consumption by preventing unnecessary switching in idle modules.

#### 3.2.2 Fast MixColumns
The MixColumns transformation was re-architected to reduce logic depth. By pre-computing common subexpressions and optimizing the xtime operation to a single logic level, the combinational depth was reduced from approximately 8–10 levels to 5–6 levels.

#### 3.2.3 Unrolled Key Expansion
Round keys were pre-computed in a fully unrolled key expansion module, eliminating the sequential key scheduling bottleneck. This trades area for timing performance, enabling single-cycle key availability for each round.

#### 3.2.4 Pipelined Key Fetch
Key fetching was overlapped with round computation through pipelining, hiding the key memory access latency behind the S-Box and MixColumns computation.

### 3.3 Results

| Metric | DP1 (v1) | DP2 (v4) |
|---|---|---|
| Logic Depth | 36 levels | 24 levels (−33%) |
| Area Overhead | Baseline | +1.5% |
| Estimated Fmax | ~55 MHz | ~80 MHz |
| Latency | 12 cycles | 22 cycles |
| Throughput | 586 Mbps | 465 Mbps* |

> **\*Note:** Cycle count increased due to unrolled key expansion, but the higher Fmax compensates. At the target frequency of 100+ MHz (achievable with 24 logic levels), v4 throughput matches or exceeds v1.

---

## 4. Design Phase 3: Security Hardening

### 4.1 Objective
Conduct a vulnerability assessment of the AES accelerator against known hardware security threats (CWEs) and implement countermeasures to create a security-hardened design suitable for real-world deployment.

### 4.2 Threat Model
Five primary attack vectors were identified and addressed:

| CWE | Threat | Countermeasure | Module |
|---|---|---|---|
| CWE-1300 | Side-channel (DPA) via S-Box power signature | Boolean masking with random masks | aes_sbox_masked |
| CWE-1255 | Insufficient key zeroization | Hardware key lock + zeroize register | aes_reg_interface_secure |
| CWE-1259 | Predictable masking patterns | 32-bit LFSR with unique seed requirement | aes_masking_lfsr |
| CWE-1247 | Fault injection attacks | Shadow round counter with mismatch detection | aes_fault_detector |
| CWE-1234 | Unauthorized register access | Privileged access control on security registers | aes_reg_interface_secure |

### 4.3 Security Feature Details

#### 4.3.1 Masked S-Box (Anti-DPA)
Each S-Box instance was replaced with a Boolean-masked variant that applies a random mask before the substitution and removes it afterward. This ensures that the power consumption during S-Box lookup is decorrelated from the actual data being processed, defeating first-order Differential Power Analysis (DPA) attacks. The design uses 16 masked S-Box instances operating in parallel for full AES state coverage.

#### 4.3.2 LFSR Masking Engine
A 32-bit Linear Feedback Shift Register generates pseudo-random masks for the S-Box masking scheme. The LFSR requires explicit seeding before operation (the valid signal indicates seeding completion) and uses a maximal-length polynomial to ensure uniform mask distribution over 2^32 − 1 cycles.

#### 4.3.3 Fault Detection
A shadow round counter runs independently of the main AES state machine, tracking the expected round progression. Any mismatch between the main counter and the shadow counter triggers a fault_detected signal, which invalidates the output (output_valid goes low) and can trigger an interrupt. This defeats fault injection attacks that attempt to skip rounds or corrupt intermediate state.

#### 4.3.4 Key Security Registers
The register interface implements key_locked and key_zeroized control registers. Once key_locked is asserted, the key registers become read-only, preventing runtime key modification. The zeroize function overwrites all key material with zeros on command, ensuring sensitive data does not persist in registers after operation.

### 4.4 PPA Impact of Security Features

| Feature | Area Overhead | Timing Impact |
|---|---|---|
| Masked S-Boxes (16x) | +~60% S-Box area | Increased critical path depth |
| LFSR Engine | Minimal (~200 gates) | None (parallel path) |
| Fault Detector | Minimal (~100 gates) | None (parallel path) |
| Secure Registers | Minimal (~150 gates) | None (register access path) |

---

## 5. Design Phase 4: Netlist to Chip Tapeout

### 5.1 Objective
Execute the complete RTL-to-GDSII physical design flow: integrate the DP3-hardened AES accelerator into the TinyQV RISC-V peripheral harness, run synthesis, placement, CTS, routing, and achieve DRC/LVS-clean sign-off at the target 64 MHz frequency.

### 5.2 Peripheral Integration
The AES accelerator was integrated into the TinyQV RISC-V SoC as a memory-mapped SPI peripheral. The integration required three modifications to the template harness: (1) widening the address bus from 6-bit to 7-bit to accommodate the expanded security register space, (2) changing the instantiated module name to tqvp_aes128_secure, and (3) updating the SPI register bridge ADDR_W parameter to match. Two infrastructure modules (spi_reg and synchronizer) were required by the harness but not included in the template repository. These were written from scratch based on the port interface specification visible in the harness instantiation.

### 5.3 RTL Debugging Iterations
Multiple synthesis and LVS failures were encountered and systematically resolved:

| # | Issue | Root Cause | Fix |
|---|---|---|---|
| 1 | RTL validation failed | SystemVerilog keywords (logic, always_ff) in Yosys Verilog-2005 mode | Automated SV→Verilog conversion |
| 2 | LVS FAIL | Latch-based clock gate not synthesizable by Yosys | Replaced with direct wire passthrough |
| 3 | LVS FAIL (persistent) | output reg + assign conflict in aes_masking_lfsr | Changed output reg to output wire |
| 4 | Server error | Autotapeout cloud platform instability | Migrated to local OpenLane |

### 5.4 Cloud vs. Local Tapeout
Initial tapeout attempts used the competition-provided Autotapeout cloud platform. Despite resolving all RTL issues, the platform consistently produced timing violations (WNS = −92.92 ns at 64 MHz) and LVS failures. Investigation revealed that Autotapeout lacks the multi-pass resizer and CTS timing optimizations present in a full OpenLane flow. The team migrated to a local OpenLane v1.0.2 installation (Docker-based, WSL2 Ubuntu) with the Sky130A PDK. The identical RTL achieved timing closure at 64 MHz on the first local run, confirming that the RTL was sound and the issue was purely in the cloud platform’s simplified optimization pipeline.

| Metric | Autotapeout (Best) | Local OpenLane |
|---|---|---|
| WNS | −67.40 ns (VIOLATED) | 0.00 ns (CLEAN) |
| TNS | −103,994 ns | 0.00 ns |
| LVS | FAIL | CLEAN |
| DRC | CLEAN | CLEAN |
| Setup Slack | Negative | +3.73 ns |
| Optimization Passes | Single-pass synthesis | Multi-pass resizer + CTS opt |
| STA Corners | Single corner | Multi-corner (min/nom/max) |

### 5.5 Physical Design Flow (OpenLane v1.0.2)
The complete 42-step OpenLane flow executed successfully:

| Step | Stage | Tool | Result |
|---|---|---|---|
| 1 | Synthesis | Yosys | Clean |
| 3–6 | Floorplan + PDN | OpenROAD | 1488 × 1477 µm |
| 7–11 | Placement + Optimization | OpenROAD | Clean |
| 12–14 | Clock Tree Synthesis | OpenROAD | Clean |
| 15–23 | Routing + Fill | OpenROAD | 0 DRC violations |
| 25–31 | SPEF + Multi-Corner STA | OpenROAD | WNS=0, TNS=0 |
| 33–34 | GDSII Export | Magic + KLayout | 122 MB GDS |
| 35 | XOR Verification | KLayout | No differences |
| 36–39 | LVS | Magic + Netgen | Circuits match |
| 40 | DRC | Magic | 0 violations |
| 41–42 | Antenna + ERC | OpenROAD | Clean |

---

## 6. Final PPA Metrics

### 6.1 Performance

| Parameter | Value |
|---|---|
| Target Clock | 64 MHz (15.625 ns period) |
| Worst Negative Slack (Setup) | 0.00 ns |
| Worst Slack (Setup) | +3.73 ns |
| Worst Slack (Hold) | +0.07 ns |
| Total Negative Slack | 0.00 ns |
| Achievable Fmax (est.) | ~84 MHz (from 15.625 − 3.73 = 11.9 ns) |
| Encryption Latency | 22 clock cycles per 128-bit block |
| Throughput @ 64 MHz | 128 × 64M / 22 ≈ 372 Mbps |

### 6.2 Power
Power analysis was performed using OpenSTA with parasitic extraction (SPEF) at the nominal process corner. Detailed power numbers are available in the 31-rcx_sta.power.rpt sign-off report included in the submission package.

### 6.3 Area

| Parameter | Value |
|---|---|
| Die Size | 1488.56 × 1476.96 µm |
| Total Devices | 45,702 |
| Total Nets | 45,414 (14 disconnected pins) |
| Core Utilization | ~45% |
| GDSII File Size | 122 MB |

---

## 7. Security Features in Final Tapeout
All five security countermeasures implemented in DP3 were successfully carried through to the final GDSII without compromise. This was a deliberate design decision — when timing closure appeared difficult, the team chose to preserve all security features rather than remove them for easier timing convergence.

| Feature | Description | Status in GDS |
|---|---|---|
| Masked S-Box | 16 Boolean-masked S-Box instances for anti-DPA | Retained ✓ |
| LFSR Masking | 32-bit PRNG for mask generation | Retained ✓ |
| Fault Detection | Shadow round counter with output invalidation | Retained ✓ |
| Key Lock | Hardware write-protect on key registers | Retained ✓ |
| Key Zeroize | One-command key material destruction | Retained ✓ |

---

## 8. Design Evolution: DP1 to DP4

| Aspect | DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|---|
| Focus | Functional AES | PPA Optimization | Security Hardening | Physical Tapeout |
| Logic Depth | 36 levels | 24 levels | 24+ (masked) | 24+ (masked) |
| S-Box Type | Standard LUT | Standard LUT | Boolean Masked | Boolean Masked |
| Security | None | None | 5 countermeasures | 5 countermeasures |
| Target Freq | 55 MHz (est) | 80 MHz (est) | 64 MHz | 64 MHz (met ✓) |
| Toolchain | Yosys | Yosys | Yosys | OpenLane |
| Output | RTL + TB | Optimized RTL | Hardened RTL | GDSII |

---

## 9. AI Tool Usage
Claude (Anthropic, Opus model) was used as an AI co-pilot throughout all design phases. A detailed AI interaction log is provided as a separate supplementary document (AI_Assisted_Design_Log_DP4_Acona.docx).

### 9.1 AI Contributions by Phase

| Phase | AI Contribution | Human Decision |
|---|---|---|
| DP1 | AES architecture guidance, testbench generation | Architectural choices, verification strategy |
| DP2 | Optimization strategies, timing analysis | Which optimizations to pursue, area/timing tradeoffs |
| DP3 | Security countermeasure implementation, CWE analysis | Threat model prioritization, security vs PPA tradeoffs |
| DP4 | RTL integration, debugging, OpenLane setup, config | Tool selection (local vs cloud), preserve security features |

### 9.2 Key Human Decision
The most significant human decision in DP4 was the refusal to remove security features (masked S-Boxes) when timing closure appeared impossible at 64 MHz. The AI suggested removing masking to reduce critical path depth, but the team chose to preserve all countermeasures. This decision was validated when the local OpenLane flow achieved timing closure with all security features intact.

---

## 10. Reflections and Lessons Learned

### 10.1 Technical Lessons
1. **RTL portability is critical:** Code that simulates correctly may fail synthesis on different tool frontends. We learned to validate RTL compatibility with the target synthesis tool (Yosys Verilog-2005) early, not at tapeout time.
2. **Never mix output reg with assign:** This Verilog anti-pattern caused persistent LVS failures that were difficult to diagnose. We now use a strict coding standard where assign-driven outputs are always declared as output wire.
3. **Local tooling provides essential control:** Cloud platforms simplify the flow but may lack critical optimization passes. For complex designs, a local OpenLane installation is indispensable.
4. **Security features need not compromise performance:** Our final design proves that a fully security-hardened AES-128 can meet a 64 MHz timing target on Sky130 with proper synthesis optimization. The key is not removing features but letting the physical design tools (resizer, CTS optimization) do their job.

### 10.2 Process Lessons
1. **Start physical design early:** DP4 was compressed into 2 weeks, and debugging tool compatibility issues consumed valuable time. Earlier OpenLane experimentation would have identified the SystemVerilog and clock gate issues before the deadline pressure.
2. **Maintain multiple tapeout paths:** Having both Autotapeout (cloud) and OpenLane (local) available proved essential when the cloud platform experienced server errors during crunch time.
3. **AI-assisted debugging accelerates iteration:** Log analysis that might take hours of manual inspection was reduced to minutes through AI-assisted pattern recognition. The output reg/assign conflict, in particular, was identified from a single warning line in a multi-hundred-line synthesis log.

### 10.3 Competition Lessons
1. **Security-first design is viable:** Many teams may drop security features to simplify tapeout. Our experience shows that with proper tooling, all security countermeasures can be retained through to GDSII.
2. **Documentation matters:** Our AI interaction log provides full transparency on how AI was used, which we believe demonstrates responsible and effective AI-assisted hardware design.

---

## 11. Submission Package Contents

| Deliverable | File / Location |
|---|---|
| Final GDSII | tt_um_tqv_peripheral_harness.gds (122 MB) |
| RTL Source | aes128_secure_tapeout.v (13 modules, 2544 lines) |
| OpenLane Config | config.json |
| DRC Report | reports/drc.rpt — 0 violations |
| LVS Report | reports/39-tt_um_tqv_peripheral_harness.lvs.rpt — Circuits match |
| STA Reports | reports/31-rcx_sta.summary.rpt + multi-corner (min/nom/max) |
| Power Report | reports/31-rcx_sta.power.rpt |
| Metrics | reports/metrics.csv |
| Manufacturability | reports/manufacturability.rpt |
| XOR Check | reports/35-xor.rpt — No differences |
| This Report | Final_Project_Report_Acona_DP1_DP4.docx |
| AI Design Log | AI_Assisted_Design_Log_DP4_Acona.docx |
| GitHub Tag | DP4-Submission |
