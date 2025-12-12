# Migration Plan: Canvas → SwiftUI-Only Architecture

**Created:** December 12, 2025
**Status:** Planning
**Target Completion:** TBD

---

## Overview

This document provides a step-by-step plan to migrate from the Canvas-based rendering architecture to the pure SwiftUI-only architecture described in `05-swiftui-only-architecture.md`.

**Strategy:** Incremental migration with parallel implementation to minimize risk.

---

## Migration Principles

1. **Keep Model Layer Intact** - AnnotationCanvas stays unchanged
2. **Parallel Implementation** - Build new views alongside old code
3. **Feature Flag Toggle** - Switch between old/new rendering during development
4. **Test Thoroughly** - Validate each phase before proceeding
5. **One Annotation Type at a Time** - Incremental approach
6. **Preserve Undo/Redo** - Command pattern remains untouched

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Performance regression | Medium | High | Benchmark before/after, optimize if needed |
| Selection bugs | Low | Medium | Comprehensive manual testing |
| Transform calculation errors | Low | High | Unit tests for coordinate conversion |
| Gesture handling breaks | Low | High | Keep existing gesture code initially |
| Breaking existing features | Low | Critical | Feature flag, parallel implementation |

---

## Phase 1: Foundation & Infrastructure

**Goal:** Build the foundational SwiftUI components without touching existing code.

**Duration:** ~2-3 days

### Tasks

#### 1.1 Create View Protocol & Base Components
```swift
// New file: AnnotationViewProtocol.swift
```

**Files to Create:**
- [ ] `quickedit/Views/Annotations/AnnotationViewProtocol.swift`
- [ ] `quickedit/Views/Annotations/AnnotationTransformModifier.swift`
- [ ] `quickedit/Views/Annotations/CoordinateHelpers.swift`

**Implementation:**
```swift
// AnnotationViewProtocol.swift
protocol AnnotationViewRenderable {
    associatedtype AnnotationViewBody: View
    @ViewBuilder
    func render(canvas: AnnotationCanvas) -> AnnotationViewBody
}

// AnnotationTransformModifier.swift
struct AnnotationTransformModifier: ViewModifier {
    let transform: AnnotationTransform
    let canvas: AnnotationCanvas

    func body(content: Content) -> some View {
        let canvasPosition = canvas.imageToCanvas(transform.position)
        let centerOffset = CGPoint(
            x: content.size.width * canvas.zoomLevel / 2,
            y: content.size.height * canvas.zoomLevel / 2
        )

        content
            .scaleEffect(
                CGSize(
                    width: abs(transform.scale.width) * canvas.zoomLevel,
                    height: abs(transform.scale.height) * canvas.zoomLevel
                ),
                anchor: .topLeading
            )
            .rotationEffect(transform.rotation, anchor: .center)
            .position(
                x: canvasPosition.x + centerOffset.x,
                y: canvasPosition.y + centerOffset.y
            )
    }
}

extension View {
    func applyAnnotationTransform(
        _ transform: AnnotationTransform,
        size: CGSize,
        canvas: AnnotationCanvas
    ) -> some View {
        modifier(AnnotationTransformModifier(transform: transform, canvas: canvas))
    }
}
```

**Testing:**
- [ ] Unit test coordinate conversion helpers
- [ ] Preview test transform modifier with sample rectangles

---

#### 1.2 Create Grid View Component
**File:** `quickedit/Views/Canvas/GridView.swift`

```swift
struct GridView: View {
    let gridSize: CGFloat
    let zoomLevel: CGFloat
    let panOffset: CGPoint

    var body: some View {
        Canvas { context, size in
            // Same implementation as current grid drawing
        }
        .allowsHitTesting(false)
    }
}
```

**Testing:**
- [ ] Visual test at different zoom levels
- [ ] Verify grid doesn't interfere with gestures

---

#### 1.3 Create Feature Flag System
**File:** `quickedit/Config/FeatureFlags.swift`

