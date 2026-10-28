# Mercer

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** not on the final leaderboard
- **Institution:** Mercer County Community College
- **Country:** USA
- **Phases with files:** DP1, DP2, DP3, DP4
- **Phases with prompt logs:** DP1

## Logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 3 | 0 | 0 | 0 |

Counted from this team's logs; see `prompt_counts_per_file.csv` at the repository root for the rule applied to each log.

## Files

| Folder | DP1 | DP2 | DP3 | DP4 | common |
|---|---|---|---|---|---|
| `ai_logs/` | 1 |  |  |  |  |
| `rtl/` | 7 | 7 | 1 | 6 |  |
| `testbench/` | 4 | 5 | 1 |  |  |
| `reports/` | 1 | 1 | 1 | 30 |  |
| `layout/` |  |  |  | 6 |  |
| `config/` | 2 | 1 | 1 | 1 |  |
| `docs/` | 5 | 4 | 2 | 1 | 1 |

| Folder | Contents |
|---|---|
| `ai_logs/` | LLM prompt logs and chat exports |
| `rtl/` | design RTL (Verilog / SystemVerilog) |
| `testbench/` | testbenches: Verilog, cocotb (Python), Verilator (C++) |
| `reports/` | synthesis, timing, power, area, DRC/LVS and tool logs |
| `layout/` | physical design files: GDS, DEF, LEF, MAG, SPEF, SDF |
| `config/` | constraints (SDC/XDC), flow configuration, Makefiles, build and helper scripts |
| `docs/` | READMEs, design notes, security and PPA write-ups |

`common/` holds files whose design phase could not be determined from the submission.

`file_map.csv` maps every file here to its path in the team's original submission.
