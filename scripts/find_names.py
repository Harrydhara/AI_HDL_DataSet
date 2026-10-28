"""List personal-identifier candidates (names, emails, user paths, GitHub handles) in the team submissions.

Output is a review sheet; nothing is changed. Usage: python find_names.py <out.csv>
"""
import os, re, sys, csv, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from teams import TEAMS
from textio import read_text

TEXT_EXT = {".md", ".txt", ".v", ".sv", ".py", ".c", ".h", ".cpp", ".json", ".yaml", ".yml", ".tcl", ".sh",
            ".cfg", ".pdf", ".docx", ".log", ".rpt", ".csv", ".mk", ".sdc", ".ys", ".toml", ".html", ".tex"}
PATTERNS = {
    "email": re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+"),
    "home_path": re.compile(r"(?:/home/|/Users/|C:\\\\?Users\\\\?|/mnt/c/Users/)([A-Za-z0-9._-]+)", re.I),
    "github_user": re.compile(r"github\.com/([A-Za-z0-9-]+)", re.I),
    "member_line": re.compile(r"(?im)^(?:[-*|]\s*|\d+\.\s*)?\**\s*(?:team\s*members?|members?|authors?|author|name|student|contributors?|team\s*lead(?:er)?|prepared\s*by|submitted\s*by)\s*\**\s*[:|-]\s*\**\s*(.{3,160})$"),
    "speaker": re.compile(r"^\*\*([A-Z][^*\[\n]{1,30}?)\s*\[[^\]\n]{1,6}\]:\*\*", re.M),
    "copyright": re.compile(r"(?i)(?:copyright|\(c\)|©)\s*(?:20\d\d)?[ ,]*([A-Z][A-Za-z.\- ]{2,40})"),
    "spdx_author": re.compile(r"(?i)//\s*(?:author|engineer|designer)\s*:\s*(.{2,60})"),
}

hits = collections.Counter()
where = {}
for team, roots in TEAMS.items():
    for ph, r in roots:
        for dp, dn, fn in os.walk(r):
            if re.search(r"[\\/]\.git([\\/]|$)", dp):
                continue
            for f in fn:
                full = os.path.join(dp, f)
                rel = os.path.relpath(full, r)
                # names in file paths
                for m in re.finditer(r"([A-Z][a-z]+)[ _]([A-Z][a-z]+)", rel):
                    k = (team, "path_name", m.group(0))
                    hits[k] += 1; where.setdefault(k, rel)
                if os.path.splitext(f)[1].lower() not in TEXT_EXT or os.path.getsize(full) > 8_000_000:
                    continue
                try:
                    t = read_text(full)
                except Exception:
                    continue
                for kind, rx in PATTERNS.items():
                    for m in rx.finditer(t):
                        v = (m.group(1) if rx.groups else m.group(0)).strip()[:160]
                        k = (team, kind, v)
                        hits[k] += 1; where.setdefault(k, rel)

with open(sys.argv[1], "w", newline="", encoding="utf8") as fh:
    w = csv.writer(fh)
    w.writerow(["team", "kind", "value", "occurrences", "example_file"])
    for (team, kind, v), n in sorted(hits.items(), key=lambda x: (x[0][0], x[0][1], -x[1])):
        w.writerow([team, kind, v, n, where[(team, kind, v)]])
print(len(hits), "candidates")
