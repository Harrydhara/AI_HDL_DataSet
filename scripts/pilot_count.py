"""Prompt and artifact counts for the 2025 pilot cycle (digital watch on a Basys-3 FPGA).

Uses the same per-file rules as count.py plus three pilot formats:
  emoji_user      "### 👤User" headings (exported Markdown chats)
  assistant_turn  lines that are only "ChatGPT:" (one per reply, so one per prompt)
  response_label  "Response:" / "Respone:" blocks following a prompt
Manual counts are used for two short logs whose prompts carry no markers.
Re-exports of the same ChatGPT conversation are collapsed: a log whose user turns are
mostly (>= 80%) contained in a longer log of the same team is not counted again.
"""
import os, re, sys, hashlib, json, collections
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from pilot_teams import PILOT
from textio import read_text
import count as C

LOGDIR = re.compile(r"(ai prompts|prompting|chatgpt logs|ai response)", re.I)
RTL_EXT = (".v", ".sv", ".vhd")
MANUAL = {("UET1", "Promt"): (2, "manual: two unlabeled prompts (power/area, security)"),
          ("DigiDynamos", "Chatgpt-Prompt"): (2, "manual: two prompts in a pasted exchange")}
UNCOUNTABLE = {"share-link-only", "image-only-pdf", "page-capture", "no-turn-markers"}
here = os.path.dirname(os.path.realpath(__file__))


def pilot_count(t):
    n = len(re.findall(r"^#{1,4}\s*[^\w\s#]+\s*User\b", t, re.M))
    if n:
        return "emoji_user", n
    rule, n = C.count(t)
    if n:
        return rule, n
    n = len(re.findall(r"^\s*ChatGPT:\s*$", t, re.M))
    if n:
        return "assistant_turn", n
    n = len(re.findall(r"^\s*Respon?se:", t, re.M))
    if n:
        return "response_label", n
    return "no-turn-markers", 0


def user_turns(t):
    parts = re.split(r"\bYou\s+said:", t)[1:]
    return {re.sub(r"\s+", " ", p)[:120] for p in parts}


rows, art = [], {}
for team, (div, root) in PILOT.items():
    files = []
    for dp, dn, fn in os.walk(root):
        for f in fn:
            files.append((os.path.relpath(os.path.join(dp, f), root), os.path.join(dp, f)))
    files.sort(key=lambda x: (x[0].lower().endswith(".pdf"), x[0]))
    seen, parsed_dirs = set(), set()
    a = collections.Counter()
    said = []          # (turn-set, row) for near-duplicate collapsing
    for rel, full in files:
        data = open(full, "rb").read()
        h = hashlib.md5(data).hexdigest()
        if h in seen:
            continue
        seen.add(h)
        ext = os.path.splitext(rel)[1].lower()
        is_code_txt = ext == ".txt" and re.search(r"verilog code", rel, re.I) and re.search(rb"\bmodule\b", data)
        if ext in RTL_EXT or is_code_txt or (ext == "" and re.search(rb"\bmodule\b", data)):
            loc = sum(1 for l in data.decode("utf8", "replace").splitlines() if l.strip() and not l.strip().startswith("//"))
            if re.search(r"(^tb_|_tb\b|_tb_|^tb\.|testbench|^test_)", os.path.basename(rel), re.I) or \
                    re.search(r"(^|[\\/])(sim_1|simulation_files|simulation_source)[\\/]", rel, re.I):
                a["tb_files"] += 1
            else:
                a["rtl_files"] += 1; a["rtl_loc"] += loc
            continue
        if ext == ".xdc":
            a["constraints"] += 1; continue
        if not LOGDIR.search(rel) or ext not in (".md", ".txt", ".pdf", ".docx") or re.search(r"readme", rel, re.I):
            continue
        a["log_files"] += 1
        d = os.path.dirname(rel).lower()
        if ext == ".pdf" and d in parsed_dirs:
            rows.append(dict(team=team, rel=rel, rule="skipped:pdf-copy", n=0)); continue
        man = next((v for (tm, k), v in MANUAL.items() if tm == team and k in rel), None)
        t = read_text(full)
        if man:
            row = dict(team=team, rel=rel, rule=man[1], n=man[0])
        elif re.search(r"chatgpt\.?com.?share", t, re.I) and len(t) < 600:
            row = dict(team=team, rel=rel, rule="share-link-only", n=0)
        elif ext == ".pdf" and not t.strip():
            row = dict(team=team, rel=rel, rule="image-only-pdf", n=0)
        else:
            rule, n = pilot_count(t)
            if not n and t.startswith("# Project Report: Extracted from"):
                rule = "page-capture"      # whole web page saved as one block; turns not separable
            row = dict(team=team, rel=rel, rule=rule, n=n)
            if rule == "said":
                said.append((user_turns(t), row))
        rows.append(row)
        if row["n"]:
            parsed_dirs.add(d)
    # collapse re-exports of the same conversation
    said.sort(key=lambda x: -len(x[0]))
    kept = []
    for turns, row in said:
        if any(len(turns & k) >= 0.8 * max(1, len(turns)) for k in kept):
            row["rule"] += " (re-export, not counted)"
            row["n_raw"], row["n"] = row["n"], 0
        else:
            kept.append(turns)
    a["prompts"] = sum(r["n"] for r in rows if r["team"] == team)
    a["countable_logs"] = sum(1 for r in rows if r["team"] == team and r["n"])
    art[team] = dict(a)

if __name__ == "__main__":
    for r in rows:
        print(f"{r['team']:18s} {r['rule'][:40]:40s} {r['n']:4d}  {r['rel'][-70:]}")
    print(f"\n{'team':18s} {'div':13s} {'prompts':>7s} {'logs':>4s} {'rtl':>4s} {'loc':>5s} {'tb':>3s} {'xdc':>3s}")
    for team, (div, _) in PILOT.items():
        a = art[team]
        print(f"{team:18s} {div:13s} {a.get('prompts',0):7d} {a.get('countable_logs',0):4d} {a.get('rtl_files',0):4d} "
              f"{a.get('rtl_loc',0):5d} {a.get('tb_files',0):3d} {a.get('constraints',0):3d}")
    tot = collections.Counter()
    for a in art.values():
        tot.update(a)
    print("TOTAL", dict(tot), "teams with countable logs:", sum(1 for a in art.values() if a.get("prompts")))
    json.dump({"rows": rows, "artifacts": art}, open(os.path.join(here, "pilot_counts.json"), "w", encoding="utf8"), indent=1)
