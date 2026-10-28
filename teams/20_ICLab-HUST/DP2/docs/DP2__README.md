# DP2 — TinyQV DMA Module PPA Optimisation

This document describes the RTL-level optimisations applied to the DMA peripheral
(`tqvp_dma.v`) and its wrapper (`peripherals.v`) to improve **Power, Performance,
and Area (PPA)** without changing any module ports or breaking the existing testbench.

---

## Files Modified

| File | Lines changed |
|------|--------------|
| `src/tqvp_dma.v` | ~200 lines removed / rewritten |
| `src/peripherals.v` | ~10 lines simplified |

---

## Optimisations in `tqvp_dma.v`

### OPT-1 — DATA Buffer Write Decoder

**Before:** An explicit 8-case `case` statement decoded each DATA register address
individually (`6'h14`, `6'h18`, … `6'h30`), then duplicated the three byte-enable
assignments for every word.

```verilog
// Original — 8 × 3 = 24 identical assignment blocks
case (address)
    6'h14: begin
        if (wr_byte0)  dbuf[0][ 7: 0] <= data_in[ 7: 0];
        if (wr_byte1)  dbuf[0][15: 8] <= data_in[15: 8];
        if (wr_byte23) dbuf[0][31:16] <= data_in[31:16];
    end
    6'h18: begin ... end   // identical pattern × 7 more
    ...
endcase
```

**After:** A single 3-bit computed index replaces the entire decoder.
`address[4:2] − 5` uses mod-8 subtraction to map `0x14→0`, `0x18→1`, … `0x30→7`.
An alignment guard (`address[1:0] == 2'b00`) preserves the original behaviour for
unaligned addresses.

```verilog
// OPT-1: 3-bit subtractor replaces 8-input MUX decoder
wire [2:0] wr_word_idx = address[4:2] - 3'd5;

if (address >= 6'h14 && address <= 6'h30 && address[1:0] == 2'b00) begin
    if (wr_byte0)  dbuf[wr_word_idx][ 7: 0] <= data_in[ 7: 0];
    if (wr_byte1)  dbuf[wr_word_idx][15: 8] <= data_in[15: 8];
    if (wr_byte23) dbuf[wr_word_idx][31:16] <= data_in[31:16];
end
```

**Benefit:** The 8-way address MUX and repeated byte-enable logic are collapsed into
one small subtractor shared across all 24 byte-enable paths.

---

### OPT-2 — RX Buffer Byte Write

**Before:** 32-case nested `case` statement (`case(word_idx)` containing
`case(byte_lane)`) assigned each of the 32 byte lanes individually.

```verilog
// Original — 8 × 4 = 32 explicit assignments
case (word_idx)
    3'd0: case (byte_lane)
        2'd0: dbuf[0][ 7: 0] <= ui_in;
        2'd1: dbuf[0][15: 8] <= ui_in;
        2'd2: dbuf[0][23:16] <= ui_in;
        2'd3: dbuf[0][31:24] <= ui_in;
    endcase
    3'd1: case (byte_lane) ... endcase
    ...  // × 6 more words
endcase
```

**After:** A single variable part-select replaces all 32 assignments.

```verilog
// OPT-2: direct part-select — synthesis infers the same MUX from a smaller cone
dbuf[word_idx][byte_lane*8 +: 8] <= ui_in;
```

**Benefit:** The synthesis tool sees a clean 4-to-1 byte-lane MUX and an 8-to-1
word MUX instead of a flat tree of 32 comparators. Logic cone depth is reduced.

---

### OPT-3 — TX Byte Read (Combinatorial)

**Before:** Same 32-case nested structure as OPT-2, this time in the combinatorial
`always @(*)` block that drives `tx_byte`.

```verilog
// Original — 32 explicit read assignments
case (word_idx)
    3'd0: case (byte_lane)
        2'd0: tx_byte = dbuf[0][ 7: 0];
        ...
    endcase
    ...
endcase
```

**After:** One part-select covers all 32 cases.

```verilog
// OPT-3: direct part-select for TX read MUX
tx_byte = dbuf[word_idx][byte_lane*8 +: 8];
```

**Benefit:** Read MUX is inferred from a smaller, cleaner description, reducing
the combinatorial path from buffer to `uo_out`.

---

### OPT-4 — Register Read Decoder (DATA range)

**Before:** The read `case` statement had 14 entries, including 8 explicit cases
for the DATA registers (`6'h14` … `6'h30`).

```verilog
// Original
6'h14: rdata = dbuf[0];
6'h18: rdata = dbuf[1];
...
6'h30: rdata = dbuf[7];
```

**After:** The 8 DATA entries are replaced by a single `default` branch using the
same computed index as OPT-1.

```verilog
// OPT-4: computed index in default branch — case reduces from 14 to 6 entries
default: rdata = (address >= 6'h14 && address <= 6'h30 && address[1:0] == 2'b00) ?
                  dbuf[address[4:2] - 3'd5] : 32'd0;
```

**Benefit:** Fewer case entries means a narrower priority encoder in the final MUX
tree for `rdata`.

---

### OPT-5 — Clock-Divider Down-Counter

