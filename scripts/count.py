"""Count human prompts per team and design phase across the heterogeneous AI-HDL logs.

Two numbers are produced per team and phase:
  raw      user turns in raw conversation exports when the team submitted one,
           otherwise the entries in its curated log;
  curated  entries in the curated, per-prompt logs teams wrote for grading
           (the competition template, prompt summaries); raw exports are ignored
           unless the team submitted nothing else for that phase.

Per-file rules (first non-zero wins):
  jsonl_antigravity  {"type":"USER_INPUT"} records
  jsonl_prompt       one JSON object per line with a "prompt" field
  user_label         **User** / **User:** / > **User:** / ## USER
  named_speaker      **<name> [emoji]:** speakers other than the assistant
  plain_user         User: / USER: / Human: at line start
  prompt_label       **Prompt** / **Prompt:** / PROMPT: / Prompt:
  prompt_numbered    Prompt 3 / ### Prompt 3 / Prompt ID: 03
  said               "You said:" / "<assistant> said:" (web chat PDF exports)
  interaction_hdr    #### Interaction 3.1.2
  question_label     **Question:**
De-duplication: identical files (by hash) are counted once per team; when several
versions of the same log file name exist for the same phase (cumulative repo
snapshots), only the largest is kept; a PDF is skipped when a parsed text log sits in
the same folder.
"""
import os, re, sys, hashlib, json, collections
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from teams import TEAMS
from findlogs_lib import iter_logs
from textio import read_text

PH = re.compile(r"(?:challenge|dp|design[ _-]?phase|milestone)[ _#-]*([1-4])(?![0-9])", re.I)
HEAD_PH = re.compile(r"^#{1,3}[^\n]*?(?:Design\s+Phase|DP)\s*#?-?\s*([1-4])\b", re.I | re.M)
RAWNAME = re.compile(r"(raw|complete_conversation|_session|cursor_|chatlog|rank\s*\d|LLM_Log|prompts?\.docx|promt|ai_log\.txt|Milestone1 AI Logs|_DP1\.pdf|optimization\.md$)", re.I)
SUMMARY = re.compile(r"(debugging|design_generation|optimization|security_hardening|physical_design)\d*\.md$", re.I)
SKIPNAME = re.compile(r"(^|[\\/])readme\.md$", re.I)

RULES = [
    ("jsonl_antigravity", lambda t: len(re.findall(r'"type"\s*:\s*"USER_INPUT"', t))),
    ("jsonl_prompt", lambda t: sum(1 for l in t.splitlines() if l.startswith("{") and '"prompt"' in l)),
    ("user_label", lambda t: len(re.findall(r"^\s*>?\s*(?:\*\*User\*\*:?|\*\*User:\*\*|#{1,4}\s*USER\b)", t, re.M))),
    ("named_speaker", lambda t: len([m for m in re.findall(r"^\*\*([^*\[\n]{1,30}?)\s*\[[^\]\n]{1,6}\]:\*\*", t, re.M)
                                      if m.strip().lower() not in ("copilot", "chatgpt", "claude", "gemini", "assistant")])),
    ("plain_user", lambda t: len(re.findall(r"^\s*(?:User|USER|Human|HUMAN)\s*:", t, re.M))),
    ("prompt_label", lambda t: len(re.findall(r"\*\*Prompt(?:\s*\(user\))?:?\*\*|^\s*(?:PROMPT|Prompt)\s*:", t, re.M))),
    ("prompt_numbered", lambda t: len(re.findall(r"^\s*(?:#+\s*)?\**\s*Prompt\s*(?:ID:\s*)?#?\s*\d+", t, re.M | re.I))),
    ("said", lambda t: len(re.findall(r"\bYou\s+said:", t)) or len(re.findall(r"\b(?:Copilot|ChatGPT|Gemini|Claude)\s+said:", t))),
    ("interaction_hdr", lambda t: len(re.findall(r"^#{2,5}\s*Interaction\b", t, re.M))),
    ("question_label", lambda t: len(re.findall(r"^\*\*Question:\*\*", t, re.M))),
]


def count(t):
    for name, f in RULES:
        n = f(t)
        if n:
            return name, n
    return "unparsed", 0


