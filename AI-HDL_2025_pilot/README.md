# AI-HDL 2025 pilot cycle

Code and prompt logs of 11 teams (4 graduate, 7 undergraduate) from the pilot cycle of the AI Hardware Design League, October 2024 to March 2025. Teams used LLMs to design a digital watch (clock, alarm, stopwatch, time-zone conversion, 12/24-hour display) for a Basys-3 FPGA, then revised it for power, area and a security feature such as PIN authentication. The pilot has no physical-design files.

| File or folder | Contents |
|---|---|
| `teams/` | one folder per team, named `<division>_<team>`, with a team card (`README.md`), `file_map.csv`, and the same category folders as the 2026 teams but no phase folders |
| `index.csv` | one row per team: division, prompt and code counts, notes |
| `prompt_counts_per_file.csv` | every prompt log, the counting rule used, its count and released path |

309 prompts are counted, from 8 teams. Some logs survive only as removed share links, screenshots or an image-only PDF; they are listed in `index.csv` and not counted. See the [top-level README](../README.md) for details.
