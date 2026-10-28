#!/bin/bash
# Run DP-2 baseline and candidate experiments, then generate comparison report.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ $# -lt 1 ]]; then
    echo "Usage: ./scripts/run_dp2_experiments.sh <openlane_path>"
    exit 1
fi

OPENLANE_PATH="$1"

# Baseline: conservative density that favors placement convergence.
echo "[1/4] Running baseline (AES_BLOCK_BYTES=1, DIE_AREA=320x240, density=0.60)"
./scripts/run_synthesis_and_ppa.sh "$OPENLANE_PATH" --aes-block-bytes 1 --die-area "0 0 320.00 240.00" --pl-target-density 0.60 --cleanup
BASELINE_RUN="$(cat runs/latest/RUN_ID.txt)"
cp runs/latest/reports/metrics.csv ../dp-2/results/baseline_metrics.csv

# Candidate: denser target under same die area.
echo "[2/4] Running candidate (AES_BLOCK_BYTES=1, DIE_AREA=320x240, density=0.70)"
./scripts/run_synthesis_and_ppa.sh "$OPENLANE_PATH" --aes-block-bytes 1 --die-area "0 0 320.00 240.00" --pl-target-density 0.70 --cleanup
CANDIDATE_RUN="$(cat runs/latest/RUN_ID.txt)"
cp runs/latest/reports/metrics.csv ../dp-2/results/optimized_metrics.csv

# Generate before/after markdown.
echo "[3/4] Generating before/after comparison report"
/home/user/electrical-and-electronics-engineering/VLSI/ai-hdl/.venv/bin/python \
    ./scripts/dp2_compare_metrics.py \
    ../dp-2/results/baseline_metrics.csv \
    ../dp-2/results/optimized_metrics.csv \
    --baseline-label "${BASELINE_RUN}" \
    --optimized-label "${CANDIDATE_RUN}" \
    --out-md ../dp-2/reports/BEFORE_AFTER_PPA.md

echo "[4/4] Done"
echo "  Baseline run:  ${BASELINE_RUN}"
echo "  Candidate run: ${CANDIDATE_RUN}"
echo "  Report: ../dp-2/reports/BEFORE_AFTER_PPA.md"
