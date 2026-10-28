# AI-HDL 2026 - Competitive Team Analysis

## Overview

This document compares the Farmceries team's work against other teams in AI-HDL 2026 design phases, extracted from Discord submissions and milestone reviews.

---

## Teams & Projects

### 1. **Farmceries** (Our Team)
**Focus**: Secure Communication Peripheral  
**GitHub**: https://github.com/[user]/team-farmceries-AI-HDL-2026/tree/basit-dp-1

#### Phase 1: Basic UART
- **Scope**: Production-grade UART with 4 configurable baud rates (9600-115200 bps)
- **Complexity**: 852 cells, 154 flip-flops
- **Functionality**: Full register interface, interrupt generation, 8N1 framing
- **Verification**: 37/37 tests passing (100%)
- **PPA Results**:
  - Area: 0.018 mm² (40% under 0.03mm² target)
  - Timing WNS: 0ns (perfect closure)
  - Power: 0.0014 µW (7000× under 10µW target)
- **Status**: ✅ Complete, production-ready

#### Phase 2: Secure UART with AES-128 Encryption
- **Scope**: Hardware-accelerated AES-128 encryption integrated into UART datapath
- **Complexity**: 98,584 cells (peripheral) / 124,778 cells (full system with CPU)
- **Functionality**: 
  - Transparent encryption/decryption via hardware
  - Dual independent AES cores (TX encrypt + RX decrypt simultaneously)
  - Full AES pipeline: S-box, ShiftRows, MixColumns, key expansion
  - 11 cycles per 128-bit block
  - Bypass mode for debugging
- **Performance**: 0.01% overhead (AES 8800× faster than UART)
- **Verification**: 18/18 tests passing (13 component + 5 integration tests)
- **Security**: AES-128 with 340 undecillion possible keys
- **Status**: ✅ Functional complete, synthesis done, pursuing full PPA analysis
- **Synthesis Challenge**: 98K-cell design exceeds local 22GB RAM for place & route

---

### 2. **Techgenius** (Team [user])
**Focus**: Security-Focused Hardware Acceleration  
**GitHub**: https://github.com/[user]/Techgenius-AI-HDL26

#### Project: Hardware Brute-Force Password Cracking Accelerator
- **Scope**: Verilog-based password cracking peripheral for TinyQV RISC-V
- **Functionality**:
  - Password candidate generation (odometer-style, 1-8 char lengths)
  - Multiple character set support
  - PIN and hash comparison modes
  - 64-bit attempt counter
  - Real-time speed measurement
  - Interrupt on success
- **Security Features**:
  - Pre-run authentication with 32-bit key
  - Anti-replay nonce protection
  - Constant-time comparisons (timing attack resistance)
  - Tamper detection + automatic zeroization
  - Rate limiting and session attempt limits
  - Forced re-authentication
  - Emergency zeroize command
  - Audit logging
- **Interface**: Register-based design
- **Verification**: Cocotb test coverage
- **Status**: ✅ Submitted for Milestone 1

---

### 3. **Obsidian Order** (Team Prudence)
**Focus**: Compute Acceleration  
**GitHub**: https://github.com/[user]/Obsidian-Order---AI-HDL-2026-Design-Phase-1

#### Initial Submission: GPIO Peripheral
- **Scope**: 8-bit GPIO peripheral platform
- **Functionality**: Write/read behavior, register interface
- **Verification**: Icarus Verilog simulation
- **Status**: Basic phase, planned cocotb tests and Yosys synthesis

#### Updated Submission: 2×2 Matrix Multiplier
- **Scope**: 16-bit fixed-point (8.8 format) matrix multiplication accelerator
- **Functionality**:
  - 2×2 matrix multiplication: C = A × B
  - 5-cycle computation
  - ~32× speedup vs software
  - Input change interrupt (sticky, edge-triggered)
- **Complexity**: ~250 cells, ~130 flip-flops
- **Performance**:
  - Timing: >50 MHz (64 MHz target met ✅)
  - Area: ~1500-2000 µm² (130nm estimate)
