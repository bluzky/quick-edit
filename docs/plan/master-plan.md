# Master Plan - QuickEdit Image Annotation Editor

**Project:** QuickEdit
**Owner:** Flex
**Start Date:** December 7, 2025
**Target Completion:** February 2026 (8-10 weeks)
**Phase:** Phase 1 - Preparation

---

## PROJECT OVERVIEW

QuickEdit is a lightweight, extensible image annotation editor for macOS designed for screenshot annotation and image markup workflows. It provides a non-destructive editing system where annotations are stored as structured data (JSON) separate from the original image, enabling integration into screenshot apps and standalone annotation tools.

**Key Deliverables:**
- macOS app with 11 built-in annotation tools (select, line, shape, text, number, free draw, blur, highlight, note, insert image, undo/redo)
- JSON-based annotation format for non-destructive editing
- Export system (annotated images + structured data)
- Extensible tool architecture for custom annotations

**Success Definition:**
- User can load an image and annotate it with all 11 tools
- Annotations saved as JSON can be reloaded and edited
- Final annotated image can be exported to PNG/JPG
- Developers can create custom tools by implementing Tool protocol
- Build remains clean: 0 errors, 0 warnings

---

## PROJECT PHASES

### Phase 1: Preparation
**Duration:** Week 1 (1 week)
**Objective:** Finalize requirements, design architecture, create UI mockups, and establish development plan

**Deliverables:**
- Requirements document with all features defined
- Architecture design (data models, tool system, canvas, undo/redo, export)
- UI wireframes and interaction patterns
- Master plan and Week 1 plan

**Success Criteria:**
- [ ] All 11 annotation tools have defined schemas
- [ ] JSON format documented with examples
- [ ] Tool protocol and ToolRegistry architecture defined
- [ ] Canvas rendering pipeline designed
- [ ] UI wireframes approved
- [ ] All design decisions documented

---

### Phase 2: Build Frontend
**Duration:** Week 2-3 (2 weeks)
**Objective:** Implement UI with full workflow using mock annotation data

**Deliverables:**
- Main editor window with canvas view
- Toolbar with tool selection
- Properties panel for tool settings
- Mock annotations rendered on canvas
- All user interactions working (tool switching, selection, resize, move)

**Success Criteria:**
- [ ] User can load an image (mock or sample)
- [ ] All 11 tools appear in toolbar
- [ ] Clicking tools shows properties panel
- [ ] Mock annotations render on canvas
- [ ] Selection tool can "select" mock annotations
- [ ] Canvas supports zoom and pan
- [ ] UI feels responsive and intuitive

---

### Phase 3: Build Backend & MVP
**Duration:** Week 4-6 (3 weeks)
**Objective:** Implement core backend, replace mocks with real data, ship MVP

**Deliverables:**
- Annotation protocol and all 11 annotation types
- AnnotationDocument SwiftData model
- JSON serialization/deserialization
- Real tool implementations (replace mocks incrementally)
- Undo/redo system with command pattern
- Basic export to PNG

**Success Criteria:**
- [ ] All 11 annotation types implemented and Codable
- [ ] Line tool fully functional (draw, edit, save, load)
- [ ] Shape tool fully functional (rectangle, circle)
- [ ] Text tool fully functional
- [ ] Select tool can move/resize real annotations
- [ ] Undo/redo works for all operations
- [ ] Annotations save to JSON and reload correctly
- [ ] **MVP RELEASE:** Export annotated PNG with basic tools working

---

### Phase 4: Polish & Expand
**Duration:** Week 7-8 (2 weeks)
**Objective:** Complete remaining tools, polish UX, handle edge cases

**Deliverables:**
- All advanced tools (number, free draw, blur, highlight, note, insert image)
- Keyboard shortcuts
- Context menus
- Enhanced export (multiple formats)
- Performance optimizations
- Documentation for developers

**Success Criteria:**
- [ ] All 11 tools working in production
- [ ] Keyboard shortcuts functional (Cmd+Z, Cmd+Shift+Z, etc.)
- [ ] Context menu for annotations (delete, duplicate, bring to front)
- [ ] Free draw path smoothing implemented
- [ ] Blur/pixelate rendering optimized
- [ ] Number tool auto-increments correctly
- [ ] Developer can extend with custom tool by following docs

---

## TIMELINE OVERVIEW

```
WEEK 1  |████| Phase 1: Preparation (Requirements, Architecture, UI Design)
WEEK 2  |████| Phase 2: Frontend (UI + Mock Data)
WEEK 3  |████| Phase 2: Frontend (Complete Workflows)
WEEK 4  |████| Phase 3: Backend (Core Models + Basic Tools)
WEEK 5  |████| Phase 3: Backend (Undo/Redo + Export)
WEEK 6  |████| Phase 3: MVP Release (Core Tools Working)
WEEK 7  |████| Phase 4: Polish (Advanced Tools)
WEEK 8  |████| Phase 4: Expand (Final Features + Docs)
```

---

## WEEKLY BREAKDOWN

