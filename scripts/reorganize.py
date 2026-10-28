"""Rearrange a built release into a uniform, human-readable layout.

usage: python reorganize.py <built_release_dir> <out_dir>

AI-HDL_2026/teams/<rank>_<team>/<phase>/<category>/<file>
AI-HDL_2025_pilot/teams/<division>_<team>/<category>/<file>
Each cycle folder also holds that cycle's tables (index.csv, prompt counts, artifact counts);
README.md, DATASHEET.md, LICENSE and scripts/ stay at the top level.

Categories: ai_logs, rtl, testbench, netlists, reports, layout, openlane_runs, config, docs, other.
Files are flattened into their category folder; when two files would share a name, the
nearest parent folder names are prefixed (parent__file). OpenLane run folders (RUN_*) keep
their internal structure under openlane_runs/. Each team folder gets README.md (team card)
and file_map.csv (released path -> path in the team's original submission).
"""
import os, re, sys, csv, shutil, collections

IN, OUT = sys.argv[1], sys.argv[2]
LP = (lambda p: "\\\\?\\" + os.path.realpath(p)) if os.name == "nt" else (lambda p: p)
IN, OUT = LP(IN), LP(OUT)
C26, C25 = "AI-HDL_2026", "AI-HDL_2025_pilot"        # one output folder per competition cycle
CYCLE_TABLES = {"index.csv", "prompt_counts.csv", "prompt_counts_per_file.csv", "artifact_stats.csv", "build_report.json"}

CATS = ["ai_logs", "rtl", "testbench", "netlists", "reports", "layout", "openlane_runs", "firmware", "config", "docs", "other"]
SKIP_FILES = {".gitignore", ".gitkeep", ".gitattributes", ".ds_store", ".keep", "keep"}
CAT_DESC = {
    "ai_logs": "LLM prompt logs and chat exports",
    "rtl": "design RTL (Verilog / SystemVerilog)",
    "testbench": "testbenches: Verilog, cocotb (Python), Verilator (C++)",
    "netlists": "synthesized gate-level netlists",
    "reports": "synthesis, timing, power, area, DRC/LVS and tool logs",
    "layout": "physical design files: GDS, DEF, LEF, MAG, SPEF, SDF",
    "openlane_runs": "complete OpenLane run folders, internal structure kept",
    "firmware": "C / assembly software for the RISC-V core (drivers, demos)",
    "config": "constraints (SDC/XDC), flow configuration, Makefiles, build and helper scripts",
    "docs": "READMEs, design notes, security and PPA write-ups",
    "other": "anything else (waveforms, misc.)",
}
LOGPAT = re.compile(r"(prompt|chat|ai[_ -]?logs?\b|ai[_ -]?log|llm|conversation|transcript|promt|rawlog|raw_logs|ai helper|"
                    r"ai response|ai prompts|ai_interaction)", re.I)
HDL = {".v", ".sv", ".vh", ".svh", ".vhd", ".vhdl"}
LAYOUT = {".gds", ".gdsii", ".oas", ".def", ".lef", ".mag", ".maglef", ".spef", ".sdf", ".odb"}
CONFIG = {".sdc", ".xdc", ".tcl", ".ys", ".sh", ".mk", ".yaml", ".yml", ".cfg", ".toml", ".ini", ".f", ".lst", ".bat",
          ".ps1", ".gtkw", ".lds", ".ld"}
DOCS = {".md", ".txt", ".rst", ".html", ".htm", ".tex", ".adoc"}
TB_DIR = re.compile(r"(^|/)(tests?|tb|testbench(es)?|sim|sim_1|simulation[^/]*|verif(ication)?|cocotb|test_harness)(/|$)", re.I)
TB_NAME = re.compile(r"(^tb[_.\-]|_tb[_.\-]|_tb$|^test[_.\-]|testbench|_test\.|^bench)", re.I)
NETLIST = re.compile(r"(synth|netlist|_syn\b|\.nl\.|gl\.v|powered|\.pnl|mapped|_gl\b|_post)", re.I)
REPORT = re.compile(r"(report|timing|power|area|\bsta\b|metric|summary|util|drc|lvs|antenna|slack|stat|qor|yosys.*log|"
                    r"synth.*\.(txt|log)|results?\.(txt|json|csv))", re.I)
RUN_SEG = re.compile(r"^(RUN_[\w.\-]+|run_\d[\w.\-]*)$", re.I)


