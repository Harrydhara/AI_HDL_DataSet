"""Extract the text of every counted prompt from the released logs.

Reads AI-HDL_2026/prompt_counts_per_file.csv (one row per counted log segment, with the counting rule
that count.py applied to it) and returns one record per prompt: team, phase, log kind
(raw export or curated log), released file, position in the file, and the prompt text.

The prompt units are the ones count.py counts, so per-team totals reproduce
prompt_counts.csv; `distinct()` applies the same selection and de-duplication as the
"distinct" columns (curated logs where a phase has one, each prompt counted once, in the
earliest phase where its opening text appears).

Usage: python extract_prompts.py OUT.jsonl
"""
import csv, json, os, re, sys, collections

ROOT = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
PHASES = ("DP1", "DP2", "DP3", "DP4")
ASSISTANTS = ("copilot", "chatgpt", "claude", "gemini", "assistant", "cursor", "ai")

# Where a prompt starts, per counting rule (same patterns as count.py).
START = {
    "user_label": r"^\s*>?\s*(?:\*\*User\*\*:?|\*\*User:\*\*|#{1,4}\s*USER\b)",
    "plain_user": r"^\s*(?:User|USER|Human|HUMAN)\s*:",
    "prompt_label": r"\*\*Prompt(?:\s*\(user\))?:?\*\*:?|^\s*(?:PROMPT|Prompt)\s*:",
    "prompt_numbered": r"^\s*(?:#+\s*)?\**\s*Prompt\s*(?:ID:\s*)?#?\s*\d+[^\n]*",
    "said": r"\bYou\s+said:",
    "question_label": r"^\*\*Question:\*\*",
}
# Where a prompt ends: the next turn of any speaker, or a response / metadata field.
END = re.compile(
    r"^\s*>?\s*\*\*(?:Cursor|Assistant|Gemini|Claude|Copilot|ChatGPT|AI|Model|LLM)\b[^*\n]{0,30}\*\*"
    r"|^\s*[*-]\s+\*\*(?!Prompt)[A-Z][\w /()-]{1,40}:?\*\*"          # "* **Claude Response:**" fields
    r"|^\s*>?\s*\*\*(?:AI |LLM |Model |Assistant )?(?:Response|Output|Result|Outcome|Answer|Reply|Summary"
    r"|Explanation|Notes?|Changes?|Timestamp|Tool|Purpose|Context|Follow[- ]?up|Analysis|Fix|Solution"
    r"|Key Takeaways?|Lessons?|Status|Verification|Code|Generated Code)\b[^*\n]{0,40}\*\*"
    r"|^#{1,4}\s*(?:ASSISTANT|Assistant|Response|AI Response|Answer|Output|Gemini|Claude|ChatGPT|Copilot|Cursor)\b"
    r"|^\s*(?:Assistant|AI|Claude|Gemini|ChatGPT|GitHub Copilot|Copilot|Cursor|Model|Response|My Response|Answer|Bot)\s*:"
    r"|^\s*(?:ASSISTANT|MODEL|RESPONSE|ANSWER)\s*:"
    r"|\b(?:Copilot|ChatGPT|Gemini)\s+said:|Claude\s+(?:said|responded):"
    r"|^_\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}[^\n]*_\s*$"          # timestamp line before a reply
    r"|^\s*-{3,}\s*$|^#{1,3}\s+\S",
    re.M)
NAMED = re.compile(r"^\*\*([^*\[\n]{1,30}?)\s*\[[^\]\n]{1,6}\]:\*\*", re.M)
HEAD_PH = re.compile(r"^#{1,3}[^\n]*?(?:Design\s+Phase|DP)\s*#?-?\s*([1-4])\b", re.I | re.M)
PH = re.compile(r"(?:challenge|dp|design[ _-]?phase|milestone)[ _#-]*([1-4])(?![0-9])", re.I)


def norm_key(s):
    return re.sub(r"[^a-z0-9]+", "", s.lower())[:80]


def read(path):
    t = open(path, "rb").read().decode("utf8", "replace")
    lines = t.splitlines()
    # PDF exports converted one word per line: join them back into running text
    if len(lines) > 200 and sum(len(l.strip()) for l in lines) / len(lines) < 8:
        t = re.sub(r"\s+", " ", " ".join(l.strip() for l in lines if l.strip()))
        t = re.sub(r"(You said:|(?:Copilot|ChatGPT|Gemini|Claude) said:)", r"\n\1", t)
    return t


def split_phases(text):
    """Segments of a log with no phase in its path, split on Design-Phase headings (count.py)."""
    cuts = [(m.start(), "DP" + m.group(1)) for m in HEAD_PH.finditer(text)]
    if not cuts:
        return [("DP?", text)]
    out = [("DP1", text[:cuts[0][0]])] if cuts[0][0] > 0 else []
    for i, (pos, ph) in enumerate(cuts):
        out.append((ph, text[pos:cuts[i + 1][0] if i + 1 < len(cuts) else len(text)]))
    return out


