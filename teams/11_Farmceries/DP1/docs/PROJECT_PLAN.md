# AI-HDL DP#1 Project Plan - Secure UART Peripheral Implementation

**Project**: Secure UART Peripheral with AES Encryption for TinyQV RISC-V Core  
**Team**: Team Farmceries  
**Deadline**: January 28, 2026  
**Milestone Review**: January 29, 2026

---

## Project Overview

### Objective

Design and implement a production-grade secure UART (Universal Asynchronous Receiver/Transmitter) peripheral with hardware encryption, FIFO buffers, and flow control that interfaces with the TinyQV RISC-V core via a 32-bit register-based interface.

### Success Criteria

1. ✅ Synthesizable RTL (passes Yosys) - **Phase 1 Complete**
2. ✅ Timing closure at 70 MHz (14ns clock period) - **Phase 1 Complete**
3. ✅ Passing testbenches (functional verification) - **Phase 1: 37/37 tests passing**
4. ✅ Complete PPA analysis (OpenLANE) - **Phase 1: 0.018mm², 0ns WNS**
5. ✅ Full documentation with LLM prompt logs - **Phase 1 Complete**
6. ❌ TX/RX FIFOs (16 bytes each) - **Phase 2: Descoped** (prioritized AES)
7. ❌ Hardware flow control (RTS/CTS) - **Phase 2: Descoped** (prioritized AES)
8. ✅ AES-128 encryption engine - **Phase 2 COMPLETE** (18/18 tests, 124K cells)
9. ✅ Secure communication integration - **Phase 2 COMPLETE** (full tt_wrapper synthesis)

---

## Technical Requirements (Enhanced)

### 1. Interface Requirements

**CPU Interface (Register-Based)**

-   32-bit address bus
-   32-bit data input/output
-   Read/write control signals
-   Compatible with TinyQV memory map
-   **Enhanced**: AES key registers (4 × 32-bit)

**UART Signals**

-   RX (Receive): `ui_in[7]` - Serial data input
-   TX (Transmit): `uo_out[0]` - Serial data output
-   **RTS (Request To Send)**: `uo_out[1]` - Flow control output
-   **CTS (Clear To Send)**: `ui_in[6]` - Flow control input
-   Interrupt: `user_interrupt` - Multiple interrupt sources

**Clock & Reset**

-   System clock: 70 MHz
-   Asynchronous active-low reset

### 2. Functional Requirements (Enhanced)

**Transmission (TX)**

-   Configurable baud rate (9600, 19200, 38400, 115200 bps)
-   8 data bits, No parity, 1 stop bit
-   **TX FIFO: 16 bytes** (buffering)
-   **CTS monitoring**: Pause transmission when remote busy
-   **AES encryption**: Encrypt blocks before transmission

**Reception (RX)**

-   Same baud rates as TX
-   Same frame format (8N1)
-   **RX FIFO: 16 bytes** (buffering)
-   **RTS assertion**: Signal remote to pause when FIFO nearly full
-   **AES decryption**: Decrypt blocks after reception
-   Interrupt on data ready / FIFO threshold

**Encryption (AES-128)**

-   Standard AES-128 encryption/decryption
-   128-bit block size (16 bytes)
-   Configurable encryption key (128-bit)
-   Automatic encryption on TX, decryption on RX
-   Integration with FIFO depth (16 bytes = 1 AES block)

**Registers (Memory-Mapped - Enhanced)**
| Address | Register | R/W | Description |
|---------|----------|-----|-------------|
| 0x00 | CTRL | W | Control: baud rate, enable, AES enable |
| 0x04 | STATUS | R | Status: TX/RX busy, FIFO counts, RTS/CTS |
| 0x08 | TX_DATA | W | Transmit data register |
| 0x0C | RX_DATA | R | Receive data register |
| 0x10 | INT_EN | R/W | Interrupt enable |
| 0x14 | INT_CLR | W | Interrupt clear |
| 0x18 | AES_KEY_0 | W | AES Key bits [31:0] |
| 0x1C | AES_KEY_1 | W | AES Key bits [63:32] |
| 0x20 | AES_KEY_2 | W | AES Key bits [95:64] |
| 0x24 | AES_KEY_3 | W | AES Key bits [127:96] |
| 0x28 | AES_CTRL | R/W | AES control (key load, mode) |
| 0x2C | FLOW_CTRL | R/W | Flow control config (RTS threshold) |

