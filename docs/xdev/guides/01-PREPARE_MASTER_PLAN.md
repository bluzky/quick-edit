# Phase 1: Prepare Master Plan

**Purpose:** Create the overall project roadmap and timeline  
**Duration:** 2-4 hours  
**When:** Before development starts (Week 0)  
**Outcome:** Complete master-plan.md ready for team alignment  
**Previous:** [00-METHODOLOGY.md](./00-METHODOLOGY.md)  
**Next:** [02-PREPARE_WEEKLY_PLAN.md](./02-PREPARE_WEEKLY_PLAN.md)

---

## Overview

Master Plan defines the entire project at high level:
- What we're building and why
- How long it will take (phases and timeline)
- Success criteria
- Risks and dependencies
- Team structure

**This plan is created ONCE and changes rarely** (only for major scope shifts).

---

## Prerequisites

Before creating master plan, you need:

1. **Clear requirements** (written down)
2. **Rough architecture** (key components)
3. **UI/UX mockups** (or clear description)
4. **Team members identified** (names, roles)
5. **Success definition** (what does "done" look like?)

If any are missing, define them first.

---

## Steps to Create Master Plan

### Step 1: Copy Template

Copy `./templates/master-plan.md` to `./docs/plan/master-plan.md`

Keep the template for reference when creating week plans.

### Step 2: Fill in Basic Information

```markdown
# Master Plan - [Your Project Name]

**Project:** [Full project name]
**Owner:** [Project owner name]
**Start Date:** [Date]
**Target Completion:** [Date]
**Phase:** [Current phase]
```

**Example:**
```markdown
# Master Plan - MyRec Screen Recording App

**Project:** MyRec - macOS Screen Recording with Audio
**Owner:** Daniel Chen
**Start Date:** November 19, 2025
**Target Completion:** December 31, 2025
**Phase:** Phase 1 - Preparation
```

### Step 3: Project Overview

Write 2-3 sentences describing:
- What the project is
- What it delivers
- Why it matters

**Example:**
> MyRec is a lightweight macOS screen recording application that captures video and audio from multiple sources (screen, system audio, microphone). It enables content creators to record tutorials, presentations, and gameplay with professional quality output. The MVP will support full-screen recording with audio mixing, with advanced features (pause/resume, camera overlay) coming in Phase 4.

### Step 4: Key Deliverables

List 3-5 main deliverables:

```markdown
**Key Deliverables:**
- Full-screen video recording with H.264/MP4 output
- System audio capture via ScreenCaptureKit
- Microphone input with real-time audio mixing
- Audio/video synchronization (±50ms accuracy)
- Production-ready application (Phase 3 completion)
```

### Step 5: Success Definition

Define what success means (specific, measurable):

```markdown
**Success Definition:**
- MVP shipped by December 31, 2025
- Core features (screen + audio recording) working
- Zero critical bugs in beta testing
- Users can record 1+ hour continuously
- Audio/video sync within ±50ms tolerance
```

### Step 6: Define Phases

For each phase, fill in:
- **Duration:** How many weeks
- **Objective:** What this phase accomplishes
- **Deliverables:** What exists at end of phase
- **Success Criteria:** How we know phase is done

**Example - Phase 1: Preparation**

```markdown
### Phase 1: Preparation
**Duration:** Week 1 (1 week)
**Objective:** Finalize requirements, design architecture, plan development

**Deliverables:**
- Signed-off requirements document
- High-level architecture diagram
- UI mockups for recording controls
- Week 1-4 development plan

**Success Criteria:**
- [ ] Requirements reviewed with stakeholders
- [ ] Architecture approved by tech lead
- [ ] UI/UX mockups approved by product
- [ ] Team aligned on development approach
```

**Example - Phase 2: Frontend**

```markdown
### Phase 2: Build Frontend
**Duration:** Week 2-3 (2 weeks)
**Objective:** Implement complete UI with mock data and workflows

**Deliverables:**
- Full recording UI implemented
- Region/window selection interface
- Audio source configuration UI
- Recording controls (start, stop, pause)
- Mock data for all user interactions

**Success Criteria:**
- [ ] All UI elements functional
- [ ] User can walk through complete recording flow
- [ ] No build errors/warnings
- [ ] All UI tests passing
```

