"""Write prompt_counts_by_team.csv and prompt_counts_per_file.csv from count.py output, and print the
phase-share statistics used in the paper.  usage: make_tables.py <dir with phase_totals.json> <analysis_dir>"""
import csv, json, os, sys

S, A = sys.argv[1], sys.argv[2]
P = ["DP1", "DP2", "DP3", "DP4"]
RANK = {"NeCRL": 1, "ITIMS Boys": 2, "ElectroNova": 3, "Devrem": 4, "Maestro": 5, "Team team": 6, "Acona Tech": 7,
        "ICLab_HUST2": 8, "HUST1": 9, "Farmceries": 11, "Obsidian Order": 12, "Team Circuitrix": 13,
        "UCC Eng. Physics": 14, "Techgenius": 15, "Astral Coders": 16, "HUSD": 18, "BellLabs": 19,
        "ICLab_HUST": 20, "BIG-4": 21, "Team Ingenius": 22}
T = json.load(open(os.path.join(S, "phase_totals.json")))
rows = json.load(open(os.path.join(S, "prompt_counts.json"), encoding="utf8"))
teams = sorted(T["curated"], key=lambda t: RANK.get(t, 99))

with open(os.path.join(A, "prompt_counts_by_team.csv"), "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["team", "final_rank"] + [f"distinct_{p}" for p in P] + [f"curated_{p}" for p in P] + [f"raw_{p}" for p in P])
    for t in teams:
        w.writerow([t, RANK.get(t, "")] + [T["distinct"][t][p] for p in P] + [T["curated"][t][p] for p in P]
                   + [T["raw"][t][p] for p in P])
with open(os.path.join(A, "prompt_counts_per_file.csv"), "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["team", "phase", "kind", "rule", "prompts", "file"])
    for r in rows:
        w.writerow([r["team"], r["phase"], r["kind"], r["rule"], r["n"], r["rel"]])

D = T["distinct"]
fin = [t for t in teams if t in RANK]
full = [t for t in fin if all(D[t][p] > 0 for p in P)]


def shares(ts):
    s = [sum(D[t][p] for t in ts) for p in P]
    n = sum(s)
    return s, [round(100 * x / n, 1) for x in s], n


s, sh, n = shares(full)
print("teams with distinct prompts in all four phases:", full)
print("pooled:", dict(zip(P, s)), "shares %:", dict(zip(P, sh)), "total", n)
mean = [round(100 * sum(D[t][p] / sum(D[t][q] for q in P) for t in full) / len(full), 1) for p in P]
print("mean per-team share %:", dict(zip(P, mean)))
print("largest phase per team:", {t: max(P, key=lambda p: D[t][p]) for t in full})
for t in full:
    s2, sh2, n2 = shares([x for x in full if x != t])
    print(f"  without {t:12s}: {dict(zip(P, sh2))}")
print("finalists with any log:", sum(1 for t in fin if sum(D[t][p] for p in P)),
      "| distinct prompts (finalists):", sum(D[t][p] for t in fin for p in P),
      "| curated:", sum(T["curated"][t][p] for t in fin for p in P),
      "| raw:", sum(T["raw"][t][p] for t in fin for p in P))