def real_ext(name):
    n = name.lower()
    if n.endswith(".gz") or n.endswith(".xz"):
        n = n[:-3]
    return os.path.splitext(n)[1]


def classify(rel):
    """rel: path inside the phase folder, '/' separated. Returns (category, run_subpath or None)."""
    parts = rel.split("/")
    base = parts[-1]
    low = rel.lower()
    ext = real_ext(base)
    for i, p in enumerate(parts[:-1]):
        if RUN_SEG.match(p):
            sub = parts[i:]
            while len(sub) > 2 and sub[0].lower() == sub[1].lower():   # RUN_x/RUN_x/... from re-zipped runs
                sub = sub[1:]
            return "openlane_runs", "/".join(sub)
        if p.lower() == "runs" and i + 1 < len(parts) - 1:          # OpenLane runs/<tag>/...
            return "openlane_runs", "/".join(parts[i + 1:])
    if ext in HDL:
        if NETLIST.search(base):
            return "netlists", None
        if TB_NAME.search(base) or TB_DIR.search("/".join(parts[:-1])):
            return "testbench", None
        return "rtl", None
    if ext in LAYOUT:
        return "layout", None
    if LOGPAT.search(low) and ext in DOCS | {".json", ".jsonl", ".log", ".csv", ""}:
        return "ai_logs", None
    if ext in (".py", ".cpp", ".cc", ".c", ".h", ".hpp") and (TB_NAME.search(base) or TB_DIR.search(low) or "cocotb" in low
                                                             or "verilator" in low):
        return "testbench", None
    if ext in (".rpt", ".log", ".stat", ".warnings", ".xml") or base.lower().endswith((".log.txt", ".rpt.txt")) or \
            (ext in {".txt", ".json", ".csv", ".html", ""} and REPORT.search(base)):
        return "reports", None
    if ext in (".c", ".h", ".s", ".S".lower(), ".ld", ".lds"):
        return "firmware", None
    if ext in CONFIG or ext == ".py" or base.lower() in ("makefile", "config.json", "info.yaml", "requirements.txt", "dockerfile") \
            or base.lower().startswith("makefile") or (ext == ".json" and "config" in base.lower()):
        return "config", None
    if ext in DOCS:
        return "docs", None
    if ext in {".vcd", ".fst", ".vvp", ".out"}:
        return "other", None
    return "other", None


def _clashes(names):
    groups = collections.defaultdict(list)
    for i, n in names.items():
        groups[n.lower()].append(i)
    return [g for g in groups.values() if len(g) > 1]


def flatten(items):
    """items: list of src_rel_parts -> unique target names.

    Colliding names whose parent folders differ get that parent as prefix (Rank1__chatlog.md);
    files that still collide (typically the same file from two cumulative snapshots) get
    _v2, _v3, ... in the order of their original path."""
    names = {i: parts[-1] for i, parts in enumerate(items)}
    for g in _clashes(names):
        parents = {(items[i][-2] if len(items[i]) > 1 else "").lower() for i in g}
        if len(parents) > 1:
            for i in g:
                if len(items[i]) > 1:
                    names[i] = items[i][-2] + "__" + items[i][-1]
    for g in _clashes(names):
        g.sort(key=lambda i: "/".join(items[i]).lower())
        for k, i in enumerate(g[1:], start=2):
            stem, ext = os.path.splitext(names[i])
            if ext.lower() in (".gz", ".xz"):
                stem, ext2 = os.path.splitext(stem)
                ext = ext2 + ext
            names[i] = f"{stem}_v{k}{ext}"
    return names


def walk(root):
    for dp, dn, fn in os.walk(root):
        for f in fn:
            full = os.path.join(dp, f)
            yield full, os.path.relpath(full, root).replace("\\", "/")


