# DP1 Report — Bell Labs — AES-128 Encryption Engine Peripheral

**AI Hardware Design League 2026 | Team #63 | University of Lagos, Nigeria**
**Mentor: Kevin Immanuel Gubbi**

---

## 1. Executive Summary

Team Bell Labs designed and implemented a fully functional AES-128 encryption engine peripheral (`tqvp_belllabs_aes128`) for the TinyQV RISC-V processor core as part of Design Phase 1 of AI-HDL 2026. The module uses an iterative architecture that performs one complete AES round per clock cycle, encrypting a 128-bit plaintext block in exactly 10 clock cycles at 64 MHz. The design was generated using an AI-first methodology with Claude (Anthropic) as the primary LLM tool, verified against the OpenSSL industry-standard AES implementation, and successfully synthesized to 12,287 standard cells using Yosys targeting the SkyWater Sky130 process.

---

## 2. Design Choice and Rationale

### Why AES-128?

AES-128 was selected as the target module for the following reasons:

**Complexity scoring.** The competition classifies modules into three tiers: Simple (GPIO, PWM), Medium (UART, SPI), and Complex (AI Accelerator, AES Engine, DMA Controller). AES-128 falls in the Complex tier, earning the highest possible Innovation Points in the DP1 grading rubric.

**AI generability.** AES-128 is a well-documented international standard (FIPS 197). This makes it an ideal candidate for AI-first design because LLMs have strong knowledge of its operations (SubBytes, ShiftRows, MixColumns, AddRoundKey, KeySchedule), enabling reliable and verifiable code generation.

**DP3 security synergy.** An encryption engine has natural and deep security implications — power side-channel attacks, key register exposure, fault injection — making it the strongest possible foundation for Design Phase 3 (Security Evaluation). The module was designed from the start with DP3 in mind, including a key lockout feature that prevents key register readback once encryption begins.

**Real-world relevance.** AES-128 is the global standard for symmetric encryption, used in TLS, Wi-Fi, disk encryption, and billions of embedded devices. Implementing it in hardware accelerates encryption by orders of magnitude compared to software execution on the RISC-V core.

---

## 3. Module Architecture

### ASCII Block Diagram

```
  TinyQV RISC-V Core
         │
    ┌────▼─────────────────────────────────────────────────┐
    │              tqvp_belllabs_aes128                    │
    │                                                      │
    │  ┌──────────────┐    ┌─────────────────────────────┐ │
    │  │ Register File│    │     AES Engine (Iterative)  │ │
    │  │              │    │                             │ │
    │  │  KEY_W0..W3  │───▶│  ┌──────────────────────┐  │ │
    │  │  PLAIN_W0..3 │───▶│  │  Initial AddRoundKey │  │ │
    │  │  CTRL/STATUS │    │  └──────────┬───────────┘  │ │
    │  │  CIPHER_W0..3│◀───│             │               │ │
    │  └──────────────┘    │  ┌──────────▼───────────┐  │ │
    │                      │  │  Round Function x10  │  │ │
    │  6-bit address bus   │  │  SubBytes+ShiftRows  │  │ │
    │  32-bit data bus     │  │  MixColumns          │  │ │
    │  data_write_n [1:0]  │  │  AddRoundKey         │  │ │
    │  data_read_n  [1:0]  │  │  KeySchedule         │  │ │
    │  data_ready          │  └──────────┬───────────┘  │ │
    │  user_interrupt      │             │               │ │
    │                      │  ┌──────────▼───────────┐  │ │
    │                      │  │  Ciphertext Output   │  │ │
    │                      │  └──────────────────────┘  │ │
    │                      └─────────────────────────────┘ │
    └──────────────────────────────────────────────────────┘
```

### Register Map

| Address (hex) | Register   | Direction | Description                     |
|---------------|------------|-----------|---------------------------------|
| 0x00          | KEY_W0     | Write     | AES key bits [31:0]             |
| 0x04          | KEY_W1     | Write     | AES key bits [63:32]            |
| 0x08          | KEY_W2     | Write     | AES key bits [95:64]            |
| 0x0C          | KEY_W3     | Write     | AES key bits [127:96]           |
| 0x10          | PLAIN_W0   | Write     | Plaintext bits [31:0]           |
| 0x14          | PLAIN_W1   | Write     | Plaintext bits [63:32]          |
| 0x18          | PLAIN_W2   | Write     | Plaintext bits [95:64]          |
| 0x1C          | PLAIN_W3   | Write     | Plaintext bits [127:96]         |
| 0x20          | CTRL       | Write     | bit[0] = START                  |
| 0x24          | STATUS     | Read      | bit[0]=DONE, bit[1]=BUSY        |
| 0x28          | CIPHER_W0  | Read      | Ciphertext bits [31:0]          |
| 0x2C          | CIPHER_W1  | Read      | Ciphertext bits [63:32]         |
| 0x30          | CIPHER_W2  | Read      | Ciphertext bits [95:64]         |
| 0x34          | CIPHER_W3  | Read      | Ciphertext bits [127:96]        |

