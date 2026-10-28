# PLEASE CHECK THE CODE SEGMENT FOR PURE SCHEME
# AES Block Diagram
┌─────────────────────────────────────────────────────────────────────────────┐
│                            TinyQV Peripheral Bus                            │
│                              (0x8000000)                                    │
└─────────────┬───────────────────┬───────────────────┬───────────────────────┘
              │                   │                   │
              ▼                   ▼                   ▼
         clk/rst_n           data_in/out         interrupt
              │                   │                   ▲
              │                   │                   │
┌─────────────▼───────────────────▼───────────────────┴───────────────────────┐
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐          │
│  │    Register     │──▶│      Key        │───▶│    AES Core     │          │
│  │   Interface     │    │   Expansion     │    │   (10 rounds)   │          │
│  │    (MMIO)       │◀──│   (11 cycles)   │◀───│   (12 cycles)   │          │
│  └────────┬────────┘    └─────────────────┘    └────────┬────────┘          │
│           │                                             │                   │
│           ▼                                             ▼                   │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐          │
│  │    Control      │──▶│     S-Box       │◀──│   MixColumns    │           │
│  │      FSM        │    │  (256-entry)    │    │    GF(2^8)      │          │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘          │
│                                                                             │
│                         AES-128 Crypto Accelerator                          │
└─────────────────────────────────────────────────────────────────────────────┘

# Write Data Flow (CPU → AES)
Step 1: Register Write
────────────────────────────────────────────────────────────────────────────

  TinyQV CPU                    Register Interface
      │                               │
      │  address[5:0] = 0x10          │
      │  data_in[31:0] = KEY[0]       │
      │  data_write_n[1:0] = 2'b10    │
      │───────────────────────────▶▶ │
      │                               │  Store to key_reg[0]
      │                               ▼
      │                         ┌──────────┐
      │                         │ KEY[0-3] │
      │                         │ DIN[0-3] │
      │                         │ CTRL     │
      │                         └──────────┘

# Step 2: Start Operation

 Register Interface              Control FSM
      │                               │
      │  CTRL[0] = 1 (START)          │
      │  CTRL[1] = 0 (ENCRYPT)        │
      │─────────────────────────────▶ │
      │                               │  Transition to KEY_EXPAND state
      │                               ▼
      │                         ┌──────────┐
      │                         │  IDLE    │
      │                         │    ↓     │
      │                         │KEY_EXPAND│
      │                         └──────────┘

# Step 3: Key Expansion (11 cycles)
────────────────────────────────────────────────────────────────────────────

  Key Registers                 Key Expansion                    S-Box
      │                               │                            │
      │  key[127:0]                   │                            │
      │─────────────────────────────▶ │                            │
      │                               │  RotWord                   │
      │                               │─────────────────────────▶  │
      │                               │                            │
      │                               │  SubWord result            │
      │                               │◀─────────────────────────  │
      │                               │                            │
      │                               │  XOR with Rcon             │
      │                               ▼                            │
      │                         ┌──────────────┐                   │
      │                         │ Round Keys   │                   │
      │                         │ [0] - [10]   │                   │
      │                         │ (44 words)   │                   │
      │                         └──────────────┘                   │

  Cycle: 1  2  3  4  5  6  7  8  9  10  11
         │  │  │  │  │  │  │  │  │   │   │
         ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼   ▼   ▼
        K0 K1 K2 K3 K4 K5 K6 K7 K8  K9  K10

        
# Step 4: AES Encryption (12 cycles)
────────────────────────────────────────────────────────────────────────────

  Cycle 1: Initial AddRoundKey
  ─────────────────────────────
      DIN[127:0] ──┬──▶ XOR ◀── RoundKey[0]
                   │      │
                   │      ▼
                   │   State[127:0]

  Cycles 2-10: Main Rounds (9 rounds)
  ────────────────────────────────────
                   ┌─────────────────────────────────────┐
                   │                                     │
      State ──────▶│  SubBytes ──▶ ShiftRows ──▶         │
                   │                                     │
                   │  MixColumns ──▶ AddRoundKey ───────▶│──▶ State
                   │                      ▲              │
                   │                      │              │
                   │              RoundKey[1-9]          │
                   │                                     │
                   └─────────────────────────────────────┘
                              ↻ Repeat 9 times

  Cycle 11-12: Final Round
  ────────────────────────
      State ──────▶ SubBytes ──▶ ShiftRows ──▶ AddRoundKey ──▶ DOUT
                                                    ▲
                                                    │
                                              RoundKey[10]

  (No MixColumns in final round)

 # Step 5: Result Read
