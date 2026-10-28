# AI-HDL 2026 Dataset

**Human–LLM hardware design trajectories from natural-language prompts to signed-off SKY130 layout.**

This dataset accompanies the paper *"AI-HDL: A Human–LLM Hardware Design Dataset"* (submitted to ACM TODAES, Special Issue on Open, Reliable, and Generalizable Datasets for AI in EDA).

This is an initial release covering the first two competition cycles. It does not define a benchmark or report model baselines, since only five teams have complete trajectories. The competition is continuing, and later cycles will be added under the same layout.

In the AI Hardware Design League 2026, every team had to generate its hardware by prompting a large language model (LLM). Each team extended a common RISC-V core (TinyQV) with its own peripheral and carried it through four gated design phases:

| Phase | Focus | What the team submitted |
|---|---|---|
| DP1 | Functional RTL | Peripheral RTL, testbenches, baseline synthesis, prompt log |
| DP2 | PPA optimization | Revised RTL, timing / power / area reports, prompt log |
| DP3 | Security hardening | Hardened RTL, security evaluation, prompt log |
| DP4 | Physical design | OpenLane configuration, GDSII / DEF, DRC / LVS and sign-off reports, prompt log |

This release contains the submissions of **20 of the 22 second-cycle (2026) finalist teams** plus one non-finalist team. It also contains the code and prompt logs of **11 teams from the 2025 pilot cycle** (`pilot_2025/`). Everything is anonymized as described below.

## Contents

```
teams/
  01_NeCRL/                  <final-leaderboard rank>_<team name>  (nf_ = not on the leaderboard)
    README.md                team card: institution, phases, prompt counts, what is in each folder
    file_map.csv             every released file -> its path in the team's original submission
    DP1/ DP2/ DP3/ DP4/      one folder per design phase
      ai_logs/               LLM prompt logs and chat exports
      rtl/                   design RTL
      testbench/             testbenches (Verilog, cocotb, Verilator C++)
      netlists/              synthesized gate-level netlists
      reports/               synthesis / timing / power / area / DRC / LVS reports and tool logs
      layout/                GDS, DEF, LEF, MAG, SPEF, SDF
      openlane_runs/<run>/   complete OpenLane run folders (internal structure kept)
      firmware/              C software for the RISC-V core
      config/                constraints, flow configuration, Makefiles, scripts
      docs/                  READMEs, design notes, security and PPA write-ups
      other/                 waveforms and anything else
    common/                  files whose design phase could not be determined (same sub-folders)
pilot_2025/
  teams/<division>_<team>/   2025 pilot submissions, same sub-folders without phase folders
  index.csv                  one row per pilot team: division, prompt and code counts, notes
  prompt_counts_per_file.csv every pilot prompt log, the counting rule used, its count and released path
index.csv                    one row per team: rank, institution, country, phases, prompt and artifact counts
prompt_counts.csv            logged prompts per team and phase (distinct, curated and raw)
prompt_counts_per_file.csv   every prompt log: phase, counting rule, count, and released path
artifact_stats.csv           RTL files and lines, testbenches, netlists, reports, GDS/DEF per team
scripts/                     counting, statistics, anonymization, build and layout scripts
DATASHEET.md                 datasheet for this dataset
LICENSE                      CC BY-NC 4.0
```

**Where to start:**
- **One team:** open its `README.md`.
- **All the prompt logs:** look in `*/ai_logs/`, or use `prompt_counts_per_file.csv`, which lists every log with its released path.

**Finding the original location.** Teams organized their repositories in many different ways, so files are regrouped by type within each phase. `file_map.csv` in each team folder gives every file's original location in the team's submission.

**Duplicate names.** When two files in the same folder would share a name, the original parent folder is added as a prefix (`Rank1__chatlog.md`). Successive versions of the same file from cumulative submissions are numbered (`debugging.md`, `debugging_v2.md`).

## Summary statistics (20 finalist teams)

| Artifact | Count |
|---|---|
| Unique files (before release filtering) | 2,883 |
| Team-authored RTL files (incl. revisions) | 392 |
| Non-comment lines of RTL | 49,007 |
| Testbench files (Verilog, C++, cocotb) | 371 |
| Gate-level netlists | 32 |
| Tool reports and logs | 500 |
| GDSII files (teams) / DEF files | 17 (9) / 13 |
| Teams with countable prompt logs | 16 |
| Distinct prompts (each counted once, in its first phase) | 495 |
| Entries in curated logs | 534 |
| User turns in raw chat exports | 1,136 |
| Teams with prompt logs in all four phases and a DP4 layout | 5 |

The participation figures reported for the competition (776 registered participants, 148 teams) describe the competition, not this release. See `index.csv` for each team's coverage by phase. Only five teams have complete trajectories: ITIMS' Boys, ElectroNova, Maestro, Farmceries and Bell Labs.

**Prompt counts.** Each team's curated log is counted (raw chat exports only where a phase has no curated log). A prompt repeated in a later, cumulative copy of a log is counted only in the earliest phase it appears. Counts describe what teams chose to record; they are not a measure of effort.

**Corrections (October 2026).** Checking every counted prompt against the released text found entries that are not prompts: Devrem's DP3 prompt-plan file, which repeats the prompts recorded in the team's log and includes a flow diagram; four DP4 entries in Devrem's log that record generated files rather than prompts; an empty template entry (Maestro, DP4); a template placeholder (Obsidian Order, DP1); and a note (ICLab_HUST2, DP3). `scripts/recount.py` lists each one, removes it and recomputes `prompt_counts.csv` from the released logs. The earlier totals were 529 distinct prompts, 568 curated entries and 1,169 raw user turns.