### State Machine

```
        rst_n=0
           │
           ▼
    ┌─────────────┐
    │   ST_IDLE   │◀──────────────────────┐
    └──────┬──────┘                       │
           │ CTRL[0]=1 written            │ rst_n=0
           ▼                              │
    ┌─────────────┐                       │
    │   ST_ENC    │  (10 clock cycles)    │
    │  round 1..10│                       │
    └──────┬──────┘                       │
           │ round==10                    │
           ▼                              │
    ┌─────────────┐  CTRL[0]=1 written    │
    │   ST_DONE   │──────────────────────▶ ST_ENC
    └─────────────┘
```

### Port List

| Port         | Width | Direction | Description                          |
|--------------|-------|-----------|--------------------------------------|
| clk          | 1     | input     | 64 MHz system clock                  |
| rst_n        | 1     | input     | Active-LOW synchronous reset         |
| ui_in        | 8     | input     | Input PMOD (UART RX on bit 7)        |
| uo_out       | 8     | output    | Output PMOD (UART TX on bit 0)       |
| address      | 6     | input     | 6-bit byte-addressed register select |
| data_in      | 32    | input     | 32-bit write data from CPU           |
| data_write_n | 2     | input     | Write width: 11=none 00=8b 01=16b 10=32b |
| data_read_n  | 2     | input     | Read width: same encoding            |
| data_out     | 32    | output    | 32-bit read data to CPU              |
| data_ready   | 1     | output    | Always 1 — reads complete in 1 cycle |
| user_interrupt | 1   | output    | 1-cycle pulse when encryption finishes |

---

## 4. AI-First Methodology

### Tools Used

- **Claude (Anthropic)** — Primary LLM for architecture design, Verilog code generation, testbench generation, synthesis scripting, and debugging.

### AI Role at Each Stage

**Architecture design (Prompt 1.2).** Claude was used to design the module architecture before any code was written. It produced the block diagram, register map, state machine design, and port list. This gave a clear specification that the code generation prompts could then target precisely.

**Verilog code generation (Prompt 1.3).** The complete 305-line AES-128 peripheral Verilog was generated by Claude. The prompt specified exact requirements: module name, active-low reset convention, TinyQV port interface, iterative architecture, complete S-box lookup table, full key schedule, and 4-state FSM. The generated code was accepted with no manual modifications.

**Testbench generation (Prompt 1.3).** Claude generated a complete Verilog testbench using the NIST AES-128 test vector, including write and read task implementations for the 32-bit bus interface and a polling loop on the STATUS register.

**Debugging (Prompt 1.D2).** When the testbench initially reported TEST FAILED, Claude performed a systematic analysis. It cross-validated the module output against OpenSSL (the industry-standard AES library), which confirmed that the Verilog module was cryptographically correct. The testbench had been initialized with an incorrect expected ciphertext value. This was corrected and the test passed.

**Synthesis scripting (Prompt 1.4).** Claude generated the Yosys `.ys` synthesis script targeting the sky130_fd_sc_hd standard cell library, with full explanations of each command.

### Total Prompts Used in DP1

| Prompt | Purpose                                  |
|--------|------------------------------------------|
| 1.2    | Architecture and register map design     |
| 1.3    | Testbench generation                     |
| 1.D2   | Debug: testbench expected value correction |
| 1.4    | Yosys synthesis script                   |
| 1.5    | DP1 Report generation                    |

---

## 5. Verification Results

### Test Vector

| Parameter          | Value                                      |
|--------------------|--------------------------------------------|
| Key                | `000102030405060708090a0b0c0d0e0f`         |
| Plaintext          | `00112233445566778899aabbccddeeff`         |
| Expected ciphertext | `69c4e0d8 6a7b0430 d8cdb780 70b4c55a`   |

### Simulation Tools

Both Verilator (v5.020) and Icarus Verilog (iverilog) were used for simulation, producing identical results.

### Result

