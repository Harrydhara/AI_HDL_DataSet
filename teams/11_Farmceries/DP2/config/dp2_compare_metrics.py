#!/usr/bin/env python3
"""Generate a DP-2 before/after comparison from two OpenLANE metrics.csv files."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

KEYS = [
    ("DIEAREA_mm^2", "Area (mm^2)"),
    ("wns", "WNS (ns)"),
    ("tns", "TNS (ns)"),
    ("power_typical_total_uW", "Total Power (uW)"),
    ("synth_cell_count", "Synth Cell Count"),
]


def read_metrics(path: Path) -> dict[str, str]:
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return next(reader)


def as_float(row: dict[str, str], key: str) -> float | None:
    value = row.get(key, "")
    if value in ("", "N/A", "-1"):
        return None
    try:
        return float(value)
    except ValueError:
        return None


def percent_delta(before: float | None, after: float | None) -> str:
    if before is None or after is None or before == 0:
        return "N/A"
    return f"{((after - before) / before) * 100:+.2f}%"


def render_markdown(
    baseline_label: str,
    optimized_label: str,
    before: dict[str, str],
    after: dict[str, str],
) -> str:
    for row in (before, after):
        if not row.get("power_typical_total_uW"):
            pi = as_float(row, "power_typical_internal_uW")
            ps = as_float(row, "power_typical_switching_uW")
            pl = as_float(row, "power_typical_leakage_uW")
            if pi is not None and ps is not None and pl is not None:
                row["power_typical_total_uW"] = f"{pi + ps + pl:.8f}"

    lines: list[str] = []
    lines.append("# DP-2 Before/After PPA Comparison")
    lines.append("")
    lines.append(f"- Baseline: {baseline_label}")
    lines.append(f"- Optimized: {optimized_label}")
    lines.append("")
    lines.append("| Metric | Baseline | Optimized | Delta | Delta % |")
    lines.append("|---|---:|---:|---:|---:|")

    for key, label in KEYS:
        before_f = as_float(before, key)
        after_f = as_float(after, key)

        before_s = before.get(key, "N/A")
        after_s = after.get(key, "N/A")

        if before_f is None or after_f is None:
            delta_s = "N/A"
            pct_s = "N/A"
        else:
            delta_s = f"{after_f - before_f:+.6f}"
            pct_s = percent_delta(before_f, after_f)

        lines.append(f"| {label} | {before_s} | {after_s} | {delta_s} | {pct_s} |")

    lines.append("")
    lines.append("## Notes")
    lines.append("")
    lines.append("- Positive delta for WNS is better.")
    lines.append("- Negative delta for TNS magnitude is better when moving toward 0.")
    lines.append("- Lower area and power are typically preferred unless justified by timing gains.")

    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline_metrics", type=Path)
    parser.add_argument("optimized_metrics", type=Path)
    parser.add_argument("--baseline-label", default="Baseline")
    parser.add_argument("--optimized-label", default="Optimized")
    parser.add_argument(
        "--out-md",
        type=Path,
        default=Path("../dp-2/reports/BEFORE_AFTER_PPA.md"),
    )
    args = parser.parse_args()

    before = read_metrics(args.baseline_metrics)
    after = read_metrics(args.optimized_metrics)

    md = render_markdown(args.baseline_label, args.optimized_label, before, after)
    args.out_md.parent.mkdir(parents=True, exist_ok=True)
    args.out_md.write_text(md, encoding="utf-8")

    print(f"Wrote {args.out_md}")


if __name__ == "__main__":
    main()
