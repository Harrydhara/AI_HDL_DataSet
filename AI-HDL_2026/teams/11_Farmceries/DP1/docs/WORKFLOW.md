# UART Development Workflow

This document describes the integrated Verilator + Cocotb workflow for UART peripheral development.

## Tools Overview

### Verilator (Linting)
- **Purpose**: Static code analysis - catches synthesizability issues
- **Speed**: Instant (no simulation)
- **Use for**: Code quality checks before every commit

### Cocotb + Icarus Verilog (Testing)
- **Purpose**: Functional verification with Python testbenches
- **Speed**: Fast for small/medium tests
- **Use for**: Development, debugging, functional tests

## Recommended Workflow

```bash
# 1. Write/modify Verilog module
vim uart/uart_baud_generator.v

# 2. Lint immediately (catches issues early)
cd dp-1/peripheral/src
make lint

# 3. Fix any warnings/errors
# ... edit code ...

# 4. Write cocotb test
vim ../../test/test_baud_gen.py

# 5. Run functional test
cd ../../test
make -f test_baud_gen.mk

# 6. Iterate until tests pass
# ... debug, fix, repeat ...

# 7. Final lint check before commit
cd ../src
make lint

# 8. Commit clean code
git add uart/uart_baud_generator.v
git commit -m "feat: implement baud rate generator"
```

## Makefile Targets

### `make lint`
Runs Verilator linting on all UART modules.

**What it checks**:
- ✓ Unintentional latches
- ✓ Width mismatches
- ✓ Incomplete case statements
- ✓ Unused/undriven signals
- ✓ Combinational loops
- ✓ Synthesizability issues

**Output**:
```bash
=== UART Peripheral - Verilator Lint ===

Linting: uart_baud_generator.v
✓ Clean (no warnings)

Linting: uart_tx.v
✓ Passed with warnings

=== Summary ===
Total modules: 5
Passed: 5
All modules passed!
```

### `make test-all`
Runs all cocotb test suites (will be populated as modules are created).

### `make clean`
Removes all build artifacts (.vcd, __pycache__, sim_build, etc.)

## Verilator Warning Control

### Common Warnings You'll See

**WIDTH**: Width mismatch
```verilog
// Warning: Width mismatch
assign data[7:0] = counter[15:0];  // Truncation!

// Fix: Explicit slicing
assign data[7:0] = counter[7:0];   // Clear intent
```

**LATCH**: Unintentional latch
```verilog
// Warning: Latch inference
always @(*) begin
    if (enable)
        output_reg = input_data;
    // Missing else!
end

// Fix: Complete assignments
always @(*) begin
    if (enable)
        output_reg = input_data;
    else
        output_reg = 8'h00;  // Or retain: output_reg = output_reg
end
```

**UNUSED**: Signal declared but never used
```verilog
// Warning: Unused signal
input wire reserved;  // Never referenced

// Fix: Either use it or document why unused
/* verilator lint_off UNUSED */
input wire reserved;  // Future expansion
/* verilator lint_on UNUSED */
```

### Suppressing Warnings

**In code** (preferred for intentional patterns):
```verilog
/* verilator lint_off WIDTH */
assign truncated = wide_signal;  // Intentional truncation
/* verilator lint_on WIDTH */
```

**In lint.sh** (for project-wide exceptions):
```bash
verilator --lint-only -Wall -Wno-UNUSED *.v
```

## Integration with Git Workflow

### Pre-commit Hook (Optional)

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Run lint before allowing commit

cd dp-1/peripheral/src
if ! make lint; then
    echo "Linting failed! Fix issues before committing."
    exit 1
fi
```

### Branch Strategy

- **main**: Stable, linted code only
- **basit-dp-1**: UART development branch
- Always `make lint` before merging to main

## Troubleshooting

### "verilator: command not found"
```bash
# Install Verilator
sudo apt-get install verilator
```

### Lint passes but synthesis fails
Verilator catches most issues, but can't catch everything:
- Clock domain crossing issues
- Timing violations
- FPGA-specific constraints

Always run synthesis as final check!

### Test passes but lint fails
This indicates your code works but isn't synthesizable or has style issues. **Fix the lint warnings** - they represent real problems that will bite you later.

## Next Steps

As you implement each UART module:

1. Create Verilog module in `uart/`
2. Update `lint.sh` to include the new module
3. Create cocotb test in `../../test/`
4. Update this README with module-specific notes

## Resources

- [Verilator Manual](https://verilator.org/guide/latest/)
- [Cocotb Documentation](https://docs.cocotb.org/)
- [UART_FUNDAMENTALS.md](../../docs/UART_FUNDAMENTALS.md) - Protocol basics
- [PROJECT_PLAN.md](../../docs/PROJECT_PLAN.md) - Implementation roadmap