```
============================================
Bell Labs AES-128 NIST Test Vector Check
============================================
Expected: 69c4e0d8  6a7b0430  d8cdb780  70b4c55a
Got:      69c4e0d8  6a7b0430  d8cdb780  70b4c55a
--------------------------------------------
TEST PASSED — AES-128 output matches NIST vector
============================================
```

**Verification status: PASS**

The correctness of the output was independently confirmed by OpenSSL (`openssl enc -aes-128-ecb`), which produced the identical ciphertext for the same key and plaintext inputs, validating the module against the industry-standard AES implementation.

---

## 6. Baseline PPA Results

Synthesis was performed using Yosys 0.62+9 targeting the `sky130_fd_sc_hd` standard cell library.

| Metric         | Value  |
|----------------|--------|
| Total cells    | 12,287 |
| Flip-flops     | 816    |
| Total wires    | 11,319 |
| Wire bits      | 13,315 |
| Public wires   | 154    |
| Ports          | 11     |

### Cell Breakdown

| Cell type        | Count | Function                          |
|------------------|-------|-----------------------------------|
| `$_MUX_`         | 7,725 | Data selection (round muxing)     |
| `$_ANDNOT_`      | 724   | Combined AND-NOT logic            |
| `$_XOR_`         | 622   | S-box and GF arithmetic           |
| `$_NOT_`         | 637   | Signal inversion                  |
| `$_OR_`          | 671   | Control logic                     |
| `$_SDFFE_PN0P_`  | 384   | Synchronous D flip-flop with enable |
| `$_SDFFE_PN0N_`  | 256   | Synchronous D flip-flop with enable |
| `$_DFF_P_`       | 169   | Standard D flip-flop              |
| Others           | 1,099 | AND, NAND, NOR, XNOR, ORNOT      |

The dominant cell type is `$_MUX_` at 62.9% of total cells, which is expected for an iterative AES design. The round-selection multiplexers and the `is_final` conditional logic (MixColumns bypass in round 10) generate a large number of MUX cells. This is a primary optimization target for DP2.

---

## 7. Challenges and How AI Helped

### Challenge 1: Testbench expected value error

The initial testbench reported TEST FAILED. The symptom was that cipher0 and cipher1 were correct but cipher2 and cipher3 were wrong. This was initially interpreted as a bug in the Verilog module.

**AI contribution.** Claude performed a systematic root cause analysis. It simulated the AES algorithm in Python using a pure byte-level reference implementation, which produced the same output as the Verilog. It then used OpenSSL to independently verify, confirming that the Verilog output was cryptographically correct and that the testbench had been initialized with an incorrect expected value. The fix was two lines in the testbench.

**Lesson learned.** Cross-validation against an industry-standard tool (OpenSSL) is more reliable than comparing against an unverified expected value. This technique will be applied throughout DP2 and DP3.

### Challenge 2: Verilator `--exe` mode requiring a C++ `main()`

Verilator's `--exe` flag requires a C++ entry point, which a pure Verilog testbench does not provide. This caused a linker error on the first compilation attempt.

**AI contribution.** Claude identified the correct flag (`--binary`) which auto-generates the C++ wrapper, resolving the issue in a single command change.

---

## 8. DP2 Optimization Targets

Based on the DP1 baseline synthesis results, the following optimizations are planned for Design Phase 2:

**Power — clock gating.** 816 flip-flops toggle every clock cycle even when encryption is idle. Adding clock enable gating on the key registers, round state registers, and cipher output registers will reduce dynamic power significantly. Target: 20–30% power reduction.

**Area — MUX reduction.** 7,725 MUX cells represent 62.9% of total cells. Many arise from the `is_final` conditional logic that selects between the MixColumns output and the direct SubBytes+ShiftRows output in round 10. Restructuring this logic may reduce the MUX count.

**Performance — pipeline stage.** The critical path runs through the combined SubBytes+ShiftRows+MixColumns+AddRoundKey combinational chain. Inserting one pipeline register between MixColumns and AddRoundKey will break this path and improve the achievable clock frequency, trading one extra cycle of latency for a higher Fmax.

### DP2 Target Goals

| Metric          | DP1 Baseline | DP2 Target          |
|-----------------|--------------|---------------------|
| Total cells     | 12,287       | < 10,000            |
| Flip-flops      | 816          | < 650               |
| Estimated power | baseline     | 20–30% reduction    |
| Estimated Fmax  | baseline     | 10–20% improvement  |

---

*Report prepared by Team Bell Labs — University of Lagos, Nigeria*
*AI Hardware Design League 2026 — Design Phase 1*
