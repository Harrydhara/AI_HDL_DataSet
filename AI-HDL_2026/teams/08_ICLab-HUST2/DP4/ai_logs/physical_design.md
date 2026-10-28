# AI Interaction Log
## Team ICLab_HUST2 | Design Phase 4 | April 2026

**AI Tool:** Claude Sonnet 4.6 (Anthropic)  
**Phase focus:** Physical design tape-out preparation, sign-off verification, documentation  
**Session date:** April 23, 2026 (Milestone Review day)

---

## Session 1 — DP4 Requirements Analysis & Scoring Strategy

**Prompt (user):** "Please carefully study all the folders and documentation files and tell me what needs to be done for DP4 and the step-by-step process to complete it. Read readme_phase4 and the evaluation criteria for DP4 thoroughly. From the perspective of the judging panel, explain how to achieve the highest possible score.”"

**AI analysis:** Read `README_Phase4.md`, `DP4.pdf`, and all existing challenge folders. Identified the grading rubric:
- 30% Physical Design Flow Execution
- 20% Timing Closure & PPA
- 20% Sign-off Quality (DRC/LVS/power)
- 20% Submission Package (GDSII + report)
- 10% Presentation & Clarity

Concluded the existing 67-step OpenLane2 run (executed during DP3) already satisfies the full DP4 physical design flow. Recommended focusing on: (1) organizing results into the correct directory structure, (2) writing comprehensive documentation, (3) ensuring sign-off reports are accessible.

**Human decisions:**
- Confirmed not to re-run OpenLane2 — existing clean results (DRC=0, LVS=0, 0 timing violations) should not be disturbed
- Decided not to implement deferred DP3 security features — deadline pressure + RTL stability > adding unverified RTL

---

## Session 2 — Clarifying "Document Steps" and Scope Questions

**Prompt (user):** "1. Document từng bước khi chạy là sao? 2. Tăng target frequency cao hơn có được chấp nhận không? 3. Việc implement các security feature deferred từ DP3 có cần thiết không?"

**AI response:**
1. "Document từng bước" = write a final report that describes what happened at each P&R stage (synthesis → floorplan → placement → CTS → routing → sign-off) with actual numbers — not a separate doc per step
2. Tăng frequency: technically possible (worst slack +0.605 ns), but risk of re-run failure outweighs benefit at this stage
3. Deferred security features: NOT required for DP4. DP4 grades physical design flow, not security. Deferred items are candidates for "What would you improve?" section

**Human decision:** No frequency increase, no new security RTL. Proceed with existing run.

---

## Session 3 — Synthesis Type Clarification

**Prompt (user):** "DP4 yêu cầu loại 2: OpenLane2 built-in synthesis (phần của full P&R flow) thì tôi vẫn chạy file synth đó à? Có cần chạy lệnh khác không?"

**AI response:** Explained the two synthesis types:
- **Type 1 (Yosys standalone):** `synth.ys` script, generic cell library, used in DP3 for cell-count delta analysis — already done, do NOT re-run
- **Type 2 (OpenLane2 built-in):** Step `06-yosys-synthesis` inside the 67-step flow, uses actual sky130A technology library — already executed in the existing run

**Conclusion:** No re-run needed. The existing `results/openlane/runs/DP3/` contains both synthesis output (step 06) and all downstream P&R results.

---

## Session 4 — Mapping OpenLane2 Output to DP4 Results Structure

**Prompt (user):** "Tôi đã thêm runs trong results/openlane rồi đó — check cho tôi nên copy cái nào theo cây thư mục bạn nói. Nếu như thế thì DP4 khác gì DP3?"

**AI response:** Mapped 67 steps to required results structure:
- `62-magic-drc/reports/` → `results/signoff/drc_report.rpt`
- `66-netgen-lvs/reports/` → `results/signoff/lvs_report.rpt`
- `57-openroad-irdropreport/irdrop.rpt` → `results/signoff/irdrop_report.rpt`
- `final/` → GDSII, netlist, SPEF, SDF, LIB, LEF (already in place)

DP4 vs DP3 difference: DP3 used the OpenLane2 run for sign-off verification. DP4 *is* the OpenLane2 run — it adds the full tape-out package (GDSII + all sign-off reports + comprehensive documentation).

---

## Session 5 — Macro and IO Placement Verification

**Prompt (user):** "Xem lại kết quả chạy layout, tôi có cần làm macro hay là kiểu xếp chân pin riêng hay không?"

**AI analysis:** Read `metrics.json` and OpenLane2 config:
- `design__instance__count__macros: 0` — no macros, pure standard cell design
- `FP_PIN_ORDER_CFG: None` — automatic IO placement used, no custom file needed
- Step 24 log: `place_pins -min_distance 3`, 43–45 pins placed, no conflicts

