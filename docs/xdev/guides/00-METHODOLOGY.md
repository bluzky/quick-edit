# Phase 0: Development Methodology Overview

**Purpose:** Understand the core methodology before starting any project  
**Time to Read:** 15-20 minutes  
**Audience:** All team members  
**Next Step:** Phase 1 - Prepare Master Plan

---

## Core Methodology

This is a **weekly sprint-based development methodology** designed for focused, iterative projects with daily verification and continuous improvement.

### Key Characteristics

- **Sprint Duration:** 1 week (5 days, Monday-Friday)
- **Verification Model:** PM signs off on work daily (not weekly)
- **Development Approach:** UI-first, incremental, MVP-focused
- **Documentation:** Clear plans, daily tracking, weekly retrospectives
- **Feedback Loop:** Retrospectives inform next week's planning

---

## Why This Methodology

### Problems It Solves

❌ **Problem:** Issues discovered at end of week → Too late to fix  
✅ **Solution:** Daily PM verification → Issues caught immediately

❌ **Problem:** Big-bang integration causes unexpected failures  
✅ **Solution:** Incremental daily integration → Test as you build

❌ **Problem:** Team doesn't improve → Same mistakes each sprint  
✅ **Solution:** Weekly retrospectives → Continuous improvement

❌ **Problem:** Unclear what "done" means → Scope creep  
✅ **Solution:** Definition of done for each day → Clear accountability

---

## Core Principles

### 1. UI First Approach
- Implement UI and mock data to test flow and UX
- Doesn't need to be perfect
- Validates user interaction patterns before backend work
- Enables early feedback

### 2. Incremental Implementation & Testing
- Every backend feature is testable immediately
- Either against mock data or with console logging
- Tests run daily
- Prevents "integration cliff" at end of project

### 3. MVP Focus
- Deliver core functionality ASAP (Week 3-4 typically)
- Then polish and add features iteratively
- Priorities: P0 (must-have), P1 (should-have), P2 (nice-to-have)

### 4. One Purpose Per Document
- Plan documents for planning (rarely change)
- Progress documents for tracking (updated daily)
- Summary documents for retrospectives (weekly)
- Don't mix concerns in one file

### 5. Plan Once, Track Results
- Write plan docs once, change only if scope shifts
- Update progress docs daily with actual results
- Reference instead of copying information
- Minimal duplication

### 6. PM Owns Daily Verification
- PM reviews each day's work (20 minutes)
- Definition of done is specific and testable
- Issues caught daily, not accumulated
- Creates accountability from day 1

### 7. Feedback-Driven Improvement
- End-of-week retrospectives capture learnings
- "What was underestimated?" informs next week's planning
- Velocity metrics improve sprint-to-sprint
- Process improvements are concrete, not vague

---

## 4 Development Phases

### Phase 1: Preparation (1 week)
- Clarify requirements
- Architecture design
- UI mockups
- Development planning
- **Outcome:** Ready to build

### Phase 2: Build Frontend (1-2 weeks)
- Implement UI with full workflow
- Mock data for all features
- All user interactions working end-to-end
- **Outcome:** UI testable, user can validate flow

### Phase 3: Build Backend & Integrate (1-2 weeks)
- Implement core backend functions
- Replace mock data with real API calls incrementally
- MVP release when core functions complete
- Disable UI for incomplete functions
- **Outcome:** MVP shipped with core features working

### Phase 4: Polish & Expand (1-2 weeks)
- Refine UX based on usage
- Handle edge cases
- Add secondary features
- Performance optimization
- **Outcome:** Production-ready product

---

## Document Types & Their Purpose

### Planning Documents
These define what we'll do. Written once, rarely change.

**master-plan.md**
- Overall project timeline (all phases)
- Milestones and success criteria
- Rarely updated after initial creation

**week-X-plan.md**
- This week's scope and objectives
- Daily breakdown with time estimates
- Created Monday morning, stable by Tuesday

**day-Y-plan.md**
- Today's specific tasks and acceptance criteria
- Created morning of each day
- Updated end of day with execution notes

### Tracking Documents
These record what actually happened. Updated daily.

**progress.md**
- Daily status (one section per day)
- Actual time spent vs estimate
- Blockers and issues
- Updated daily + end of week with retrospective

### Summary Documents
These capture learnings. Written once at end of week.

**summary.md**
- Week retrospective and metrics
- What went well, what was underestimated
- Improvements for next sprint
- Created Friday, never updated

---

## Daily Workflow Overview

