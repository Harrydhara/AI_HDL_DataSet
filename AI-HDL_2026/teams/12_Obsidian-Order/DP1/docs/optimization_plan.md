# DP2 Optimization Plan

## Project: tqvp_gpio Optimization
**Team:** Obsidian Order  
**Date:** March 7, 2026  
**Phase:** Design Phase 2 (DP2) - PPA Optimization

---

## Optimization Goals

### 1. Performance Optimization
**Objective:** Improve maximum operating frequency from 50 MHz to 100 MHz

**Strategy:** Pipeline Matrix Multiplier
- Add 2-stage pipeline to matrix multiplication unit
- Stage 1: Perform multiplication operations
- Stage 2: Perform accumulation/addition operations
- Reduce combinational critical path length by 50%

**Implementation Details:**
- Add pipeline registers between multiply and accumulate stages
- Matrix operation trigger initiates computation
- Result available after 2 clock cycles (vs current 5 cycles)
- Maintain synchronous design, no latches
- Preserve all existing functionality

**Expected Results:**
- Critical path: 20ns → 10ns (-50%)
- Max frequency: 50 MHz → 100 MHz (+100%)
- Latency increase: Acceptable trade-off for performance gain

**Metrics to Track:**
- Timing analysis from synthesis
- Critical path delay
- Setup/hold timing margins
- Functional correctness in pipelined mode

---

### 2. Power Optimization
**Objective:** Reduce power consumption by 30-40% during idle/low-activity periods

**Strategy:** Clock Gating for Matrix Registers
- Implement clock gating on matrix multiplier registers
- Gate clock when matrix unit is not actively computing
- Use trigger signal to enable/disable clock

**Implementation Details:**
- Add clock gating cells/logic for matrix computation registers
- Enable clock only when trigger is active
- Use proper clock gating methodology (avoid glitches)
- Consider using `$gclk` primitives or manual gating logic
- Maintain all functional requirements

**Expected Results:**
- Power reduction: 30-40% during idle states
- Dynamic power savings proportional to idle time
- Minimal area increase (<5%)

**Metrics to Track:**
- Cell count increase from gating logic
- Power estimation from synthesis tools
- Functional verification of gated logic
- Timing impact (should be minimal)

---

### 3. Area Optimization
**Objective:** Optimize combinational logic to reduce cell count by 10-20%

**Strategy:** Logic Optimization
- Review and optimize MUX structures (currently 32 MUXes)
- Simplify redundant combinational paths
- Let synthesis tools apply aggressive optimization
- Consider resource sharing opportunities

**Implementation Details:**
- Analyze current implementation for redundancies
- Restructure control logic if beneficial
- Use synthesis directives for area optimization
- Balance with timing requirements

**Expected Results:**
- Combinational cell reduction: 10-20%
- Maintain or improve timing
- No functional changes

**Metrics to Track:**
- Total cell count change
- Logic gate count breakdown
- Timing impact
- Functional equivalence

---

## Trade-Off Analysis

### Pipeline Trade-Offs
**Pros:**
- Significant frequency improvement (2x)
- Better timing margins
- Competitive advantage for performance metrics
- Scalable architecture

**Cons:**
- Increased latency (1 extra cycle)
- More flip-flops (~25% increase in FFs)
- Slightly higher area (~5-10%)
- Increased design complexity

**Decision:** IMPLEMENT - Performance gain is critical for DP2 scoring. Latency increase is acceptable for target applications. Modern designs favor pipelined architectures.

---

### Clock Gating Trade-Offs
**Pros:**
- Substantial power savings (30-40%)
- Low implementation cost
- Standard industry practice
- Minimal timing impact

**Cons:**
- Additional gating logic (~5% area)
- Slightly more complex verification
- Need to verify gating control logic

**Decision:** IMPLEMENT - Essential for power score. Industry-standard technique with proven benefits. Area cost is minimal compared to power savings.

---

### Area Optimization Trade-Offs
**Pros:**
- Reduced cell count
- Better resource utilization
- Lower manufacturing cost (hypothetically)

**Cons:**
- Risk of longer critical paths if over-optimized
- Diminishing returns
- May conflict with timing goals

**Decision:** IMPLEMENT WITH CAUTION - Apply aggressive synthesis optimization but prioritize timing. Pipeline already addresses timing, so some area optimization is safe. Monitor critical path during implementation.

