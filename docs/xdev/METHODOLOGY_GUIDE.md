# Development Methodology Guide - Template Overview

---

## TEMPLATE ARCHITECTURE

This document explains how all templates fit together in your development methodology.

### Document Hierarchy

```
📊 master-plan.md                    [Created once, high-level]
   └─ Overall project timeline, phases, milestones
   └─ Updated when: Major scope change

📈 master-progress.md               [Updated weekly]
   └─ Overall project status, phase completion
   └─ Updated when: Week completes, milestone reached

📋 week-X-plan.md                   [Created start of week]
   └─ Weekly scope, daily breakdown
   └─ Updated when: Scope change during week

📁 week-X/
   ├─ README.md                     [Overview, links to all week docs]
   ├─ progress.md                   [Daily tracking during week]
   ├─ summary.md                    [Retrospective, completed after week]
   │
   ├─ day-1-plan.md                 [Detailed plan, morning before day]
   ├─ day-2-plan.md
   ├─ day-3-plan.md
   ├─ day-4-plan.md
   └─ day-5-plan.md
```

---

## WORKFLOW BY TIMELINE

### BEFORE PROJECT STARTS

**Create:** `master-plan.md`
- Define all phases, timeline, milestones
- List success criteria
- Identify risks
- Scope out architecture

**Outcome:** Complete project roadmap, stakeholder alignment

---

### START OF EACH WEEK (Day 1 Morning)

**Create:** 
- `week-X-plan.md` — Define week scope, daily breakdown
- `week-X/README.md` — Overview and quick links
- `week-X/progress.md` — Initialize with day structure

**Update:**
- `master-plan.md` — If timeline has shifted

**Outcome:** Team knows exactly what week will accomplish

---

### EACH DAY MORNING (Before work starts)

**Create:** `week-X/day-Y-plan.md`
- Detailed breakdown of day's tasks
- Acceptance criteria
- Testing strategy
- Architecture decisions

**Team Reviews:** Confirms understanding of objectives

**Outcome:** Developer knows exactly what to build and how to verify

---

### EACH DAY EXECUTION (During work)

**Developer:**
- Follows `day-Y-plan.md`
- Implements tasks
- Runs unit tests
- Manual testing
- Updates execution notes in `day-Y-plan.md`

**Progress Tracking:**
- Update `week-X/progress.md` with daily status
- Document blockers immediately
- Log actual time spent

**Outcome:** Work is incremental, testable, trackable

---

### EACH DAY END (Before day finishes)

**Developer:**
- Complete execution notes in `day-Y-plan.md`
- Mark tasks as complete
- Document any blockers
- Ensure tests pass and build is clean

**PM:**
- Reviews `day-Y-plan.md` definition of done
- Manually verifies feature works
- Gets hands-on with the build
- Signs off when satisfied

**Update:**
- Mark "PM Verification: ✅ Approved" in day plan
- Update `week-X/progress.md` with day's results

**Outcome:** Each day's work is independently verified and signed off

---

### EACH WEEK END (Friday End of Day)

**Developer:**
- Complete all remaining tasks from final day
- Finalize `week-X/progress.md`
- Fill in actual time spent for all days
- Write blockers summary
- Write TODOs for later

**Team:**
- Conduct retrospective
- Document what went well/underestimated/faster
- Identify process improvements
- Update retrospective section in `progress.md`

**Create:** `week-X/summary.md`
- Comprehensive week retrospective
- Metrics and learnings
- Adjustments for next sprint
- Stakeholder communication

**Update:**
- `master-progress.md` with week results
- `master-plan.md` if timeline shifted

**Outcome:** Week is fully documented, learnings captured, next week is informed by retrospective

---

## DOCUMENT USAGE PATTERNS

### `master-plan.md` — Reference Document
- **Created:** Once at project start
- **Updated:** Only for major scope/timeline changes
- **Frequency:** Referenced during planning, rarely updated
- **Audience:** Project managers, stakeholders, team leads
- **Purpose:** Project bible — what we're building and when

---

### `master-progress.md` — Status Dashboard
- **Created:** Week 1
- **Updated:** End of each week, when milestones complete
- **Frequency:** Weekly
- **Audience:** Managers, stakeholders, team leads
- **Purpose:** High-level project health at a glance

---

### `week-X-plan.md` — Scope Document
- **Created:** Start of each week
- **Updated:** If scope changes mid-week
- **Frequency:** Created once per week, rarely changed
- **Audience:** Development team
- **Purpose:** What this week will accomplish, how work is divided

---

### `week-X/README.md` — Navigation Hub
- **Created:** Start of each week
- **Updated:** When daily plans are created
- **Frequency:** Weekly
- **Audience:** Quick reference for team
- **Purpose:** Find the right document quickly

---

### `week-X/progress.md` — Execution Log
- **Created:** Start of week
- **Updated:** Every day during week
- **Frequency:** Daily updates
- **Audience:** Development team, PM, managers
- **Purpose:** What actually happened vs what was planned

---

### `week-X/day-Y-plan.md` — Execution Plan
- **Created:** Morning of each day
- **Updated:** During day + at end of day
- **Frequency:** Daily
- **Audience:** Developer, PM
- **Purpose:** Detailed implementation guide + sign-off document

---

## TYPICAL WEEK FLOW

### Monday Morning
1. Prepare `week-X-plan.md` (or final prep if already done Friday)
2. Create `week-X/` directory with README.md, progress.md
3. Create `day-1-plan.md`
4. Team reviews plan → alignment
5. Developer starts work

### Monday - Friday
- Each morning: Update day plan
- Each day: Implement → test → update progress.md
- Each day end: PM verification → sign-off
- Friday: Retrospective → summary.md

