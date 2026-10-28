# ITIMS Boys

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 2
- **Institution:** Hanoi University of Science and Technology
- **Country:** Vietnam
- **Phases with files:** DP1, DP2, DP3, DP4
- **Phases with prompt logs:** DP1, DP2, DP3, DP4
- **Taped out:** SPI controller + CRC-16 (undergraduate division winner)

## Logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 6 | 5 | 19 | 8 |

Counted from this team's logs; see `prompt_counts_per_file.csv` at the repository root for the rule applied to each log.

## Files

| Folder | DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|---|
| `ai_logs/` | 3 | 2 | 2 | 3 |
| `rtl/` | 2 | 1 | 1 | 2 |
| `testbench/` | 4 |  |  | 3 |
| `reports/` | 18 | 18 | 18 | 18 |
| `layout/` | 1 | 1 | 1 | 2 |
| `config/` | 1 |  |  |  |
| `docs/` | 6 | 6 | 8 | 3 |
| `other/` | 2 | 1 | 1 | 1 |

| Folder | Contents |
|---|---|
| `ai_logs/` | LLM prompt logs and chat exports |
| `rtl/` | design RTL (Verilog / SystemVerilog) |
| `testbench/` | testbenches: Verilog, cocotb (Python), Verilator (C++) |
| `reports/` | synthesis, timing, power, area, DRC/LVS and tool logs |
| `layout/` | physical design files: GDS, DEF, LEF, MAG, SPEF, SDF |
| `config/` | constraints (SDC/XDC), flow configuration, Makefiles, build and helper scripts |
| `docs/` | READMEs, design notes, security and PPA write-ups |
| `other/` | anything else (waveforms, misc.) |

`file_map.csv` maps every file here to its path in the team's original submission.
