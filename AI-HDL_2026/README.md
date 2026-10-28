# AI-HDL 2026 (second cycle)

Submissions of 20 of the 22 finalist teams of the 2026 AI Hardware Design League, plus one non-finalist team. Every team extended the TinyQV RISC-V core with its own peripheral and carried it through four design phases, from LLM-prompted RTL to a signed-off SKY130 layout: functional RTL (DP1), PPA optimization (DP2), security hardening (DP3) and physical design (DP4).

| File or folder | Contents |
|---|---|
| `teams/` | one folder per team, named `<final rank>_<team>` (`nf_` = not on the final leaderboard), with a team card (`README.md`), `file_map.csv`, and `DP1/` to `DP4/` and `common/` folders |
| `index.csv` | one row per team: rank, institution, country, phases, prompt and artifact counts |
| `prompt_counts.csv` | logged prompts per team and phase (distinct, curated and raw) |
| `prompt_counts_per_file.csv` | every prompt log: phase, counting rule, count and released path |
| `artifact_stats.csv` | RTL files and lines, testbenches, netlists, reports and GDS/DEF files per team |
| `build_report.json` | files kept per team and type when the release was built |

The prompt logs of 16 finalist teams contain 495 distinct prompts, and five teams have prompt logs for all four phases and a DP4 layout. See the [top-level README](../README.md) for how the data were prepared and for known gaps.
