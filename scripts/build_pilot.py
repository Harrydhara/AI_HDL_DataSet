"""Add the anonymized 2025 pilot cycle to a release.

usage: python build_pilot.py <release_dir>

Layout: pilot_2025/teams/<graduate|undergraduate>_<team>/<original relative path>
 - Verilog, testbenches, constraints and text documents are anonymized and kept
 - prompt logs in Word/PDF are converted to anonymized Markdown (an image-only PDF is left out)
 - images, archives and other binary files are left out
Also writes pilot_2025/index.csv and pilot_2025/prompt_counts_per_file.csv.
reorganize.py then moves this folder to AI-HDL_2025_pilot/ in the published release.
"""
import os, re, sys, csv, hashlib, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_teams import PILOT
from textio import read_text, decode_text
import anon_rules
import pilot_count as PC

OUT = sys.argv[1]
if os.name == "nt" and not OUT.startswith("\\\\?\\"):
    OUT = "\\\\?\\" + os.path.realpath(OUT)
P = os.path.join(OUT, "pilot_2025")
DROP = {".png", ".jpg", ".jpeg", ".gif", ".zip", ".ds_store", ".bmp", ".svg"}
LOGDIR = re.compile(r"(ai prompts|prompting|chatgpt logs|ai response)", re.I)


def slug(team, div):
    return f"{div}_" + re.sub(r"[^A-Za-z0-9]+", "-", team).strip("-")


kept, dropped = collections.Counter(), collections.Counter()
for team, (div, root) in PILOT.items():
    rules = anon_rules.build(team)
    seen = set()
    for dp, dn, fn in os.walk(root):
        for f in fn:
            full = os.path.join(dp, f)
            rel = os.path.relpath(full, root)
            data = open(full, "rb").read()
            h = hashlib.md5(data).hexdigest()
            if h in seen:
                continue
            seen.add(h)
            ext = os.path.splitext(f)[1].lower() if not f.startswith(".") else f.lower()
            dest_rel = anon_rules.anonymize_name(rel, rules)
            dest_rel = os.sep.join(p.rstrip(" .") or "_" for p in re.split(r"[\\/]", dest_rel))
            if ext in DROP or f.lower() == ".ds_store":
                dropped[ext] += 1; continue
            if ext in (".pdf", ".docx"):
                t = read_text(full)
                if not t.strip():
                    dropped["image_only_pdf"] += 1; continue
                if ext == ".pdf" and os.path.exists(os.path.splitext(full)[0] + ".md"):
                    dropped["pdf_copy_of_md"] += 1; continue
                out = anon_rules.anonymize(t, rules)
                dest_rel = os.path.splitext(dest_rel)[0] + ".md"
            elif b"\x00" in data[:4096]:
                dropped["binary:" + ext] += 1; continue
            else:
                out = anon_rules.anonymize(decode_text(data), rules)
            dst = os.path.join(P, "teams", slug(team, div), dest_rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            open(dst, "w", encoding="utf8", newline="").write(out)
            kept[team] += 1

art = PC.art
with open(os.path.join(P, "index.csv"), "w", newline="", encoding="utf8") as fh:
    w = csv.writer(fh)
    w.writerow(["folder", "team", "division", "prompts_counted", "countable_logs", "rtl_files", "rtl_loc", "testbench_files",
                "constraint_files", "notes"])
    notes = {"UET1": "RTL byte-identical to UET3", "UET3": "RTL byte-identical to UET1",
             "ChipX": "prompt log is an image-only PDF (not released)",
             "Blue Team": "prompt log is a ChatGPT share link only", "Red Team": "prompt log is a ChatGPT share link only",
             "DigiDynamos": "phases 1-3.1 logged as ChatGPT share links / screenshots",
             "CC-1": "Claude/Gemini/Grok logs are whole-page captures; turns not counted"}
    for team, (div, _) in PILOT.items():
        a = art[team]
        w.writerow([slug(team, div), team, div, a.get("prompts", 0), a.get("countable_logs", 0), a.get("rtl_files", 0),
                    a.get("rtl_loc", 0), a.get("tb_files", 0), a.get("constraints", 0), notes.get(team, "")])
with open(os.path.join(P, "prompt_counts_per_file.csv"), "w", newline="", encoding="utf8") as fh:
    w = csv.writer(fh)
    w.writerow(["team", "rule", "prompts", "file"])
    for r in PC.rows:
        w.writerow([r["team"], r["rule"], r["n"], anon_rules.anonymize_name(r["rel"], anon_rules.build(r["team"]))])
print("kept", dict(kept), "\ndropped", dict(dropped))
