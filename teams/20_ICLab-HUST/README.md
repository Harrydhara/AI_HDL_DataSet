# ICLab_HUST

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 20
- **Institution:** Hanoi University of Science and Technology
- **Country:** Vietnam
- **Phases with files:** DP1, DP2, DP3, DP4
- **Phases with prompt logs:** DP1, DP2, DP3

## Distinct logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 19 | 2 | 12 | 0 |

Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. See `prompt_counts_per_file.csv` at the repository root for the rule applied to each log. Counts describe what was logged, not effort.

## Files

| Folder | DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|---|
| `ai_logs/` | 2 | 1 | 1 |  |
| `rtl/` | 6 | 2 | 1 |  |
| `testbench/` | 24 |  | 2 |  |
| `netlists/` | 2 | 1 | 1 |  |
| `reports/` | 4 | 3 | 3 | 1 |
| `layout/` |  |  |  | 1 |
| `config/` | 24 | 1 | 1 |  |
| `docs/` | 2 | 5 | 5 | 5 |
| `other/` | 4 | 1 | 2 |  |

| Folder | Contents |
|---|---|
| `ai_logs/` | LLM prompt logs and chat exports |
| `rtl/` | design RTL (Verilog / SystemVerilog) |
| `testbench/` | testbenches: Verilog, cocotb (Python), Verilator (C++) |
| `netlists/` | synthesized gate-level netlists |
| `reports/` | synthesis, timing, power, area, DRC/LVS and tool logs |
| `layout/` | physical design files: GDS, DEF, LEF, MAG, SPEF, SDF |
| `config/` | constraints (SDC/XDC), flow configuration, Makefiles, build and helper scripts |
| `docs/` | READMEs, design notes, security and PPA write-ups |
| `other/` | anything else (waveforms, misc.) |

`file_map.csv` maps every file here to its path in the team's original submission.