────────────────────────────────────────────────────────────────────────────

  AES Core                      Register Interface              TinyQV CPU
      │                               │                              │
      │  ciphertext[127:0]            │                              │
      │─────────────────────────────▶ │                              │
      │                               │  Store to dout_reg[0-3]      │
      │                               │                              │
      │  done = 1                     │                              │
      │─────────────────────────────▶ │                              │
      │                               │  STATUS[1] = 1               │
      │                               │                              │
      │                               │  address = 0x30              │
      │                               │  data_read_n = 2'b10         │
      │                               │◀─────────────────────────────│
      │                               │                              │
      │                               │  data_out = DOUT[0]          │
      │                               │  data_ready = 1              │
      │                               │─────────────────────────────▶│
      │                               │                              │

 # Step 6: Interrupt Generation
────────────────────────────────────────────────────────────────────────────

  Control FSM                   Register Interface              TinyQV CPU
      │                               │                              │
      │  operation_done = 1           │                              │
      │─────────────────────────────▶ │                              │
      │                               │                              │
      │                               │  INT_STATUS[0] = 1           │ 
      │                               │                              │
      │                               │  if (INT_EN[0] == 1)         │
      │                               │    user_interrupt = 1        │
      │                               │─────────────────────────────▶│
      │                               │                              │
      │                               │                              │  ISR
      │                               │                              │  │
      │                               │  Write 1 to INT_STATUS[0]    │  │
      │                               │◀─────────────────────────────│◀─┘
      │                               │                              │
      │                               │  user_interrupt = 0          │
      │                               │─────────────────────────────▶│


# CONTROL_FSM_DIAGRAM
                            ┌──────────────────┐
                            │                  │
               rst_n=0      │      IDLE        │◀─────────────────┐
            ┌──────────────▶│                  │                  │
            │               │   STATUS=0x00    │                  │
            │               └────────┬─────────┘                  │
            │                        │                            │
            │                        │ START=1                    │
            │                        ▼                            │
            │               ┌──────────────────┐                  │
            │               │                  │                  │
            │               │   KEY_EXPAND     │                  │
            │               │                  │                  │
            │               │  BUSY=1          │                  │
            │               │  11 cycles       │                  │
            │               └────────┬─────────┘                  │
            │                        │                            │
            │                        │ key_done=1                 │
            │                        ▼                            │
            │               ┌──────────────────┐                  │
            │               │                  │                  │
            │               │   INIT_ROUND     │                  │
            │               │                  │                  │
            │               │  AddRoundKey     │                  │
            │               │  1 cycle         │                  │
            │               └────────┬─────────┘                  │
            │                        │                            │
            │                        ▼                            │
            │               ┌──────────────────┐                  │
            │               │                  │                  │
            │               │   MAIN_ROUNDS    │◀──┐              │
            │               │                  │   │              │
            │               │  Rounds 1-9      │   │ round < 9    │
            │               │  9 cycles        │───┘              │
            │               └────────┬─────────┘                  │
            │                        │                            │
            │                        │ round = 9                  │
            │                        ▼                            │
            │               ┌──────────────────┐                  │
            │               │                  │                  │
            │               │   FINAL_ROUND    │                  │
            │               │                  │                  │
            │               │  No MixColumns   │                  │
            │               │  1 cycle         │                  │
            │               └────────┬─────────┘                  │
            │                        │                            │
            │                        ▼                            │
            │               ┌──────────────────┐                  │
            │               │                  │                  │
            │               │     DONE         │──────────────────┘
            │               │                  │
            │               │  DONE=1          │
            │               │  IRQ (if enabled)│
            │               └──────────────────┘
            │
        ┌───┴───┐
        │ RESET │
        └───────┘