```swift
struct FeatureFlags {
    static var useSwiftUIRendering: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "UseSwiftUIRendering")
        #else
        return false  // Production uses Canvas for now
        #endif
    }

    static func toggle() {
        #if DEBUG
        let current = useSwiftUIRendering
        UserDefaults.standard.set(!current, forKey: "UseSwiftUIRendering")
        #endif
    }
}
```

**Testing:**
- [ ] Toggle works in debug builds
- [ ] Always false in release builds

---

## Phase 2: Implement Annotation Views (One at a Time)

**Goal:** Create SwiftUI view for each annotation type, starting with simplest.

**Duration:** ~3-5 days

### 2.1 ShapeAnnotationView (Start Here - Simplest)

**File:** `quickedit/Views/Annotations/ShapeAnnotationView.swift`

```swift
struct ShapeAnnotationView: View {
    let annotation: ShapeAnnotation

    var body: some View {
        ShapePath(kind: annotation.shapeKind, cornerRadius: annotation.cornerRadius)
            .fill(annotation.fill)
            .overlay(
                ShapePath(kind: annotation.shapeKind, cornerRadius: annotation.cornerRadius)
                    .stroke(annotation.stroke, lineWidth: annotation.strokeWidth)
            )
            .frame(width: annotation.size.width, height: annotation.size.height)
    }
}

struct ShapePath: Shape {
    let kind: ShapeKind
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        // Reuse existing makeShapePath function
        makeShapePath(kind: kind, size: rect.size, cornerRadius: cornerRadius)
    }
}
```

**Testing:**
- [ ] SwiftUI Preview with all shape kinds
- [ ] Visual comparison with Canvas rendering
- [ ] Test fill/stroke combinations
- [ ] Test at different scales

**Preview Code:**
```swift
#Preview("Shape Annotations") {
    VStack(spacing: 20) {
        ShapeAnnotationView(annotation: ShapeAnnotation(
            zIndex: 0,
            transform: .identity,
            size: CGSize(width: 100, height: 100),
            fill: .blue.opacity(0.2),
            stroke: .blue,
            strokeWidth: 2,
            shapeKind: .rectangle,
            cornerRadius: 0
        ))

        ShapeAnnotationView(annotation: ShapeAnnotation(
            zIndex: 0,
            transform: .identity,
            size: CGSize(width: 100, height: 100),
            fill: .green.opacity(0.2),
            stroke: .green,
            strokeWidth: 2,
            shapeKind: .ellipse,
            cornerRadius: 0
        ))

        // ... more shapes
    }
    .padding()
}
```

---

### 2.2 LineAnnotationView

**File:** `quickedit/Views/Annotations/LineAnnotationView.swift`

```swift
struct LineAnnotationView: View {
    let annotation: LineAnnotation

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main line
            LinePath(start: annotation.startPoint, end: annotation.endPoint)
                .stroke(
                    annotation.stroke,
                    style: StrokeStyle(
                        lineWidth: annotation.strokeWidth,
                        lineCap: annotation.lineCap.cgLineCap,
                        dash: annotation.lineStyle.dashPattern(for: annotation.strokeWidth)
                    )
                )

            // Arrow heads
            if annotation.arrowStartType != .none {
                ArrowHeadView(
                    type: annotation.arrowStartType,
                    size: annotation.arrowSize,
                    color: annotation.stroke,
                    lineWidth: annotation.strokeWidth
                )
                .rotationEffect(Angle(radians: Double(startAngle)))
                .position(annotation.startPoint)
            }

            if annotation.arrowEndType != .none {
                ArrowHeadView(
                    type: annotation.arrowEndType,
                    size: annotation.arrowSize,
                    color: annotation.stroke,
                    lineWidth: annotation.strokeWidth
                )
                .rotationEffect(Angle(radians: Double(endAngle)))
                .position(annotation.endPoint)
            }
        }
        .frame(width: annotation.size.width, height: annotation.size.height)
    }

    private var startAngle: CGFloat {
        let angle = atan2(
            annotation.endPoint.y - annotation.startPoint.y,
            annotation.endPoint.x - annotation.startPoint.x
        )
        return angle + .pi  // Point back toward start
    }

    private var endAngle: CGFloat {
        atan2(
            annotation.endPoint.y - annotation.startPoint.y,
            annotation.endPoint.x - annotation.startPoint.x
        )
    }
}

struct LinePath: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

struct ArrowHeadView: View {
    let type: ArrowType
    let size: CGFloat
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        switch type {
        case .none:
            EmptyView()
        case .open:
            OpenArrowShape(size: size)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        case .filled:
            FilledArrowShape(size: size)
                .fill(color)
        case .diamond:
            DiamondArrowShape(size: size)
                .fill(color)
        case .circle:
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
    }
}

struct OpenArrowShape: Shape {
    let size: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let halfWidth = size * 0.4
        path.move(to: CGPoint(x: -size, y: -halfWidth))
        path.addLine(to: .zero)
        path.addLine(to: CGPoint(x: -size, y: halfWidth))
        return path
    }
}

// ... FilledArrowShape, DiamondArrowShape similar
```

