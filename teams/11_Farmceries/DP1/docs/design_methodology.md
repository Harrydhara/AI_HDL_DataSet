# Design Methodology

## Initial Approach

We started from the provided TinyQV CPU core and built our UART peripheral, integrating it through the existing wrapper/top-level structure.

## AI Integration Strategy

AI was used as an accelerator for module drafting, design review, run-debug support, and documentation refinement.

## Design Evolution

- Team-built UART implementation and closure
- Secure UART integration path with AES modules
- Reduced-mode synthesis experiments to improve OpenLANE closure feasibility

## Key Decisions

- Keep full local OpenLANE run archives under runs/RUN_*/
- Track only a lightweight latest snapshot under runs/latest/
- Move submission package to dp-1/submission with guideline-aligned structure

## Verification Strategy

- Module and integration testbench collateral captured in submission/testbench/
- PPA evidence captured from validated OpenLANE runs and stored in submission/results/synthesis/