def segments(rel, root_ph, text):
    """Yield (phase, text) pieces; split a file with no path phase on Design-Phase headings."""
    m = PH.findall(rel)
    if m:
        yield "DP" + m[-1], text
        return
    if root_ph:
        yield root_ph, text
        return
    cuts = [(mm.start(), "DP" + mm.group(1)) for mm in HEAD_PH.finditer(text)]
    if not cuts:
        yield "DP?", text
        return
    if cuts[0][0] > 0:
        yield "DP1", text[:cuts[0][0]]           # logs open with the DP1 work
    for i, (pos, ph) in enumerate(cuts):
        end = cuts[i + 1][0] if i + 1 < len(cuts) else len(text)
        yield ph, text[pos:end]


if __name__ == "__main__":
    rows = []   # dict per counted segment
    for team in TEAMS:
        files = sorted(((ph, rel, full) for _, ph, rel, full in iter_logs({team: TEAMS[team]})),
                       key=lambda x: (x[0] or "DP0", x[1]))
        seen = set()
        cand = []
        for ph, rel, full in files:
            if SKIPNAME.search(rel):
                continue
            data = open(full, "rb").read()
            h = hashlib.md5(data).hexdigest()
            if h in seen:
                continue
            seen.add(h)
            cand.append((ph, rel, full, len(data)))
        # keep the largest version of each (phase-from-path, file name)
        best = {}
        for ph, rel, full, size in cand:
            m = PH.findall(rel)
            tail = "/".join(re.split(r"[\\/]", rel.lower())[-2:])
            key = ("DP" + m[-1] if m else ph, tail)
            if key not in best or size > best[key][3]:
                best[key] = (ph, rel, full, size)
        kept = sorted(best.values(), key=lambda x: (os.path.splitext(x[1])[1].lower() == ".pdf", x[1]))
        parsed_dirs = set()
        for ph, rel, full, size in kept:
            d = os.path.dirname(rel).lower()
            if rel.lower().endswith(".pdf") and d in parsed_dirs:
                rows.append(dict(team=team, phase="-", rel=rel, rule="skipped:pdf-copy", n=0, kind="-"))
                continue
            text = read_text(full)
            kind = "raw" if RAWNAME.search(os.path.basename(rel)) and not SUMMARY.search(rel) or \
                re.search(r"raw_logs|raw_logs\.md", rel, re.I) else "curated"
            # Gemini/Cursor transcripts saved under template names are raw conversations
            if re.search(r"^\s*\*\*(User|Gemini|Cursor|Claude)\*\*:?\s*$|^\*\*User:\*\*", text, re.M):
                kind = "raw"
            any_n = False
            for seg_ph, seg in segments(rel, ph, text):
                rule, n = count(seg)
                any_n |= n > 0
                k = kind
                # whole-conversation exports are raw even when saved under a non-raw file name
                if rule in ("named_speaker", "jsonl_antigravity", "jsonl_prompt", "said") or \
                   (rule in ("plain_user", "user_label") and not SUMMARY.search(rel)):
                    k = "raw"
                rows.append(dict(team=team, phase=seg_ph, rel=rel, rule=rule, n=n, kind=k))
            if any_n and not rel.lower().endswith(".pdf"):
                parsed_dirs.add(d)

    here = os.path.dirname(os.path.realpath(__file__))
    json.dump(rows, open(os.path.join(here, "prompt_counts.json"), "w", encoding="utf8"), indent=1)

    PHASES = ("DP1", "DP2", "DP3", "DP4")
    raw = collections.defaultdict(collections.Counter)
    cur = collections.defaultdict(collections.Counter)
    for r in rows:
        if r["n"] == 0:
            continue
        (raw if r["kind"] == "raw" else cur)[r["team"]][r["phase"]] += r["n"]

    final_raw, final_cur = {}, {}
    for team in TEAMS:
        fr, fc = collections.Counter(), collections.Counter()
        for p in PHASES + ("DP?",):
            fr[p] = raw[team][p] or cur[team][p]
            fc[p] = cur[team][p] or raw[team][p]
        final_raw[team], final_cur[team] = fr, fc

    for r in rows:
        print(f"{r['team']:16s} {r['phase']:4s} {r['kind']:7s} {r['rule']:18s} {r['n']:4d}  {r['rel'][-75:]}")
    for label, tab in (("RAW (raw transcript if present, else curated)", final_raw),
                       ("CURATED (curated log if present, else raw)", final_cur)):
        print("\n" + label)
        print(f"{'team':16s} " + " ".join(f"{p:>5s}" for p in PHASES + ('DP?',)))
        for team in TEAMS:
            print(f"{team:16s} " + " ".join(f"{tab[team][p]:5d}" for p in PHASES + ('DP?',)))
    json.dump({"raw": final_raw, "curated": final_cur}, open(os.path.join(here, "phase_totals.json"), "w"), indent=1)
