# Devrem

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 4
- **Institution:** Yildiz Technical University
- **Country:** Türkiye
- **Phases with files:** DP2, DP3, DP4
- **Phases with prompt logs:** DP1, DP3, DP4

## Distinct logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 7 | 0 | 14 | 2 |

Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. See `prompt_counts_per_file.csv` in the `AI-HDL_2026` folder for the rule applied to each log. Counts describe what was logged, not effort.

## Files

| Folder | DP2 | DP3 | DP4 | common |
|---|---|---|---|---|
| `ai_logs/` |  | 1 |  | 1 |
| `rtl/` |  |  |  | 3 |
| `testbench/` |  |  |  | 2 |
| `netlists/` |  |  |  | 1 |
| `reports/` | 1 |  |  | 2 |
| `layout/` |  |  |  | 2 |
| `config/` |  |  |  | 3 |
| `docs/` | 1 | 1 | 2 | 12 |
| `other/` |  |  |  | 2 |

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

`common/` holds files whose design phase could not be determined from the submission.

`file_map.csv` maps every file here to its path in the team's original submission.