**Prompt text and markers.** `scripts/extract_prompts.py` extracts the text of every counted prompt from the released logs, using the same prompt boundaries as the counts. `scripts/prompt_markers.py` holds the keyword markers (repeated error, frustration, urgency, confusion, conceptual question, redirecting the model, thanks, pasted tool output) used in the paper's descriptive analysis of where designers got stuck, and `scripts/make_fig_struggle.py` draws its figure. The markers are matched against the participant's own words, not pasted logs; they describe the text, not emotion or effort.

## 2025 pilot cycle

The pilot cycle (October 2024 – March 2025) asked teams to use LLMs to design a digital watch (clock, alarm, stopwatch, time-zone conversion, 12/24-hour display) for a Basys-3 FPGA. Later phases added power / area optimization and a security feature such as PIN authentication. `pilot_2025/` holds the code and prompt logs of 11 teams (4 graduate, 7 undergraduate):

| Artifact | Count |
|---|---|
| RTL files / non-comment lines | 92 / 5,738 |
| Testbench files | 12 |
| FPGA constraint files (.xdc) | 6 |
| Teams with countable prompt logs | 8 |
| Prompts counted | 309 |

Notes on the pilot data:
- **Duplicate code:** UET1 and UET3 submitted byte-identical RTL.
- **Uncountable logs:** some prompt logs survive only as ChatGPT share links (removed for privacy), as screenshots, or as an image-only PDF. These are listed in `pilot_2025/index.csv` and are not counted.
- **CC-1's raw logs:** one team's (CC-1) raw ChatGPT exports account for most of the counted pilot prompts.

## How the release was prepared

- **De-duplication.** Many teams resubmitted their whole repository at every phase. Identical files are stored once per team, in the earliest phase where they appear. Several versions of an edited file are all kept, in the phases where they were submitted.
- **Template removal.** Files that are byte-identical in three or more teams' submissions are left out. These are 104 RTL files plus build and documentation files from the shared TinyQV / RISC-V template, available at https://github.com/TinyTapeout/ttsky25a-tinyQV.
- **Anonymization.**
  - Student and mentor names are replaced with per-team pseudonyms (`Member A`, `Member B`, …, `[mentor]`). This covers file contents, file names and chat speaker labels.
  - Personal email addresses are replaced with `[email]`, and personal GitHub, LinkedIn and home-directory user names with `[user]`. Paths such as `/home/<name>/` become `/home/user/`, and shell prompts such as `name@laptop:~` become `user@host:~`.
  - Links to shared chats (ChatGPT, Claude, Gemini) are replaced with `[shared-chat link removed]`.
  - Team names, institutions and countries are kept because they appear on the public leaderboard.
  - Names and emails of third-party open-source authors in the template and tool files are kept.
- **Prompt logs in PDF or Word** are converted to anonymized Markdown text.
- **Left out:** other binary documents (design-report PDFs, Word files, slides, screenshots and images), archives, and waveform dumps. Names cannot be reliably removed from them. Text files over 20 MB are also left out.
- **Layouts:** GDSII, DEF and LEF files are kept unchanged.

`scripts/build_release.py` rebuilds this folder from the original submissions. `scripts/anon_rules.py` holds the anonymization rules.

## Known gaps

- **Missing finalists:** the submissions of two finalist teams (Wilcads, VisionForge) are not included.
- **Missing layouts:** all 22 finalists passed the DP4 gate, but DP4 layout files are present for only 9 of the 20 released finalists.
- **Missing or partial logs:**
  - Team team's folder contains DP1 code only.
  - TechGenius, Astral Coders and Circuitrix submitted empty prompt-log files.
  - HUST1 and Acona Tech prompt logs cover one phase only. Acona Tech's DP1–DP2 logs, and several pilot logs, were submitted only as links to shared Claude, Gemini or ChatGPT chats; those links were removed for privacy.
- **Mixed log formats:** the competition template, prompt summaries, and raw Cursor, Copilot, Gemini, Claude Code and Antigravity exports. Prompt counts therefore depend on how each team condensed its sessions. See `prompt_counts_per_file.csv` for the rule applied to each file.
- **Logs written by the model:** some logs were written or maintained by the LLM at the team's request. ElectroNova's DP3 summary is in the model's first person ("My Response"); Bell Labs asked the model to keep `dp3_prompts.txt` and `dp4_prompts.txt` up to date; NeCRL's Rank 6 log was copied out by the model; Devrem's log was appended by the agent. Wording in such logs may not be the participants' own.
- **Languages:** most logs are in English; seven DP4 prompts of ICLab_HUST2 are in Vietnamese.
- **Taped-out designs:** the two reference designs (NeCRL AES-128 and ITIMS' Boys SPI + CRC-16) were submitted for fabrication on SKY130. Silicon measurements will be added when the parts return. All power figures in the teams' reports are vectorless OpenSTA estimates, not measurements. The ITIMS' Boys write-up lists its power with a µW unit, but the underlying reports are in mW.

## License

Released under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0). Files derived from the TinyQV template and the open-source tools keep their original licenses.

## Citation

```
@article{aihdl2026dataset,
  title   = {{AI-HDL}: A Human--{LLM} Hardware Design Dataset},
  journal = {ACM Transactions on Design Automation of Electronic Systems (submitted)},
  year    = {2026}
}
```

## Contact

To report an error or residual personal data, open an issue at https://github.com/prismlabarizona/AI-HDL_Dataset_2025-2026/issues.