| Week | Phase | Goal | Status |
|------|-------|------|--------|
| Week 1 | Phase 1 | Requirements, architecture design, UI mockups | ⏳ Planned |
| Week 2 | Phase 2 | Editor UI with toolbar, canvas, mock annotations | ⏳ Planned |
| Week 3 | Phase 2 | Complete UI workflow, tool switching, properties panel | ⏳ Planned |
| Week 4 | Phase 3 | Annotation models, Line/Shape/Text tools functional | ⏳ Planned |
| Week 5 | Phase 3 | Select tool, undo/redo, JSON serialization | ⏳ Planned |
| Week 6 | Phase 3 | MVP: Export PNG, basic tools working end-to-end | ⏳ Planned |
| Week 7 | Phase 4 | Advanced tools (number, free draw, blur, highlight) | ⏳ Planned |
| Week 8 | Phase 4 | Note tool, insert image, keyboard shortcuts, docs | ⏳ Planned |

---

## KEY MILESTONES

| Milestone | Target Date | Deliverable | Status |
|-----------|-------------|-------------|--------|
| Requirements finalized | Dec 13, 2025 | Requirements doc signed off | ⏳ Pending |
| Architecture approved | Dec 13, 2025 | Architecture docs complete | ⏳ Pending |
| UI wireframes complete | Dec 13, 2025 | UI mockups approved | ⏳ Pending |
| Frontend prototype | Dec 27, 2025 | UI with mock data functional | ⏳ Pending |
| MVP release | Jan 17, 2026 | Core tools working + export | ⏳ Pending |
| Final release | Jan 31, 2026 | All tools + polish complete | ⏳ Pending |

---

## SCOPE & CONSTRAINTS

### In Scope (MVP - Week 6)
- Load single image for annotation
- 5 core tools: Select, Line, Shape (rectangle/circle), Text, Undo/Redo
- Basic JSON save/load
- Export to PNG with annotations rendered
- Tool properties panel (color, width, font, etc.)

### In Scope (Final - Week 8)
- All 11 annotation tools
- Advanced features: Number (auto-increment), Free draw (path smoothing), Blur/pixelate
- Note tool with callouts, Insert image, Highlight
- Keyboard shortcuts (Cmd+Z, tool hotkeys)
- Context menus for annotations
- Export multiple formats (PNG, JPG)
- Developer documentation for custom tools

### Out of Scope (Post-MVP)
- Multi-page document support
- Cloud storage integration
- Collaborative editing
- iOS/iPadOS version
- PDF export with vector annotations
- Animation/GIF export
- AI-powered features (auto-blur faces, etc.)
- Plugin marketplace

### Constraints
- **Timeline:** 8 weeks (10 weeks with buffer)
- **Resources:** Single developer
- **Technology:** SwiftUI, SwiftData, macOS 26.1+
- **Environment:** macOS only, Xcode 26.1.1
- **App Sandbox:** Enabled, requires user-selected-files entitlement

---

## RISKS & DEPENDENCIES

### Critical Risks
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| SwiftUI Canvas performance with many annotations | High | Medium | Implement lazy rendering, path simplification, limit max annotations |
| Complex gesture handling (conflicts between tools) | Medium | Medium | Design clear gesture priority, use gesture masks |
| JSON serialization of complex types (fonts, colors) | Medium | Low | Design Codable-friendly data models early in Phase 1 |
| Undo/redo for complex multi-step operations | Medium | Medium | Use command pattern from day 1, test incrementally |
| Blur filter performance on large images | Medium | Low | Use Core Image filters, implement preview-quality modes |

### External Dependencies
- Xcode 26.1.1 (already installed)
- macOS 26.1 SDK (already available)
- SF Symbols for tool icons (built-in)
- No external libraries (SwiftUI/SwiftData only)

---

## TEAM STRUCTURE

**Team Members:**
- Flex — Developer, Designer, PM

**Stakeholders:**
- Flex — Product owner
- Future users: Screenshot app developers, general users needing annotation tools

---

## SUCCESS METRICS

### Quality Metrics
- **Build Status:** 0 errors, 0 warnings at all times
- **Test Coverage:** Core annotation types 80%+, tool implementations 70%+
- **Test Pass Rate:** 100%
- **Daily PM Sign-off:** Every day before 5 PM

### Performance Metrics
- Canvas renders 50+ annotations at 60 FPS
- JSON save/load completes in < 500ms for typical document
- Export to PNG completes in < 2s for 1920x1080 image

### Business Metrics
- MVP delivered by Week 6
- All core features working end-to-end
- Extensibility proven with at least 1 example custom tool
- Documentation complete for developers

---

## ASSUMPTIONS & NOTES

- User has basic familiarity with annotation tools (similar to Skitch, Markup, etc.)
- Initial version targets macOS only; cross-platform later if needed
- SwiftData persistence for documents, JSON for portability/integration
- Image files referenced by path (not embedded in document by default)
- Color representation uses hex strings for JSON compatibility
- Font storage uses font name strings (not full NSFont descriptors)
- Coordinate precision uses CGFloat (Double on 64-bit)
- Z-index auto-assigned based on creation order (manual reordering post-MVP)

---

## GLOSSARY

- **MVP:** Minimum Viable Product — core 5 tools working with save/load/export
- **Annotation:** Visual element overlaid on base image (line, shape, text, etc.)
- **Tool:** User-facing interface for creating/editing annotations
- **Canvas:** Drawing surface displaying base image + annotations
- **Non-destructive:** Original image unchanged; annotations stored separately
- **Definition of Done:** Feature passes unit tests, manual testing, PM verification

---

**Last Updated:** December 7, 2025
**Next Review:** December 13, 2025 (End of Week 1)