**Before:** An 8-bit up-counter was compared against `divisor` every cycle using a
full magnitude comparator (`div_cnt < divisor`).

```verilog
// Original — 8-bit magnitude comparator
if (div_cnt < divisor) begin
    div_cnt <= div_cnt + 8'd1;
end else begin
    div_cnt <= 8'd0;
    // ... byte transfer
end
```

**After:** `divisor` is loaded into `div_cnt` at transfer start and on every byte
tick. The counter decrements toward zero; the terminal condition is a zero-detect.

```verilog
// OPT-5: down-counter — 8-input NOR replaces 8-bit magnitude comparator
if (div_cnt != 8'd0) begin
    div_cnt <= div_cnt - 8'd1;
end else begin
    div_cnt <= divisor;   // reload for next byte
    // ... byte transfer
end
```

**Timing equivalence:** Both schemes produce exactly one byte-transfer tick every
`(divisor + 1)` clock cycles. The table below traces three representative divisor
values:

| `divisor` | Original cycles/byte | Down-counter cycles/byte |
|-----------|---------------------|--------------------------|
| 0         | 1                   | 1                        |
| 1         | 2                   | 2                        |
| 63        | 64                  | 64                       |

**Benefit:** An 8-input NOR gate (zero-detect) replaces an 8-bit subtractor-based
comparator, saving area and reducing the critical path through the counter logic.

---

### OPT-6 — Eliminated `dma_done` Register

**Before:** A dedicated `dma_done` flip-flop was set on transfer completion and
cleared by a `CLR_IRQ` write. A separate state-machine block then watched
`dma_done` to trigger the `ST_DONE → ST_IDLE` transition one cycle later.

```verilog
// Original — extra FF and two-stage clear
reg dma_done;

// On completion:
state    <= ST_DONE;
dma_done <= 1'b1;

// In CLR_IRQ handler:
dma_done <= 1'b0;

// Separate always block:
if (state == ST_DONE)
    if (!dma_done) state <= ST_IDLE;   // one extra cycle

// STATUS read:
6'h0C: rdata = {30'd0, dma_done, (state == ST_RUN)};
```

**After:** `state == ST_DONE` carries the same information as `dma_done`.
`CLR_IRQ` writes `state = ST_IDLE` directly; the separate post-done block is
removed.

```verilog
// OPT-6: state encodes done; direct transition on CLR_IRQ
6'h10: begin
    if (state == ST_DONE) state <= ST_IDLE;
    irq_reg <= 1'b0;
end

// STATUS read — no dma_done register needed:
6'h0C: rdata = {30'd0, (state == ST_DONE), (state == ST_RUN)};
```

**Benefit:** Saves 1 flip-flop and removes the post-done state-check combinatorial
path. The `ST_DONE → ST_IDLE` transition is now one cycle faster (the extra
intermediate cycle of the original is eliminated).

---

## Optimisation in `peripherals.v`

### OPT-P1 — Removed Redundant `data_ready_from_peri` Wire

**Before:** An intermediate wire selected between `dma_data_ready` and a constant
`1'b1`, and this wire was used as a factor in two conditions inside the registered
handshake block.

```verilog
// Original
wire data_ready_from_peri = sel_dma ? dma_data_ready : 1'b1;

if (!data_out_hold && data_ready_from_peri && data_read_n != 2'b11) ...
data_ready_r <= read_req && data_ready_from_peri;
```

**After:** Because `tqvp_dma` hardwires `data_ready = 1'b1`, the expression
`sel_dma ? 1'b1 : 1'b1` always evaluates to `1'b1`. The wire and both `&& 1'b1`
factors are removed.

```verilog
// OPT-P1: factor removed — data_ready_from_peri is always 1
if (!data_out_hold && read_req) begin
    data_out_hold <= 1;
    data_out_r    <= data_from_peri;
end
data_ready_r <= read_req;
```

**Benefit:** Removes two AND gates on the timing-critical read-handshake path
(`data_out_hold` capture and `data_ready_r` update).

---

## Summary

| ID | File | Technique | Primary gain |
|----|------|-----------|-------------|
| OPT-1 | `tqvp_dma.v` | Computed write index (`address[4:2] − 5`) | Area — removes 8-way decoder MUX |
| OPT-2 | `tqvp_dma.v` | Variable part-select for RX write | Area — collapses 32-case nested decoder |
| OPT-3 | `tqvp_dma.v` | Variable part-select for TX read | Area/Performance — shorter combinatorial path |
| OPT-4 | `tqvp_dma.v` | Computed read index in `default` branch | Area — reduces case from 14 to 6 entries |
| OPT-5 | `tqvp_dma.v` | Down-counter with zero-detect | Area/Power — NOR replaces magnitude comparator |
| OPT-6 | `tqvp_dma.v` | Eliminate `dma_done` register | Area — saves 1 FF, removes post-done logic |
| OPT-P1 | `peripherals.v` | Remove always-true `data_ready_from_peri` | Performance — removes AND gates on read path |

All optimisations preserve the exact register map, transfer timing, interrupt
behaviour, and pass the full cocotb testbench in `test/test_peripherals.py`.