def arrange(src_team, dst_team, phased):
    """Returns file map rows and per-(phase,category) counts."""
    buckets = collections.defaultdict(list)       # (phase, cat) -> [(full, parts)]
    runs = []                                     # (full, phase, run_subpath, rel)
    for full, rel in walk(src_team):
        if os.path.basename(rel).lower() in SKIP_FILES or os.path.basename(rel).startswith("._") \
                or "__macosx" in rel.lower().split("/"):
            continue                                  # git housekeeping and macOS metadata
        if phased:
            phase, inner = rel.split("/", 1) if "/" in rel else ("common", rel)
        else:
            phase, inner = "", rel
        cat, run = classify(inner)
        if cat == "openlane_runs":
            runs.append((full, phase, run, rel))
        else:
            buckets[(phase, cat)].append((full, inner.split("/"), rel))
    rows, counts = [], collections.Counter()
    for (phase, cat), lst in buckets.items():
        names = flatten([parts for _, parts, _ in lst])
        for i, (full, parts, rel) in enumerate(lst):
            new = "/".join(x for x in (phase, cat, names[i]) if x)
            dst = os.path.join(dst_team, *new.split("/"))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copyfile(full, dst)
            rows.append((new, rel, cat))
            counts[(phase, cat)] += 1
    # one folder per distinct run; the same run tag from two snapshots becomes tag, tag_2, ...
    run_names = {}
    used = collections.defaultdict(set)
    for full, phase, run, rel in sorted(runs, key=lambda x: x[3].lower()):
        tag = run.split("/", 1)[0]
        origin = rel[: rel.lower().rfind(run.lower())]          # path above the run folder
        key = (phase, origin.lower(), tag.lower())
        if key not in run_names:
            name, k = tag, 2
            while name.lower() in used[phase]:
                name, k = f"{tag}_{k}", k + 1
            used[phase].add(name.lower())
            run_names[key] = name
    for full, phase, run, rel in runs:
        tag = run.split("/", 1)[0]
        origin = rel[: rel.lower().rfind(run.lower())]
        run = run_names[(phase, origin.lower(), tag.lower())] + run[len(tag):]
        new = "/".join(x for x in (phase, "openlane_runs", run) if x)
        dst = os.path.join(dst_team, *new.split("/"))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copyfile(full, dst)
        rows.append((new, rel, "openlane_runs"))
        counts[(phase, "openlane_runs")] += 1
    rows.sort()
    with open(os.path.join(dst_team, "file_map.csv"), "w", newline="", encoding="utf8") as fh:
        w = csv.writer(fh)
        w.writerow(["released_path", "path_in_original_submission", "category"])
        for new, rel, cat in rows:
            orig = rel.split("/", 1)[1] if phased and "/" in rel else rel
            w.writerow([new, orig, cat])
    return rows, counts


def team_card(dst_team, title, meta, counts, phased, prompts, cycle_dir):
    phases = sorted({p for p, _ in counts}, key=lambda p: (p == "common", p))
    used = [c for c in CATS if any(counts[(p, c)] for p in phases)]
    L = [f"# {title}", ""]
    for k, v in meta:
        if v:
            L.append(f"- **{k}:** {v}")
    L.append("")
    if prompts:
        L += ["## Distinct logged prompts", "", "| " + " | ".join(prompts[0]) + " |", "|" + "---|" * len(prompts[0]),
              "| " + " | ".join(str(x) for x in prompts[1]) + " |", "",
              "Counted from this team's logs; a prompt repeated in a later, cumulative log is counted once, in its first phase. "
              f"See `prompt_counts_per_file.csv` in the `{cycle_dir}` folder for the rule applied to each log. "
              "Counts describe what was logged, not effort.", ""]
    L += ["## Files", ""]
    if phased:
        L.append("| Folder | " + " | ".join(phases) + " |")
        L.append("|---|" + "---|" * len(phases))
        for c in used:
            L.append(f"| `{c}/` | " + " | ".join(str(counts[(p, c)] or "") for p in phases) + " |")
    else:
        L += ["| Folder | Files |", "|---|---|"] + [f"| `{c}/` | {counts[('', c)]} |" for c in used]
    L += ["", "| Folder | Contents |", "|---|---|"] + [f"| `{c}/` | {CAT_DESC[c]} |" for c in used]
    if phased and "common" in phases:
        L += ["", "`common/` holds files whose design phase could not be determined from the submission."]
    L += ["", "`file_map.csv` maps every file here to its path in the team's original submission.", ""]
    open(os.path.join(dst_team, "README.md"), "w", encoding="utf8").write("\n".join(L))


def read_csv(path):
    return list(csv.DictReader(open(path, encoding="utf8"))) if os.path.exists(path) else []


# ---------------------------------------------------------------------------
if os.path.exists(OUT):
    shutil.rmtree(OUT)
os.makedirs(os.path.join(OUT, C26))
for f in os.listdir(IN):
    if f in ("teams", "pilot_2025", ".git"):
        continue
    s = os.path.join(IN, f)
    dst = os.path.join(OUT, C26, f) if f in CYCLE_TABLES else os.path.join(OUT, f)
    (shutil.copytree if os.path.isdir(s) else shutil.copyfile)(s, dst)

