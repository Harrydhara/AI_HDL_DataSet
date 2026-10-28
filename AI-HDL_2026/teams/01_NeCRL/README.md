# NeCRL

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 1
- **Institution:** San Francisco State University
- **Country:** USA
- **Phases with files:** DP1, DP2, DP3, DP4
- **Phases with prompt logs:** DP1, DP2, DP3
- **Taped out:** AES-128 accelerator (graduate division winner)

## Distinct logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 18 | 34 | 60 | 0 |

Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. See `prompt_counts_per_file.csv` in the `AI-HDL_2026` folder for the rule applied to each log. Counts describe what was logged, not effort.

## Files

| Folder | DP1 | DP2 | DP3 | DP4 | common |
|---|---|---|---|---|---|
| `ai_logs/` | 2 | 2 | 7 |  |  |
| `rtl/` |  |  |  |  | 8 |
| `testbench/` |  |  |  |  | 8 |
| `netlists/` |  |  |  | 2 | 1 |
| `reports/` | 2 |  |  | 125 |  |
| `layout/` |  |  |  | 2 |  |
| `config/` |  |  |  | 3 | 3 |
| `docs/` |  |  | 1 | 1 | 2 |

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

`common/` holds files whose design phase could not be determined from the submission.

`file_map.csv` maps every file here to its path in the team's original submission.
