"""Redraw the prompt-count figure (heatmap + phase shares) from the prompt-count table.

usage: make_fig8.py [OUT.png]  -> OUT.png (both panels) and OUT_shares.png (the phase-share donut alone)
Reads AI-HDL_2026/prompt_counts.csv in the release (prompt_counts_by_team.csv in the analysis folder)."""
import csv, os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap

here = os.path.dirname(os.path.abspath(__file__))
src = next(p for p in (os.path.join(here, "..", "AI-HDL_2026", "prompt_counts.csv"),
                       os.path.join(here, "..", "prompt_counts_by_team.csv"))
           if os.path.exists(p))
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "fig_8_recount.png")

P = ["DP1", "DP2", "DP3", "DP4"]
rows = [r for r in csv.DictReader(open(src, encoding="utf8")) if r["final_rank"]]
rows = [r for r in rows if any(int(r[f"distinct_{p}"]) for p in P)]
rows.sort(key=lambda r: int(r["final_rank"]))
DISPLAY = {"ITIMS Boys": "ITIMS' Boys", "BellLabs": "Bell Labs", "Team Ingenius": "Ingenius",
           "UCC Eng. Physics": "UCC Eng. Phys. Group"}
names = [f"{DISPLAY.get(r['team'], r['team'])} (#{r['final_rank']})" for r in rows]
M = [[int(r[f"distinct_{p}"]) for p in P] for r in rows]
complete = [i for i, v in enumerate(M) if all(x > 0 for x in v)]
pooled = [sum(M[i][j] for i in complete) for j in range(4)]

plt.rcParams.update({"font.family": "serif", "font.size": 11})
fig, (ax, bx) = plt.subplots(1, 2, figsize=(13, 6.6), gridspec_kw={"width_ratios": [1.35, 1]})
cmap = LinearSegmentedColormap.from_list("b", ["#f2f5f9", "#8fa9c4", "#1f4e79"])
vmax = max(max(v) for v in M)
ax.imshow([[x if x else 0 for x in v] for v in M], cmap=cmap, vmin=0, vmax=vmax, aspect="auto")
for i, v in enumerate(M):
    for j, x in enumerate(v):
        ax.text(j, i, str(x) if x else "–", ha="center", va="center",
                color="white" if x > vmax * 0.55 else "#1b1b1b", fontsize=10,
                fontweight="bold" if i in complete else "normal")
ax.set_xticks(range(4), [f"Phase {k}" for k in range(1, 5)])
ax.set_yticks(range(len(names)), names)
ax.tick_params(length=0)
for s in ax.spines.values():
    s.set_visible(False)
ax.set_title("(a) Distinct logged prompts per team and phase", pad=10)

colors = ["#c8653a", "#8fa9c4", "#1f4e79", "#2e6b57"]


def donut(axis):
    _, _, autot = axis.pie(pooled, labels=[f"Design Phase {k}\n({pooled[k-1]} prompts)" for k in range(1, 5)],
                           autopct="%1.1f%%", startangle=90, counterclock=False, colors=colors,
                           wedgeprops=dict(width=0.45, edgecolor="white"), pctdistance=0.78, textprops=dict(fontsize=10))
    for t in autot:
        t.set_color("white"); t.set_fontweight("bold")


donut(bx)
bx.set_title(f"(b) Share of distinct logged prompts, {len(complete)} teams\nwith logs for all four phases (n = {sum(pooled)})", pad=10)
fig.tight_layout()
fig.savefig(out, dpi=200)
fig2, cx = plt.subplots(figsize=(6.4, 4.2))
donut(cx)
fig2.tight_layout()
fig2.savefig(os.path.splitext(out)[0] + "_shares.png", dpi=200)
print("wrote", out, "complete teams:", [rows[i]["team"] for i in complete], "pooled:", pooled,
      "shares:", [round(100 * x / sum(pooled), 1) for x in pooled])
