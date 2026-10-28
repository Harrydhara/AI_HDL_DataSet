# ICLab_HUST2

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 8
- **Institution:** Hanoi University of Science and Technology
- **Country:** Vietnam
- **Phases with files:** DP1, DP2, DP3, DP4
- **Phases with prompt logs:** DP1, DP3, DP4

## Distinct logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 14 | 0 | 7 | 9 |

Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. See `prompt_counts_per_file.csv` in the `AI-HDL_2026` folder for the rule applied to each log. Counts describe what was logged, not effort.

## Files

| Folder | DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|---|
| `ai_logs/` | 6 | 1 | 1 | 1 |
| `rtl/` | 15 | 6 | 1 |  |
| `testbench/` | 16 |  | 2 |  |
| `netlists/` | 1 | 1 | 1 |  |
| `reports/` | 9 | 5 | 2 | 5 |
| `config/` | 8 | 1 |  |  |
| `docs/` | 20 | 5 | 8 | 9 |
| `other/` | 11 | 5 | 2 |  |

| Folder | Contents |
|---|---|
| `ai_logs/` | LLM prompt logs and chat exports |
| `rtl/` | design RTL (Verilog / SystemVerilog) |
| `testbench/` | testbenches: Verilog, cocotb (Python), Verilator (C++) |
| `netlists/` | synthesized gate-level netlists |
| `reports/` | synthesis, timing, power, area, DRC/LVS and tool logs |
| `config/` | constraints (SDC/XDC), flow configuration, Makefiles, build and helper scripts |
| `docs/` | READMEs, design notes, security and PPA write-ups |
| `other/` | anything else (waveforms, misc.) |

`file_map.csv` maps every file here to its path in the team's original submission.
