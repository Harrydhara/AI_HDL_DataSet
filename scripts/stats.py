"""Artifact statistics per team, after removing shared template files and cumulative-snapshot duplicates."""
import os, re, sys, hashlib, json, collections
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from teams import TEAMS

PH = re.compile(r"(?:challenge|dp|design[ _-]?phase|milestone)[ _#-]*([1-4])(?![0-9])", re.I)
RTL = (".v", ".sv", ".vh", ".svh")
IS_TB = re.compile(r"(^|[\\/_])(tb|test|testbench|bench|sim)[\\/_.]|_tb\.|tb_|test_|testbench|harness", re.I)
IS_REPORT = re.compile(r"\.(rpt|log)$|report|timing|power|area|sta|metrics|summary\.csv|\.sdf$", re.I)
SKIP_DIRS = re.compile(r"[\\/](\.git|node_modules|__pycache__|venv|\.venv|runs[\\/][^\\/]+[\\/]tmp)([\\/]|$)", re.I)

here = os.path.dirname(os.path.realpath(__file__))
LEADER = {"NeCRL": 1, "ITIMS Boys": 2, "ElectroNova": 3, "Devrem": 4, "Maestro": 5, "Team team": 6, "Acona Tech": 7,
          "ICLab_HUST2": 8, "HUST1": 9, "Farmceries": 11, "Obsidian Order": 12, "Team Circuitrix": 13,
          "UCC Eng. Physics": 14, "Techgenius": 15, "Astral Coders": 16, "HUSD": 18, "BellLabs": 19,
          "ICLab_HUST": 20, "BIG-4": 21, "Team Ingenius": 22}

# pass 1: hash -> set of teams (to find shared template files)
files = collections.defaultdict(list)   # team -> [(phase, rel, full, hash, size)]
owners = collections.defaultdict(set)
for team, roots in TEAMS.items():
    for ph, r in roots:
        for dp, dn, fn in os.walk(r):
            if SKIP_DIRS.search(dp):
                continue
            for f in fn:
                full = os.path.join(dp, f)
                rel = os.path.relpath(full, r)
                try:
                    data = open(full, "rb").read()
                except OSError:
                    continue
                h = hashlib.md5(data).hexdigest()
                m = PH.findall(rel)
                files[team].append(("DP" + m[-1] if m else (ph or "DP?"), rel, full, h, len(data)))
                owners[h].add(team)

template = {h for h, t in owners.items() if len(t) >= 3}

out = {}
for team in TEAMS:
    seen = set()
    c = collections.Counter()
    phases_rtl = set()
    for ph, rel, full, h, size in files[team]:
        if h in seen:
            continue
        seen.add(h)
        ext = os.path.splitext(rel)[1].lower()
        if ext in RTL:
            if h in template:
                c["rtl_template"] += 1
                continue
            text = open(full, "rb").read().decode("utf8", "replace")
            loc = sum(1 for l in text.splitlines() if l.strip() and not l.strip().startswith("//"))
            if IS_TB.search(rel):
                c["tb_files"] += 1
            elif re.search(r"(synth|netlist|_syn|\.nl\.|gl\.v|powered|pnl)", rel, re.I) or loc > 20000:
                c["netlists"] += 1
            else:
                c["rtl_files"] += 1
                c["rtl_loc"] += loc
                phases_rtl.add(ph)
        elif ext in (".cpp", ".cc", ".py") and IS_TB.search(rel):
            c["tb_files"] += 1
        elif ext in (".gds", ".gz", ".xz") and ".gds" in rel.lower():
            c["gds"] += 1
        elif ext in (".def",) or rel.lower().endswith(".def.gz"):
            c["def"] += 1
        elif ext in (".rpt", ".log", ".txt", ".csv", ".json") and IS_REPORT.search(os.path.basename(rel)) and \
                not re.search(r"prompt|chat|ai_log|conversation", rel, re.I):
            c["reports"] += 1
        c["files"] += 1
    c["rtl_phases"] = len(phases_rtl - {"DP?"})
    out[team] = dict(c)

json.dump(out, open(os.path.join(here, "artifact_stats.json"), "w"), indent=1)
cols = ["files", "rtl_files", "rtl_loc", "tb_files", "netlists", "reports", "gds", "def", "rtl_template"]
print(f"{'team':16s} {'rank':>4s} " + " ".join(f"{k:>10s}" for k in cols))
for team in sorted(TEAMS, key=lambda t: LEADER.get(t, 99)):
    print(f"{team:16s} {LEADER.get(team, '-'):>4} " + " ".join(f"{out[team].get(k, 0):10d}" for k in cols))
print(f"template RTL hashes shared by >=3 teams: {sum(1 for h in template)}")
