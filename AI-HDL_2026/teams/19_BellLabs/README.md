# BellLabs

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 19
- **Institution:** University of Lagos
- **Country:** Nigeria
- **Phases with files:** DP1, DP2, DP3, DP4
- **Phases with prompt logs:** DP1, DP2, DP3, DP4

## Distinct logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 6 | 14 | 34 | 4 |

Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. See `prompt_counts_per_file.csv` in the `AI-HDL_2026` folder for the rule applied to each log. Counts describe what was logged, not effort.

## Files

| Folder | DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|---|
| `ai_logs/` | 1 | 1 | 1 | 1 |
| `rtl/` |  | 1 |  | 2 |
| `testbench/` |  |  |  | 2 |
| `netlists/` | 1 | 1 | 1 | 1 |
| `reports/` | 1 | 8 | 2 | 9 |
| `layout/` |  |  |  | 2 |
| `config/` | 1 | 3 | 2 | 2 |
| `docs/` | 2 | 11 | 4 | 2 |
| `other/` | 1 | 1 | 1 | 2 |

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