**Testing:**
- [ ] Preview with different arrow types
- [ ] Test line styles (solid, dashed, dotted)
- [ ] Test line caps
- [ ] Visual comparison with Canvas version

---

### 2.3 TextAnnotationView

**File:** `quickedit/Views/Annotations/TextAnnotationView.swift`

```swift
struct TextAnnotationView: View {
    let annotation: TextAnnotation

    var body: some View {
        Text(annotation.text)
            .font(fontFor(annotation))
            .foregroundColor(annotation.color)
            .multilineTextAlignment(annotation.alignment.swiftUIAlignment)
            .frame(
                width: annotation.size.width,
                height: annotation.size.height,
                alignment: annotation.alignment.frameAlignment
            )
            .background(annotation.backgroundColor)
    }

    private func fontFor(_ annotation: TextAnnotation) -> Font {
        let descriptor = NSFontDescriptor(name: annotation.fontName, size: annotation.fontSize)
        if annotation.isBold && annotation.isItalic {
            return Font(descriptor.withSymbolicTraits([.bold, .italic]) ?? descriptor)
        } else if annotation.isBold {
            return Font(descriptor.withSymbolicTraits(.bold) ?? descriptor)
        } else if annotation.isItalic {
            return Font(descriptor.withSymbolicTraits(.italic) ?? descriptor)
        }
        return Font(descriptor)
    }
}

extension TextAlignment {
    var swiftUIAlignment: SwiftUI.TextAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        case .justify: return .leading  // SwiftUI doesn't have justify
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        case .justify: return .leading
        }
    }
}
```

**Testing:**
- [ ] Preview with different fonts
- [ ] Test bold/italic combinations
- [ ] Test alignment options
- [ ] Test multiline text

**Note:** Text annotation model needs to be created first (currently not in codebase).

---

### 2.4 Create Annotation View Router

**File:** `quickedit/Views/Annotations/AnnotationView.swift`

```swift
struct AnnotationView: View {
    let annotation: any Annotation
    let canvas: AnnotationCanvas

    var body: some View {
        Group {
            if let shape = annotation as? ShapeAnnotation {
                ShapeAnnotationView(annotation: shape)
            } else if let line = annotation as? LineAnnotation {
                LineAnnotationView(annotation: line)
            } else if let text = annotation as? TextAnnotation {
                TextAnnotationView(annotation: text)
            } else {
                // Fallback for unimplemented types
                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: annotation.size.width, height: annotation.size.height)
                    .overlay(
                        Text("Unsupported: \(String(describing: type(of: annotation)))")
                            .font(.caption)
                    )
            }
        }
        .applyAnnotationTransform(
            annotation.transform,
            size: annotation.size,
            canvas: canvas
        )
    }
}
```

---

## Phase 3: Selection System

**Goal:** Replace protocol-based selection rendering with SwiftUI views.

**Duration:** ~2 days

### 3.1 Create Selection Handle Components

**File:** `quickedit/Views/Selection/ResizeHandleView.swift`

