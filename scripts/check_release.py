"""Scan a built release for leftover personal data. usage: check_release.py <release_dir>"""
import os, re, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import anon_rules

R = sys.argv[1]
if os.name == "nt" and not R.startswith("\\\\?\\"):
    R = "\\\\?\\" + os.path.realpath(R)
names = set()
for people in list(anon_rules.PEOPLE.values()) + [anon_rules.STAFF]:
    for spellings in people:
        for s in spellings:
            for v in anon_rules._variants(s):
                names.add(v.lower())
for part in list(names):
    for tok in re.split(r"[ _-]", part):
        if len(tok) >= 5 and tok not in ("member", "abdul", "basit"):
            names.add(tok)          # distinctive single tokens (surnames, given names)
names |= {h.lower() for h in anon_rules.HANDLES}
names |= {n.lower() for d in anon_rules.FIRST_NAMES.values() for n in d}
NAME_RX = re.compile(r"(?<![^\W_])(" + "|".join(re.escape(n) for n in sorted(names, key=len, reverse=True)) + r")(?![^\W_])", re.I)
EMAIL = anon_rules.EMAIL
HOME = re.compile(r"(/home/|/Users/|C:\\\\?Users\\\\?)(?!user\b)([A-Za-z0-9._-]+)", re.I)

hits = collections.Counter()
examples = {}
for dp, dn, fn in os.walk(R):
    for f in fn:
        full = os.path.join(dp, f)
        rel = os.path.relpath(full, R)
        if rel.startswith("scripts") or f in ("DATASHEET.md",):
            continue
        for m in NAME_RX.finditer(rel):
            k = ("name_in_path", m.group(0)); hits[k] += 1; examples.setdefault(k, rel)
        if any(p != p.rstrip(" .") for p in re.split(r"[\\/]", rel)):
            k = ("bad_path", rel); hits[k] += 1; examples.setdefault(k, rel)
        b = open(full, "rb").read()
        if b"\x00" in b[:4096]:
            continue
        t = b.decode("utf8", "replace")
        for m in NAME_RX.finditer(t):
            k = ("name", m.group(0).lower()); hits[k] += 1; examples.setdefault(k, rel)
        for m in EMAIL.finditer(t):
            if not anon_rules.EMAIL_KEEP.search(m.group(0)):
                k = ("email", m.group(0)); hits[k] += 1; examples.setdefault(k, rel)
        for m in re.finditer(r"(chatgpt\.com|claude\.ai|gemini\.google\.com|chat\.openai\.com)/share/[\w-]+", t):
            k = ("share_link", m.group(0)); hits[k] += 1; examples.setdefault(k, rel)
        for m in HOME.finditer(t):
            k = ("home_path", m.group(2)); hits[k] += 1; examples.setdefault(k, rel)

if not hits:
    print("no leftover personal identifiers found")
for (kind, v), n in hits.most_common(200):
    print(f"{kind:12s} {n:5d}  {v[:60]:60s}  e.g. {examples[(kind, v)][-90:]}")
