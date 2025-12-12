# Canvas → SwiftUI Migration Checklist

**Quick Reference:** Track migration progress at a glance.

---

## Phase 1: Foundation ✅

**Goal:** Build base components without touching existing code.

### Files to Create
- [x] `quickedit/Config/FeatureFlags.swift`
- [x] `quickedit/Views/Annotations/AnnotationViewProtocol.swift`
- [x] `quickedit/Views/Annotations/AnnotationTransformModifier.swift`
- [x] `quickedit/Views/Annotations/CoordinateHelpers.swift`
- [x] `quickedit/Views/Canvas/GridView.swift`

### Tests
- [x] Preview test transform modifier
- [x] Visual test grid (via GridView preview)
- [x] Verify feature flag toggle works
- [ ] Unit test coordinate conversion helpers (optional)

**Status:** Complete
**Completed:** December 12, 2025

---

## Phase 2: Annotation Views ✅

**Goal:** Create SwiftUI view for each annotation type.

### Files to Create
- [x] `quickedit/Views/Annotations/ShapeAnnotationView.swift`
- [x] `quickedit/Views/Annotations/LineAnnotationView.swift`
- [x] `quickedit/Views/Annotations/AnnotationView.swift` (router)
- [ ] `quickedit/Views/Annotations/TextAnnotationView.swift` (deferred - TextAnnotation not yet implemented)
- [ ] `quickedit/Views/Annotations/NumberAnnotationView.swift` (deferred - NumberAnnotation not yet implemented)

### Tests for Each View
- [x] SwiftUI Preview with variations (all views have multiple previews)
- [x] Test at different scales/rotations (via previews)
- [x] Test all customization options (shapes, lines, arrows, styles)
- [ ] Visual comparison with Canvas rendering (Phase 5)

**Status:** Complete
**Completed:** December 12, 2025

---

## Phase 3: Selection System ✅

**Goal:** Replace protocol-based selection with SwiftUI views.

### Files to Create
- [x] `quickedit/Views/Selection/ResizeHandleView.swift`
- [x] `quickedit/Views/Selection/CircleHandleView.swift`
- [x] `quickedit/Views/Selection/ShapeSelectionView.swift`
- [x] `quickedit/Views/Selection/LineSelectionView.swift`
- [x] `quickedit/Views/Selection/SingleSelectionView.swift`
- [x] `quickedit/Views/Selection/MultiSelectionView.swift`

### Tests
- [x] SwiftUI Previews for all selection views
- [x] Verify handles appear at correct positions (via previews)
- [x] Test single selection for all types (Shape, Line)
- [x] Test multi-selection bounding box (via preview)
- [ ] Visual comparison with Canvas selection (Phase 5)

**Status:** Complete
**Completed:** December 12, 2025

---

## Phase 4: New Canvas View ✅

**Goal:** Create SwiftUI canvas that can be toggled with feature flag.

### Files to Create
- [x] `quickedit/Views/Canvas/SwiftUIAnnotationCanvasView.swift`
- [x] `quickedit/Views/Canvas/ToolPreviewView.swift`

### Files to Update
- [x] `quickedit/AnnotationCanvasView.swift` - Add feature flag switch

### Tests
- [x] Verify gestures work (drag, zoom, magnification) - implemented
- [x] Test tool activation - forwarded to tools
- [x] Test annotation creation - integrated with AnnotationCanvas
- [x] SwiftUI Preview with sample annotations
- [ ] Compare with Canvas version (Phase 5)

**Status:** Complete
**Completed:** December 12, 2025

---

## Phase 5: Testing & Validation ⬜

**Goal:** Ensure SwiftUI version matches Canvas version exactly.

### Test Files to Create
- [ ] `quickedit/Tests/VisualComparisonTests.swift`
- [ ] `quickedit/Tests/PerformanceTests.swift`

