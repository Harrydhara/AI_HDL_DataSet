# DP2 Integration Guide for Acona-Tech-AI-HDL-2026
It is our first optimization plan after the analysis of DP1. After that v1 we develop v2 v3 and last version, v4. You can check the dp2 report and README.md files. 
## Quick Summary

We have **7 new files** to add to our repository:

| # | New File | Location in Your Repo |
|---|----------|----------------------|
| 1 | `aes_clock_gate.sv` | `rtl_optimized/` |
| 2 | `tqvp_aes128_opt.sv` | `rtl_optimized/` |
| 3 | `tb_aes128_clock_gated.sv` | `tb/` |
| 4 | `DP2_Step1_Baseline_Analysis.md` | `docs/dp2/` |
| 5 | `CLOCK_GATING_README.md` | `docs/dp2/` |
| 6 | `run_simulation.sh` | `scripts/` |
| 7 | `run_synthesis.sh` | `scripts/` |

---

## Visual: Before vs After

### BEFORE ( DP1 Repository)

```
Acona-Tech-AI-HDL-2026-main/
│
├── rtl/
│   ├── aes_sbox.sv           ✓ exists
│   ├── aes_mixcolumns.sv     ✓ exists
│   ├── aes_key_expansion.sv  ✓ exists
│   ├── aes_core.sv           ✓ exists
│   ├── aes_control_fsm.sv    ✓ exists
│   ├── aes_reg_interface.sv  ✓ exists
│   ├── tqvp_aes128.sv        ✓ exists
│   └── tqvp_aes128_top.sv    ✓ exists
│
├── tb/
│   ├── tb_aes_core.sv        ✓ exists
│   └── ... other testbenches
│
├── reports/
│   └── baseline_synth/
│       └── yosys_stat.txt    ✓ exists
│
└── docs/
    └── ... DP1 docs
```

### AFTER (With DP2 Additions)

```
Acona-Tech-AI-HDL-2026-main/
│
├── rtl/                          ← UNCHANGED (keep for baseline comparison)
│   └── ... (all DP1 files)
│
├── rtl_optimized/                ← NEW FOLDER ⭐
│   │
│   │  # New optimized modules:
│   ├── aes_clock_gate.sv         ← NEW FILE ⭐
│   ├── tqvp_aes128_opt.sv        ← NEW FILE ⭐
│   │
│   │  # Copied from rtl/ (unchanged modules):
│   ├── aes_sbox.sv               ← COPY from rtl/
│   ├── aes_mixcolumns.sv         ← COPY from rtl/
│   ├── aes_key_expansion.sv      ← COPY from rtl/
│   ├── aes_core.sv               ← COPY from rtl/
│   └── aes_reg_interface.sv      ← COPY from rtl/
│
├── tb/
│   ├── ... (existing testbenches)
│   └── tb_aes128_clock_gated.sv  ← NEW FILE ⭐
│
├── scripts/                      ← NEW FOLDER ⭐
│   ├── run_simulation.sh         ← NEW FILE ⭐
│   └── run_synthesis.sh          ← NEW FILE ⭐
│
├── reports/
│   ├── baseline_synth/           ← KEEP (DP1 baseline)
│   │   └── yosys_stat.txt
│   └── optimized_synth/          ← NEW FOLDER ⭐
│       └── (will contain DP2 synthesis reports)
│
└── docs/
    ├── ... (existing DP1 docs)
    └── dp2/                      ← NEW FOLDER ⭐
        ├── DP2_Step1_Baseline_Analysis.md   ← NEW FILE ⭐
```

---

## Step-by-Step Instructions

### Step 1: Created New Folders

Open terminal in your repository root and run:

```bash
cd Acona-Tech-AI-HDL-2026-main

# Create new directories
mkdir -p rtl_optimized
mkdir -p docs/dp2
mkdir -p scripts
mkdir -p reports/optimized_synth
```

### Step 2: Copied Baseline Files

Copy the unchanged modules from `rtl/` to `rtl_optimized/`:

```bash
# Copy unchanged modules
cp rtl/aes_sbox.sv rtl_optimized/
cp rtl/aes_mixcolumns.sv rtl_optimized/
cp rtl/aes_key_expansion.sv rtl_optimized/
cp rtl/aes_core.sv rtl_optimized/
cp rtl/aes_reg_interface.sv rtl_optimized/
```

### Step 3: Download New Files from Claude

Download these files from the Claude conversation and place them:

| Download This | Put It Here |
|---------------|-------------|
| `aes_clock_gate.sv` | `rtl_optimized/aes_clock_gate.sv` |
| `tqvp_aes128_opt.sv` | `rtl_optimized/tqvp_aes128_opt.sv` |
| `tb_aes128_clock_gated.sv` | `tb/tb_aes128_clock_gated.sv` |
| `DP2_Step1_Baseline_Analysis.md` | `docs/dp2/DP2_Step1_Baseline_Analysis.md` |
| `CLOCK_GATING_README.md` | `docs/dp2/CLOCK_GATING_README.md` |
| `run_simulation.sh` | `scripts/run_simulation.sh` |
| `run_synthesis.sh` | `scripts/run_synthesis.sh` |

### Step 4: Make Scripts Executable

```bash
chmod +x scripts/run_simulation.sh
chmod +x scripts/run_synthesis.sh
```

### Step 5: Verify Structure

```bash
# Check the structure
find . -name "*.sv" -o -name "*.sh" -o -name "*.md" | head -30
```

---

## Why This Structure?

| Folder | Purpose |
|--------|---------|
| `rtl/` | **Keep unchanged** - This is your DP1 baseline for comparison |
| `rtl_optimized/` | DP2 optimized design - allows side-by-side comparison |
| `docs/dp2/` | DP2 documentation (separate from DP1 docs) |
| `scripts/` | Automation scripts for simulation and synthesis |
| `reports/optimized_synth/` | Will store DP2 synthesis reports |

---

## After Integration: Run Verification

```bash
# Navigate to scripts
cd scripts

# Run simulation (requires Icarus Verilog)
./run_simulation.sh

# Run synthesis comparison (requires Yosys)
./run_synthesis.sh
```

---

