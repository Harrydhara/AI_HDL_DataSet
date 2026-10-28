"""Team -> list of (phase or None, root dir) for the extracted Drive data."""
import os

S = "\\\\?\\" + os.path.join(os.path.dirname(os.path.realpath(__file__)), "data")
A = os.path.join(S, "AI-HDL_2026", "AI-HDL 2026")
Z = os.path.join(S, "AI-HDL_2026", "AI-HDL_2026")
D4 = os.path.join(S, "AI-HDL_dp4", "AI-HDL dp4")


def p(*a):
    return os.path.join(*a)


TEAMS = {
    "NeCRL": [(None, p(D4, "NECRL---AI-HDL-main__unz"))],
    "ITIMS Boys": [("DP1", p(A, "DP1", "ITIMS-Boys-DP1-Submission")), ("DP2", p(A, "DP2", "ITIMS-Boys-DP2-Submission")),
                   ("DP3", p(A, "DP3", "ITIMS-Boys")), ("DP4", p(A, "DP4", "ITIMS-Boys"))],
    "ElectroNova": [(f"DP{i}", p(A, f"DP{i}", "ElectroNova_AI-HDL")) for i in range(1, 5)],
    "Devrem": [(None, p(Z, "aihdl_2026_devrem-main (1)__unz"))],
    "Maestro": [(None, p(S, "Harish", "Harish", "Maestros"))],
    "Acona Tech": [(f"DP{i}", p(Z, f"Acona-Tech-AI-HDL-2026-DP{i}__unz")) for i in range(1, 5)],
    "ICLab_HUST2": [(f"DP{i}", p(A, f"DP{i}", "ICLab_HUST2")) for i in range(1, 5)],
    "HUST1": [(None, p(S, "Harish", "Harish", "HUST1"))],
    "Farmceries": [(f"DP{i}", p(Z, f"team-farmceries-AI-HDL-2026-DP{i}-Submission__unz")) for i in range(1, 5)],
    "ICLab_HUST": [(f"DP{i}", p(A, f"DP{i}", "ICLab_HUST")) for i in range(1, 5)],
    "BIG-4": [(f"DP{i}", p(A, f"DP{i}", "BIG-4")) for i in range(1, 3)],
    "HUSD": [(f"DP{i}", p(A, f"DP{i}", "HUSD")) for i in range(1, 4)],
    "Mercer": [(None, p(D4, "MercerTeamAIHDL-main__unz"))],
    "BellLabs": [("DP4", p(Z, "BellLabs_AIHDL-DP4-Submission__unz"))],
    "Obsidian Order": [("DP1", p(Z, "Obsidian-Order---AI-HDL-2026-Design-Phase-1-main__unz"))],
    "Techgenius": [(None, p(Z, "Techgenius-AI-HDL26-main__unz"))],
    "Team team": [(None, p(Z, "2026AI_HDL-main__unz"))],
    "Astral Coders": [(None, p(S, "Oluwatope", "Oluwatope", "Astral-Coders"))],
    "Team Circuitrix": [(None, p(S, "Oluwatope", "Oluwatope", "Team circuitrix"))],
    "Team Ingenius": [(None, p(S, "Oluwatope", "Oluwatope", "Team_Ingenius"))],
    "UCC Eng. Physics": [(None, p(S, "Kwadoh", "Kwadoh", " UCC Engineering Physics Microprocessor Group"))],
}

for t, roots in TEAMS.items():
    for ph, r in roots:
        assert os.path.isdir(r), (t, r)
