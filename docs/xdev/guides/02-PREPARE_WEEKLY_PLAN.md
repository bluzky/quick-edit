# Phase 2: Prepare Weekly Plan

**Purpose:** Define this week's scope and daily breakdown  
**Duration:** 1-2 hours  
**When:** Monday morning, start of each week  
**Outcome:** Complete week-X-plan.md ready for team alignment  
**Previous:** [01-PREPARE_MASTER_PLAN.md](./01-PREPARE_MASTER_PLAN.md)  
**Next:** [03-DAILY_IMPLEMENTATION.md](./03-DAILY_IMPLEMENTATION.md)

---

## Overview

Weekly Plan bridges master plan and daily execution:
- Breaks down week's work from master plan
- Lists specific objectives and components
- Estimates time per day
- Identifies testing approach
- Flags risks

**This plan is created ONCE per week** (Monday morning), changes only if scope shifts mid-week.

---

## Prerequisites

Before creating weekly plan:

1. **Master plan** is complete and approved
2. **Previous week's summary** (if not Week 1) - shows actual vs planned
3. **Velocity data** - how much work team completes per week
4. **Current blockers** - any ongoing issues
5. **Team capacity** - who's available this week

---

## When to Create Weekly Plan

**Timing:** Monday morning before 10 AM

**Process:**
1. Review master plan for this week's phase
2. Review previous week's summary (velocity, learnings)
3. Create week plan
4. Brief team at 10 AM
5. Create first day plan immediately after

---

## Steps to Create Weekly Plan

### Step 1: Copy Template

Copy `./templates/week-X-plan.md` to `./docs/plan/week-X-plan.md`

Replace X with week number (week-1-plan.md, week-2-plan.md, etc.)

### Step 2: Fill in Header

```markdown
# Week X Plan - [Feature/Component Name]

**Week:** Week X ([Date Range])
**Phase:** Phase X - [Phase Name]
**Target Completion:** [Target Date]
**Status:** 🔄 Planning / Ready to Start
```

**Example:**
```markdown
# Week 1 Plan - Preparation & Architecture

**Week:** Week 1 (November 19-23, 2025)
**Phase:** Phase 1 - Preparation
**Target Completion:** November 23, 2025
**Status:** 🔄 Planning
```

### Step 3: Week Overview

Write 2-3 sentences describing:
- What exists before this week (current state)
- What will exist after this week (target state)
- Main focus

```markdown
## Week Overview

**Current State:**
- Requirements gathered but not finalized
- No architecture defined
- Team ready to start

**Target State:**
- Requirements signed off
- Architecture documented and approved
- UI mockups complete
- Week 1-4 development plan ready
- Team ready to build frontend

**Focus:** Planning and architecture foundation
```

### Step 4: Week Objectives

List objectives in priority order (P0, P1, P2):

```markdown
## Week Objectives

### Must-Have (P0) - Week is not complete without these
- [ ] Clarify and sign-off requirements
- [ ] Design high-level architecture
- [ ] Create UI mockups
- [ ] Identify technical risks

### Should-Have (P1) - Complete if time allows
- [ ] Low-level architecture for critical path
- [ ] Database schema design
- [ ] API contract definitions

### Nice-to-Have (P2) - Do if time permits
- [ ] Performance estimations
- [ ] Security analysis
```

### Step 5: Daily Breakdown

For each day (5 days), fill in:
- Goal (what day accomplishes)
- Time estimate
- Key deliverable

```markdown
## Daily Breakdown

**DAY 1 (Monday) - Requirements Finalization** (~6 hours)
- Clarify ambiguous requirements with stakeholders
- Document use cases and user flows
- Identify constraints and limitations
- Expected outcome: Requirements doc complete and signed-off

**DAY 2 (Tuesday) - Architecture Design** (~7 hours)
- Design high-level system architecture
- Identify key components and responsibilities
- Define data flow and integration points
- Expected outcome: Architecture diagram and notes complete

**DAY 3 (Wednesday) - UI/UX Design** (~6.5 hours)
- Create mockups for main features
- Plan user workflows and interactions
- Identify edge cases and error states
- Expected outcome: UI mockups ready for review

**DAY 4 (Thursday) - Technical Planning** (~7 hours)
- Define development plan (Week 1-4)
- Create database schema (if needed)
- Plan testing strategy
- Expected outcome: Development plan document complete

**DAY 5 (Friday) - Review & Sign-Off** (~5 hours)
- Review all week 1 deliverables
- Stakeholder presentations
- Get final approvals
- Expected outcome: Everything signed-off, ready for Phase 2
```

