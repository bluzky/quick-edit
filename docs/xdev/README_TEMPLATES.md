# Methodology Templates - Complete Package

**Version:** 1.0
**Last Updated:** November 19, 2025
**Total Templates:** 7 core templates + 2 guides

---

## 📦 TEMPLATE FILES

All templates are ready to use. Copy them to your project and customize as needed.

### Core Templates

#### 1. **master-plan.md** (Project Level)
- **Purpose:** Overall project roadmap and timeline
- **When to Create:** Once, at project start
- **When to Update:** Only for major scope/timeline changes
- **File Size:** 3.9K
- **Content:**
  - Project overview & objectives
  - Phase definitions (duration, goals)
  - Timeline overview
  - Weekly breakdown
  - Key milestones
  - Success metrics, risks, dependencies

**Usage:**
- Reference document for entire team
- Shared with stakeholders
- Rarely changes after initial creation

---

#### 2. **master-progress.md** (Project Level)
- **Purpose:** Overall project health dashboard
- **When to Create:** Week 1
- **When to Update:** End of each week
- **File Size:** 4.6K
- **Content:**
  - Current phase status
  - Phase completion percentages
  - Weekly progress summaries
  - Milestone tracking
  - Quality metrics
  - Active blockers & issues
  - Scope changes
  - Resource status
  - Upcoming priorities

**Usage:**
- High-level project status at a glance
- Communication tool for managers/stakeholders
- Updated weekly after retrospective

---

#### 3. **week-X-plan.md** (Weekly Level)
- **Purpose:** Define this week's scope and daily breakdown
- **When to Create:** Start of each week
- **When to Update:** Only if scope changes mid-week
- **File Size:** 3.8K
- **Content:**
  - Week overview (current → target state)
  - Objectives (P0, P1, P2)
  - Daily breakdown (5 days, time estimates)
  - Components to build (services, models, UI)
  - Testing strategy
  - Success metrics & criteria
  - Risks & mitigations
  - Dependencies & prerequisites
  - Preview of next week

**Usage:**
- Planning artifact for development team
- Reference for scope alignment
- Created once per week, stable document

---

#### 4. **week-X/README.md** (Weekly Navigation)
- **Purpose:** Quick reference hub for the week
- **When to Create:** Start of each week
- **When to Update:** When daily plans are created
- **File Size:** 2.3K
- **Content:**
  - Week goal statement
  - Success definition checklist
  - Daily overview (one line each)
  - Components being built (table)
  - Testing requirements summary
  - Quick links to all docs
  - Current status indicators

**Usage:**
- Quick navigation for team
- One-page overview of week
- First document to reference

---

#### 5. **week-X/progress.md** (Weekly Tracking)
- **Purpose:** Track actual execution vs planned work
- **When to Create:** Start of week
- **When to Update:** Every day + end of week
- **File Size:** 3.6K
- **Content:**
  - Daily status (one section per day)
  - Tasks completed (checkboxes)
  - Actual time spent vs estimate
  - Blockers encountered
  - Quality metrics (build, tests)
  - Blockers summary table
  - TODOs for later
  - **Retrospective section (end of week only):**
    - What went well
    - What was underestimated
    - What was faster than expected
    - Surprises & learnings
    - Adjustments for next sprint
  - Week summary & PM sign-off

**Usage:**
- Daily progress log
- Running record of what happened
- Source for end-of-week retrospective

---

#### 6. **week-X/summary.md** (Weekly Retrospective)
- **Purpose:** Comprehensive week retrospective and learnings
- **When to Create:** End of week (Friday)
- **When to Update:** Never (snapshot)
- **File Size:** 5.5K
- **Content:**
  - Executive summary
  - Accomplished objectives & deliverables
  - Code quality metrics
  - Metrics & data (time, velocity, quality)
  - Key decisions made
  - Technical learnings
  - Process improvements identified
  - Blockers & how resolved
  - Risk assessment
  - Team observations
  - Velocity & adjustments for next week
  - Comparative analysis (week vs week)
  - Final grade & sign-off
  - Next steps & carryover items

**Usage:**
- Comprehensive documentation of week
- Communicating wins to stakeholders
- Source of velocity metrics
- Process improvement feedback loop

---

#### 7. **week-X/day-Y-plan.md** (Daily Execution)
- **Purpose:** Detailed daily execution guide and sign-off document
- **When to Create:** Morning of each day
- **When to Update:** During day + end of day
- **File Size:** 6.1K
- **Files per Week:** 5 (one per day)
- **Content:**
  - Day objective (clear goal)
  - Definition of done (testable criteria)
  - Tasks (3-4 per day):
    - What (description)
    - Why (importance)
    - How (architecture & approach)
    - Acceptance criteria
    - Dependencies
  - Testing strategy (unit + manual)
  - Implementation notes
  - Related files (create/modify/delete)
  - Risks & mitigations
  - Time breakdown
  - Documentation references
  - **Execution section (filled during/after):**
    - Start time & progress updates
    - Actual time spent
    - Blockers & solutions
    - Quality results
    - Key learnings
    - PM verification & sign-off

**Usage:**
- Daily execution contract with PM
- Detailed implementation guide
- Sign-off document for PM verification

---

## 📚 GUIDE DOCUMENTS

### **METHODOLOGY_GUIDE.md**
- **Purpose:** Comprehensive guide to the methodology
- **File Size:** 14K
- **Contains:**
  - Document hierarchy explanation
  - Workflow by timeline (before project, each week, each day)
  - Document usage patterns
  - Typical weekly flow & daily workflow
  - Template customization guidance
  - Key principles & best practices
  - Common mistakes to avoid
  - Success indicators
  - Quick start checklist

