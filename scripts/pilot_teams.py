"""Pilot cycle (AI-HDL 2025, digital watch on Basys-3 FPGA): team -> extracted folder."""
import os

S = "\\\\?\\" + os.path.join(os.path.dirname(os.path.realpath(__file__)), "data", "pilot", "AI_HDL_Pilot_Team_Code")
G, U = os.path.join(S, "Graduate Teams"), os.path.join(S, "Undergraduate Teams")

PILOT = {
    "ChipX": ("graduate", os.path.join(G, "ChipX_Code")),
    "UET1": ("graduate", os.path.join(G, "UET1_Code")),
    "UET3": ("graduate", os.path.join(G, "UET3_Code")),
    "UHD_CAT": ("graduate", os.path.join(G, "UHD_CAT_Code")),
    "AI_or_Die": ("undergraduate", os.path.join(U, "AI_or_Die_Code")),
    "Blue Team": ("undergraduate", os.path.join(U, "Blue_Team_Code")),
    "CC-1": ("undergraduate", os.path.join(U, "CC-1_Code")),
    "DigiDynamos": ("undergraduate", os.path.join(U, "DigiDynamos_Code")),
    "GPT_Earns_Degrees": ("undergraduate", os.path.join(U, "GPT_Earns_Degrees_Code")),
    "Red Team": ("undergraduate", os.path.join(U, "Red_Team_Code")),
    "UET2": ("undergraduate", os.path.join(U, "UET2_Code")),
}
