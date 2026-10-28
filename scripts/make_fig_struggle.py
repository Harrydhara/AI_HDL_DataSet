"""Figure: where designers got stuck, from the keyword markers in the released prompt logs.

(a) every distinct prompt of each finalist team (the units of prompt_counts.csv, after the
    corrections in recount.py), in log order within each phase, marked by its first matching
    code; runs of three or more consecutive error-driven prompts are underlined.
(b) share of each phase's distinct prompts carrying each code.
The two panels are drawn as separate full-width figures, to be stacked in the paper.

Usage: python make_fig_struggle.py OUT_BASENAME   -> OUT_BASENAME_a.pdf/.png and OUT_BASENAME_b.pdf/.png
"""
import os, sys, collections
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import extract_prompts as E
import recount as RC
import prompt_markers as M

RANK = {"NeCRL": 1, "ITIMS Boys": 2, "ElectroNova": 3, "Devrem": 4, "Maestro": 5, "Acona Tech": 7,
        "ICLab_HUST2": 8, "HUST1": 9, "Farmceries": 11, "Obsidian Order": 12, "UCC Eng. Physics": 14,
        "HUSD": 18, "BellLabs": 19, "ICLab_HUST": 20, "BIG-4": 21, "Team Ingenius": 22}
DISPLAY = {"ITIMS Boys": "ITIMS' Boys", "BellLabs": "Bell Labs", "Team Ingenius": "Ingenius",
           "UCC Eng. Physics": "UCC Eng. Phys."}

# codes in priority order: a prompt is drawn with the first code it carries
CODES = [
    ("distress", "Repeated error, frustration or urgency", {"repeated_error", "frustration", "urgency"},
     dict(marker="o", color="#eb6834")),
    ("control", "Redirects or constrains the model", {"control"}, dict(marker="^", color="#3d3c39")),
    ("concept", "Conceptual question or confusion", {"conceptual", "confusion"}, dict(marker="D", color="#1baf7a")),
    ("paste", "Pastes tool output", {"pastes_output"}, dict(marker="s", color="#2a78d6")),
]
INK, MUTED, TICK, SHADE = "#0b0b0b", "#6f6e69", "#bdbcb5", "#f1f0ec"


def code_of(markers):
    for key, _, names, _ in CODES:
        if markers & names:
            return key
    return None


def load():
    records, bad = E.load()
    assert not bad, bad
    recs = [r for r in records if r["team"] != "Mercer" and not RC.excluded(r)]
    for r in recs:
        r["m"] = M.markers(r["text"])
        r["err"] = M.error_driven(r["text"])
        r["code"] = code_of(r["m"])
    return E.distinct(recs)


PHASE_NAMES = ["DP1\nFunction", "DP2\nPPA", "DP3\nSecurity", "DP4\nLayout"]
SHORT = {"distress": "Repeated error, frustration, urgency", "control": "Redirects the model",
         "concept": "Conceptual question, confusion", "paste": "Pastes tool output"}


def spread(ys, gap, lo):
    """Label positions at least `gap` apart, keeping order and staying above `lo`."""
    order = sorted(range(len(ys)), key=lambda i: ys[i])
    pos = {}
    prev = lo - gap
    for i in order:
        pos[i] = max(ys[i], prev + gap)
        prev = pos[i]
    return [pos[i] for i in range(len(ys))]


