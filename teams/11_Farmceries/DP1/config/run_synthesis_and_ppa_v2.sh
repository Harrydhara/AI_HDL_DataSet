#!/bin/bash
# AI-HDL DP#1 Complete Flow: Synthesis + OpenLANE PPA Analysis
#
# Features:
# - Runs Yosys synthesis first
# - Runs full OpenLANE PPA flow in Docker
# - Supports reduced AES block experiments for lower-resource runs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "Usage: ./scripts/run_synthesis_and_ppa.sh [openlane_path] [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --cleanup                    Remove temporary files after completion"
    echo "  --pdk-root <path>            Custom PDK root path (default: \$HOME/.ciel)"
    echo "  --aes-block-bytes <N>        AES block bytes for PPA: 1|2|4|8|16 (default: 16)"
    echo "  --die-area \"x0 y0 x1 y1\"      Override OpenLANE DIE_AREA (default: 0 0 190.00 140.00)"
    echo "  --pl-target-density <0..1>   Override OpenLANE placement target density (default: 0.85)"
    echo ""
    echo "OpenLANE path resolution order:"
    echo "  1) Positional [openlane_path] argument"
    echo "  2) OPENLANE_ROOT environment variable"
    echo ""
    echo "Examples:"
    echo "  ./scripts/run_synthesis_and_ppa.sh ~vlsi/tools/OpenLane --cleanup"
    echo "  ./scripts/run_synthesis_and_ppa.sh --aes-block-bytes 1"
    echo "  ./scripts/run_synthesis_and_ppa.sh --pl-target-density 0.80 --die-area \"0 0 200 150\""
    echo "  ./scripts/run_synthesis_and_ppa.sh /path/to/OpenLane --pdk-root /custom/pdk"
}

expand_special_path() {
    local path="$1"
    case "$path" in
        "~vlsi/"*) echo "$HOME/electrical-and-electronics-engineering/VLSI/${path#~vlsi/}" ;;
        "~/"*) echo "$HOME/${path#~/}" ;;
        *) echo "$path" ;;
    esac
}

