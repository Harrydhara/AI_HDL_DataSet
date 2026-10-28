# ElectroNova

- **Cycle:** 2026 (second cycle)
- **Final leaderboard rank:** 3
- **Institution:** College of Engineering Trivandrum
- **Country:** India
- **Phases with files:** DP1, DP2, DP3, DP4
- **Phases with prompt logs:** DP1, DP2, DP3, DP4

## Distinct logged prompts

| DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|
| 5 | 40 | 19 | 30 |

Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. See `prompt_counts_per_file.csv` at the repository root for the rule applied to each log. Counts describe what was logged, not effort.

## Files

| Folder | DP1 | DP2 | DP3 | DP4 |
|---|---|---|---|---|
| `ai_logs/` | 3 | 1 | 1 | 1 |
| `rtl/` | 115 | 3 | 4 |  |
| `testbench/` | 66 | 2 | 5 |  |
| `netlists/` | 4 | 1 |  |  |
| `reports/` | 10 | 3 | 1 |  |
| `layout/` | 1 | 2 | 2 |  |
| `openlane_runs/` |  |  |  | 196 |
| `config/` | 23 | 3 |  |  |
| `docs/` | 51 | 3 | 5 | 3 |
| `other/` | 28 |  |  |  |

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
| `other/` | anything else (waveforms, misc.) |

`file_map.csv` maps every file here to its path in the team's original submission.