### Morning (9:00 AM)
1. Create day plan (if not done previous afternoon)
2. Review objectives with PM (5 minutes)
3. Confirm no blockers from yesterday
4. Start implementation

### During Day
1. Follow day plan
2. Run tests incrementally
3. Log progress notes
4. Document blockers immediately

### Afternoon (4:00 PM)
1. Finish implementation
2. Complete all tests
3. Update day plan execution section
4. Update progress.md

### Evening (4:30 PM)
1. PM reviews definition of done (20 minutes)
2. Manual testing
3. PM signs off or requests fixes

### Evening (5:00 PM)
1. Mark day complete in progress.md
2. Prepare notes for next day

---

## Weekly Workflow Overview

### Monday Morning
1. Create week-X-plan.md (weekly scope)
2. Create week-X/ directory structure
3. Create week-X/day-1-plan.md
4. Team alignment (15 minutes)
5. Development starts

### Tuesday-Thursday
- Same daily cycle (plan → execute → PM verify → track)

### Friday Afternoon (4:00 PM)
1. Complete final day's work
2. Ensure all tests pass
3. Build is clean (0 errors, 0 warnings)

### Friday (4:30-5:00 PM) - Retrospective
1. What went well?
2. What was underestimated?
3. What was faster than expected?
4. Surprises and learnings?
5. How can we improve?

### Friday (5:00-6:00 PM)
1. Create summary.md (week analysis)
2. Update master-progress.md (project status)
3. Update master-plan.md (if timeline shifted)

### Friday Evening or Monday Early
1. Prepare week-X+1-plan.md
2. Brief team on next week

---

## Key Metrics & Success Indicators

### Daily Metrics
- ✅ Build status: 0 errors, 0 warnings
- ✅ Test pass rate: 100%
- ✅ PM sign-off obtained
- ✅ Blockers documented if any

### Weekly Metrics
- ✅ Objectives completed (P0, P1)
- ✅ Velocity (tasks/week or hours/week)
- ✅ Build quality maintained
- ✅ No carryover to next week

### Project Metrics
- ✅ Phase completion on schedule
- ✅ Quality trends (errors/warnings decreasing)
- ✅ Velocity trends (improving or stable)
- ✅ Complete documentation

### Success Indicators
- ✅ Each day's work is independently testable
- ✅ Issues caught daily, not at end of week
- ✅ Team velocity improves week-to-week
- ✅ Retrospectives generate improvements
- ✅ Project stays on timeline

---

## Document Locations

All templates are in `./templates/` directory:

**Project Level:**
- `./templates/master-plan.md`
- `./templates/master-progress.md`

**Weekly Level:**
- `./templates/week-X-plan.md`
- `./templates/week-X/README.md`
- `./templates/week-X/progress.md`
- `./templates/week-X/summary.md`

**Daily Level:**
- `./templates/week-X/day-Y-plan.md`

---

## Common Mistakes to Avoid

### ❌ Don't skip day plans
Creates no written contract with PM. Always create written plan.

### ❌ Don't batch progress updates
Update progress.md every day, not Friday. Blockers discovered same day.

### ❌ Don't skip PM daily review
Issues accumulate until Friday. PM reviews each day (20 minutes).

### ❌ Don't make definition of done vague
"Feature works" is too vague. "User can X, Y, Z and tests pass" is testable.

### ❌ Don't include code in day plans
Plans become outdated. Reference architecture, not implementation.

### ❌ Don't skip retrospective
Same mistakes repeated. Retrospective is mandatory, even if brief.

### ❌ Don't over-plan
2-hour planning for 1-week sprint is too much. 15-30 min/day, 1-2 hrs/week.

### ❌ Don't ignore velocity metrics
Adjust estimates based on actual data. Track velocity trends.

---

## Next Steps

1. **Read this file thoroughly** (15-20 minutes)
2. **Understand the 7 core principles** (key to success)
3. **Review document purposes** (plan vs track vs summary)
4. **Ready for Phase 1** → Prepare Master Plan

---

## Quick Reference

| Aspect | Detail |
|--------|--------|
| Sprint Duration | 5 days (Mon-Fri) |
| Phases | 4 (Prep → Frontend → Backend/MVP → Polish) |
| Daily Sign-off | Required (PM verifies each day) |
| Weekly Retrospective | Friday 4:30 PM |
| Templates Location | `./templates/` directory |
| Document Update Frequency | Plans (rarely), Progress (daily), Summary (weekly) |

---

**Status:** Ready for Phase 1  
**Next:** [01-PREPARE_MASTER_PLAN.md](./01-PREPARE_MASTER_PLAN.md)
