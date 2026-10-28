# CC-1

- **Cycle:** 2025 pilot (digital watch on a Basys-3 FPGA)
- **Division:** undergraduate
- **Notes:** Claude/Gemini/Grok logs are whole-page captures; turns not counted

## Distinct logged prompts

| Prompts counted | Countable logs |
|---|---|
| 242 | 8 |

Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. See `prompt_counts_per_file.csv` in the `AI-HDL_2025_pilot` folder for the rule applied to each log. Counts describe what was logged, not effort.

## Files

| Folder | Files |
|---|---|
| `ai_logs/` | 16 |
| `rtl/` | 8 |
| `testbench/` | 1 |
| `reports/` | 1 |
| `config/` | 1 |
| `docs/` | 3 |

| Folder | Contents |
|---|---|
| `ai_logs/` | LLM prompt logs and chat exports |
| `rtl/` | design RTL (Verilog / SystemVerilog) |
| `testbench/` | testbenches: Verilog, cocotb (Python), Verilator (C++) |
| `reports/` | synthesis, timing, power, area, DRC/LVS and tool logs |
| `config/` | constraints (SDC/XDC), flow configuration, Makefiles, build and helper scripts |
| `docs/` | READMEs, design notes, security and PPA write-ups |

`file_map.csv` maps every file here to its path in the team's original submission.
