# Challenges Faced

## 1. Secure Configuration Closure

- Issue: Secure configuration complexity significantly increased area/cell count versus the team-built UART initial run.
- Outcome: Reduced secure mode with AES_BLOCK_BYTES=1 reached flow completion.

## 2. 2-Byte Reduced Mode Failure

- Issue: AES_BLOCK_BYTES=2 currently fails at placement due utilization > 100%.
- Current status: Not closed yet; kept as a follow-up optimization target.

## 3. Submission Package Drift

- Issue: Legacy submission package layout diverged from required guideline structure.
- Outcome: Migrated to submission/ and aligned major required folders/files.

## 4. Generated Artifact Sprawl

- Issue: Temporary logs and directories accumulated during iterative debugging.
- Outcome: Removed stale artifacts and formalized runs/latest tracked snapshot policy.