### 3. Performance Requirements (Updated)

**Timing**

-   Clock frequency: 70 MHz (14ns period)
-   Setup/hold timing: Must meet at all corners
-   Target WNS: 0 ns or better
-   AES latency: ~24 cycles per 128-bit block

**Area**

-   Die area budget: ~0.050 mm² (increased from basic UART)
-   Basic UART: 0.018mm² (525 cells)
-   Estimated additions:
    -   FIFOs: ~400-600 cells
    -   Flow control: ~50-100 cells
    -   AES-128: ~1500-2000 cells
    -   **Total estimate: ~2500-3200 cells**

**Power**

-   Typical power: < 15 µW (with AES active)
-   Idle power: < 5 µW
-   Minimize switching activity when idle

---

## Implementation Plan (Revised)

### Phase 1: Basic UART (Jan 17-20) ✅ COMPLETED

**Tasks:**

-   [x] Study UART fundamentals
-   [x] Review interface specifications
-   [x] Create block diagrams
-   [x] Define register map
-   [x] Set up project structure
-   [x] Implement baud generator
-   [x] Implement UART TX
-   [x] Implement UART RX
-   [x] Implement register interface
-   [x] Integration and testing (37 tests)
-   [x] Synthesis and PPA analysis

**Results:**

-   ✅ 37/37 tests passing
-   ✅ 0.01795mm² area
-   ✅ 0ns WNS (timing met)
-   ✅ 0.0014µW power
-   ✅ Complete documentation

**Deliverables:**

-   uart/UART_FUNDAMENTALS.md
-   uart/BLOCK_DIAGRAMS.md
-   PROJECT_PLAN.md (v1)
-   Basic UART Verilog modules
-   37 passing tests
-   DESIGN_REPORT.md
-   PPA_ANALYSIS.md

---

### Phase 2: FIFO Buffers & Flow Control (Jan 21-22) 🔄 IN PROGRESS

**Day 1 (Jan 21): TX/RX FIFOs**
**Tasks:**

-   [ ] Design TX FIFO (16 bytes, dual-pointer)
-   [ ] Design RX FIFO (16 bytes, dual-pointer)
-   [ ] Implement FIFO control logic (full/empty/count)
-   [ ] Add watermark detection
-   [ ] Update register interface for FIFO status
-   [ ] Create FIFO testbenches

**Verification:**

-   Test FIFO full/empty conditions
-   Verify watermark interrupts
-   Test overflow/underflow protection
-   Burst write/read tests

**Success Criteria:**

-   FIFOs correctly buffer data
-   Status flags accurate
-   No data loss on full/empty conditions
-   Tests passing

**Day 2 (Jan 22): Hardware Flow Control**
**Tasks:**

-   [ ] Implement RTS output logic (RX FIFO threshold-based)
-   [ ] Implement CTS input monitoring (TX pause logic)
-   [ ] Add flow control configuration registers
-   [ ] Update UART TX FSM for CTS checking
-   [ ] Create flow control testbenches

**Verification:**

-   Test RTS assertion when RX FIFO nearly full
-   Test TX pause when CTS asserted
-   Test resume when CTS deasserted
-   End-to-end flow control test

**Success Criteria:**

-   RTS correctly reflects RX FIFO status
-   TX properly pauses on CTS
-   Zero data loss with flow control
-   Tests passing

---

### Phase 3: AES-128 Encryption Engine (Jan 23-25) 🔄 PLANNED

**Day 1 (Jan 23): AES Core Components**
**Tasks:**

-   [ ] Implement S-Box (SubBytes transformation)
-   [ ] Implement ShiftRows logic
-   [ ] Implement MixColumns (Galois field multiplication)
-   [ ] Implement AddRoundKey (XOR operation)
-   [ ] Create component testbenches

**Verification:**

-   Test S-Box with NIST test vectors
-   Verify ShiftRows byte positions
-   Test MixColumns with known inputs
-   Component-level validation

