#!/usr/bin/env bash
set -euo pipefail

# Wrapper for DP-4 runs that reuses the validated DP-1 OpenLANE flow
# and snapshots artifacts into dp-4/results for submission tracking.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <openlane_path> [--aes-block-bytes N] [--die-area \"x0 y0 x1 y1\"] [--pl-target-density D] [--cleanup]"
  exit 1
fi

OPENLANE_PATH="$1"
shift

AES_BLOCK_BYTES="1"
DIE_AREA="0 0 320.00 240.00"
PL_TARGET_DENSITY="0.61"
DO_CLEANUP="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --aes-block-bytes)
      AES_BLOCK_BYTES="$2"
      shift 2
      ;;
    --die-area)
      DIE_AREA="$2"
      shift 2
      ;;
    --pl-target-density)
      PL_TARGET_DENSITY="$2"
      shift 2
      ;;
    --cleanup)
      DO_CLEANUP="true"
      shift 1
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DP4_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${DP4_DIR}/.." && pwd)"

DP1_DIR="${REPO_ROOT}/dp-1"
DP1_SCRIPT="${DP1_DIR}/scripts/run_synthesis_and_ppa.sh"

if [[ ! -x "${DP1_SCRIPT}" ]]; then
  echo "Error: missing executable script: ${DP1_SCRIPT}"
  exit 1
fi

CMD=(
  "${DP1_SCRIPT}" "${OPENLANE_PATH}"
  --aes-block-bytes "${AES_BLOCK_BYTES}"
  --die-area "${DIE_AREA}"
  --pl-target-density "${PL_TARGET_DENSITY}"
)

if [[ "${DO_CLEANUP}" == "true" ]]; then
  CMD+=(--cleanup)
fi

echo "Running: ${CMD[*]}"
(
  cd "${DP1_DIR}"
  "${CMD[@]}"
)

RUN_ID_FILE="${DP1_DIR}/runs/latest/RUN_ID.txt"
if [[ ! -f "${RUN_ID_FILE}" ]]; then
  echo "Error: expected RUN_ID file not found at ${RUN_ID_FILE}"
  exit 1
fi

RUN_ID="$(cat "${RUN_ID_FILE}")"
RUN_DIR="${DP1_DIR}/runs/${RUN_ID}"
DEST_DIR="${DP4_DIR}/results/${RUN_ID}"
mkdir -p "${DEST_DIR}" "${DP4_DIR}/gds" "${DP4_DIR}/netlist" "${DP4_DIR}/constraints" "${DP4_DIR}/signoff"

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -f "${src}" ]]; then
    cp -f "${src}" "${dst}"
  fi
}

cp -f "${RUN_ID_FILE}" "${DEST_DIR}/RUN_ID.txt"

copy_if_exists "${DP1_DIR}/runs/latest/SUMMARY.md" "${DEST_DIR}/SUMMARY.md"
copy_if_exists "${DP1_DIR}/runs/latest/openlane_flow.log.txt" "${DEST_DIR}/openlane_flow.log.txt"
copy_if_exists "${RUN_DIR}/reports/metrics.csv" "${DEST_DIR}/metrics.csv"
copy_if_exists "${RUN_DIR}/reports/manufacturability.rpt" "${DEST_DIR}/manufacturability.rpt"

# Promote key files to canonical DP-4 submission folders.
for gds in "${RUN_DIR}"/results/final/gds/*.gds; do
  if [[ -f "${gds}" ]]; then
    cp -f "${gds}" "${DP4_DIR}/gds/${RUN_ID}_$(basename "${gds}")"
  fi
done

for netlist in "${RUN_DIR}"/results/final/verilog/gl/*; do
  if [[ -f "${netlist}" ]]; then
    cp -f "${netlist}" "${DP4_DIR}/netlist/${RUN_ID}_$(basename "${netlist}")"
  fi
done

for sdc in "${RUN_DIR}"/results/final/sdc/*.sdc; do
  if [[ -f "${sdc}" ]]; then
    cp -f "${sdc}" "${DP4_DIR}/constraints/${RUN_ID}_$(basename "${sdc}")"
  fi
done

copy_if_exists "${RUN_DIR}/reports/signoff/drc.rpt" "${DP4_DIR}/signoff/${RUN_ID}_drc.rpt"
copy_if_exists "${RUN_DIR}/reports/signoff/38-tt_um_tqv_peripheral_harness.lvs.rpt" "${DP4_DIR}/signoff/${RUN_ID}_lvs.rpt"
copy_if_exists "${RUN_DIR}/reports/signoff/31-rcx_sta.summary.rpt" "${DP4_DIR}/signoff/${RUN_ID}_sta_summary.rpt"
copy_if_exists "${RUN_DIR}/reports/signoff/31-rcx_sta.checks.rpt" "${DP4_DIR}/signoff/${RUN_ID}_sta_checks.rpt"

{
  echo "date=$(date -Iseconds)"
  echo "openlane_path=${OPENLANE_PATH}"
  echo "aes_block_bytes=${AES_BLOCK_BYTES}"
  echo "die_area=${DIE_AREA}"
  echo "pl_target_density=${PL_TARGET_DENSITY}"
  echo "cleanup=${DO_CLEANUP}"
} > "${DEST_DIR}/command.txt"

echo "DP-4 snapshot saved to: ${DEST_DIR}"