- **Verification**: 7/7 cocotb tests passing
- **Test Vector**: [[1,2],[3,4]] × [[5,6],[7,8]] = [[19,22],[43,50]] ✓
- **Documentation**: RTL (201 lines), Tests (425 lines), comprehensive README, prompts log
- **Innovation Justification**: Enables TinyML workloads (neural networks, sensor fusion, 2D graphics)
- **Status**: ✅ Complete with higher complexity than typical DP1

---

### 4. **HUST1** (Team OO/Soo)
**Focus**: System-Level Performance & Security  
**GitHub**: https://github.com/[user]/HUST1

#### Design Phase 1-2: DMA Controller (AHB-Lite)
- **Scope**: Direct Memory Access controller for RISC-V SoC
- **Functionality**: Data transfer offloading, high-speed memory/peripheral movement
- **Architecture**: Three main sub-modules via top-level wrapper
- **Protocol**: AHB-Lite bus standard
- **Status**: ✅ Initial submission

#### Design Phase 2-3: DMA Controller Evolution (AXI4/APB Hybrid)
- **Architecture Update**: Migrated from AHB-Lite to hybrid AXI4/APB
- **Features**: Decoupled data path, low-power circuit techniques
- **Status**: ✅ Enhanced implementation

#### Design Phase 3: Security Hardening
- **Scope**: Security evaluation and threat mitigation for DMA controller
- **Vulnerabilities Found**:
  - CWE-119: Out-of-bounds memory access (unauthorized access)
  - CWE-1280: Confused Deputy attack (privilege escalation)
- **Mitigation**: Hardware-level Address Boundary Filtering System
  - Lightweight Memory Protection Unit (MPU) in RTL
  - 33-bit addition logic for boundary enforcement
  - Memory sandboxing mechanism
  - Integer overflow attack neutralization
- **Results Post-Mitigation**:
  - Area overhead: Only 3.2% (highly efficient!)
  - Timing improvement: Critical path to 0.07 ns (optimization bonus!)
  - Security validation: Vulnerabilities neutralized
- **Status**: ✅ Security-hardened, post-OpenLane PPA validation complete

---

### 5. **CNN-ACCELERATOR** (Team [user])
**Focus**: ML Hardware Acceleration  
**GitHub**: https://github.com/[user]/CNN-ACCELERATOR

#### Project: Convolutional Neural Network Accelerator
- **Scope**: Hardware accelerator for CNN operations
- **Target**: ML workloads on custom hardware
- **Status**: Mentioned in office hours context, limited details available

---

## Comparative Analysis

### Project Complexity Ranking

| Rank | Team | Project | Complexity | Cells/Scope | Status |
|------|------|---------|-----------|-----------|--------|
| 1 | **Farmceries** | Secure UART + AES-128 | ⭐⭐⭐⭐⭐ | 124,778 cells | ✅ Phase 2 Complete |
| 2 | **HUST1** | DMA + AXI4/APB + Security | ⭐⭐⭐⭐ | Multi-phase evolution | ✅ Phase 3 Complete |
| 3 | **Techgenius** | Password Cracker (Security) | ⭐⭐⭐⭐ | Register-based accelerator | ✅ Submitted |
| 4 | **Obsidian Order** | Matrix Multiplier | ⭐⭐⭐ | ~250 cells | ✅ Complete |
| 5 | **CNN-ACCELERATOR** | CNN Accelerator | ⭐⭐⭐ | ML focused | 🔄 In progress |
| 6 | **Obsidian Order** | GPIO Peripheral | ⭐⭐ | Basic | ⚠️ Early phase |

### Feature Categories

#### Security Focus
- 🏆 **Farmceries**: AES-128 hardware encryption (communication security)
- 🏆 **Techgenius**: Anti-tampering, authentication, zeroization (operational security)
- 🏆 **HUST1**: Memory protection, boundary filtering (system security)

#### Compute Performance
- 🏆 **CNN-ACCELERATOR**: Neural network acceleration (specialized)
- 🏆 **Obsidian Order**: 32× speedup on matrix Math (vectorization)
- **Farmceries**: 8800× AES speedup over software (specialized)

#### System Integration
- 🏆 **HUST1**: Multi-phase SoC-level integration (DMA is centerpiece)
- 🏆 **Farmceries**: Full peripheral ecosystem (CPU integration tested)
- **Techgenius**: Peripheral-level integration (register interface)
- **Obsidian Order**: Standalone accelerator (limited SoC context)

