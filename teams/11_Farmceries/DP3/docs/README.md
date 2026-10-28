# DP-3 Workspace: Security Evaluation and Threat Mitigation

This directory tracks all DP-3 security assessment, countermeasure implementation,
validation results, and reports for the Farmceries Secure UART + AES-128 design.

## Scope

- **Design under analysis:** `dp-1/peripheral/src/aes/secure_uart_peripheral.v` (and sub-modules)
- **Starting point:** DP-2 optimized design (branch `dp-2`, tag `DP2-Submission`)
- **Security objective:** Identify vulnerabilities, implement RTL countermeasures, prove fixes work

## Contents

```
dp-3/
├── README.md                                  ← this file
├── ai_logs/
│   └── raw_logs/
│       └── 00_dp3_session.md                 ← LLM session log for this phase
├── reports/
│   ├── SECURITY_ASSESSMENT.md                ← CIA/STRIDE/DREAD + CWE list (Week 1)
│   ├── THREAT_MITIGATION_PLAN.md             ← one fix per CWE (Week 1)
│   ├── SECURITY_EVALUATION_REPORT.md         ← master submission doc (Week 2)
│   └── PPA_OVERHEAD.md                       ← DP-2 baseline vs DP-3 hardened
└── results/
    ├── dp2_baseline_metrics.csv              ← copied from dp-2/results/
    └── dp3_hardened_metrics.csv             ← new OpenLANE run on hardened design
```

## Countermeasures Implemented

| # | Name | CWE Fixed | RTL Location |
|---|------|-----------|-------------|
| CM#1 | Two-stage authenticated write lock | CWE-284 | `secure_uart_peripheral.v` — SEC_CTRL FSM |
| CM#2 | AES key read-back masking | CWE-312 | `secure_uart_peripheral.v` — register-read case |
| CM#3 | BAUD_DIV sanity clamp | CWE-400 | `secure_uart_peripheral.v` — UART_CTRL write |

## Security Test Suite

All tests in `dp-1/peripheral/test/test_secure_uart.py`. Run with:

```bash
cd dp-1/peripheral/test
make -f test_secure_uart.mk
```

**Result: 9/9 PASS (TESTS=9 PASS=9 FAIL=0 SKIP=0)**

## Deliverables Mapping (DP-3 Docs)

- **Secure RTL:** `dp-1/peripheral/src/aes/secure_uart_peripheral.v` (hardened, functionally correct)
- **Security Evaluation Report:** `dp-3/reports/SECURITY_EVALUATION_REPORT.md`
  - Vulnerability assessment: `SECURITY_ASSESSMENT.md`
  - Countermeasure explanation: Section 4 of the Evaluation Report
  - Validation results: Section 5 (Proof of Security) + Section 6 (Regression)
  - PPA overhead: `PPA_OVERHEAD.md`
- **GitHub Tag:** `DP3-Submission`

## Automation

Synthesis + PPA runs use the existing script from DP-1/DP-2:

```bash
cd dp-1
./scripts/run_synthesis_and_ppa.sh /path/to/OpenLane --cleanup
```