**When to Read:**
- Team orientation
- Setting up new project
- Understanding the methodology

---

### **TEMPLATES_SUMMARY.txt**
- **Purpose:** Visual summary of all templates
- **File Size:** 22K
- **Contains:**
  - Document hierarchy with ASCII art
  - Purpose, created/updated schedule for each template
  - Weekly structure breakdown
  - Typical week timeline
  - Quick reference table
  - Key principles
  - Success checklists

**When to Read:**
- Quick visual reference
- Wallchart for team room
- Print-friendly overview

---

## 🚀 QUICK START

### For a New Project

1. **Week 0 (Preparation)**
   - [ ] Copy `master-plan.md` to your project
   - [ ] Customize with your project info
   - [ ] Get stakeholder alignment
   - [ ] Create `master-progress.md`

2. **Before Week 1 Starts**
   - [ ] Create `week-1-plan.md`
   - [ ] Copy `week-X/` directory structure to `week-1/`
   - [ ] Customize with Week 1 details

3. **Monday Morning of Week 1**
   - [ ] Create `week-1/day-1-plan.md`
   - [ ] Team reviews plan (15 min alignment)
   - [ ] Development starts

4. **Each Day**
   - [ ] Morning: Create detailed day plan
   - [ ] Execute work
   - [ ] Update progress.md end of day
   - [ ] PM verification & sign-off

5. **Friday End of Week 1**
   - [ ] Create `week-1/summary.md`
   - [ ] Update `master-progress.md`
   - [ ] Conduct retrospective
   - [ ] Prepare `week-2-plan.md`

---

## 📋 FILE ORGANIZATION RECOMMENDATION

```
project/
├── docs/
│   ├── requirements/
│   │   └── [requirement docs]
│   ├── architecture/
│   │   └── [architecture docs]
│   ├── ui_wireframe/
│   │   └── [UI designs]
│   └── plan/
│       ├── master-plan.md          ← Project roadmap
│       ├── master-progress.md      ← Project status
│       │
│       ├── week-1-plan.md          ← Week 1 scope
│       ├── week-1/
│       │   ├── README.md           ← Week 1 overview
│       │   ├── progress.md         ← Week 1 execution log
│       │   ├── summary.md          ← Week 1 retrospective
│       │   ├── day-1-plan.md       ← Monday details
│       │   ├── day-2-plan.md       ← Tuesday details
│       │   ├── day-3-plan.md       ← Wednesday details
│       │   ├── day-4-plan.md       ← Thursday details
│       │   └── day-5-plan.md       ← Friday details
│       │
│       ├── week-2-plan.md
│       ├── week-2/
│       │   ├── README.md
│       │   ├── progress.md
│       │   ├── summary.md
│       │   ├── day-6-plan.md
│       │   └── ...
│       │
│       └── [additional weeks...]
│
├── src/
│   └── [source code]
│
└── tests/
    └── [tests]
```

---

## 🎯 KEY PRINCIPLES

1. **One Purpose Per Document** — Don't try to do everything in one place
2. **Plan Once, Track Results** — Write plan once, update execution log
3. **Daily PM Sign-off** — Catch issues every day, not at end of week
4. **Reference Not Copy** — Link instead of duplicating information
5. **Update Frequently** — Daily progress, weekly retrospective
6. **Easy Navigation** — Use links, tables, clear structure

---

## ✅ CUSTOMIZATION CHECKLIST

Before using these templates on your project:

- [ ] Read METHODOLOGY_GUIDE.md
- [ ] Customize `master-plan.md` with your project details
- [ ] Adjust phase definitions if needed
- [ ] Add any project-specific metrics to templates
- [ ] Brief team on the methodology
- [ ] Create Week 1 plan
- [ ] Start Monday!

---

## 📞 GETTING HELP

### Understanding a Template
→ Read METHODOLOGY_GUIDE.md section "Document Usage Patterns"

### Setting Up a New Project
→ Follow "Quick Start" section above

### Changing the Methodology
→ Read METHODOLOGY_GUIDE.md section "Template Customization"

### Fixing Common Issues
→ Read METHODOLOGY_GUIDE.md section "Common Mistakes & How to Avoid"

---

## 📊 TEMPLATE FILE REFERENCE

| File | Size | Purpose |
|------|------|---------|
| master-plan.md | 3.9K | Project roadmap |
| master-progress.md | 4.6K | Project status |
| week-X-plan.md | 3.8K | Weekly scope |
| week-X/README.md | 2.3K | Weekly navigation |
| week-X/progress.md | 3.6K | Weekly execution log |
| week-X/summary.md | 5.5K | Weekly retrospective |
| week-X/day-Y-plan.md | 6.1K | Daily execution guide |
| METHODOLOGY_GUIDE.md | 14K | Complete methodology guide |
| TEMPLATES_SUMMARY.txt | 22K | Visual summary |

**Total:** ~66K of templates and documentation

---

## 🎉 YOU'RE READY!

All templates are created and documented. Copy them to your project, customize for your needs, and start using them Monday morning.

### Next Steps
1. Copy templates to your project
2. Customize `master-plan.md`
3. Brief your team
4. Create `week-1-plan.md`
5. Start Day 1! 🚀

---

**Questions?** Read METHODOLOGY_GUIDE.md for detailed explanation of each template and how they work together.

**Ready?** Let's build something great! 💪
