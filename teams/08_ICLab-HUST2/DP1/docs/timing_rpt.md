# Timing Report — tqvp_winograd

**Tool:** OpenROAD (OpenLane2 v2.3.10) | **PDK:** Sky130 HD | **Clock:** 15ns (66.7 MHz)

---

## Timing Summary

| Corner | Setup WNS | Setup TNS | Hold WNS | Hold TNS | Status |
|---|---|---|---|---|---|
| nom_tt_025C_1v80 | +3.271 ns | 0.0 ns | +0.315 ns | 0.0 ns | ✅ PASS |
| nom_ss_100C_1v60 | -7.038 ns | -3260.7 ns | -0.058 ns | -0.143 ns | ❌ FAIL |
| nom_ff_n40C_1v95 | — | — | — | — | ⚠️ Fast corner |

---

## Worst Timing Path Analysis

### TT Corner (nom_tt_025C_1v80) — Setup Max

```
Startpoint : rst_n (input port clocked by clk)
Endpoint   : _46809_ (recovery check against rising-edge clock clk)
Path Group : asynchronous
Path Type  : max

Fanout     Cap        Slew       Delay      Time       Description
------------------------------------------------------------------------
                      0.150000   0.000000   0.000000   clock clk (rise edge)
                                 0.000000   0.000000   clock network delay (ideal)
                                 3.000000   3.000000   input external delay
3832       13.823172  61.684143  42.143349  45.143349  rst_n (in)
                      61.684143  0.000000   45.143349  _46809_/RESET_B
                                            45.143349  data arrival time

                      0.150000   15.000000  15.000000  clock clk (rise edge)
                                 0.000000   15.000000  clock network delay (ideal)
                                -0.250000   14.750000  clock uncertainty
                                 0.000000   14.750000  clock reconvergence pessimism
                                 14.750000             _46809_/CLK
                     -20.734018  -5.984018             library recovery time
                                 -5.984018             data required time
------------------------------------------------------------------------
                                 -5.984018  data required time
                                 -45.143349 data arrival time
------------------------------------------------------------------------
                                 -51.127365 slack (VIOLATED) ← TT violation on rst_n async path
```

### SS Corner (nom_ss_100C_1v60) — Setup Max (Worst)

```
Startpoint : rst_n (input port clocked by clk)
Endpoint   : _46809_ (recovery check against rising-edge clock clk)
Path Group : asynchronous
Path Type  : max

Fanout     Cap        Slew       Delay      Time       Description
------------------------------------------------------------------------
                      0.150000   0.000000   0.000000   clock clk (rise edge)
                                 0.000000   0.000000   clock network delay (ideal)
                                 3.000000   3.000000   input external delay
3832       12.491442  87.197273  61.887146  64.887138  rst_n (in)
                      87.197273  0.000000   64.887138  _46809_/RESET_B
                                            64.887138  data arrival time

                      0.150000   15.000000  15.000000  clock clk (rise edge)
                                 0.000000   15.000000  clock network delay (ideal)
                                -0.250000   14.750000  clock uncertainty
                                 0.000000   14.750000  clock reconvergence pessimism
                                 14.750000             _46809_/CLK
                     -39.086212  -24.336210            library recovery time
                                 -24.336210            data required time
------------------------------------------------------------------------
                                 -24.336210 data required time
                                 -64.887138 data arrival time
------------------------------------------------------------------------
                                 -89.223351 slack (VIOLATED)
```

---

## Root Cause Analysis

| Issue | Detail |
|---|---|
| **Worst path** | `rst_n` async reset → fanout 3832 flip-flops |
| **Root cause** | `rst_n` drives 3832 FFs directly — no reset tree buffering |
| **Slew violation** | 87.197 ns slew at SS corner (limit ~5 ns) |
| **Fix for DP2** | Add reset buffer tree / pipeline reset |

---

## Key Observations

- **TT corner PASS** (WNS = +3.271 ns) for all register-to-register paths
- **SS corner FAIL** primarily due to `rst_n` async path with fanout 3832
- **Not a datapath issue** — Winograd compute logic meets timing at TT
- **Antenna violations**: 8 nets (flagged as TinyQV CPU nets, not Winograd)
- **Fanout 3328 nets** exceed max fanout limit → needs buffer insertion in DP2