### Friday End
2. Update `master-progress.md`
3. Update `master-plan.md` if needed
4. Prepare Monday plan for next week

---

## DAILY WORKFLOW IN DETAIL

### 9:00 AM - Day Starts
- Developer has `day-Y-plan.md` ready
- Review objectives and definition of done
- Confirm no blockers from yesterday
- Start implementation

### During Day
- Implement tasks from day plan
- Run tests incrementally
- Update `day-Y-plan.md` with progress notes
- Document any blockers in real-time

### 4:00 PM - Wind Down
- Finish implementation
- Complete all tests
- Update execution section in `day-Y-plan.md`
- Update `week-X/progress.md` with day results
- Flag any blockers

### 4:30 PM - PM Review
- PM reads `day-Y-plan.md` definition of done
- PM manually tests the feature
- PM asks questions, explores edge cases
- PM signs off: ✅ Approved or 🔄 Needs Fix

### 5:00 PM - End of Day
- Mark day complete in progress.md
- Prepare notes for next day
- Blockers logged for discussion next day

---

## WHAT GOES WHERE

### Information Should Be In:

| Information | Document | Why |
|-------------|----------|-----|
| Overall timeline | `master-plan.md` | Single source of truth for project |
| Current phase status | `master-progress.md` | Dashboard for leadership |
| Week scope | `week-X-plan.md` | Planning artifact |
| Today's tasks | `day-Y-plan.md` | Detailed execution guide |
| What actually happened | `week-X/progress.md` | Actual vs planned |
| Daily blockers | `week-X/progress.md` | Tracked during week |
| Learnings & metrics | `week-X/summary.md` | Post-week analysis |
| Improvements for next sprint | `week-X/summary.md` | Feedback loop |

### Avoid Duplication

❌ **DON'T:** Put week scope in both `week-X-plan.md` AND `progress.md`
✅ **DO:** Plan in `week-X-plan.md`, track results in `progress.md`

❌ **DON'T:** Copy full code into day plans
✅ **DO:** Reference architecture, link to files

❌ **DON'T:** Update `master-plan.md` for minor changes
✅ **DO:** Only update for major scope/timeline shifts

---

## TEMPLATE CUSTOMIZATION

These templates are starting points. Customize by:

### Add Project-Specific Sections
- If you need deployment tracking: add to progress.md
- If you need performance metrics: add to summary.md
- If you need client communication: add to master-progress.md

### Simplify for Small Projects
- Single developer? Can skip some process overhead
- Short week? Can combine day planning into one morning session
- High-velocity team? Can skip time tracking if velocity is stable

### Expand for Large Projects
- Multiple teams? Add team-specific summary sections
- Complex dependencies? Add dependency tracking table
- Regulated environment? Add compliance tracking

---

## KEY PRINCIPLES

### 1. **Each Document Has One Purpose**
- `master-plan.md` = project scope
- `day-Y-plan.md` = detailed execution
- Don't make one document do everything

### 2. **Minimize Duplication**
- Plan once, update execution log once
- Reference instead of copying
- One source of truth per information type

### 3. **Update Only What Changed**
- Don't rewrite progress.md daily, just add new day status
- Don't update master-plan.md unless timeline shifts
- Keep documents lean and current

### 4. **Make Documents Easy to Navigate**
- Use links between documents
- Keep tables for quick scanning
- Clear hierarchy (headers, sections)

### 5. **Sign-Off Is Critical**
- PM verifies each day's work
- Developer confirms completion
- Document approval in the plan itself

---

## QUICK START CHECKLIST

For a new project, create these in order:

### Week 0 (Preparation)
- [ ] Create `master-plan.md`
- [ ] Create `master-progress.md`
- [ ] Get stakeholder alignment
- [ ] Identify risks

### Week 1 Start
- [ ] Create `week-1-plan.md`
- [ ] Create `week-1/` directory
- [ ] Create `week-1/README.md`
- [ ] Create `week-1/progress.md`
- [ ] Create `week-1/day-1-plan.md`

### Daily (Repeat for Days 2-5)
- [ ] Create `week-1/day-Y-plan.md`
- [ ] Developer reviews plan
- [ ] Developer executes
- [ ] PM verifies and signs off
- [ ] Update `progress.md`

### Week 1 End
- [ ] Create `week-1/summary.md`
- [ ] Update `master-progress.md`
- [ ] Update `master-plan.md` if needed
- [ ] Prepare `week-2-plan.md`

---

## TOOLS & STORAGE

### Recommended Structure
```
project/
├── docs/
│   ├── requirements/
│   ├── architecture/
│   ├── ui_wireframe/
│   └── plan/
│       ├── master-plan.md
│       ├── master-progress.md
│       ├── week-1-plan.md
│       ├── week-2-plan.md
│       ├── week-1/
│       │   ├── README.md
│       │   ├── progress.md
│       │   ├── summary.md
│       │   ├── day-1-plan.md
│       │   ├── day-2-plan.md
│       │   └── ...
│       └── week-2/
│           ├── README.md
│           ├── progress.md
│           └── ...
├── src/
└── tests/
```

---

## SUCCESS INDICATORS

### You're Using These Templates Well When:

✅ Each day's work is independently testable
✅ PM signs off on completion each day
✅ Blockers are caught immediately, not at end of week
✅ Team velocity improves week-to-week
✅ Retrospectives generate actionable improvements
✅ Project stays on timeline or improvements are documented
✅ New team members can jump in by reading week plan + day plan
✅ End of project, all documentation exists for reference

---

**This guide is complete. Start using the templates!**