### Test Coverage
- [ ] Visual comparison (all annotation types)
- [ ] Performance benchmarks (10, 50, 100 annotations)
- [ ] Manual testing checklist (see detailed plan)
- [ ] Zoom levels: 0.1x, 1x, 5x
- [ ] Rotations: 0°, 45°, 90°, 180°
- [ ] Flips: horizontal, vertical

### Acceptance Criteria
- [ ] No visual differences
- [ ] Performance within 20% for ≤50 annotations
- [ ] All gestures work
- [ ] Selection handles correct
- [ ] Undo/redo still works

**Status:** Not Started
**Estimated:** 2-3 days

---

## Phase 6: Cleanup ⬜

**Goal:** Remove old Canvas code, make SwiftUI default.

### Feature Flag Removal
- [ ] Delete `quickedit/Config/FeatureFlags.swift`
- [ ] Update `AnnotationCanvasView.swift` to use SwiftUI directly

### Delete Old Code
- [ ] Delete `CanvasBasedAnnotationCanvasView` struct
- [ ] Remove `drawAnnotations()` method
- [ ] Remove `drawShape()` method
- [ ] Remove `drawLine()` method
- [ ] Remove `drawSelectionHandles()` method
- [ ] Remove `drawArrow()` helper
- [ ] Remove `ScrollWheelPanContainer` (if not needed)

### Update Protocol
- [ ] Remove `drawSelectionHandles()` from `Annotation` protocol
- [ ] Remove implementation from `ShapeAnnotation`
- [ ] Remove implementation from `LineAnnotation`

### Documentation Updates
- [ ] Mark `04-canvas-architecture.md` as deprecated
- [ ] Update `05-swiftui-only-architecture.md` as current
- [ ] Update `docs/architecture/README.md`
- [ ] Update `CLAUDE.md`

**Status:** Not Started
**Estimated:** 1 day

---

## Phase 7: Optimization (Optional) ⬜

**Goal:** Improve performance if benchmarks show issues.

### Only if Performance < Acceptable
- [ ] Implement view caching with `.drawingGroup()`
- [ ] Implement lazy loading for visible annotations
- [ ] Profile with Instruments
- [ ] Optimize hot paths

**Status:** Not Started
**Estimated:** TBD

---

## Overall Progress

```
Phase 1: Foundation          ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛  100% ✅
Phase 2: Annotation Views    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛  100% ✅
Phase 3: Selection System    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛  100% ✅
Phase 4: New Canvas View     ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛  100% ✅
Phase 5: Testing             ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜  0%
Phase 6: Cleanup             ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜  0%
Phase 7: Optimization        ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜  0%

Total Migration: 57% Complete (4/7 phases)
```

---

## Quick Commands

### Toggle Rendering Mode (Debug Only)
```swift
// In debug menu or console:
FeatureFlags.toggle()
```

### Run Performance Tests
```bash
xcodebuild test -project quickedit.xcodeproj \
  -scheme quickedit \
  -only-testing:quickeditTests/RenderingPerformanceTests
```

### Visual Comparison
```bash
xcodebuild test -project quickedit.xcodeproj \
  -scheme quickedit \
  -only-testing:quickeditTests/VisualComparisonTests
```

---

## Dependencies

```
Phase 1 ──→ Phase 2 ──→ Phase 3 ──┐
                                   ├──→ Phase 4 ──→ Phase 5 ──→ Phase 6 ──→ Phase 7
                                   │
                                   └──────────────────────────────────────────────┘
                                   (Can develop in parallel, merge before Phase 4)
```

---

## Rollback

If issues arise:
1. Set `FeatureFlags.useSwiftUIRendering = false`
2. Revert to last stable commit
3. File issues for bugs found

---

## Notes

- **Start with ShapeAnnotationView** (simplest)
- **Keep old code** until Phase 6
- **Test thoroughly** at each phase
- **Can pause** at any time
- **Low risk** - feature flag protects production

---

**Last Updated:** December 12, 2025
**Current Phase:** Planning
**Next Action:** Review plan, then start Phase 1
