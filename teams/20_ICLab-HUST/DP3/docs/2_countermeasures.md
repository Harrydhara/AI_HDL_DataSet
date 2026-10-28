# Security Countermeasures — Implementation Details

**Module:** `tqvp_dma.v`

**Strategy:** Defense-in-Depth, Security by Design

**Vulnerabilities addressed:** SEC-1, SEC-2, SEC-3, SEC-4

---

## Overview

All four countermeasures are implemented **directly in RTL**, following the
*Security by Design* principle — security properties are part of the hardware
logic itself, not enforced by software conventions that can be bypassed.

| ID | Countermeasure | Hardware Added | PPA Cost |
|---|---|---|---|
| SEC-1 | Write-lock gate `cfg_write_ok` | 1 combinational wire | Negligible |
| SEC-2 | Start-unlock key `sec_key_valid` | 1 FF + 8-bit comparator + AND gate | ≈ +2–3 cells |
| SEC-3 | TX output zeroization | None (default-zero already existed) | Zero |
| SEC-4 | RX buffer zeroization at start | Reset fanout on 256 FFs | < 0.5 % area |

---

## SEC-1 Fix: Transfer-Active Write Lock (`cfg_write_ok`)

### Problem recap

Configuration registers (`COUNT`, `DIVISOR`, `mode`, `irq_enable`, `dbuf`)
could be overwritten while the DMA was running, enabling TOCTOU attacks that
corrupt the transfer mid-flight.

### Implementation

A single 1-bit combinational signal acts as a hardware gate across every
configuration write path:

```verilog
// Locked while DMA engine is running — prevents TOCTOU attacks
wire cfg_write_ok = (state != ST_RUN);
```

This wire is ANDed into the write-enable condition of every affected register:

```verilog
// CTRL: mode and irq_enable are locked during ST_RUN
if (cfg_write_ok) begin
    irq_enable <= data_in[2];
    dma_mode   <= data_in[1];
end

// COUNT is locked during ST_RUN
if (wr_byte0 && cfg_write_ok) count <= ...;

// DIVISOR is locked during ST_RUN
if (wr_byte0 && cfg_write_ok) divisor <= data_in[7:0];

// DATA buffer is locked during ST_RUN
if (cfg_write_ok && address >= 6'h14 && address <= 6'h30 ...) begin
    dbuf[wr_word_idx][...] <= data_in[...];
end
```

Any write attempt to these registers while `state == ST_RUN` is **silently
ignored by the hardware** — no error signal is needed, no software change is
required.

### Why this works

The DMA configuration is now frozen at the exact moment the FSM enters `ST_RUN`.
No concurrent software thread, no rogue bus master, and no interrupt handler
can change `COUNT`, `mode`, or `DIVISOR` until the current transfer completes
and the FSM returns to `ST_IDLE` or `ST_DONE`.

### PPA cost

`cfg_write_ok` is a pure combinational wire with no flip-flop. Each guarded
write path adds one 2-input AND gate. **Total overhead: fewer than 5 cells,
zero timing impact.**

---

## SEC-2 Fix: Start-Unlock Key (`sec_key_valid`)

### Problem recap

Any write to `CTRL[start]` launched the DMA immediately, with no authentication.
This allowed rogue writes and replay attacks.

### Implementation

A new write-only register `SEC_KEY` at address `0x34` and a 1-bit status
flip-flop `sec_key_valid` implement a hardware handshake:

```verilog
// Address 0x34 — SEC_KEY register
6'h34: begin
    if (wr_byte0)
        sec_key_valid <= (data_in[7:0] == 8'hA5);
end
```

An 8-bit hardware comparator checks the written value. Only writing the exact
magic constant `8'hA5` sets `sec_key_valid` to `1`. Any other value clears it,
allowing software to explicitly revoke a previously armed key.

The key is then ANDed into the `CTRL[start]` condition:

```verilog
// CTRL (0x00): start is accepted only when sec_key_valid is set
if (data_in[0] && state == ST_IDLE && sec_key_valid) begin
    state    <= ST_RUN;
    byte_idx <= 6'd0;
    div_cnt  <= divisor;
    irq_reg  <= 1'b0;
    // RX mode: zeroize buffer (SEC-4)
    if (data_in[1] == 1'b0)
        for (i = 0; i < 8; i = i + 1) dbuf[i] <= 32'd0;
end
// Key is consumed unconditionally on every CTRL byte-0 write
sec_key_valid <= 1'b0;
```

The last line is the most important — `sec_key_valid` is **always cleared**
whenever the CPU writes to `CTRL`, regardless of whether the DMA actually
started. This gives the key **one-time-use** semantics.

### Software usage (required sequence)

```
1. Write 8'hA5 to SEC_KEY (address 0x34)   → arms the key
2. Read  STATUS[bit2] to confirm key_valid  → optional sanity check
3. Write start bits to CTRL (address 0x00)  → DMA launches
   (key is consumed here — must be re-armed for the next transfer)
```