```swift
struct ResizeHandleView: View {
    let handle: ResizeHandle
    let zoomLevel: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(
                width: ResizeHandleLayout.handleSize / zoomLevel,
                height: ResizeHandleLayout.handleSize / zoomLevel
            )
            .overlay(
                Rectangle()
                    .strokeBorder(Color.accentColor, lineWidth: 1)
            )
    }
}

struct CircleHandleView: View {
    let zoomLevel: CGFloat

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(
                width: ResizeHandleLayout.handleSize / zoomLevel,
                height: ResizeHandleLayout.handleSize / zoomLevel
            )
            .overlay(
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            )
    }
}
```

---

### 3.2 Create Type-Specific Selection Views

**File:** `quickedit/Views/Selection/ShapeSelectionView.swift`

```swift
struct ShapeSelectionView: View {
    let annotation: ShapeAnnotation
    let canvas: AnnotationCanvas

    var body: some View {
        let rect = canvas.canvasRect(for: annotation)

        ZStack {
            // Selection outline
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 1)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

            // 8 resize handles
            ForEach(ResizeHandle.allCases, id: \.self) { handle in
                ResizeHandleView(handle: handle, zoomLevel: canvas.zoomLevel)
                    .position(handlePosition(for: handle, in: rect))
            }
        }
    }

    private func handlePosition(for handle: ResizeHandle, in rect: CGRect) -> CGPoint {
        switch handle {
        case .topLeft:      return CGPoint(x: rect.minX, y: rect.minY)
        case .top:          return CGPoint(x: rect.midX, y: rect.minY)
        case .topRight:     return CGPoint(x: rect.maxX, y: rect.minY)
        case .left:         return CGPoint(x: rect.minX, y: rect.midY)
        case .right:        return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomLeft:   return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottom:       return CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomRight:  return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }
}
```

**File:** `quickedit/Views/Selection/LineSelectionView.swift`

```swift
struct LineSelectionView: View {
    let annotation: LineAnnotation
    let canvas: AnnotationCanvas

    var body: some View {
        let controls = annotation.controlPoints()

        ZStack {
            // Selection line
            if controls.count >= 2 {
                let start = canvas.imageToCanvas(controls[0].position)
                let end = canvas.imageToCanvas(controls[1].position)

                Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                .stroke(Color.accentColor, lineWidth: 1)
            }

            // Endpoint handles (circles)
            ForEach(controls, id: \.id) { control in
                CircleHandleView(zoomLevel: canvas.zoomLevel)
                    .position(canvas.imageToCanvas(control.position))
            }
        }
    }
}
```

---

### 3.3 Create Selection Container View

**File:** `quickedit/Views/Selection/SelectionHandlesView.swift`

```swift
struct SelectionHandlesView: View {
    @ObservedObject var canvas: AnnotationCanvas

    var body: some View {
        ZStack {
            if canvas.selectedAnnotationIDs.count == 1,
               let id = canvas.selectedAnnotationIDs.first,
               let annotation = canvas.annotation(withID: id) {
                // Single selection: type-specific handles
                SingleSelectionView(annotation: annotation, canvas: canvas)
            } else if canvas.selectedAnnotationIDs.count > 1 {
                // Multi-selection: bounding box
                MultiSelectionView(
                    annotationIDs: canvas.selectedAnnotationIDs,
                    canvas: canvas
                )
            }
        }
        .allowsHitTesting(false)  // Handles are visual only for now
    }
}

struct SingleSelectionView: View {
    let annotation: any Annotation
    let canvas: AnnotationCanvas

    var body: some View {
        if let shape = annotation as? ShapeAnnotation {
            ShapeSelectionView(annotation: shape, canvas: canvas)
        } else if let line = annotation as? LineAnnotation {
            LineSelectionView(annotation: line, canvas: canvas)
        }
        // Add more types as implemented
    }
}

struct MultiSelectionView: View {
    let annotationIDs: Set<UUID>
    let canvas: AnnotationCanvas

    var body: some View {
        if let bounds = canvas.selectionBoundingBox(for: annotationIDs) {
            let origin = canvas.imageToCanvas(bounds.origin)
            let size = CGSize(
                width: bounds.width * canvas.zoomLevel,
                height: bounds.height * canvas.zoomLevel
            )

            Rectangle()
                .stroke(Color.accentColor, lineWidth: 1)
                .frame(width: size.width, height: size.height)
                .position(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
        }
    }
}
```