### Step 6: Components to Build

List what will be created this week:

```markdown
## Components to Build

### Documentation
- Requirements document
- Architecture document
- Development plan (Week 1-4)

### Design Artifacts
- UI mockups (high-fidelity)
- User flow diagrams
- Database schema (if applicable)

### Other
- Risk register
- Testing strategy document
```

### Step 7: Testing Strategy

Define what testing happens this week:

```markdown
## Testing Strategy

### Documentation Review
- [ ] Requirements review with stakeholders
- [ ] Architecture review with tech lead
- [ ] UI mockups review with product owner

### Team Alignment
- [ ] All team members understand requirements
- [ ] All team members understand architecture
- [ ] No questions about Phase 2 approach

### Sign-Off
- [ ] Requirements signed by product owner
- [ ] Architecture approved by tech lead
- [ ] UI mockups approved by design lead
```

### Step 8: Success Metrics

Define how we'll know the week was successful:

```markdown
## Success Metrics

| Metric | Target |
|--------|--------|
| Requirements signed-off | 100% |
| Architecture complete | Yes |
| UI mockups created | 5+ screens |
| Development plan detailed | Yes |
| Team alignment | 100% |
| Blockers identified | All documented |
| Risk register complete | Yes |
```

### Step 9: Risks & Mitigations

Identify things that could go wrong:

```markdown
## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Requirements unclear | High | Schedule stakeholder review Day 2 |
| Architecture too complex | Medium | Simplify, refine in Phase 3 |
| Stakeholder unavailable | Medium | Set meetings Day 1, confirm attendance |
| Technical unknowns | Low | Prototype problematic areas Day 4 |
```

### Step 10: Dependencies

List what must be done first:

```markdown
## Dependencies & Prerequisites

### Must Be Complete Before Week Starts
- [ ] Team assembled and ready
- [ ] Office/tools set up
- [ ] Requirements document (draft)

### External Dependencies
- [ ] Stakeholder availability (need meetings)
- [ ] Design tools access (Figma, etc.)
- [ ] Development environment ready
```

### Step 11: Team Allocation

Show who's doing what:

```markdown
## Team Allocation

| Team Member | Hours | Focus |
|-------------|-------|-------|
| Tech Lead | 35 | Architecture, tech planning |
| Product Manager | 25 | Requirements finalization, UX |
| Developer | 30 | Architecture review, planning |
| Designer | 20 | UI mockups |
| QA Lead | 10 | Test strategy planning |

Total Hours: ~120 (feasible for 5-person team, 1 week)
```

### Step 12: Success Criteria for PM

Define specifically what PM will verify:

```markdown
## Success Criteria for PM Verification

By end of week, PM should be able to verify:
- [ ] Requirements document exists and is clear
- [ ] Architecture document exists with diagrams
- [ ] UI mockups exist for all major flows
- [ ] Development plan details Weeks 1-4
- [ ] All team members understand the plan
- [ ] No unresolved questions or blockers
- [ ] Stakeholders have signed off
```

### Step 13: Notes & Decisions

Document any special considerations:

```markdown
## Notes & Decisions

### Architecture Decisions Made This Week
- **Decision:** Use ScreenCaptureKit (macOS 13+)
- **Rationale:** Best option for screen recording, actively maintained
- **Trade-off:** No older macOS support

### Technical Notes
- Database schema will be finalized in Phase 2
- API contracts will be written in Phase 2
- Performance testing in Phase 4 only

### Process Notes
- Daily standup at 10 AM (15 minutes)
- End-of-day sync with PM (20 minutes)
- Retrospective Friday 4:30 PM
```

### Step 14: Preview of Week 2

Give team visibility into what's coming:

```markdown
## Week 2 Preview

After this week completes, Week 2 will focus on:
- Frontend setup and environment
- UI component creation (buttons, controls, layouts)
- Mock data structures
- Build system configuration

**Key Dependencies from Week 1:**
- Approved architecture (used for component planning)
- Final UI mockups (guides component implementation)
- Clear requirements (ensures features match requirements)
```

---

## Validation Checklist

Before publishing weekly plan:

- [ ] All 4-5 days clearly defined with goals
- [ ] Estimated time per day realistic (total 30-40 hours)
- [ ] Objectives are specific and testable
- [ ] Components to build listed
- [ ] Testing strategy clear
- [ ] Success metrics defined
- [ ] Risks identified with mitigations
- [ ] Team allocation reasonable
- [ ] Success criteria for PM specific
- [ ] No unresolved dependencies

---

## Creating Supporting Documents

Once weekly plan is created, also prepare:

### 1. Create week-X/ Directory
```bash
mkdir -p docs/plan/week-X
```

### 2. Create README.md for Navigation
Copy `./templates/week-X/README.md` to `./docs/plan/week-X/README.md`

This provides quick links to all week documents.

### 3. Create progress.md for Tracking
Copy `./templates/week-X/progress.md` to `./docs/plan/week-X/progress.md`

This will be updated daily with actual progress.

### 4. Create Day 1 Plan
See [03-DAILY_IMPLEMENTATION.md](./03-DAILY_IMPLEMENTATION.md)

Create first day plan immediately after team alignment.

---

## Team Alignment Meeting

### When
Monday 10 AM (1 hour after plan creation)

### Attendees
- PM/Team Lead
- All developers
- QA lead
- Product owner (if available)

### Agenda
1. **Overview** (5 min) — Week goal and phase context
2. **Daily breakdown** (10 min) — What happens each day
3. **Components** (10 min) — What gets built/created
4. **Success criteria** (5 min) — What does "done" look like
5. **Dependencies** (5 min) — What we need from others
6. **Q&A** (10 min) — Questions and clarifications
7. **Confirm** (5 min) — Everyone understands

### Outcomes
- ✅ Everyone understands week goal
- ✅ No questions about expectations
- ✅ Any blockers identified
- ✅ Ready to start Day 1 plan creation

---

## After Weekly Plan

### Before Team Meeting (10 AM)
1. Create and review week-X-plan.md
2. Create week-X/ directory structure
3. Create week-X/README.md
4. Create week-X/progress.md (template)

### During Team Meeting (10-11 AM)
- Present week plan to team
- Answer questions
- Confirm understanding

### After Team Meeting (11 AM-12 PM)
- Create Day 1 plan (see next phase)
- Brief developers on Day 1
- Developers start work at 12 PM

---

## Common Issues & Solutions

### Issue: Too much scope for one week
**Solution:** Move P1/P2 items to next week, keep only P0

### Issue: Time estimates off
**Solution:** Adjust using previous week's velocity, add buffer

### Issue: Unclear dependencies
**Solution:** Document explicitly, schedule blocking meetings early

### Issue: Team not aligned
**Solution:** Extend alignment meeting, add more Q&A time

### Issue: Scope keeps changing
**Solution:** Lock scope at start of week, new requests go to next week

---

## Document Checklist

By end of Monday 11 AM, you should have:

- ✅ `docs/plan/week-X-plan.md` — Weekly scope complete
- ✅ `docs/plan/week-X/` directory created
- ✅ `docs/plan/week-X/README.md` — Navigation hub
- ✅ `docs/plan/week-X/progress.md` — Progress log (template)
- ✅ Team alignment meeting completed
- ✅ Day 1 plan started or planned for creation

---

## Files Created This Phase

After this phase:
- ✅ `docs/plan/week-X-plan.md` — Weekly plan
- ✅ `docs/plan/week-X/README.md` — Navigation
- ✅ `docs/plan/week-X/progress.md` — Tracking log
- ✅ Team alignment completed
- ✅ Ready for daily implementation

---

**Status:** Phase 2 Complete  
**Next:** [03-DAILY_IMPLEMENTATION.md](./03-DAILY_IMPLEMENTATION.md) - Daily Plan & Execution