**Example - Phase 3: Backend & MVP**

```markdown
### Phase 3: Build Backend & Integrate
**Duration:** Week 4-5 (2 weeks)
**Objective:** Implement core backend, integrate with UI, release MVP

**Deliverables:**
- ScreenCaptureKit integration (video)
- Audio capture and mixing (system + mic)
- H.264 video encoding
- MP4 file output
- Live audio/video synchronization
- MVP release (core features working)

**Success Criteria:**
- [ ] Full-screen recording working
- [ ] Audio sources captured and mixed
- [ ] Video output is correct format
- [ ] Audio/video sync within ±50ms
- [ ] 30+ minute recording test successful
```

**Example - Phase 4: Polish & Expand**

```markdown
### Phase 4: Polish & Expand
**Duration:** Week 6-7 (2 weeks)
**Objective:** Polish MVP, add advanced features, production readiness

**Deliverables:**
- Pause/resume functionality
- Camera preview overlay
- Advanced recording controls
- Performance optimization
- Edge case handling
- Production documentation

**Success Criteria:**
- [ ] All edge cases handled
- [ ] Zero known critical bugs
- [ ] Performance optimized
- [ ] User documentation complete
- [ ] Ready for public release
```

### Step 7: Timeline Overview

Create a visual timeline showing phases:

```markdown
## Timeline Overview

```
WEEK 1  |████| Phase 1: Preparation
WEEK 2  |████| Phase 2: Frontend (Part 1)
WEEK 3  |████| Phase 2: Frontend (Part 2)
WEEK 4  |████| Phase 3: Backend & MVP
WEEK 5  |████| Phase 3: Backend & MVP
WEEK 6  |████| Phase 4: Polish
WEEK 7  |████| Phase 4: Expand
```
```

### Step 8: Weekly Breakdown

Create a table showing each week:

```markdown
## Weekly Breakdown

| Week | Phase | Goal | Status |
|------|-------|------|--------|
| Week 1 | Phase 1 | Preparation & planning | ⏳ |
| Week 2 | Phase 2 | Frontend setup & UI | ⏳ |
| Week 3 | Phase 2 | Frontend flows & mocks | ⏳ |
| Week 4 | Phase 3 | Backend core features | ⏳ |
| Week 5 | Phase 3 | Integration & MVP | ⏳ |
| Week 6 | Phase 4 | Polish & refinement | ⏳ |
| Week 7 | Phase 4 | Expand & ship | ⏳ |
```

### Step 9: Milestones

Define major milestones with target dates:

```markdown
## Key Milestones

| Milestone | Target Date | Deliverable | Status |
|-----------|-------------|-------------|--------|
| Requirements finalized | Nov 22, 2025 | Signed requirements | ⏳ |
| Architecture approved | Nov 22, 2025 | Architecture document | ⏳ |
| Frontend prototype | Nov 30, 2025 | UI with mock data | ⏳ |
| MVP release | Dec 12, 2025 | Core features working | ⏳ |
| Final release | Dec 31, 2025 | Production-ready | ⏳ |
```

### Step 10: Scope Definition

Clearly state what's IN scope and what's NOT:

```markdown
## Scope & Constraints

### In Scope (MVP)
- Full-screen recording
- System audio capture
- Microphone input
- Audio/video mixing
- MP4 H.264 output
- Synchronization (±50ms)

### Out of Scope (Post-MVP)
- Region-specific recording (Phase 3+ if time)
- Window-specific recording (Phase 4)
- Camera overlay (Phase 4)
- Pause/resume (Phase 4)
- Advanced effects (future)
```

### Step 11: Risks & Dependencies

Identify potential issues:

```markdown
## Risks & Dependencies

### Critical Risks
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| ScreenCaptureKit limitations | High | Low | Research early, prototype Week 1 |
| Audio sync drift | High | Medium | Test long recordings daily |
| Memory usage (long recording) | Medium | Medium | Profile weekly, optimize as needed |

### External Dependencies
- macOS 13+ (ScreenCaptureKit requirement)
- Honeywell WMS (warehouse integration - outside scope)
- Third-party audio libraries (if used)
```

### Step 12: Team Structure

Document who's involved:

```markdown
## Team Structure

**Team Members:**
- Daniel Chen (Lead Developer, Elixir/Phoenix specialist)
- [Product Owner Name] (Product & Requirements)
- [QA Name] (Testing & Verification)

**Stakeholders:**
- [Executive Name] (Executive sponsor)
- [Customer Name] (End-user representative)
```

### Step 13: Success Metrics

Define how we'll measure success:

```markdown
## Success Metrics

### Quality Metrics
- **Build Status:** 0 errors, 0 warnings (every day)
- **Test Coverage:** 80%+ code coverage
- **Test Pass Rate:** 100% (all tests passing)

### Performance Metrics
- **Sync Accuracy:** ±50ms (acceptable range)
- **Memory Usage:** < 500MB (continuous recording)
- **CPU Usage:** < 30% on M1 Mac (idle)

### Schedule Metrics
- MVP delivered on Dec 12 (on schedule)
- All phases completed by Dec 31
- Zero schedule delays
```

### Step 14: Assumptions & Notes

Document what you're assuming:

```markdown
## Assumptions & Notes

### Key Assumptions
- Team has macOS development experience
- ScreenCaptureKit APIs are available (macOS 13+)
- MP4 output format is sufficient (no ProRes needed)
- Single camera input only (no multi-camera)
- 30fps sufficient (no 60fps requirement)

### Technical Decisions
- Use ScreenCaptureKit (macOS 13+ only)
- Use AVAudioEngine for audio input
- H.264 codec for video encoding
- PCM → AAC for audio encoding
```

---

## Validation Checklist

Before signing off on master plan:

- [ ] All 4 phases defined with clear objectives
- [ ] Duration realistic based on team size and complexity
- [ ] Success criteria are specific and measurable
- [ ] Milestones have target dates
- [ ] Key deliverables listed for each phase
- [ ] Scope clearly defines in/out of MVP
- [ ] Risks identified with mitigations
- [ ] Team members and roles clear
- [ ] Success metrics defined
- [ ] Stakeholders have reviewed and approved
- [ ] Next milestone (Week 1 preparation) clear

---

## Review & Approval

### Who Reviews?
- [ ] Product Owner — Requirements and scope approval
- [ ] Tech Lead — Architecture and feasibility
- [ ] Team Lead/PM — Schedule and team capacity
- [ ] Stakeholders — Timeline and deliverables

### What They Look For
- Timeline is realistic for team size
- Scope is clearly defined (no vague items)
- MVP is achievable in planned timeframe
- Risks are identified with plans
- Success criteria are measurable
- Everyone understands the plan

### Sign-Off
```markdown
**Reviewed by:** [Name] on [Date]
**Approved by:** [Name] on [Date]
**Status:** ✅ Ready for Phase 2
```

---

## After Master Plan

### Before Week 1 Starts
1. Create `master-progress.md` (copy from template)
2. Brief entire team on plan
3. Confirm no questions about phases
4. Get stakeholder alignment

### Ready for Phase 2
→ [02-PREPARE_WEEKLY_PLAN.md](./02-PREPARE_WEEKLY_PLAN.md)

Create the Week 1 plan (Preparation phase)

---

## Common Issues & Solutions

### Issue: Timeline too aggressive
**Solution:** Add buffer weeks, reduce Phase 4 scope, hire more developers

### Issue: Scope too big
**Solution:** Move features to Phase 4 (post-MVP), mark as P2 (nice-to-have)

### Issue: Architecture unclear
**Solution:** Extend Phase 1, do more prototyping, involve tech lead

### Issue: Requirements still changing
**Solution:** Lock requirements before Phase 1 ends, formal change process after

### Issue: Team capacity unknown
**Solution:** Start with one sprint, adjust plan based on actual velocity

---

## Files Created

After this phase:
- ✅ `docs/plan/master-plan.md` — Project roadmap
- ✅ `docs/plan/master-progress.md` — Status dashboard (initialized)
- ✅ Team briefing completed
- ✅ Stakeholder approval obtained

---

**Status:** Phase 1 Complete  
**Next:** [02-PREPARE_WEEKLY_PLAN.md](./02-PREPARE_WEEKLY_PLAN.md) - Create Week 1 Plan