# Parse arguments
CLEANUP=false
OPENLANE_PATH=""
CUSTOM_PDK_ROOT=""
AES_BLOCK_BYTES=16
DIE_AREA_OVERRIDE=""
PL_TARGET_DENSITY="0.85"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cleanup)
            CLEANUP=true
            shift
            ;;
        --pdk-root)
            if [[ $# -lt 2 ]]; then
                echo -e "${RED}Error: --pdk-root requires a value${NC}"
                usage
                exit 1
            fi
            CUSTOM_PDK_ROOT="$2"
            shift 2
            ;;
        --aes-block-bytes)
            if [[ $# -lt 2 ]]; then
                echo -e "${RED}Error: --aes-block-bytes requires a value${NC}"
                usage
                exit 1
            fi
            AES_BLOCK_BYTES="$2"
            shift 2
            ;;
        --die-area)
            if [[ $# -lt 2 ]]; then
                echo -e "${RED}Error: --die-area requires a value${NC}"
                usage
                exit 1
            fi
            DIE_AREA_OVERRIDE="$2"
            shift 2
            ;;
        --pl-target-density)
            if [[ $# -lt 2 ]]; then
                echo -e "${RED}Error: --pl-target-density requires a value${NC}"
                usage
                exit 1
            fi
            PL_TARGET_DENSITY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$OPENLANE_PATH" ]]; then
                OPENLANE_PATH="$1"
                shift
            else
                echo -e "${RED}Error: Unexpected argument '$1'${NC}"
                usage
                exit 1
            fi
            ;;
    esac
done

case "$AES_BLOCK_BYTES" in
    1|2|4|8|16)
        ;;
    *)
        echo -e "${RED}Error: --aes-block-bytes must be one of: 1, 2, 4, 8, 16${NC}"
        exit 1
        ;;
esac

if ! [[ "$PL_TARGET_DENSITY" =~ ^((0(\.[0-9]+)?)|(1(\.0+)?))$ ]]; then
    echo -e "${RED}Error: --pl-target-density must be a number between 0 and 1${NC}"
    exit 1
fi

if [[ -n "$OPENLANE_PATH" ]]; then
    OPENLANE_PATH="$(expand_special_path "$OPENLANE_PATH")"
fi

if [[ -z "$OPENLANE_PATH" && -n "${OPENLANE_ROOT:-}" ]]; then
    OPENLANE_PATH="$OPENLANE_ROOT"
fi

if [[ -z "$OPENLANE_PATH" ]]; then
    echo -e "${RED}Error: OpenLANE path not provided and OPENLANE_ROOT is not set.${NC}"
    echo ""
    usage
    exit 1
fi

if [[ ! -d "$OPENLANE_PATH" ]]; then
    echo -e "${RED}Error: OpenLANE directory not found: $OPENLANE_PATH${NC}"
    exit 1
fi

# Configuration
WORK_DIR="synthesis-work"
OUTPUT_DIR="outputs"
PERIPHERAL_NAME="uart"
TOP_MODULE="tt_um_tqv_peripheral_harness"
OPENLANE_DESIGN_NAME="dp1_${PERIPHERAL_NAME}"
OPENLANE_IMAGE="ghcr.io/the-openroad-project/openlane:ff5509f65b17bfa4068d5336495ab1718987ff69-amd64"
# Slightly larger than the previous TinyTapeout-sized floorplan to avoid
# immediate over-utilization for secure-UART experiments.
DIE_AREA="0 0 190.00 140.00"

if [[ -n "$DIE_AREA_OVERRIDE" ]]; then
    DIE_AREA="$DIE_AREA_OVERRIDE"
fi

# Set PDK_ROOT (custom flag > env var > default)
if [[ -n "$CUSTOM_PDK_ROOT" ]]; then
    PDK_ROOT="$CUSTOM_PDK_ROOT"
elif [[ -n "${PDK_ROOT:-}" ]]; then
    PDK_ROOT="$PDK_ROOT"
else
    PDK_ROOT="$HOME/.ciel"
fi

if [[ ! -d "$PDK_ROOT" ]]; then
    echo -e "${RED}Error: PDK root directory not found: $PDK_ROOT${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  AI-HDL DP#1 Complete Synthesis & PPA     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}OpenLANE path: $OPENLANE_PATH${NC}"
echo -e "${GREEN}PDK root: $PDK_ROOT${NC}"
echo -e "${GREEN}AES block bytes for this run: $AES_BLOCK_BYTES${NC}"
echo -e "${GREEN}DIE_AREA: $DIE_AREA${NC}"
echo -e "${GREEN}PL target density: $PL_TARGET_DENSITY${NC}"
echo -e "${GREEN}Running full synthesis + PPA analysis${NC}"
echo ""

# Step 1: Clean and create working directories
echo -e "${YELLOW}[1/8] Preparing directories...${NC}"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$OUTPUT_DIR"
echo -e "${GREEN}  ✓ Created $WORK_DIR and $OUTPUT_DIR${NC}"

# Step 2: Copy files
echo -e "${YELLOW}[2/8] Copying source files to flat directory...${NC}"
cp peripheral/src/peripheral.v "$WORK_DIR/"
cp peripheral/src/tt_wrapper.v "$WORK_DIR/"
cp peripheral/src/uart/*.v "$WORK_DIR/"
cp peripheral/src/aes/*.v "$WORK_DIR/"
cp peripheral/src/test_harness/*.sv "$WORK_DIR/"
cp cpu/src/*.v "$WORK_DIR/"

if [[ "$AES_BLOCK_BYTES" != "16" ]]; then
    sed -i "s/localparam integer AES_BLOCK_BYTES_CFG = 16;/localparam integer AES_BLOCK_BYTES_CFG = $AES_BLOCK_BYTES;/" "$WORK_DIR/peripheral.v"
    echo -e "${YELLOW}  • Applied reduced AES block mode in working copy: ${AES_BLOCK_BYTES} byte(s)${NC}"
fi

echo -e "${GREEN}  ✓ All files copied${NC}"

# Step 3: Generate synthesis script
echo -e "${YELLOW}[3/8] Generating Yosys synthesis script...${NC}"
cat > "$WORK_DIR/synth.ys" << 'SYNTH_SCRIPT'
# Yosys Synthesis Script for AI-HDL DP#1

# Read SystemVerilog test harness files
read_verilog -sv reclocking.sv
read_verilog -sv rising_edge_detector.sv
read_verilog -sv falling_edge_detector.sv
read_verilog -sv spi_reg.sv
read_verilog -sv synchronizer.sv

# Read Verilog core files (bottom-up order is safer)
read_verilog alu.v
read_verilog core.v
read_verilog counter.v
read_verilog cpu.v
read_verilog decode.v
read_verilog latch_reg.v
read_verilog mem_ctrl.v
read_verilog qspi_ctrl.v
read_verilog qspi_flash.v
read_verilog register.v
read_verilog time.v

# Read UART peripheral modules
read_verilog uart_baud_generator.v
read_verilog uart_tx.v
read_verilog uart_rx.v
read_verilog uart_register_interface.v
read_verilog uart_peripheral.v

# Read AES peripheral modules (Phase 2 - in dependency order)
read_verilog -defer aes_sbox.v
read_verilog -defer aes_add_round_key.v
read_verilog -defer aes_shift_rows.v
read_verilog -defer aes_mix_columns.v
read_verilog -defer aes_round.v
read_verilog -defer aes_inv_round.v
read_verilog -defer aes_key_expansion.v
read_verilog -defer aes_core.v
read_verilog -defer aes_uart_streaming.v
read_verilog -defer aes_uart_controller.v
read_verilog -defer secure_uart_peripheral.v

# Read top-level files
read_verilog peripheral.v
read_verilog tinyqv.v
read_verilog tt_wrapper.v

# Synthesize
hierarchy -top tt_um_tqv_peripheral_harness
synth -top tt_um_tqv_peripheral_harness
opt
clean
stat
SYNTH_SCRIPT
echo -e "${GREEN}  ✓ synth.ys created${NC}"

# Step 4: Run Yosys
echo -e "${YELLOW}[4/8] Running Yosys synthesis...${NC}"
(
    cd "$WORK_DIR"
    if yosys synth.ys > synthesis.log 2>&1; then
        echo -e "${GREEN}  ✓ Synthesis successful${NC}"
    else
        echo -e "${RED}  ✗ Synthesis failed! Check $OUTPUT_DIR/synthesis.log${NC}"
        cp synthesis.log "../$OUTPUT_DIR/synthesis.log" 2>/dev/null || true
        exit 1
    fi
)
cp "$WORK_DIR/synthesis.log" "$OUTPUT_DIR/synthesis.log"
grep -A 30 "=== design hierarchy ===" "$WORK_DIR/synthesis.log" | head -40 || true

# Step 5: Generate OpenLANE config
echo -e "${YELLOW}[5/8] Generating OpenLANE configuration...${NC}"
python3 << PYTHON_CONFIG
import json

with open('peripheral/src/config.json', 'r', encoding='utf-8') as f:
    config = json.load(f)

config = {k: v for k, v in config.items() if k != '//'}

config['DESIGN_NAME'] = '$TOP_MODULE'
config['VERILOG_FILES'] = [
    'dir::reclocking.sv',
    'dir::synchronizer.sv',
    'dir::rising_edge_detector.sv',
    'dir::falling_edge_detector.sv',
    'dir::spi_reg.sv',
    'dir::alu.v',
    'dir::core.v',
    'dir::decode.v',
    'dir::cpu.v',
    'dir::register.v',
    'dir::latch_reg.v',
    'dir::mem_ctrl.v',
    'dir::qspi_ctrl.v',
    'dir::qspi_flash.v',
    'dir::uart_baud_generator.v',
    'dir::uart_tx.v',
    'dir::uart_rx.v',
    'dir::uart_register_interface.v',
    'dir::uart_peripheral.v',
    'dir::aes_sbox.v',
    'dir::aes_add_round_key.v',
    'dir::aes_shift_rows.v',
    'dir::aes_mix_columns.v',
    'dir::aes_round.v',
    'dir::aes_inv_round.v',
    'dir::aes_key_expansion.v',
    'dir::aes_core.v',
    'dir::aes_uart_streaming.v',
    'dir::aes_uart_controller.v',
    'dir::secure_uart_peripheral.v',
    'dir::peripheral.v',
    'dir::counter.v',
    'dir::time.v',
    'dir::tinyqv.v',
    'dir::tt_wrapper.v'
]
config['DIE_AREA'] = '$DIE_AREA'

# Lower synthesis memory pressure for large RTL compositions.
config['SYNTH_SHARE_RESOURCES'] = 0
config['SYNTH_NO_FLAT'] = 1

# Placement tuning: reduced AES experiments were failing GPL-0302 with
# suggested density ~0.79, so use a denser target for robust convergence.
config['PL_TARGET_DENSITY'] = $PL_TARGET_DENSITY
config['PL_TARGET_DENSITY_PCT'] = int(float($PL_TARGET_DENSITY) * 100)

with open('$WORK_DIR/config.json', 'w', encoding='utf-8') as f:
    json.dump(config, f, indent=2)
PYTHON_CONFIG
echo -e "${GREEN}  ✓ config.json created${NC}"

# Step 6: Run OpenLANE PPA analysis
echo -e "${YELLOW}[6/8] Running OpenLANE PPA analysis...${NC}"
WORK_DIR_ABS="$(cd "$WORK_DIR" && pwd)"
OUTPUT_DIR_ABS="$(cd "$OUTPUT_DIR" && pwd)"
OPENLANE_LOG="$OUTPUT_DIR_ABS/openlane.log"

echo "  Mounting $WORK_DIR_ABS into OpenLANE container"
echo "  Starting OpenLANE flow (this may take several minutes)..."

CONTAINER_ID=""
cleanup_container() {
    if [[ -n "$CONTAINER_ID" ]]; then
        docker stop "$CONTAINER_ID" > /dev/null 2>&1 || true
        docker rm "$CONTAINER_ID" > /dev/null 2>&1 || true
    fi
}
trap cleanup_container EXIT

OLD_CONTAINERS="$(docker ps -aq --filter "ancestor=$OPENLANE_IMAGE" || true)"
if [[ -n "$OLD_CONTAINERS" ]]; then
    echo "  Cleaning up old OpenLANE containers..."
    docker stop $OLD_CONTAINERS > /dev/null 2>&1 || true
    docker rm $OLD_CONTAINERS > /dev/null 2>&1 || true
fi

CONTAINER_ID=$(docker run -d \
    -v "$OPENLANE_PATH:/openlane" \
    -v "$OPENLANE_PATH/designs:/openlane/install" \
    -v "$HOME:$HOME" \
    -v "$PDK_ROOT:$PDK_ROOT" \
    -v "$WORK_DIR_ABS:/openlane/designs/$OPENLANE_DESIGN_NAME" \
    -e PDK_ROOT="$PDK_ROOT" \
    -e PDK="sky130A" \
    --user "$(id -u):$(id -g)" \
    "$OPENLANE_IMAGE" \
    sleep infinity)

if [[ -z "$CONTAINER_ID" ]]; then
    echo -e "${RED}  ✗ Failed to start OpenLANE Docker container${NC}"
    exit 1
fi

FLOW_SUCCESS=false
if docker exec "$CONTAINER_ID" /bin/bash -lc "cd /openlane && ./flow.tcl -design $OPENLANE_DESIGN_NAME" 2>&1 | tee "$OPENLANE_LOG"; then
    FLOW_SUCCESS=true
    echo -e "${GREEN}  ✓ OpenLANE completed successfully${NC}"
else
    echo -e "${RED}  ✗ OpenLANE flow failed${NC}"
    echo "  Last 50 lines from $OPENLANE_LOG:"
    tail -50 "$OPENLANE_LOG" || true
fi

if [[ "$FLOW_SUCCESS" != true ]]; then
    exit 1
fi

LATEST_RUN="$(ls -t "$WORK_DIR_ABS/runs" 2>/dev/null | head -1 || true)"
if [[ -n "$LATEST_RUN" && -f "$WORK_DIR_ABS/runs/$LATEST_RUN/reports/metrics.csv" ]]; then
    echo ""
    echo -e "${BLUE}=== Key PPA Metrics ===${NC}"
    python3 - << PYTHON_METRICS
import csv
from pathlib import Path

metrics = Path('$WORK_DIR_ABS/runs/$LATEST_RUN/reports/metrics.csv')
with metrics.open('r', encoding='utf-8') as f:
    row = next(csv.DictReader(f))

print(f"  Area: {row.get('DIEAREA_mm^2', 'N/A')} mm²")
print(f"  WNS:  {row.get('wns', 'N/A')} ns (Worst Negative Slack)")
print(f"  TNS:  {row.get('tns', 'N/A')} ns (Total Negative Slack)")
pi = row.get('power_typical_internal_uW', '-1')
ps = row.get('power_typical_switching_uW', '-1')
pl = row.get('power_typical_leakage_uW', '-1')
if pi not in ('-1', '', 'N/A'):
    total_uw = float(pi) + float(ps) + float(pl)
    print(f"  Power: {total_uw:.6f} µW ({total_uw/1000:.9f} mW)")
else:
    print("  Power: N/A")
PYTHON_METRICS
fi

# Step 7: Move runs to stable output location
echo -e "${YELLOW}[7/8] Moving results to runs/ directory...${NC}"
mkdir -p runs
if [[ -d "$WORK_DIR/runs" ]]; then
    for run_dir in "$WORK_DIR"/runs/*; do
        [[ -d "$run_dir" ]] || continue
        mv "$run_dir" runs/
    done
fi

LATEST_RUN="$(ls -t runs 2>/dev/null | head -1 || true)"
if [[ -n "$LATEST_RUN" ]]; then
    echo -e "${GREEN}  ✓ Results moved to runs/$LATEST_RUN${NC}"

    # Keep a compact, always-tracked snapshot for git in runs/latest/.
    LATEST_TRACKED_DIR="runs/latest"
    rm -rf "$LATEST_TRACKED_DIR"
    mkdir -p "$LATEST_TRACKED_DIR/reports" "$LATEST_TRACKED_DIR/logs"

    printf "%s\n" "$LATEST_RUN" > "$LATEST_TRACKED_DIR/RUN_ID.txt"
    [[ -f "runs/$LATEST_RUN/reports/metrics.csv" ]] && cp "runs/$LATEST_RUN/reports/metrics.csv" "$LATEST_TRACKED_DIR/reports/"
    [[ -f "runs/$LATEST_RUN/reports/manufacturability.rpt" ]] && cp "runs/$LATEST_RUN/reports/manufacturability.rpt" "$LATEST_TRACKED_DIR/reports/"
    [[ -f "runs/$LATEST_RUN/logs/synthesis/1-synthesis.log" ]] && cp "runs/$LATEST_RUN/logs/synthesis/1-synthesis.log" "$LATEST_TRACKED_DIR/logs/synthesis_1.log.txt"
    [[ -f "$OPENLANE_LOG" ]] && cp "$OPENLANE_LOG" "$LATEST_TRACKED_DIR/logs/openlane_flow.log.txt"

    if [[ -f "$LATEST_TRACKED_DIR/reports/metrics.csv" ]]; then
        python3 - << PYTHON_LATEST_SUMMARY
import csv
from pathlib import Path

metrics_path = Path("$LATEST_TRACKED_DIR/reports/metrics.csv")
summary_path = Path("$LATEST_TRACKED_DIR/SUMMARY.md")
run_id = "$LATEST_RUN"

with metrics_path.open("r", encoding="utf-8") as f:
    row = next(csv.DictReader(f))

area = row.get("DIEAREA_mm^2", "N/A")
wns = row.get("wns", "N/A")
tns = row.get("tns", "N/A")

pi = row.get("power_typical_internal_uW", "-1")
ps = row.get("power_typical_switching_uW", "-1")
pl = row.get("power_typical_leakage_uW", "-1")
power = "N/A"
if pi not in ("-1", "", "N/A"):
    power = f"{float(pi) + float(ps) + float(pl):.6f}"

summary = f"""# Latest OpenLANE Run Snapshot

- Run ID: {run_id}
- Area (mm^2): {area}
- WNS (ns): {wns}
- TNS (ns): {tns}
- Total Typical Power (uW): {power}

This directory is intentionally lightweight and tracked in git.
Full run archives remain under runs/RUN_*/ (ignored by default).
"""

summary_path.write_text(summary, encoding="utf-8")
PYTHON_LATEST_SUMMARY
    fi

    echo -e "${GREEN}  ✓ Updated tracked snapshot at runs/latest/${NC}"
fi

# Step 8: Cleanup
echo -e "${YELLOW}[8/8] Cleanup...${NC}"
if [[ "$CLEANUP" == true ]]; then
    rm -rf "$WORK_DIR"
    echo -e "${GREEN}  ✓ Temporary files removed${NC}"
else
    echo -e "${YELLOW}  Keeping $WORK_DIR for review${NC}"
    echo -e "${YELLOW}  (Use --cleanup flag to auto-remove)${NC}"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Synthesis & PPA Analysis Complete!    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

echo "Results saved to:"
echo "  - Logs: $OUTPUT_DIR/ (synthesis.log, openlane.log)"
if [[ -n "$LATEST_RUN" ]]; then
    echo "  - Full run: runs/$LATEST_RUN/"
    echo "  - Tracked snapshot: runs/latest/"
fi
echo ""
echo "Next steps:"
echo "  1. Review PPA metrics above"
if [[ -n "$LATEST_RUN" ]]; then
    echo "  2. Check detailed reports in: runs/$LATEST_RUN/reports/"
    echo "  3. View GDSII layout:"
    echo "     klayout runs/$LATEST_RUN/results/final/gds/*.gds"
    echo "  4. Review timing reports if WNS is negative"
fi
echo ""