def main(out):
    D = load()
    teams = sorted({r["team"] for r in D}, key=lambda t: RANK[t])
    by = collections.defaultdict(list)
    for r in D:
        by[(r["team"], r["phase"])].append(r)
    complete = {t for t in teams if all(by[(t, p)] for p in E.PHASES)}

    plt.rcParams.update({"font.family": "serif", "font.size": 8.5, "axes.edgecolor": "#c3c2b7",
                         "axes.labelcolor": INK, "xtick.color": MUTED, "ytick.color": INK})
    fig = plt.figure(figsize=(6.6, 5.2))
    gs = fig.add_gridspec(2, 1, height_ratios=[1, 0.15], hspace=0.14,
                          left=0.215, right=0.985, top=0.94, bottom=0.01)
    ax = fig.add_subplot(gs[0])
    lx = fig.add_subplot(gs[1])
    lx.axis("off")

    # (a) prompts in order
    n_rows = len(teams)
    for j in range(4):
        if j % 2 == 0:
            ax.axvspan(j, j + 1, color=SHADE, lw=0, zorder=0)
    loops = []
    for i, t in enumerate(teams):
        y = i
        for j, p in enumerate(E.PHASES):
            rs = by[(t, p)]
            if not rs:
                ax.text(j + 0.5, y, "–", ha="center", va="center", color=MUTED, fontsize=8)
                continue
            xs = [j + 0.05 + 0.90 * (k + 0.5) / len(rs) for k in range(len(rs))]
            size = 4.8 if len(rs) <= 20 else 3.8      # dense cells (NeCRL and Bell Labs DP3) get smaller marks
            for x, r in zip(xs, rs):
                if r["code"] is None:
                    ax.plot([x, x], [y - 0.2, y + 0.2], color=TICK, lw=0.7, zorder=1, solid_capstyle="butt")
                else:
                    st = next(c[3] for c in CODES if c[0] == r["code"])
                    ax.plot(x, y, linestyle="none", marker=st["marker"], markersize=size,
                            markerfacecolor=st["color"], markeredgecolor="white", markeredgewidth=0.5, zorder=3)
            # stuck loops: >= 3 consecutive error-driven prompts
            k = 0
            while k < len(rs):
                if rs[k]["err"]:
                    e = k
                    while e + 1 < len(rs) and rs[e + 1]["err"]:
                        e += 1
                    if e - k + 1 >= 3:
                        ax.plot([xs[k] - 0.01, xs[e] + 0.01], [y + 0.36, y + 0.36], color="#eb6834", lw=1.8,
                                solid_capstyle="round", zorder=2)
                        loops.append((t, p, e - k + 1, len(rs)))
                    k = e + 1
                else:
                    k += 1
    ax.set_xlim(0, 4)
    ax.set_ylim(n_rows - 0.4, -0.6)
    ax.set_yticks(range(n_rows), [f"{DISPLAY.get(t, t)}{'$^\\dagger$' if t in complete else ''} ({RANK[t]})"
                                  for t in teams])
    ax.set_xticks([0.5, 1.5, 2.5, 3.5], PHASE_NAMES)
    ax.tick_params(length=0)
    for s in ax.spines.values():
        s.set_visible(False)
    ax.set_title("(a) Distinct logged prompts in log order, by team and phase", loc="left", fontsize=9, color=INK)

    handles = [Line2D([], [], linestyle="none", marker=st["marker"], markersize=6, markerfacecolor=st["color"],
                      markeredgecolor="white", label=label) for _, label, _, st in CODES]
    handles += [Line2D([], [], color=TICK, lw=0.9, marker="|", markersize=7, linestyle="none", label="No code"),
                Line2D([], [], color="#eb6834", lw=1.8, label="Stuck loop: 3+ error-driven prompts in a row")]
    lx.legend(handles=handles, loc="center", ncol=2, frameon=False, fontsize=7.5, handletextpad=0.5,
              columnspacing=2.4, borderaxespad=0)
    for ext in ("pdf", "png"):
        fig.savefig(f"{out}_a.{ext}", dpi=300)

    # (b) share of prompts with each code, by phase (a prompt can carry several codes)
    fig2, bx = plt.subplots(figsize=(6.6, 2.5))
    fig2.subplots_adjust(left=0.08, right=0.62, top=0.86, bottom=0.2)
    xs = range(4)
    stats = {}
    for key, label, names, st in CODES:
        ys = []
        for p in E.PHASES:
            rs = [r for r in D if r["phase"] == p]
            ys.append(100 * sum(bool(r["m"] & names) for r in rs) / len(rs))
        stats[key] = ys
        bx.plot(xs, ys, color=st["color"], lw=1.8, marker=st["marker"], markersize=5.5,
                markeredgecolor="white", markeredgewidth=0.6, zorder=3, clip_on=False)
    # direct labels at the end of each line, spaced so they do not overlap
    keys = [c[0] for c in CODES]
    ends = spread([stats[k][-1] for k in keys], gap=2.6, lo=0.0)
    for k, y_end, y_lab in zip(keys, [stats[k][-1] for k in keys], ends):
        bx.annotate(SHORT[k], xy=(3, y_end), xytext=(3.18, y_lab), textcoords="data", va="center", ha="left",
                    fontsize=8, color=INK, annotation_clip=False,
                    arrowprops=dict(arrowstyle="-", color="#c3c2b7", lw=0.6, shrinkA=0, shrinkB=4)
                    if abs(y_lab - y_end) > 0.6 else None)
    n_ph = [sum(r["phase"] == p for r in D) for p in E.PHASES]
    t_ph = [len({r["team"] for r in D if r["phase"] == p}) for p in E.PHASES]
    bx.set_xticks(list(xs), PHASE_NAMES)
    bx.set_xlim(-0.15, 3.0)
    bx.set_ylim(0, 22)
    bx.set_yticks([0, 5, 10, 15, 20], ["0", "5", "10", "15", "20%"])
    bx.grid(axis="y", color="#e1e0d9", lw=0.6)
    bx.set_axisbelow(True)
    for s in ("top", "left", "right"):
        bx.spines[s].set_visible(False)
    bx.tick_params(length=0)
    bx.set_title("(b) Share of each phase's distinct prompts with each code", loc="left", fontsize=9, color=INK)
    for ext in ("pdf", "png"):
        fig2.savefig(f"{out}_b.{ext}", dpi=300)
    print("wrote", f"{out}_a", f"{out}_b", "teams", len(teams), "prompts", len(D), "per phase", n_ph,
          "teams per phase", t_ph)
    for key, ys in stats.items():
        print(f"  {key:8s}", " ".join(f"{y:5.1f}" for y in ys))
    print("  loops:", loops)


if __name__ == "__main__":
    main(sys.argv[1])