**Day 2 (Jan 24): Key Expansion & Round Function**
**Tasks:**

-   [ ] Implement key expansion module (11 round keys)
-   [ ] Design round function FSM
-   [ ] Integrate SubBytes → ShiftRows → MixColumns → AddRoundKey
-   [ ] Implement encryption/decryption modes
-   [ ] Create round function testbenches

**Verification:**

-   Test key expansion with known keys
-   Verify 10-round encryption
-   Test with NIST standard test vectors
-   Timing verification (~24 cycles/block)

**Day 3 (Jan 25): AES Top-Level Integration**
**Tasks:**

-   [ ] Create AES top-level module
-   [ ] Add AES control registers
-   [ ] Implement AES key storage (128-bit)
-   [ ] Add encryption/decryption control
-   [ ] Comprehensive AES testing

**Verification:**

-   Full encryption/decryption cycle
-   Multiple key testing
-   Performance validation
-   Edge case testing

---

### Phase 4: Secure UART Integration (Jan 26) 🔄 PLANNED

**Tasks:**

-   [ ] Integrate AES with TX FIFO (encrypt before transmit)
-   [ ] Integrate AES with RX FIFO (decrypt after receive)
-   [ ] Update peripheral top-level module
-   [ ] Add AES registers to memory map
-   [ ] Create end-to-end secure communication tests

**Verification:**

-   Test plaintext → encrypt → transmit flow
-   Test receive → decrypt → plaintext flow
-   Verify encryption correctness
-   End-to-end loopback test
-   Performance measurement

**Success Criteria:**

-   Seamless AES integration
-   Correct encryption/decryption
-   All data path tests passing
-   Timing still met (70MHz)

---

### Phase 5: Synthesis & PPA Analysis (Jan 27) 🔄 PLANNED

**Tasks:**

-   [ ] Run Verilator linting on all new modules
-   [ ] Fix any lint warnings
-   [ ] Run Yosys synthesis
-   [ ] Analyze cell count and area
-   [ ] Run full OpenLANE PPA
-   [ ] Check timing, area, power metrics
-   [ ] Optimize if needed

**Verification:**

-   Synthesis: 0 errors, minimal warnings
-   Area: ≤ 0.050 mm²
-   Timing: WNS ≥ 0 ns
-   Power: ≤ 15 µW

**Success Criteria:**

-   Clean synthesis
-   All PPA targets met
-   Design fits within constraints

---

### Phase 6: Documentation & Submission (Jan 27-28) 🔄 PLANNED

**Day 1 (Jan 27): Technical Documentation**
**Tasks:**

-   [ ] Update DESIGN_REPORT.md (add FIFOs, flow control, AES)
-   [ ] Update PPA_ANALYSIS.md with new metrics
-   [ ] Update all README files
-   [ ] Organize prompt logs (Phase 2 logs)
-   [ ] Create final diagrams/screenshots

**Day 2 (Jan 28): Final Review & Submission**
**Tasks:**

-   [ ] Final testing (all 50+ tests)
-   [ ] Code review and cleanup
-   [ ] Final synthesis run
-   [ ] Create git tag: `DP1-Final-Submission`
-   [ ] Push to GitHub
-   [ ] Verify submission package

**Deliverables:**

-   Updated DESIGN_REPORT.md
-   Updated PPA_ANALYSIS.md
-   Complete prompt logs (Phases 1 & 2)
-   All test results
-   Synthesis reports
-   README updates

---

## Daily Schedule (Updated)

**Jan 17-20**: Basic UART ✅ COMPLETE
**Jan 21**: FIFOs 🔄 TODAY
**Jan 22**: Flow Control
**Jan 23**: AES Components
**Jan 24**: AES Integration (rounds + keys)
**Jan 25**: AES Top-Level
**Jan 26**: Secure UART Integration
**Jan 27**: Synthesis, PPA, Documentation
**Jan 28**: Final Review & Submission

---

## Risk Management (Updated)

**Verification:**

-   Write to CTRL, read back
-   Check STATUS flags
-   Verify TX_DATA write triggers transmission
-   Verify RX_DATA read clears RX_READY

**Success Criteria:**