index = {r["folder"]: r for r in read_csv(os.path.join(IN, "index.csv"))}
allmap = {}
for team in sorted(os.listdir(os.path.join(IN, "teams"))):
    r = index.get(team, {})
    rows, counts = arrange(os.path.join(IN, "teams", team), os.path.join(OUT, C26, "teams", team), True)
    allmap[("2026", team)] = rows
    meta = [("Cycle", "2026 (second cycle)"), ("Final leaderboard rank", r.get("final_rank") or "not on the final leaderboard"),
            ("Institution", r.get("institution")), ("Country", r.get("country")),
            ("Phases with files", (r.get("phases_with_files") or "").replace(";", ", ")),
            ("Phases with prompt logs", (r.get("phases_with_prompt_logs") or "none found").replace(";", ", ")),
            ("Taped out", r.get("taped_out"))]
    pr = (["DP1", "DP2", "DP3", "DP4"], [r.get(f"distinct_prompts_DP{i}", "") for i in range(1, 5)]) if r else None
    team_card(os.path.join(OUT, C26, "teams", team), r.get("team", team), meta, counts, True, pr, C26)

pidx = {r["folder"]: r for r in read_csv(os.path.join(IN, "pilot_2025", "index.csv"))}
os.makedirs(os.path.join(OUT, C25), exist_ok=True)
for f in os.listdir(os.path.join(IN, "pilot_2025")):
    if f != "teams":
        shutil.copyfile(os.path.join(IN, "pilot_2025", f), os.path.join(OUT, C25, f))
for team in sorted(os.listdir(os.path.join(IN, "pilot_2025", "teams"))):
    r = pidx.get(team, {})
    rows, counts = arrange(os.path.join(IN, "pilot_2025", "teams", team), os.path.join(OUT, C25, "teams", team), False)
    allmap[("2025", team)] = rows
    meta = [("Cycle", "2025 pilot (digital watch on a Basys-3 FPGA)"), ("Division", r.get("division")), ("Notes", r.get("notes"))]
    pr = (["Prompts counted", "Countable logs"], [r.get("prompts_counted", ""), r.get("countable_logs", "")]) if r else None
    team_card(os.path.join(OUT, C25, "teams", team), r.get("team", team), meta, counts, False, pr, C25)


# add the released path to the per-file prompt-count tables
def add_released(path, cycle, team_of):
    rows = read_csv(path)
    if not rows:
        return
    lookup = {}
    for (cyc, team), mp in allmap.items():
        if cyc != cycle:
            continue
        for new, rel, cat in mp:
            inner = rel.split("/", 1)[1] if cycle == "2026" and "/" in rel else rel
            lookup[(team, inner.lower())] = f"{C25 if cycle == '2025' else C26}/teams/{team}/{new}"
    out_rows = []
    for row in rows:
        folder = team_of(row["team"])
        rel = row["file"].replace("\\", "/")
        rel = "/".join(p.rstrip(" .") or "_" for p in rel.split("/"))
        if rel.lower().endswith((".pdf", ".docx")):
            rel = os.path.splitext(rel)[0] + ".md"
        row["released_path"] = lookup.get((folder, rel.lower()), "")
        if not row["released_path"]:            # gzipped or otherwise renamed
            row["released_path"] = lookup.get((folder, (rel + ".gz").lower()), "")
        if not row["released_path"]:
            row["released_path"] = "(empty file, not released)" if str(row.get("prompts", "")) == "0" else "(not released)"
        out_rows.append(row)
    with open(path, "w", newline="", encoding="utf8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(out_rows[0].keys()))
        w.writeheader()
        w.writerows(out_rows)


folder_by_team = {r["team"]: f for f, r in index.items()}
add_released(os.path.join(OUT, C26, "prompt_counts_per_file.csv"), "2026", lambda t: folder_by_team.get(t, ""))
pfolder = {r["team"]: f for f, r in pidx.items()}
add_released(os.path.join(OUT, C25, "prompt_counts_per_file.csv"), "2025", lambda t: pfolder.get(t, ""))

tot = collections.Counter()
for rows in allmap.values():
    for new, rel, cat in rows:
        tot[cat] += 1
print("files by category:", dict(tot.most_common()))
deep = max((len(f"teams/{t}/{n}".split("/")) for (c, t), rows in allmap.items() for n, _, _ in rows), default=0)
print("max depth:", deep)