---

## Phase 4: New Canvas View with Feature Flag

**Goal:** Create new SwiftUI-based canvas view that can be toggled with feature flag.

**Duration:** ~1 day

### 4.1 Create SwiftUI Canvas View

**File:** `quickedit/Views/Canvas/SwiftUIAnnotationCanvasView.swift`

```swift
struct SwiftUIAnnotationCanvasView: View {
    @ObservedObject var canvas: AnnotationCanvas

    @State private var dragState: DragState = .idle
    @State private var initialZoom: CGFloat = ZoomConfig.defaultZoom
    @State private var magnifyAnchor: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Background
                Color(red: 0xf5/255, green: 0xf5/255, blue: 0xf5/255)
                    .ignoresSafeArea()

                // Grid overlay
                if canvas.showGrid {
                    GridView(
                        gridSize: canvas.gridSize,
                        zoomLevel: canvas.zoomLevel,
                        panOffset: canvas.panOffset
                    )
                }

                // Annotations layer
                ForEach(
                    canvas.annotations.sorted(by: { $0.zIndex < $1.zIndex }),
                    id: \.id
                ) { annotation in
                    if annotation.visible {
                        AnnotationView(annotation: annotation, canvas: canvas)
                    }
                }

                // Selection handles layer
                SelectionHandlesView(canvas: canvas)

                // Tool preview layer (if needed)
                if let tool = canvas.activeTool {
                    ToolPreviewView(tool: tool, canvas: canvas)
                }
            }
            .gesture(dragGesture)
            .simultaneousGesture(magnificationGesture)
            .onAppear {
                canvas.updateCanvasSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                canvas.updateCanvasSize(newSize)
            }
        }
    }

    // Gesture handlers (same as before)
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if case .idle = dragState {
                    dragState = .active(start: value.startLocation)
                    canvas.activeTool?.onMouseDown(at: value.startLocation, on: canvas)
                }

                if canvas.activeTool != nil {
                    canvas.activeTool?.onMouseDrag(to: value.location, on: canvas)
                }
            }
            .onEnded { value in
                defer { dragState = .idle }

                canvas.activeTool?.onMouseUp(at: value.location, on: canvas)

                // Handle tap selection
                if canvas.activeTool == nil {
                    let distance = hypot(
                        value.translation.width,
                        value.translation.height
                    )
                    if distance < 2 {
                        handleTap(at: value.startLocation)
                    }
                }
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if magnifyAnchor == nil {
                    magnifyAnchor = canvas.canvasSize.center
                    initialZoom = canvas.zoomLevel
                }
                let level = initialZoom * value
                canvas.setZoom(level, centerOn: magnifyAnchor)
            }
            .onEnded { _ in
                magnifyAnchor = nil
            }
    }

    private func handleTap(at location: CGPoint) {
        if let hit = canvas.annotation(at: location) {
            canvas.toggleSelection(for: hit.id)
        } else {
            canvas.clearSelection()
        }
    }
}

enum DragState {
    case idle
    case active(start: CGPoint)
}

struct ToolPreviewView: View {
    let tool: any AnnotationTool
    let canvas: AnnotationCanvas

    var body: some View {
        // For now, fallback to Canvas-based preview
        Canvas { context, size in
            var mutableContext = context
            tool.renderPreview(in: &mutableContext, canvas: canvas)
        }
        .allowsHitTesting(false)
    }
}
```

---

### 4.2 Update AnnotationCanvasView to Use Feature Flag

**File:** `quickedit/AnnotationCanvasView.swift` (Update existing)

```swift
struct AnnotationCanvasView: View {
    @ObservedObject var canvas: AnnotationCanvas

    var body: some View {
        if FeatureFlags.useSwiftUIRendering {
            SwiftUIAnnotationCanvasView(canvas: canvas)
        } else {
            CanvasBasedAnnotationCanvasView(canvas: canvas)
        }
    }
}

// Rename existing implementation
struct CanvasBasedAnnotationCanvasView: View {
    // ... existing Canvas-based code
}
```