-   All registers accessible
-   Baud rate changes correctly
-   Status flags accurate

---

### Phase 6: Integration & Testing (Jan 24-25)

**Tasks:**

-   [ ] Integrate all modules (TX, RX, baud gen, registers)
-   [ ] Update top-level peripheral.v
-   [ ] Create comprehensive testbench
-   [ ] Test loopback mode (TX → RX)
-   [ ] Test with TinyQV CPU interface
-   [ ] Run cocotb tests

**Test Scenarios:**

1. Basic loopback (connect TX to RX)
2. Multiple byte transmission
3. Different baud rates
4. FIFO full/empty conditions (if implemented)
5. Interrupt generation
6. Register read/write

**Success Criteria:**

-   All cocotb tests pass
-   Loopback test successful
-   No timing violations in simulation

---

### Phase 7: Synthesis & PPA (Jan 26)

**Tasks:**

-   [ ] Run synthesis: `./scripts/run_synthesis.sh --cleanup`
-   [ ] Fix any synthesis errors
-   [ ] Run full PPA: `./scripts/run_synthesis_and_ppa.sh ~vlsi/tools/OpenLane --cleanup`
-   [ ] Analyze timing reports
-   [ ] Optimize if needed (area/timing trade-offs)
-   [ ] Document PPA results

**Verification:**

-   Synthesis: 0 errors
-   WNS (Worst Negative Slack): 0 ns or better
-   Area: < 0.03 mm²
-   Power: < 10 µW

**Success Criteria:**

-   Clean synthesis
-   Timing closure
-   Reasonable area/power

---

### Phase 8: Documentation (Jan 27)

**Tasks:**

-   [ ] Complete DESIGN_REPORT.md
-   [ ] Complete PPA_ANALYSIS.md
-   [ ] Organize prompt logs
-   [ ] Create diagrams/screenshots
-   [ ] Update README.md
-   [ ] Final review

**Deliverables Structure:**

```
submission/
├── README.md                    # Executive summary
├── DESIGN_REPORT.md            # Technical details
├── PPA_ANALYSIS.md             # Metrics analysis
├── prompt_logs/
│   ├── 01_baud_generator.md
│   ├── 02_uart_tx.md
│   ├── 03_uart_rx.md
│   └── 04_integration.md
├── synthesis_reports/
│   ├── synthesis.log
│   └── openlane.log
├── testbench_results/
│   ├── cocotb_results.txt
│   └── waveforms/
└── media/
    ├── block_diagram.png
    └── layout_screenshot.png
```

**Success Criteria:**

-   All templates filled
-   Prompt logs complete
-   Clear, professional documentation

---

### Phase 9: Submission (Jan 28)

**Tasks:**

-   [ ] Final testing
-   [ ] Create git tag: `DP1-Submission`
-   [ ] Push to GitHub
-   [ ] Verify submission package
-   [ ] Submit via competition portal

**Final Checks:**

-   [ ] All code compiles
-   [ ] All tests pass
-   [ ] Documentation complete
-   [ ] PPA metrics documented
-   [ ] Git history clean

---

## Risk Management (Updated)

### Risk 1: AES Timing Closure

**Probability**: Medium-High  
**Impact**: High  
**Mitigation**:

-   Use iterative AES (reuse single round function)
-   Keep combinational paths short
-   Run synthesis incrementally
-   Pipeline AES if timing critical
-   **Fallback**: Reduce clock or simplify AES

### Risk 2: Area Budget Exceeded

**Probability**: Medium  
**Impact**: Medium  
**Mitigation**:

-   Iterative AES saves ~10× vs pipelined
-   ROM-based S-Box vs combinational
-   Optimize FIFO implementation
-   **Fallback**: Reduce FIFO depth or simplify AES

### Risk 3: Integration Complexity

**Probability**: Medium  
**Impact**: Medium  
**Mitigation**:

-   Test each module independently first
-   Incremental integration (FIFOs → Flow Control → AES)
-   Use waveform debugging extensively
-   **Fallback**: Submit with FIFOs + Flow Control only

### Risk 4: Time Constraints (Enhanced Scope)

**Probability**: Low-Medium  
**Impact**: High  
**Mitigation**:

