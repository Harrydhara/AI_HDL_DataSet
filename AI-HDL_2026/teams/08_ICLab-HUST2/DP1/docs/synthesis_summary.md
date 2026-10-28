# Synthesis Summary — tt_um_tt_tinyQV

**Tool:** Yosys (via OpenLane2) · **PDK:** sky130A · **Strategy:** AREA 0 · **Target clock:** 50 MHz (20 ns)

---

## 1. Design Hierarchy

```
tt_um_tt_tinyQV
├── tinyQV_peripherals (CLOCK_MHZ=64)
│   └── tqvp_winograd
│       └── interface (winograd_peripheral) (DATA_WIDTH=32, FRAC_BITS=16)
│           └── winograd (winograd_conv_top)
│               ├── elementwise   (NUM_ELEMENTS=16)
│               ├── matrix_filter
│               ├── matrix_input
│               └── matrix_output
├── uart_tx (BIT_RATE=4M, CLK=64MHz)
└── tinyQV (RISC-V core)
    ├── tinyqv_cpu
    │   ├── tinyqv_core (NUM_REGS=16)
    │   │   ├── tinyqv_registers
    │   │   ├── tinyqv_mul (B_BITS=16)
    │   │   ├── tinyqv_alu
    │   │   ├── tinyqv_shifter
    │   │   └── tinyqv_counter
    │   ├── tinyQV_time
    │   └── tinyqv_decoder
    └── tinyqv_mem_ctrl
        └── qspi_controller
```

---

## 2. Top-level Cell Count

| Metric | Value |
|---|---|
| **Total cells (flat)** | **70,981** |
| Total wire bits | 74,518 |
| Total public wire bits | 12,603 |
| Inferred latches | **0** |
| Synthesis errors | **0** |
| Synthesis warnings | 3 (lint, non-critical) |

### Cell type breakdown

| Type | Count | Share |
|---|---|---|
| `$_MUX_` | 28,924 | 40.7% |
| `$_NOT_` | 5,871 | 8.3% |
| `$_DFF_P_` | 4,741 | 6.7% |
| `$_OAI4_` | 4,696 | 6.6% |
| `$_DFF_PN0_` | 3,853 | 5.4% |
| `$_OR_` | 4,531 | 6.4% |
| `$_ANDNOT_` | 4,442 | 6.3% |
| `$_AOI3_` | 1,723 | 2.4% |
| `$_OAI3_` | 1,751 | 2.5% |
| `$_XOR_` | 2,706 | 3.8% |
| Other | ~9,743 | 13.7% |

**Total sequential (DFF) cells:** `4,741 + 3,853 + 6 + 2 = 8,602`
**Total combinational cells:** `~62,379`

---

## 3. Per-module Breakdown

| Module | Cells | DFFs | Notes |
|---|---|---|---|
| `winograd_filter_transform` | **15,174** | 1,231 | Largest module — four 34-bit combinational adder trees, sets critical path |
| `winograd_input_transform` | **13,056** | 1,583 | B^T·d·B data transform, high MUX count (4,985) |
| `winograd_peripheral` | **10,575** | 1,176 | Register file + feed FSM, 6,294 MUX cells |
| `winograd_elementwise` | **9,811** | 529 | 16× 32-bit fixed-point multiplier + accumulator |
| `winograd_conv_top` | 9,945 | 2,045 | FSM orchestrator + internal buffers |
| `winograd_output_transform` | 6,145 | 942 | A^T·M·A inverse transform |
| `tinyqv_cpu` | 1,837 | 235 | RISC-V pipeline |
| `tinyqv_registers` | 714 | 416 | 16×32-bit register file |
| `qspi_controller` | 446 | 62 | QSPI flash interface |
| `tinyqv_mul` | 390 | 16 | 16-bit multiplier |
| `tinyqv_decoder` | 579 | 0 | Combinational instruction decode |
| `uart_tx` | 108 | 18 | UART at 4 Mbps |
| `tinyQV_peripherals` (wrapper) | 153 | 34 | Address decode + DMA |

**Winograd accelerator subtotal (all submodules):** ~**54,706 cells** = **77%** of total design

---

## 4. Synthesis Quality

### Latch check
Yosys inferred zero latches (`inferred_latch__count = 0`). The "No latch inferred" messages in the log are **expected behaviour** — Yosys is confirming that combinational `always` blocks have correct default assignments, not reporting errors.

Signals verified: `wino_data_in`, `wino_filter_in`, `laddr_mapped`, `reg_access[0:15]` — all are intentional combinational logic in `interface.v` and `register.v`.

### Unused modules removed
Four modules from `latch_reg.v` were pruned after elaboration (`latch_reg_n`, `latch_reg_p`, `latch_reg32_n`, `latch_reg32_p`) — these are behavioral models that are never instantiated at the top level.

### Optimization passes
Yosys ran the full optimization flow: `OPT_MUXTREE` → `OPT_REDUCE` → `OPT_CLEAN` → `ABC` technology mapping. The `AREA 0` strategy prioritises minimising cell count over timing.

---

## 5. Dominant Resource: MUX Trees

28,924 MUX cells (40.7%) is a defining characteristic of this design for the following reasons:

- `winograd_filter_transform`: 6,573 MUX — implements the 4×4 G·g·G^T matrix using shift-based fixed-point arithmetic; Yosys maps this to MUX trees rather than full adders
- `winograd_peripheral` (`interface.v`): 6,294 MUX — 33 individual 32-bit register banks written as `case` statements instead of arrays; each register becomes a chain of MUX cells
- `winograd_input_transform`: 4,985 MUX — B^T·d·B data transform
- `winograd_elementwise`: 2,128 MUX — 16-to-1 read mux for `m_buffer`

The high MUX count is the direct cause of the 90% core utilisation and the 48-iteration routing convergence.

---

## 6. Key Observations for DP2

| Issue | Module | Impact | DP2 Fix |
|---|---|---|---|
| MUX explosion from `case` registers | `interface.v` | 6,294 MUX cells | Replace individual regs with `reg [31:0] buf [0:N]` array |
| 32-bit fixed-point multiplier × 16 | `elementwise.v` | 9,811 cells | Reduce DATA_WIDTH 32→16 |
| Combinational 34-bit adder tree | `matrix_filter.v` | Critical path → SS timing fail | Add 1 pipeline stage or switch to W16 |
| Unused `latch_reg.v` modules | — | 0 cells (already removed by Yosys) | Remove from RTL file list |