def split_on(pattern, text, flags=0):
    """(prompt, key text) for each match of a prompt-start pattern; the prompt runs to the
    next speaker turn or response field, the key text is the 300 characters count.py keys on."""
    starts = list(re.compile(pattern, re.M | flags).finditer(text))
    out = []
    for i, m in enumerate(starts):
        nxt = starts[i + 1].start() if i + 1 < len(starts) else len(text)
        body = text[m.end():nxt]
        e = END.search(body, 1)
        out.append((body[:e.start()] if e else body, text[m.end():m.end() + 300]))
    return out


def prompts_in(rule, text):
    """(prompt text, key text) pairs in one log segment."""
    if rule == "jsonl_antigravity":
        out = []
        for line in text.splitlines():
            m = re.search(r'"type"\s*:\s*"USER_INPUT".*?"content"\s*:\s*"(.{0,300})', line)
            if m:
                try:
                    body = json.loads(line).get("content", "")
                except ValueError:
                    body = m.group(1)
                out.append((body, m.group(1)))
        return out
    if rule == "jsonl_prompt":
        out = []
        for line in text.splitlines():
            if line.startswith("{") and '"prompt"' in line:
                m = re.search(r'"prompt"\s*:\s*"(.{0,300})', line)
                try:
                    body = json.loads(line)["prompt"]
                except ValueError:
                    body = line
                out.append((body, m.group(1) if m else body))
        return out
    if rule == "named_speaker":
        marks = list(NAMED.finditer(text))
        out = []
        for i, m in enumerate(marks):
            if m.group(1).strip().lower() in ASSISTANTS:
                continue
            end = marks[i + 1].start() if i + 1 < len(marks) else len(text)
            e = END.search(text, m.end() + 1, end)
            out.append((text[m.end():e.start() if e else end], text[m.end():m.end() + 300]))
        return out
    return split_on(START[rule], text, re.I if rule == "prompt_numbered" else 0)


def load():
    """All counted prompts, and the log segments whose released copy gave a different count."""
    rows = list(csv.DictReader(open(os.path.join(ROOT, "AI-HDL_2026", "prompt_counts_per_file.csv"), encoding="utf8")))
    by_file = collections.defaultdict(list)
    for r in rows:
        if r["kind"] in ("raw", "curated") and int(r["prompts"]) > 0:
            by_file[r["released_path"]].append(r)
    records, mismatches = [], []
    for path, rs in by_file.items():
        text = read(os.path.join(ROOT, path))
        if len(rs) > 1 and not PH.findall(rs[0]["file"]):
            # count.py emitted one row per heading segment that had prompts, in order
            segs = [s for s in split_phases(text) if prompts_in(rs[0]["rule"], s[1])]
        else:
            segs = [(rs[0]["phase"], text)]
        for (ph, seg), r in zip(segs, rs):
            want = int(r["prompts"])
            ps = prompts_in(r["rule"], seg)
            if len(ps) != want:
                # the released copy of a log can be formatted differently from the file count.py
                # read (e.g. text converted from a PDF copy); try the other prompt markers
                for alt in START:
                    alt_ps = prompts_in(alt, seg)
                    if len(alt_ps) == want:
                        ps = alt_ps
                        break
            if len(ps) != want:
                mismatches.append((r["team"], r["phase"], path, want, len(ps)))
            for i, (p, k) in enumerate(ps):
                records.append(dict(team=r["team"], phase=r["phase"], kind=r["kind"], rule=r["rule"],
                                    file=path, index=i, text=p.strip(), key=norm_key(k)))
    return records, mismatches


def distinct(records):
    """Prompts counted in the distinct columns of prompt_counts.csv, in log order."""
    out = []
    for team in sorted({r["team"] for r in records}):
        seen = set()
        for ph in PHASES + ("DP?",):
            sel = [r for r in records if r["team"] == team and r["phase"] == ph]
            pick = [r for r in sel if r["kind"] == "curated"] or [r for r in sel if r["kind"] == "raw"]
            here = set()
            for r in pick:
                k = r["key"] or f"__{r['file']}#{r['index']}"
                if k not in seen and k not in here:
                    out.append(r)
                here.add(k)
            seen |= here
    return out


if __name__ == "__main__":
    recs, bad = load()
    with open(sys.argv[1], "w", encoding="utf8") as f:
        for r in recs:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(len(recs), "prompts extracted;", len(bad), "segments whose count differs from the CSV")
    for b in bad:
        print("  ", b)
