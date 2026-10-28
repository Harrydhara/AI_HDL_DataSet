#!/bin/bash
# UART Peripheral Verilator Linting Script
# Catches synthesizability issues, width mismatches, latches, etc.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== UART Peripheral - Verilator Lint ===${NC}"
echo ""

# Track pass/fail
TOTAL=0
PASSED=0
FAILED=0

# Function to lint a single module
lint_module() {
    local module=$1
    echo -e "${YELLOW}Linting: ${module}${NC}"
    TOTAL=$((TOTAL + 1))
    
    if verilator --lint-only \
        -Wall \
        -Wno-DECLFILENAME \
        -Wno-UNUSED \
        --top-module $(basename $module .v) \
        $module 2>&1 | tee /tmp/verilator_lint.log
    then
        if grep -q "%Warning" /tmp/verilator_lint.log; then
            echo -e "${YELLOW}✓ Passed with warnings${NC}\n"
            PASSED=$((PASSED + 1))
        else
            echo -e "${GREEN}✓ Clean (no warnings)${NC}\n"
            PASSED=$((PASSED + 1))
        fi
    else
        echo -e "${RED}✗ Failed${NC}\n"
        FAILED=$((FAILED + 1))
    fi
}

# List of modules to lint (will be created during implementation)
MODULES=(
    "uart_baud_generator.v"
    "uart_tx.v"
    "uart_rx.v"
    "uart_register_interface.v"
    "uart_peripheral.v"
)

# Lint each module individually
for module in "${MODULES[@]}"; do
    if [ -f "$module" ]; then
        lint_module "$module"
    else
        echo -e "${YELLOW}Skipping: $module (not yet implemented)${NC}\n"
    fi
done

# Summary
echo -e "${YELLOW}=== Summary ===${NC}"
echo "Total modules: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All modules passed!${NC}"
fi
