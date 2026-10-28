import os, re

LOGPAT = re.compile(r"(prompt|chat|ai[_ -]?log|llm|conversation|transcript|rawlog|ai_interaction|gpt|claude|gemini|copilot|interaction)", re.I)
EXT = {".md", ".txt", ".pdf", ".json", ".docx", ".log", ".html", ".jsonl", ".csv"}


def iter_logs(teams):
    for team, roots in teams.items():
        for ph, r in roots:
            for dp, dn, fn in os.walk(r):
                for f in fn:
                    full = os.path.join(dp, f)
                    rel = os.path.relpath(full, r)
                    if os.path.splitext(f)[1].lower() in EXT and LOGPAT.search(rel):
                        yield team, ph, rel, full
