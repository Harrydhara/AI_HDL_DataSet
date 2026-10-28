# Block Diagram – Ingenius CRC Peripheral

This diagram shows the structure of our CRC peripheral exactly as implemented in DP1.  
It matches the RTL modules `tt_um_ingenius_crc.v` and `crc_datapath.v`.


```
TinyQV Bus
   │
   ▼
┌──────────────────────────────┐
│      MMIO Wrapper            │
│  (tt_um_ingenius_crc)        │
│                              │
│  - CTRL register              │
│  - STATUS register            │
│  - SEED register              │
│  - LEN register               │
│  - DATA register              │
│  - RESULT register            │
│                              │
│  Generates:                   │
│   • crc_start (pulse)         │
│   • crc_reset (pulse)         │
│                              │
│  Receives from datapath:      │
│   • crc_busy                  │
│   • crc_done                  │
│   • crc_result                │
│                              │
│  user_interrupt = crc_done    │
└───────────────┬──────────────┘
                │
                ▼
┌──────────────────────────────┐
│        CRC Datapath          │
│       (crc_datapath)         │
│                              │
│  Inputs:                      │
│   • start_pulse               │
│   • reset                     │
│   • seed[31:0]                │
│   • len[15:0]                 │
│   • data_in[31:0]             │
│                              │
│  Internal:                    │
│   • crc_reg                   │
│   • counter                   │
│   • POLY = 0x04C11DB7         │
│                              │
│  Outputs:                     │
│   • busy                      │
│   • done                      │
│   • result[31:0]              │
└──────────────────────────────┘
```

