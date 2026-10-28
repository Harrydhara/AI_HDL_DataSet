# Farmceries

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 11
- **Institution:** University of Lagos
- **Country:** Nigeria
- **Phases with files:** DP1, DP2, DP3, DP4
- **Phases with prompt logs:** DP1, DP2, DP3, DP4

## Logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 21 | 3 | 9 | 6 |

Counted from this team's logs; see `prompt_counts_per_file.csv` at the repository root for the rule applied to each log.

## Files

| Folder | DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|---|
| `ai_logs/` | 6 | 3 | 1 | 1 |
| `rtl/` | 27 |  |  | 1 |
| `testbench/` | 22 |  |  |  |
| `netlists/` |  |  |  | 1 |
| `reports/` | 4 | 1 | 1 | 3 |
| `layout/` |  |  |  | 1 |
| `openlane_runs/` | 17 |  |  | 5 |
| `config/` | 26 | 2 |  | 2 |
| `docs/` | 50 | 6 | 6 | 7 |

| Folder | Contents |
|---|---|
| `ai_logs/` | LLM prompt logs and chat exports |
| `rtl/` | design RTL (Verilog / SystemVerilog) |
| `testbench/` | testbenches: Verilog, cocotb (Python), Verilator (C++) |
| `netlists/` | synthesized gate-level netlists |
| `reports/` | synthesis, timing, power, area, DRC/LVS and tool logs |
| `layout/` | physical design files: GDS, DEF, LEF, MAG, SPEF, SDF |
| `openlane_runs/` | complete OpenLane run folders, internal structure kept |
| `config/` | constraints (SDC/XDC), flow configuration, Makefiles, build and helper scripts |
| `docs/` | READMEs, design notes, security and PPA write-ups |

`file_map.csv` maps every file here to its path in the team's original submission.
