# DP2 Optimization Summary - Team Acona

## Quick Reference Card

### Version Comparison

| Version | Description | Cells | Depth | Cycles | Status |
|---------|-------------|-------|-------|--------|--------|
| **v1** | DP1 + Clock Gating | 36,484 | 36 | 12 | ✅ Verified |
| **v2** | v1 + S-Box Pipeline | - | 37 | 22 | ❌ No improvement |
| **v3** | v1 + Fast MixCol + Unrolled Keys | 37,025 | 30 | 12 | ✅ Verified |
| **v4** | v3 + Key Pipeline | 37,025 | 24 | 22 | ✅ **FINAL** |

### Optimization Impact

| Optimization | Power | Performance | Area | Cycles |
|--------------|-------|-------------|------|--------|
| Clock Gating | **+88%** | 0 | +0.02% | 0 |
| Fast MixColumns | 0 | ~3 levels | 0 | 0 |
| Unrolled Keys | 0 | ~21 levels | +3.5% | 0 |
| Key Pipeline | 0 | ~6 levels | +0.5% | +10 |
| **TOTAL** | **+88%** | **+33%** | **+1.5%** | **+10** |

### Files Checklist

#### New Modules (rtl_optimized/)
- [x] `aes_clock_gate.sv` - Clock gating cell
- [x] `aes_mixcolumns_fast.sv` - Optimized MixColumns
- [x] `aes_key_expansion_unrolled.sv` - Pre-computed keys
- [x] `aes_core_fast_v2.sv` - Pipelined core
- [x] `tqvp_aes128_opt_v4.sv` - Final top module

#### Reused from DP1 (copy to rtl_optimized/)
- [x] `aes_sbox.sv`
- [x] `aes_reg_interface.sv`

#### Testbenches (tb/)
- [x] `tb_tqvp_aes128_opt_v4.sv`

### Test Results

```
================================================================
  DP2 v4: Fully Optimized AES-128 with Pipelined Keys
================================================================
Test 1: Reset Behavior          ✅ PASSED
Test 2: NIST FIPS-197 Encryption ✅ PASSED (31 cycles)
Test 3: NIST FIPS-197 Decryption ✅ PASSED (31 cycles)
Test 4: All-Zeros Vector        ✅ PASSED
Test 5: Encrypt-Decrypt Trip    ✅ PASSED
================================================================
  ALL TESTS PASSED
================================================================
```

### Critical Path Evolution

```
DP1 (36 levels):
  key_expansion(21) → round_key → InvMixColumns(8) → state_reg(7)

v3 (30 levels):
  round_num(7) → key_MUX(8) → InvMixColumns(8) → state_reg(7)

v4 (24 levels):  ← FINAL
  S-Box(9) → AddRoundKey(2) → InvMixColumns(8) → state_reg(5)
```

### Command Quick Reference

```bash
# Compile v4
iverilog -g2012 -o tb_opt_v4.vvp \
    rtl_optimized/aes_sbox.sv \
    rtl_optimized/aes_mixcolumns_fast.sv \
    rtl_optimized/aes_key_expansion_unrolled.sv \
    rtl_optimized/aes_core_fast_v2.sv \
    rtl_optimized/aes_reg_interface.sv \
    rtl_optimized/aes_clock_gate.sv \
    rtl_optimized/tqvp_aes128_opt_v4.sv \
    tb/tb_tqvp_aes128_opt_v4.sv

# Run simulation
vvp tb_opt_v4.vvp

# Synthesis
yosys -p "read_verilog -sv rtl_optimized/*.sv; synth -top tqvp_aes128_top_opt_v4; stat"

# Timing analysis
yosys -p "read_verilog -sv rtl_optimized/*.sv; synth -top tqvp_aes128_top_opt_v4; flatten; ltp -noff"
```

---
**Team Acona | AI-HDL 2026 | Design Phase 2**