#### Testing & Verification
- 🏆 **Farmceries**: 18/18 + 37/37 tests (55 total, 100% pass rate)
- 🏆 **Obsidian Order**: 7/7 tests (validated with Icarus)
- **Techgenius**: Cocotb coverage (details not specified)
- **HUST1**: OpenLane PPA validation (post-security audit)

#### Documentation Quality
- 🏆 **Farmceries**: Comprehensive (architecture diagrams, design report, PPA analysis, fundamentals guides, integration docs)
- 🏆 **Obsidian Order**: Detailed (README, prompts log, 425 lines of tests)
- 🏆 **HUST1**: Security audit report (threat analysis included)
- **Techgenius**: Register interface defined (implied comprehensive)

### PPA Metrics Comparison

| Team | Project | Area | Timing WNS | Power | Status |
|------|---------|------|-----------|-------|--------|
| **Farmceries (P1)** | Basic UART | 0.018 mm² ✅ | 0ns ✅ | 0.0014 µW ✅ | Complete |
| **Farmceries (P2)** | Sec. UART | TBD | TBD | TBD | Synthesis done |
| **Obsidian Order** | Matrix Mult. | 1500-2000 µm² | >50MHz ✅ | N/A | Complete |
| **HUST1 (P3)** | DMA+Security | 3.2% overhead | 0.07ns ✅ | N/A | Complete |
| **CNN-ACCELERATOR** | CNN | N/A | N/A | N/A | In progress |
| **Techgenius** | Password Cracker | N/A | N/A | N/A | Submitted |

---

## Competitive Strengths & Positioning

### Farmceries Team Advantages
✅ **Highest cell count** (124,778 cells) - demonstrates complexity handling  
✅ **Two-phase progression** - shows iterative design methodology  
✅ **Proven PPA metrics** - Phase 1 exceeds all targets significantly  
✅ **Best test coverage** - 55 total tests across two phases  
✅ **Exceptional power efficiency** - 7000× under target in Phase 1  
✅ **Cryptographic hardware** - industry-relevant security implementation  
✅ **Comprehensive documentation** - 6+ detailed technical documents  
✅ **Hardware-accelerated encryption** - differs from pure compute focus  

### Competitive Landscape

**Differentiation**:
- **Farmceries**: Security-first peripheral (encryption + communication)
- **Techgenius**: Security-focused accelerator (brute-force cracking)
- **HUST1**: System-level DMA with security hardening (platform architecture)
- **Obsidian Order**: Compute acceleration (Math operations)
- **CNN-ACCELERATOR**: ML specialization (neural networks)

**Our Unique Position**:
- Only team implementing transparent hardware encryption
- Largest cell count indicates advanced design complexity
- Two-phase evolution vs single-phase designs
- Production-ready Phase 1 with flawless metrics
- Security implementation differs from network/algorithmic focus

### Areas of Interest for Learning From Others

From **Techgenius**:
- Security hardening patterns (anti-tampering, constant-time ops)
- Tamper-resistant zeroization mechanisms
- Audit logging integration

From **HUST1**:
- Multi-phase evolution strategy (good for continued development)
- Security vulnerability assessment workflow
- Address boundary enforcement patterns

From **Obsidian Order**:
- Clean documentation structure
- Pragmatic test planning (7 focused tests)
- Performance optimization for specific workload (32× speedup)

---

## Conclusion

The AI-HDL competition shows diverse approaches to peripheral design:

1. **Farmceries** stands out for **cryptographic hardware integration** with **exceptional Phase 1 metrics** and **proven scalability** (852 → 124,778 cells)

2. **HUST1** demonstrates **platform-level thinking** with **security-by-design** evolution

3. **Techgenius** focuses on **security operation** (brute-force detection/prevention)

4. **Obsidian Order** emphasizes **computational efficiency** with clean methodology

5. **CNN-ACCELERATOR** represents **ML specialization** direction

**Overall Assessment**: Farmceries' work is competitive due to complexity handling, comprehensive testing, exceptional metrics, and unique security focus through cryptographic hardware rather than operational security or compute kernels.
