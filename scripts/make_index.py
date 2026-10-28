"""Write index.csv for the release from the prompt and artifact tables. usage: make_index.py <analysis_dir> <release_dir>"""
import csv, os, sys

A, R = sys.argv[1], sys.argv[2]
INST = {
    "NeCRL": ("San Francisco State University", "USA"), "ITIMS Boys": ("Hanoi University of Science and Technology", "Vietnam"),
    "ElectroNova": ("College of Engineering Trivandrum", "India"), "Devrem": ("Yildiz Technical University", "Türkiye"),
    "Maestro": ("The University of Arizona", "USA"), "Team team": ("KU Leuven", "Belgium"),
    "Acona Tech": ("Ankara Yıldırım Beyazıt University", "Türkiye"), "ICLab_HUST2": ("Hanoi University of Science and Technology", "Vietnam"),
    "HUST1": ("Hanoi University of Science and Technology", "Vietnam"), "Farmceries": ("University of Lagos", "Nigeria"),
    "Obsidian Order": ("Jomo Kenyatta University of Agriculture and Technology", "Kenya"),
    "Team Circuitrix": ("Obafemi Awolowo University", "Nigeria"), "UCC Eng. Physics": ("University of Cape Coast", "Ghana"),
    "Techgenius": ("Regent University College of Science and Technology", "Ghana"), "Astral Coders": ("University of Lagos", "Nigeria"),
    "HUSD": ("Hanoi University of Science and Technology", "Vietnam"), "BellLabs": ("University of Lagos", "Nigeria"),
    "ICLab_HUST": ("Hanoi University of Science and Technology", "Vietnam"), "BIG-4": ("Hanoi University of Science and Technology", "Vietnam"),
    "Team Ingenius": ("University of Lagos", "Nigeria"), "Mercer": ("Mercer County Community College", "USA"),
}
TAPED = {"NeCRL": "AES-128 accelerator (graduate division winner)", "ITIMS Boys": "SPI controller + CRC-16 (undergraduate division winner)"}
P = ["DP1", "DP2", "DP3", "DP4"]
pc = {r["team"]: r for r in csv.DictReader(open(os.path.join(A, "prompt_counts_by_team.csv"), encoding="utf8"))}
ar = {r["team"]: r for r in csv.DictReader(open(os.path.join(A, "artifact_stats_by_team.csv"), encoding="utf8"))}
# a built release keeps teams/ at its root; the published release has it under AI-HDL_2026/
C = os.path.join(R, "AI-HDL_2026") if os.path.isdir(os.path.join(R, "AI-HDL_2026", "teams")) else R
teams_dir = os.path.join(C, "teams")
folders = {d.split("_", 1)[1]: d for d in os.listdir(teams_dir)}


def folder(team):
    key = "".join(c if c.isalnum() else "-" for c in team).strip("-")
    while "--" in key:
        key = key.replace("--", "-")
    return folders.get(key, "")


with open(os.path.join(C, "index.csv"), "w", newline="", encoding="utf8") as fh:
    w = csv.writer(fh)
    w.writerow(["folder", "team", "final_rank", "institution", "country", "phases_with_files", "phases_with_prompt_logs",
                "all_four_phases_logged", "distinct_prompts_DP1", "distinct_prompts_DP2", "distinct_prompts_DP3", "distinct_prompts_DP4",
                "rtl_files", "rtl_loc", "testbench_files", "reports", "gds_files", "taped_out"])
    for team in sorted(pc, key=lambda t: int(pc[t]["final_rank"] or 99)):
        f = folder(team)
        present = sorted(d for d in os.listdir(os.path.join(teams_dir, f)) if d in P) if f else []
        logged = [p for p in P if int(pc[team][f"distinct_{p}"])]
        a = ar.get(team, {})
        w.writerow([f, team, pc[team]["final_rank"], *INST.get(team, ("", "")), ";".join(present), ";".join(logged),
                    "yes" if len(logged) == 4 else "no", *[pc[team][f"distinct_{p}"] for p in P],
                    a.get("rtl_files", ""), a.get("rtl_loc", ""), a.get("tb_files", ""), a.get("reports", ""), a.get("gds", ""),
                    TAPED.get(team, "")])
print("index.csv written")