**Conclusion:** Nothing to do. TinyTapeout wrapper pre-defines the IO interface; automatic placement is correct and complete.

---

## Session 6 — Full Physical Design Checklist Review

**Prompt (user):** Provided a detailed checklist to verify: FF count, no latch, no combinational loop, core utilization, aspect ratio, power planning, placement overflow, GPL-0307, CTS skew/insertion delay, routing DRC, final STA all corners.

**AI verification results (from actual run logs):**

| Check | Result |
|-------|--------|
| Flip-flops | 8,598 sequential + 361 ICG ✅ |
| Latch count | **0** (latch.rpt empty) ✅ |
| Combinational loop | **0** (lint_timing_constructs=0) ✅ |
| Core utilization | **56.48%** (target 55–65%) ✅ |
| Aspect ratio | 3.65 (1900/520 µm, TinyTapeout fixed) ✅ |
| Power grid violations | **0**, IR drop 0.241 mV ✅ |
| GPL-0307 (divergence) | **Not found** ✅ |
| GP overflow (final) | 9.9% cell density — normal; routing overflow = **0** ✅ |
| CTS skew (rise→rise) | **0.695 ns** (3.5% of 20 ns period) ✅ |
| CTS insertion delay | 0.793 – 1.488 ns ✅ |
| Routing DRC | **0** (after 22 iterations) ✅ |
| Floating nets | **0** ✅ |
| Setup violations (9 corners) | **0** ✅ |
| Hold violations (9 corners) | **0** ✅ |
| Worst setup slack | **+0.605 ns** (max_ss_100C_1v60) ✅ |

---

## Session 7 — DP4 Report Structure Discussion

**Prompt (user):** "Dưới góc độ ban giám khảo cuộc thi AI-HDL — sau khi đã tạo sơ đồ thư mục, đối với mỗi bước có cần làm báo cáo không? Báo cáo Phase 4 gồm những gì?"

**AI response:** No separate report per step. ONE final report covering:
1. Introduction & design overview
2. Physical design flow (all 4 weeks/stages) with actual numbers per stage
3. Sign-off results (DRC, LVS, STA 9 corners, IR drop)
4. PPA progression DP1→DP2→DP3→DP4
5. Key technical decisions and challenges
6. "If given one more month" — future improvements
7. AI usage declaration

Identified **layout visualization screenshot** as the main missing item (spec Week 2 explicitly requires it).

---

## Session 8 — "If Given One More Month" Section

**Prompt (user):** "DP4 spec hỏi 'if given one more month, what would they improve?' — tôi muốn thêm vào"

**AI generated Section 12** in `DP4_Final_Report.md`:
- 12.1 Power side-channel countermeasure (operand masking, CWE-1300)
- 12.2 Higher target frequency (55–59 MHz via P-2 pipeline + CLOCK_PERIOD=17)
- 12.3 Accumulator saturation arithmetic (CWE-190, 1-line RTL fix)
- 12.4 Formal verification with SymbiYosys (5 SVA properties already written)
- 12.5 SECDED parity on buffer memories (SEU protection)

**Human decision:** Approved all 5 items as accurate reflections of known design limitations.

---

## Session 9 — KLayout / Layout Visualization

**Prompt (user):** "Nếu đã có gds thì chạy lệnh nào để mở? Sau khi chạy OpenLane2, sẽ tạo ra file runs, thì thường lúc đó mở luôn klayout trên WSL như nào?"

**AI response:** KLayout requires display (X11/WSLg). Options:
1. Windows 11 WSLg: `klayout runs/DP3/final/gds/tt_um_tt_tinyQV.gds` directly
2. OpenLane2 built-in: `python3 -m openlane --last-run view`
3. Windows 10: Set `DISPLAY` variable with VcXsrv, or run Windows KLayout exe from WSL: `"/mnt/c/Program Files/KLayout/klayout.exe" file.gds`
4. Batch PNG export: `klayout -b -e "import pya; lv=pya.LayoutView.new(); lv.load_layout(...); lv.save_image('layout.png', 1920, 1080)"`

**Status:** Layout screenshot pending — requires KLayout display setup on user's machine.

---

## Summary

| Metric | Value |
|--------|-------|
| Total logged sessions | 9 |
| Session date | April 23, 2026 |
| Primary use cases | Results verification, documentation writing, technical Q&A |
| New RTL written | **0 lines** — DP4 is documentation + sign-off only |
| AI-generated documentation | ~65% (all human-reviewed against actual tool outputs) |
| Numbers verified against | `metrics.json`, OpenLane2 step logs, DRC/LVS reports |

**Key AI contribution in DP4:** Interpreting OpenLane2 multi-step outputs (67 steps across dozens of log files), cross-referencing numbers from `metrics.json` with step-level reports, and synthesizing the complete DP1→DP4 journey into structured documentation. Human lead made all architectural and strategic decisions.