-   Proven velocity: Basic UART in 2 days
-   Infrastructure already setup
-   AI-assisted acceleration
-   Clear 7-day roadmap
-   **Fallback**: Prioritize FIFOs + Flow Control, AES if time permits

### Risk 5: AES Functional Correctness

**Probability**: Low-Medium  
**Impact**: High  
**Mitigation**:

-   Use NIST FIPS 197 test vectors
-   Test each component independently
-   Validate with known AES implementations
-   AI can generate well-tested AES code
-   **Fallback**: Use simpler encryption or none

---

## Resource Requirements (Updated)

### Tools

-   ✅ Yosys (synthesis)
-   ✅ OpenLANE (PPA)
-   ✅ Cocotb (testing)
-   ✅ Icarus Verilog (simulation)
-   ✅ GTKWave (waveform viewing)
-   ✅ KLayout (layout viewing)

### Documentation

-   ✅ UART specification (created)
-   ✅ AES-128 fundamentals (created)
-   ✅ FIFO & Flow Control docs (created)
-   ✅ TinyQV interface spec (from example)
-   ✅ Automation scripts (created)

### Team Skills Needed

-   ✅ Verilog/SystemVerilog
-   ✅ Digital design fundamentals
-   ✅ Testbench creation (Cocotb)
-   ✅ LLM prompt engineering
-   ✅ Git workflow
-   🔄 Cryptography basics (AES)
-   🔄 FIFO design patterns

---

## Success Metrics (Updated)

### Technical Metrics - Phase 1 ✅

-   ✅ Synthesis: 0 errors, minimal warnings
-   ✅ Timing: WNS = 0 ns
-   ✅ Area: 0.018 mm²
-   ✅ Power: 0.0014 µW
-   ✅ Tests: 37/37 pass rate (100%)

### Technical Metrics - Phase 2 (Target)

-   [ ] Synthesis: 0 errors, < 20 warnings
-   [ ] Timing: WNS ≥ 0 ns @ 70MHz
-   [ ] Area: ≤ 0.050 mm²
-   [ ] Power: ≤ 15 µW
-   [ ] Tests: 50+ tests, 100% pass rate

### Process Metrics

-   ✅ Daily commits (Phase 1)
-   ✅ All prompts logged (Phase 1: 417KB)
-   [ ] Continuous documentation updates
-   [ ] Phase 2 prompt logs organized

### Deliverable Metrics

-   ✅ Phase 1 files complete
-   [ ] Phase 2 implementation complete
-   [ ] Updated documentation
-   [ ] Clean git history with proper tags

---

## Team Communication

**Daily Progress**: Document completion

-   What modules completed today?
-   What tests passing?
-   Any blockers or issues?

**LLM Interaction Log**: Track all prompts (Phase 2)

-   Save full conversations for AES, FIFOs, Flow Control
-   Note AI suggestions and iterations
-   Include debugging sessions

**Git Commits**: Clear, descriptive messages

-   Use conventional commits (feat:, fix:, docs:)
-   Reference phase and module
-   Keep commits atomic and meaningful

---

## Next Immediate Steps (Jan 21, 1:00pm)

1. ✅ **Updated documentation** - AES fundamentals, FIFO/Flow Control docs
2. ✅ **Reorganized docs** - uart/ and aes/ subdirectories
3. 🔄 **Update READMEs** - Reflect Secure UART scope
4. 🔄 **Start FIFO implementation** - TX FIFO first
5. **Log LLM prompts** - Begin Phase 2 conversation logs

---

**Status**: Phase 1 Complete ✅ | Phase 2 Documentation Complete ✅ | Ready for Implementation 🚀  
**Next Phase**: FIFO Buffers (Jan 21 afternoon)  
**Timeline**: On track for Jan 28 deadline

---

_Last Updated: January 21, 2026 - 1:50pm GMT+1_ 3. **Review BLOCK_DIAGRAMS.md** - Understand the architecture 4. **Start Phase 2** - Begin with baud rate generator 5. **Log first LLM prompt** - Save the conversation!

---

**Status**: Planning Complete ✅  
**Next Phase**: Baud Rate Generator (Jan 20)  
**Ready to Start**: Yes! 🚀