---

## Implementation Timeline

### Week 1: Baseline Analysis ✓
- [x] Run baseline synthesis (Yosys)
- [x] Capture baseline PPA metrics
- [x] Create optimization report
- [x] Create optimization plan
- [x] Commit baseline work

### Week 2: Performance Optimization (FOCUS NOW)
- [ ] Implement 2-stage pipeline in matrix multiplier
- [ ] Update RTL (src/tqvp_gpio.v)
- [ ] Add pipeline registers and control logic
- [ ] Run initial verification

### Week 2: Power Optimization
- [ ] Implement clock gating logic
- [ ] Add gating controls for matrix registers
- [ ] Verify gating behavior
- [ ] Ensure no functional changes

### Week 2: Verification & Analysis
- [ ] Run full cocotb regression suite
- [ ] Debug any failures
- [ ] Add new tests for pipeline latency
- [ ] Verify power-saving behavior

### Week 2: Final PPA Analysis
- [ ] Run synthesis on optimized design
- [ ] Capture optimized PPA metrics
- [ ] Compare before/after
- [ ] Update optimization report
- [ ] Document trade-offs

### Week 2: Submission
- [ ] Final verification (all tests pass)
- [ ] Complete all documentation
- [ ] Create screenshots/evidence
- [ ] Git commit and tag
- [ ] Push to repository
- [ ] Submit to mentors

---

## Verification Strategy

### Functional Tests
1. **GPIO Operations:** Verify all GPIO read/write functions
2. **Interrupt Handling:** Verify interrupt generation and clearing
3. **Matrix Basic:** Verify matrix multiplication correctness
4. **Matrix Pipeline:** NEW - Verify 2-cycle latency operation
5. **Clock Gating:** NEW - Verify proper gating behavior
6. **Edge Cases:** Test reset, overflow, boundary conditions

### Regression Suite
- Run existing 7 cocotb tests
- Add 2-3 new tests for optimizations
- Target: 10/10 tests passing
- Document any failures and fixes

### Synthesis Verification
- Compare synthesis reports (before/after)
- Verify cell counts match expectations
- Check for timing violations
- Confirm no latches generated

---

## Risk Mitigation

### Risk 1: Pipeline Breaks Functionality
**Mitigation:** Incremental testing, maintain old code path initially, comprehensive regression

### Risk 2: Clock Gating Introduces Glitches
**Mitigation:** Use standard gating templates, careful trigger logic, extensive testing

### Risk 3: Area Optimization Hurts Timing
**Mitigation:** Monitor synthesis results, prioritize timing, backtrack if needed

### Risk 4: Time Constraints
**Mitigation:** Focus on pipeline + gating first (highest impact), area optimization is optional

---

## Success Criteria

### Must-Haves (Required for DP2)
- ✓ Baseline PPA captured and documented
- ⧗ Pipeline implementation complete and verified
- ⧗ Clock gating implementation complete and verified
- ⧗ All regression tests passing
- ⧗ Optimized PPA metrics captured
- ⧗ Before/after comparison documented
- ⧗ Trade-offs analyzed and explained
- ⧗ Code committed and tagged

### Nice-to-Haves (Bonus Points)
- OpenLane power analysis (actual power numbers)
- Detailed timing analysis reports
- Area optimization implemented successfully
- Additional test coverage
- Clean, well-commented code

---

## Expected Final Results

### Baseline (DP1)
- Cells: 159
- Flip-Flops: 32
- Frequency: 50 MHz
- Power: ~0.5 mW

### Target (DP2)
- Cells: ~175-180 (+10-15%)
- Flip-Flops: ~40 (+25%)
- Frequency: 100 MHz (+100%)
- Power: ~0.3 mW (-40%)

### Scoring Impact
- Performance: Strong improvement (2x frequency)
- Power: Strong improvement (40% reduction)
- Area: Controlled growth (acceptable for gains)
- Overall: Balanced optimization demonstrating PPA trade-off mastery

---

## References
- DP1 Final Design: src/tqvp_gpio.v
- Baseline Synthesis: synth/baseline/baseline_report.txt
- Test Suite: test/test.py
- Documentation: docs/

---

*Status: Ready for Week 2 Implementation*  
*Next Action: Implement pipeline optimization in RTL*