---

## Phase 5: Testing & Validation

**Goal:** Ensure SwiftUI version works identically to Canvas version.

**Duration:** ~2-3 days

### 5.1 Visual Comparison Tests

**Test Cases:**
- [ ] Create test annotation sets
- [ ] Render side-by-side (Canvas vs SwiftUI)
- [ ] Screenshot comparison
- [ ] Test all annotation types
- [ ] Test at different zoom levels (0.1x, 1x, 5x)
- [ ] Test rotations (0°, 45°, 90°, 180°)
- [ ] Test flips (horizontal, vertical)

**Test File:** `quickedit/Tests/VisualComparisonTests.swift`

```swift
import XCTest
@testable import quickedit

final class VisualComparisonTests: XCTestCase {
    func testShapeRenderingMatch() {
        // Create test canvas with shapes
        // Enable Canvas rendering, take snapshot
        // Enable SwiftUI rendering, take snapshot
        // Compare images
    }

    // ... more tests
}
```

---

### 5.2 Performance Benchmarks

**File:** `quickedit/Tests/PerformanceTests.swift`

```swift
final class RenderingPerformanceTests: XCTestCase {
    func testCanvasRendering_10Annotations() {
        measure {
            // Render with Canvas
        }
    }

    func testSwiftUIRendering_10Annotations() {
        measure {
            // Render with SwiftUI
        }
    }

    func testCanvasRendering_50Annotations() {
        measure {
            // Render with Canvas
        }
    }

    func testSwiftUIRendering_50Annotations() {
        measure {
            // Render with SwiftUI
        }
    }

    func testCanvasRendering_100Annotations() {
        measure {
            // Render with Canvas
        }
    }

    func testSwiftUIRendering_100Annotations() {
        measure {
            // Render with SwiftUI
        }
    }
}
```

**Acceptance Criteria:**
- SwiftUI should be within 20% of Canvas performance for ≤50 annotations
- No crashes or visual glitches
- Selection handles appear correctly
- Gestures work identically

---

### 5.3 Manual Testing Checklist

**Test Scenarios:**
- [ ] Create annotation of each type
- [ ] Select annotation
- [ ] Move annotation
- [ ] Resize annotation (corners and edges)
- [ ] Rotate annotation (ShapeAnnotation only)
- [ ] Delete annotation
- [ ] Undo/redo
- [ ] Zoom in/out
- [ ] Pan canvas
- [ ] Multi-select
- [ ] Tool switching
- [ ] Grid toggle
- [ ] Snap to grid
- [ ] Copy/paste (if implemented)
- [ ] Export (rendering)

---

## Phase 6: Cleanup & Migration

**Goal:** Remove old Canvas code, make SwiftUI the default.

**Duration:** ~1 day

### 6.1 Remove Feature Flag

```swift
// Delete FeatureFlags.swift
// Update AnnotationCanvasView.swift
struct AnnotationCanvasView: View {
    @ObservedObject var canvas: AnnotationCanvas

    var body: some View {
        SwiftUIAnnotationCanvasView(canvas: canvas)
    }
}
```

---

### 6.2 Delete Old Canvas Rendering Code

**Files to Delete/Modify:**
- [ ] Delete `CanvasBasedAnnotationCanvasView` from `AnnotationCanvasView.swift`
- [ ] Remove `drawAnnotations()` method
- [ ] Remove `drawShape()` method
- [ ] Remove `drawLine()` method
- [ ] Remove `drawSelectionHandles()` method
- [ ] Remove `drawArrow()` helper
- [ ] Remove `ScrollWheelPanContainer` (if not needed)

---

### 6.3 Update Annotation Protocol

**Remove no longer needed:**
```swift
protocol Annotation: AnyObject, Identifiable {
    // ...

    // DELETE THIS:
    // func drawSelectionHandles(in context: inout GraphicsContext, canvas: AnnotationCanvas)
}
```

