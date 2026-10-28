#!/bin/bash

echo "Starting Verilator Simulation..."

# move to repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

echo "Running from:"
pwd

# clean previous builds
rm -rf obj_dir

# compile and build executable
verilator \
--binary \
--trace \
--timing \
--top-module tb_tiny_gpu \
designs/tiny_gpu/src/ai_accelerator.v \
designs/tiny_gpu/src/peripheral_bus.v \
designs/tiny_gpu/src/tiny_gpu.v \
designs/tiny_gpu/testbench/tb_tiny_gpu.v

# run simulation
./obj_dir/Vtb_tiny_gpu