### Why this defeats replay and rogue writes

- A **replay attack** that re-sends only the `CTRL` write will fail because the
  key was already consumed during the original sequence. The attacker must also
  replay the `SEC_KEY` write, which is a separate, time-ordered bus transaction.
- A **rogue write** targeting only `CTRL` (without a preceding valid `SEC_KEY`
  write) is silently ignored.
- The `STATUS` register exposes `sec_key_valid` so legitimate software can
  verify the key is armed before issuing the start command.

### PPA cost

One flip-flop (`sec_key_valid`) + one 8-bit equality comparator + one AND gate
into the start condition. **Estimated +2–3 standard cells, < 0.05 % area.**

---

## SEC-3 Fix: TX Output Zeroization

### Problem recap

`uo_out` retained the last transmitted byte after a TX transfer ended, leaking
data to any passive observer on the output bus.

### Implementation

The combinational block that drives `uo_out` is structured with an explicit
**safe default of zero**:

```verilog
reg [7:0] tx_byte;
always @(*) begin
    tx_byte = 8'd0;  // Safe default — held in all non-TX-active states
    if (state == ST_RUN && dma_mode == 1'b1) begin
        // Only drive real data when actively transmitting
        tx_byte = dbuf[word_idx][byte_lane*8 +: 8];
    end
end

assign uo_out = tx_byte;
```

The real buffer data is only propagated to `uo_out` when **both** conditions
are true simultaneously: FSM is in `ST_RUN` **AND** the direction is TX
(`dma_mode == 1`). In every other state (`ST_IDLE`, `ST_DONE`, or RX mode),
the output is immediately forced to `8'h00`.

### Why this works

The moment the FSM leaves `ST_RUN` (or exits TX mode), the combinational
multiplexer selects the constant `8'd0` path. There is no propagation delay —
the output goes to zero in the same clock cycle that the state changes. No
sensitive byte can linger on the physical GPIO pins after a transfer ends.

### PPA cost

**Zero.** A default-zero assignment already existed in the original design.
This countermeasure makes the security intent architecturally explicit in the
RTL comment and documentation, with no new cells added.

---

## SEC-4 Fix: RX Buffer Zeroization at Transfer Start

### Problem recap

The 32-byte receive buffer `dbuf` was not cleared between transfers, leaving
stale data from a previous capture accessible in the tail words of the buffer.

### Implementation

When a valid RX transfer starts (key present, `ST_IDLE`, RX mode selected),
all 8 words of `dbuf` are cleared to zero in a single clock cycle before any
new data arrives:

```verilog
// Inside the CTRL[start] handler — RX mode only
if (data_in[1] == 1'b0) begin  // 0 = RX mode
    for (i = 0; i < 8; i = i + 1)
        dbuf[i] <= 32'd0;      // Parallel clear — all 256 bits in one cycle
end
```

The synthesizer unrolls the `for` loop into **8 parallel flip-flop reset
assignments**. All 256 bits of `dbuf` are cleared simultaneously in the same
clock cycle that the FSM transitions from `ST_IDLE` to `ST_RUN`.

Note: TX mode intentionally skips the clear, because `dbuf` holds the
transmit payload that the CPU already loaded — erasing it would destroy the
data to be sent.

### Why this works

By the time the first byte arrives from `ui_in` (one divisor period later),
the buffer is already guaranteed to be all zeros. Any tail words that the new
transfer does not write remain zero rather than holding stale data from a
prior session. Cross-context memory aliasing is completely eliminated.

### PPA cost

No new logic cells are added. The `for` loop only adds **reset fanout** to the
existing `dbuf` flip-flops. The reset signal needs a slightly stronger driver
to reach all 256 FFs, adding a small routing overhead. **Estimated < 0.5 %
area increase** from driver resizing, zero timing impact.

---

## Combined PPA Impact

| Countermeasure | Theoretical cells added | Measured DP2 → DP3 |
|---|---|---|
| SEC-1 (write-lock wire) | +0 | included in net −452 |
| SEC-2 (key FF + comparator) | +3 | included in net −452 |
| SEC-3 (TX zeroize) | +0 | included in net −452 |
| SEC-4 (RX buffer clear) | +0 | included in net −452 |
| **Security subtotal** | **+3 cells** | — |
| RTL optimizations OPT-1..6 | −54 to −68 | — |
| SDC fix (false-path cells freed) | −26 | — |
| Antenna cells (routing density) | −290 | — |
| **Net result** | — | **−452 cells, −2.89 % area** |

The security features cost approximately **+3 cells in isolation**. The net
DP3 design is smaller and faster than DP2 because six RTL optimizations and an
SDC correction were made at the same time. Full analysis in
[4_ppa_overhead_analysis.md](4_ppa_overhead_analysis.md).
