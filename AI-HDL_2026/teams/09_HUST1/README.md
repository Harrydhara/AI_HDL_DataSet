# HUST1

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 9
- **Institution:** Hanoi University of Science and Technology
- **Country:** Vietnam
- **Phases with files:** DP3, DP4
- **Phases with prompt logs:** DP3

## Distinct logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 0 | 0 | 8 | 0 |

Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. See `prompt_counts_per_file.csv` in the `AI-HDL_2026` folder for the rule applied to each log. Counts describe what was logged, not effort.

## Files

| Folder | DP3 | DP4 |
|---|---|---|
| `ai_logs/` | 1 |  |
| `rtl/` | 121 |  |
| `testbench/` | 67 |  |
| `netlists/` | 3 |  |
| `reports/` |  | 8 |
| `layout/` |  | 11 |
| `config/` | 21 |  |
| `docs/` | 41 | 1 |
| `other/` | 34 |  |

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
