"""Recount prompts from the released logs, with the corrections listed below.

count.py counted prompt markers in the original submissions. Checking the counted prompts against
the released text found entries that are not prompts. They are removed here, and the three tables
of prompt_counts.csv are recomputed from the release:
  distinct  curated logs where a phase has one, else raw exports; each prompt counted once,
            in the earliest phase where its opening text appears
  curated   entries in curated logs (raw exports only for a phase with no curated log)
  raw       user turns in raw exports (curated logs only for a phase with no raw export)

Usage: python recount.py          -> prints the tables and the changes against prompt_counts.csv
       python recount.py --write  -> also rewrites prompt_counts.csv
"""
import csv, os, sys, collections
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import extract_prompts as E

DEVREM_PLAN = "teams/04_Devrem/DP3/ai_logs/dp3_claude_code_prompts.md"
DEVREM_LOG = "teams/04_Devrem/common/ai_logs/LLM_PROMPT_LOG.md"

# (released file, phase, prompt indices or None for the whole file, reason)
CORRECTIONS = [
    (DEVREM_PLAN, "DP3", None,
     "a pre-written prompt plan (with placeholders such as <PASTE ... HERE>); the prompts actually run are the 14 "
     "DP3 entries of LLM_PROMPT_LOG.md, and 11 of the 27 matches are lines of a flow diagram"),
    (DEVREM_LOG, "DP4", "(Automated fix", "entry records an automated fix, not a prompt"),
    (DEVREM_LOG, "DP4", "(Generated as part of DP4 preparation)", "entry records generated files, not a prompt"),
    ("teams/05_Maestro/DP4/ai_logs/design_generation4.md", "DP4", [0], "empty template entry"),
    ("teams/12_Obsidian-Order/DP1/ai_logs/prompts_log.md", "DP1", [1], "template placeholder '[exact prompt text]'"),
    ("teams/08_ICLab-HUST2/DP3/ai_logs/security_hardening.md", "DP3", [4],
     "note '(part of same implementation session as CM-1)', not a separate prompt"),
]


def excluded(r):
    for path, ph, sel, _ in CORRECTIONS:
        if r["file"] != path or r["phase"] != ph:
            continue
        if sel is None or (isinstance(sel, list) and r["index"] in sel) or \
           (isinstance(sel, str) and r["text"].lstrip().startswith(sel)):
            return True
    return False


def tables(records):
    recs = [r for r in records if not excluded(r)]
    by = collections.defaultdict(collections.Counter)      # (team, kind) -> phase -> n
    for r in recs:
        by[(r["team"], r["kind"])][r["phase"]] += 1
    teams = sorted({r["team"] for r in records})
    raw, cur, dis = {}, {}, {}
    for t in teams:
        raw[t] = {p: by[(t, "raw")][p] or by[(t, "curated")][p] for p in E.PHASES}
        cur[t] = {p: by[(t, "curated")][p] or by[(t, "raw")][p] for p in E.PHASES}
        dis[t] = collections.Counter(r["phase"] for r in E.distinct([r for r in recs if r["team"] == t]))
    return recs, raw, cur, dis


if __name__ == "__main__":
    records, bad = E.load()
    assert not bad, bad
    recs, raw, cur, dis = tables(records)
    path = os.path.join(E.ROOT, "prompt_counts.csv")
    old = {r["team"]: r for r in csv.DictReader(open(path, encoding="utf8"))}
    fields = list(next(iter(old.values())).keys())
    tot = collections.Counter()
    for t, row in old.items():
        new = dict(row)
        for p in E.PHASES:     # teams with no countable log have no records
            new[f"distinct_{p}"] = dis.get(t, {}).get(p, 0)
            new[f"curated_{p}"] = cur.get(t, {}).get(p, 0)
            new[f"raw_{p}"] = raw.get(t, {}).get(p, 0)
        for k in fields[2:]:
            if str(row[k]) != str(new[k]):
                print(f"{t:16s} {k:14s} {row[k]:>4s} -> {new[k]}")
        if t != "Mercer":
            for p in E.PHASES:
                for k in ("distinct", "curated", "raw"):
                    tot[k] += new[f"{k}_{p}"]
        old[t] = new
    print("finalist totals:", dict(tot))
    for path_, ph, sel, why in CORRECTIONS:
        print(f"  removed: {path_} {ph} {sel if sel else '(whole file)'}: {why}")
    if "--write" in sys.argv:
        with open(path, "w", newline="", encoding="utf8") as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            for t in old:
                w.writerow(old[t])
        print("rewrote", path)
