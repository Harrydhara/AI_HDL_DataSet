"""Assemble the anonymized AI-HDL 2026 release.

usage: python build_release.py <out_dir> [--dry-run]

Layout: teams/<rank>_<team>/<DP1..DP4|common>/<original relative path>
 - files are placed in the phase named by their path (challenge-N, DP-N, ...), else the
   phase folder they were submitted in, else common/
 - identical files are stored once per team (at the earliest phase they appear)
 - files shared byte-for-byte by >= 3 teams (the TinyQV / RISC-V template) are left out
 - text files are anonymized; PDF/Word prompt logs are converted to anonymized .md;
   other binary documents (PDF, Word, slides, images, archives) are left out
"""
import os, re, sys, hashlib, json, collections, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from teams import TEAMS
from textio import read_text, decode_text
import anon_rules

OUT = sys.argv[1]
if os.name == "nt" and not OUT.startswith("\\\\?\\"):
    OUT = "\\\\?\\" + os.path.realpath(OUT)
DRY = "--dry-run" in sys.argv

RANK = {"NeCRL": 1, "ITIMS Boys": 2, "ElectroNova": 3, "Devrem": 4, "Maestro": 5, "Team team": 6, "Acona Tech": 7,
        "ICLab_HUST2": 8, "HUST1": 9, "Farmceries": 11, "Obsidian Order": 12, "Team Circuitrix": 13,
        "UCC Eng. Physics": 14, "Techgenius": 15, "Astral Coders": 16, "HUSD": 18, "BellLabs": 19,
        "ICLab_HUST": 20, "BIG-4": 21, "Team Ingenius": 22}
PH = re.compile(r"(?:challenge|dp|design[ _-]?phase|milestone)[ _#-]*([1-4])(?![0-9])", re.I)
SKIP_DIR = re.compile(r"(^|[\\/])(\.git|\.github|node_modules|__pycache__|\.venv|venv|\.vscode|\.idea|sim_build|obj_dir|tmp)([\\/]|$)", re.I)
LOGPAT = re.compile(r"(prompt|chat|ai[_ -]?log|llm|conversation|transcript|rawlog|promt)", re.I)
KEEP_BINARY = (".gds", ".gds.gz", ".gds.xz", ".def", ".def.gz", ".oas", ".lef")
DROP_EXT = {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".svg", ".webp", ".pdf", ".docx", ".doc", ".pptx", ".ppt", ".xlsx",
            ".xls", ".zip", ".tar", ".gz", ".xz", ".7z", ".mp4", ".mov", ".exe", ".dll", ".so", ".o", ".a", ".bin", ".bit",
            ".fst", ".ghw", ".pyc", ".DS_Store".lower(), ".ico", ".odg", ".drawio"}
MAX_TEXT = 20_000_000

def slug(team):
    return f"{RANK.get(team, 99):02d}_" + re.sub(r"[^A-Za-z0-9]+", "-", team).strip("-") if team in RANK else \
        "nf_" + re.sub(r"[^A-Za-z0-9]+", "-", team).strip("-")

def is_binary(b):
    return b"\x00" in b[:4096]

# pass 1: template hashes
owners = collections.defaultdict(set)
allf = collections.defaultdict(list)
for team, roots in TEAMS.items():
    for ph, r in roots:
        for dp, dn, fn in os.walk(r):
            dn[:] = [d for d in dn if not SKIP_DIR.search(os.path.join(dp, d) + os.sep)]
            for f in fn:
                full = os.path.join(dp, f)
                rel = os.path.relpath(full, r)
                if SKIP_DIR.search(rel):
                    continue
                try:
                    h = hashlib.md5(open(full, "rb").read()).hexdigest()
                except OSError:
                    continue
                allf[team].append((ph, rel, full, h))
                owners[h].add(team)
template = {h for h, t in owners.items() if len(t) >= 3}

summary = collections.defaultdict(collections.Counter)
dropped = collections.Counter()
total_bytes = 0
by_ext = collections.Counter()
biggest = []
for team in TEAMS:
    rules = anon_rules.build(team)
    seen = set()
    files = sorted(allf[team], key=lambda x: (x[0] or "DP0", x[1]))
    for ph, rel, full, h in files:
        if h in seen:
            continue
        seen.add(h)
        low = rel.lower()
        ext = os.path.splitext(low)[1]
        m = PH.findall(rel)
        phase = "DP" + m[-1] if m else (ph or "common")
        if h in template:
            dropped["template"] += 1; continue
        dest_rel = anon_rules.anonymize_name(rel.replace("__unz", ""), rules)
        # Windows and git cannot handle path components that end in a space or dot
        dest_rel = os.sep.join(p.rstrip(" .") or "_" for p in re.split(r"[\\/]", dest_rel))
        data = open(full, "rb").read()
        keep_bin = any(low.endswith(k) for k in KEEP_BINARY)
        if keep_bin:
            out_bytes = data
            summary[team]["layout"] += 1
        elif ext in (".pdf", ".docx") and LOGPAT.search(rel):
            t = read_text(full)
            if not t.strip():
                dropped["unreadable_log"] += 1; continue
            out_bytes = anon_rules.anonymize(t, rules).encode("utf8")
            dest_rel = os.path.splitext(dest_rel)[0] + ".md"
            summary[team]["converted_logs"] += 1
        elif ext in DROP_EXT or is_binary(data):
            dropped["binary_or_document:" + (ext or "noext")] += 1; continue
        elif len(data) > MAX_TEXT:
            dropped["text_over_20MB:" + ext] += 1; continue
        else:
            t = decode_text(data)
            out_bytes = anon_rules.anonymize(t, rules).encode("utf8")
            summary[team]["text"] += 1
        # gzip large generated files (layouts, reports, netlists); keep logs/docs readable
        if len(out_bytes) > 1_000_000 and ext not in (".md",) and not low.endswith((".gz", ".xz")):
            import gzip
            out_bytes = gzip.compress(out_bytes, 9, mtime=0)
            dest_rel += ".gz"
            summary[team]["gzipped"] += 1
        total_bytes += len(out_bytes)
        by_ext[ext] += len(out_bytes)
        biggest.append((len(out_bytes), slug(team), phase, dest_rel))
        if not DRY:
            dst = os.path.join(OUT, "teams", slug(team), phase, dest_rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            open(dst, "wb").write(out_bytes)

print(f"total {total_bytes/1e6:.1f} MB")
print("by extension (MB):", {k: round(v / 1e6, 1) for k, v in by_ext.most_common(15)})
for s, t, p, r in sorted(biggest, reverse=True)[:25]:
    print(f"  {s/1e6:7.1f} MB  {t}/{p}/{r[-90:]}")
for t, c in summary.items():
    print(f"  {slug(t):24s} {dict(c)}")
print("dropped:", dict(sorted(dropped.items(), key=lambda x: -x[1])[:25]))
if not DRY:
    json.dump({"kept": {slug(t): dict(c) for t, c in summary.items()}, "dropped": dict(dropped)},
              open(os.path.join(OUT, "build_report.json"), "w"), indent=1)
