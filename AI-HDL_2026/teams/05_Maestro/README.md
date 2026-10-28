# Maestro

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 5
- **Institution:** The University of Arizona
- **Country:** USA
- **Phases with files:** DP1, DP2, DP3, DP4
- **Phases with prompt logs:** DP1, DP2, DP3, DP4

## Distinct logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 3 | 6 | 16 | 17 |

Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. See `prompt_counts_per_file.csv` in the `AI-HDL_2026` folder for the rule applied to each log. Counts describe what was logged, not effort.

## Files

| Folder | DP1 | DP2 | DP3 | DP4 | common |
|---|---|---|---|---|---|
| `ai_logs/` | 3 | 4 | 4 | 3 |  |
| `rtl/` | 2 | 4 | 1 | 5 | 2 |
| `testbench/` | 1 | 1 | 1 | 1 |  |
| `netlists/` |  |  |  | 1 |  |
| `reports/` | 19 | 26 | 18 | 34 |  |
| `layout/` |  |  |  | 4 |  |
| `docs/` | 6 | 7 | 8 | 8 | 1 |
| `other/` |  | 1 |  | 1 |  |

| Folder | Contents |
|---|---|
| `ai_logs/` | LLM prompt logs and chat exports |
| `rtl/` | design RTL (Verilog / SystemVerilog) |
| `testbench/` | testbenches: Verilog, cocotb (Python), Verilator (C++) |
| `netlists/` | synthesized gate-level netlists |
| `reports/` | synthesis, timing, power, area, DRC/LVS and tool logs |
| `layout/` | physical design files: GDS, DEF, LEF, MAG, SPEF, SDF |
| `docs/` | READMEs, design notes, security and PPA write-ups |
| `other/` | anything else (waveforms, misc.) |

`common/` holds files whose design phase could not be determined from the submission.

`file_map.csv` maps every file here to its path in the team's original submission.