**Update implementations:**
- [ ] Remove `drawSelectionHandles()` from `ShapeAnnotation`
- [ ] Remove `drawSelectionHandles()` from `LineAnnotation`

---

### 6.4 Update Documentation

**Files to Update:**
- [ ] `docs/architecture/04-canvas-architecture.md` - Mark as deprecated
- [ ] `docs/architecture/05-swiftui-only-architecture.md` - Mark as current
- [ ] `docs/architecture/README.md` - Update index
- [ ] `CLAUDE.md` - Update architecture summary

---

## Phase 7: Optimization (Optional)

**Goal:** Improve performance if needed.

**Duration:** TBD (only if performance issues found)

### 7.1 View Caching

If rendering 50+ annotations is slow:

```swift
struct CachedAnnotationView: View {
    let annotation: any Annotation
    let canvas: AnnotationCanvas

    var body: some View {
        AnnotationView(annotation: annotation, canvas: canvas)
            .id(annotation.id)  // Cache based on ID
            .drawingGroup()     // Render to off-screen buffer
    }
}
```

---

### 7.2 Lazy Loading

For 100+ annotations:

```swift
struct LazyAnnotationLayer: View {
    let annotations: [any Annotation]
    let canvas: AnnotationCanvas
    let visibleRect: CGRect

    var body: some View {
        ForEach(visibleAnnotations, id: \.id) { annotation in
            AnnotationView(annotation: annotation, canvas: canvas)
        }
    }

    private var visibleAnnotations: [any Annotation] {
        annotations.filter { annotation in
            visibleRect.intersects(annotation.bounds)
        }
    }
}
```

---

## Success Criteria

The migration is complete when:

- ✅ All annotation types render correctly in SwiftUI
- ✅ Selection handles work for all types
- ✅ All gestures work (drag, zoom, pan)
- ✅ Undo/redo still works
- ✅ Performance is acceptable (< 20% slower than Canvas for ≤50 annotations)
- ✅ No visual differences from Canvas version
- ✅ All tests pass
- ✅ Old Canvas code removed
- ✅ Documentation updated

---

## Rollback Plan

If migration fails or introduces critical bugs:

1. **Immediate Rollback:**
   ```swift
   // Revert FeatureFlags.useSwiftUIRendering to false
   ```

2. **Keep Old Code:**
   - Don't delete Canvas code until SwiftUI version is proven stable
   - Feature flag allows instant switch back

3. **Git Strategy:**
   - Each phase is a separate commit
   - Can revert to any phase if needed
   - Tag stable points: `migration-phase1-complete`, etc.

---

## Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Foundation | 2-3 days | None |
| Phase 2: Annotation Views | 3-5 days | Phase 1 complete |
| Phase 3: Selection System | 2 days | Phase 2 complete |
| Phase 4: New Canvas View | 1 day | Phase 1-3 complete |
| Phase 5: Testing | 2-3 days | Phase 4 complete |
| Phase 6: Cleanup | 1 day | Phase 5 complete |
| Phase 7: Optimization | TBD | Only if needed |
| **Total** | **11-15 days** | Sequential execution |

---

## Open Questions

1. **Text Annotation:** Need to implement `TextAnnotation` model first?
2. **Number Annotation:** Same as text - model needed?
3. **Tool Preview:** Keep Canvas-based or migrate to SwiftUI?
4. **Hit Testing:** Can we use SwiftUI's built-in hit testing?
5. **Accessibility:** How to expose annotations to VoiceOver?

---

## Next Steps

1. **Review this plan** with team/stakeholders
2. **Create GitHub issues** for each phase
3. **Set up feature flag** in codebase
4. **Start Phase 1:** Build foundation components
5. **Daily standup:** Track progress, adjust timeline

---

## Notes

- This is an **incremental, low-risk migration**
- Can pause at any phase if issues arise
- Feature flag allows A/B testing in production
- Performance can be optimized later if needed
- Focus on correctness first, speed second

---

**Status:** Ready for implementation
**Next Review:** After Phase 1 completion
