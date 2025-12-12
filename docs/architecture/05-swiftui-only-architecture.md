# SwiftUI-Only Architecture

**Created:** December 12, 2025
**Status:** Draft Proposal

## Overview

This document proposes a **pure SwiftUI architecture** that eliminates the Canvas/GraphicsContext approach in favor of declarative SwiftUI views. The goal is a simpler, more maintainable implementation that leverages SwiftUI's built-in capabilities.

---

## Key Changes from Canvas Architecture

### Before (Canvas-based)
```swift
Canvas { context, size in
    // Manual path drawing
    context.fill(path, with: .color(annotation.fill))
    // Manual transform application
    contextCopy.translateBy(x: centerX, y: centerY)
    contextCopy.rotate(by: transform.rotation)
}
```

### After (SwiftUI-only)
```swift
ZStack {
    ForEach(annotations) { annotation in
        AnnotationView(annotation: annotation)
            .position(...)
            .rotationEffect(...)
            .scaleEffect(...)
    }
}
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        ContentView (UI)                      │
│  ┌─────────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │  MainToolbar    │  │ Properties   │  │ Color/Settings │ │
│  └────────┬────────┘  └──────┬───────┘  └───────┬────────┘ │
│           │                  │                   │          │
│           └──────────────────┼───────────────────┘          │
│                              │                              │
│                    ┌─────────▼─────────┐                    │
│                    │ EditorViewModel   │                    │
│                    │ @ObservedObject   │                    │
│                    └─────────┬─────────┘                    │
└──────────────────────────────┼──────────────────────────────┘
                               │
                    ┌──────────▼───────────┐
                    │  AnnotationCanvas    │
                    │  (Model + State)     │
                    │  - SAME AS BEFORE -  │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │ AnnotationCanvasView │
                    │   (Pure SwiftUI)     │
                    └──────────┬───────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼────────┐    ┌────────▼────────┐    ┌──────▼──────┐
│AnnotationView  │    │ SelectionView   │    │  GridView   │
│  (Protocol)    │    │  (Handles)      │    │  (Dots)     │
└───────┬────────┘    └─────────────────┘    └─────────────┘
        │
┌───────┴────────────────────────┐
│                                │
│  ShapeAnnotationView      LineAnnotationView
│  TextAnnotationView       NumberAnnotationView
│  (SwiftUI Views)          (etc...)
```

---

## Core Components

### 1. AnnotationCanvas (Model) - **UNCHANGED**

The model layer remains the same:
- Stores all canvas state (`@Published` properties)
- Provides 30+ public APIs
- Manages command history (undo/redo)
- Handles coordinate conversions
- **No changes needed!**

**Why keep it:** The model layer is well-designed and doesn't need changes for the view layer refactor.

---

### 2. AnnotationCanvasView (NEW - Pure SwiftUI)

**Responsibilities:**
- Render annotations using SwiftUI views
- Handle mouse/gesture events
- Display selection handles
- Show grid overlay

```swift
struct AnnotationCanvasView: View {
    @ObservedObject var canvas: AnnotationCanvas
    @State private var dragState: DragState = .idle

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Background
                Color(red: 0xf5/255, green: 0xf5/255, blue: 0xf5/255)

                // Grid overlay
                if canvas.showGrid {
                    GridView(
                        gridSize: canvas.gridSize,
                        zoomLevel: canvas.zoomLevel,
                        panOffset: canvas.panOffset
                    )
                }

                // Annotations layer
                ForEach(canvas.annotations.sorted(by: { $0.zIndex < $1.zIndex })) { annotation in
                    AnnotationView(annotation: annotation, canvas: canvas)
                        .opacity(annotation.visible ? 1 : 0)
                }

                // Selection handles layer
                SelectionHandlesView(canvas: canvas)

                // Tool preview layer
                if let tool = canvas.activeTool {
                    ToolPreviewView(tool: tool, canvas: canvas)
                }
            }
            .gesture(dragGesture)
            .gesture(magnificationGesture)
            .onAppear {
                canvas.updateCanvasSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                canvas.updateCanvasSize(newSize)
            }
        }
    }
}
```

---

### 3. AnnotationView (Protocol-Based View)

Each annotation type renders itself as a SwiftUI view:

```swift
protocol AnnotationViewRenderable {
    @ViewBuilder
    func render(canvas: AnnotationCanvas) -> some View
}

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
            }
            // ... more types
        }
        .applyTransform(annotation.transform, canvas: canvas)
    }
}
```

---

### 4. Concrete Annotation Views

#### ShapeAnnotationView
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
        makeShapePath(kind: kind, size: rect.size, cornerRadius: cornerRadius)
    }
}
```

#### LineAnnotationView
```swift
struct LineAnnotationView: View {
    let annotation: LineAnnotation

    var body: some View {
        ZStack {
            // Line path
            Path { path in
                path.move(to: annotation.startPoint)
                path.addLine(to: annotation.endPoint)
            }
            .stroke(
                annotation.stroke,
                style: StrokeStyle(
                    lineWidth: annotation.strokeWidth,
                    lineCap: annotation.lineCap.strokeCap,
                    dash: annotation.lineStyle.dashPattern(for: annotation.strokeWidth)
                )
            )

            // Arrow heads
            if annotation.arrowEndType != .none {
                ArrowHeadView(
                    type: annotation.arrowEndType,
                    size: annotation.arrowSize,
                    color: annotation.stroke,
                    angle: lineAngle
                )
                .position(annotation.endPoint)
            }

            if annotation.arrowStartType != .none {
                ArrowHeadView(
                    type: annotation.arrowStartType,
                    size: annotation.arrowSize,
                    color: annotation.stroke,
                    angle: lineAngle + .pi
                )
                .position(annotation.startPoint)
            }
        }
        .frame(width: annotation.size.width, height: annotation.size.height)
    }

    private var lineAngle: CGFloat {
        atan2(annotation.endPoint.y - annotation.startPoint.y,
              annotation.endPoint.x - annotation.startPoint.x)
    }
}
```

#### TextAnnotationView
```swift
struct TextAnnotationView: View {
    let annotation: TextAnnotation

    var body: some View {
        Text(annotation.text)
            .font(annotation.font.swiftUIFont(size: annotation.fontSize))
            .foregroundColor(annotation.color)
            .multilineTextAlignment(annotation.alignment.textAlignment)
            .frame(width: annotation.size.width, height: annotation.size.height)
            .background(annotation.backgroundColor)
    }
}
```

---

### 5. Transform Application (View Extension)

A custom view modifier handles all coordinate space conversions and transforms:

```swift
struct AnnotationTransformModifier: ViewModifier {
    let transform: AnnotationTransform
    let canvas: AnnotationCanvas

    func body(content: Content) -> some View {
        let canvasPosition = canvas.imageToCanvas(transform.position)

        content
            .scaleEffect(
                x: transform.scale.width * canvas.zoomLevel,
                y: transform.scale.height * canvas.zoomLevel,
                anchor: .topLeading
            )
            .rotationEffect(transform.rotation, anchor: .center)
            .position(
                x: canvasPosition.x,
                y: canvasPosition.y
            )
    }
}

extension View {
    func applyTransform(_ transform: AnnotationTransform, canvas: AnnotationCanvas) -> some View {
        modifier(AnnotationTransformModifier(transform: transform, canvas: canvas))
    }
}
```

---

### 6. Selection Handles View

Selection rendering moves from protocol method to dedicated view:

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
            } else if !canvas.selectedAnnotationIDs.isEmpty {
                // Multi-selection: bounding box outline
                MultiSelectionView(annotationIDs: canvas.selectedAnnotationIDs, canvas: canvas)
            }
        }
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
    }
}

struct ShapeSelectionView: View {
    let annotation: ShapeAnnotation
    let canvas: AnnotationCanvas

    var body: some View {
        let canvasRect = canvas.canvasRect(for: annotation)

        ZStack {
            // Outline
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 1)
                .frame(width: canvasRect.width, height: canvasRect.height)
                .position(x: canvasRect.midX, y: canvasRect.midY)

            // 8 resize handles
            ForEach(ResizeHandle.allCases, id: \.self) { handle in
                ResizeHandleView(handle: handle)
                    .position(handlePosition(for: handle, in: canvasRect))
            }
        }
    }

    private func handlePosition(for handle: ResizeHandle, in rect: CGRect) -> CGPoint {
        let x: CGFloat
        let y: CGFloat

        switch handle {
        case .topLeft:      x = rect.minX; y = rect.minY
        case .top:          x = rect.midX; y = rect.minY
        case .topRight:     x = rect.maxX; y = rect.minY
        case .left:         x = rect.minX; y = rect.midY
        case .right:        x = rect.maxX; y = rect.midY
        case .bottomLeft:   x = rect.minX; y = rect.maxY
        case .bottom:       x = rect.midX; y = rect.maxY
        case .bottomRight:  x = rect.maxX; y = rect.maxY
        }

        return CGPoint(x: x, y: y)
    }
}

struct ResizeHandleView: View {
    let handle: ResizeHandle

    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .overlay(
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 1)
            )
    }
}
```

---

### 7. Grid View

```swift
struct GridView: View {
    let gridSize: CGFloat
    let zoomLevel: CGFloat
    let panOffset: CGPoint

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let spacing = gridSize * zoomLevel
                guard spacing >= 4 else { return }

                let startX = fmod(panOffset.x, spacing)
                let startY = fmod(panOffset.y, spacing)

                let dotColor = Color(red: 0xc4/255, green: 0xc4/255, blue: 0xc4/255)
                let dotRadius: CGFloat = 1.0

                var x = startX
                while x < size.width {
                    var y = startY
                    while y < size.height {
                        let dotRect = CGRect(
                            x: x - dotRadius,
                            y: y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2
                        )
                        context.fill(Path(ellipseIn: dotRect), with: .color(dotColor))
                        y += spacing
                    }
                    x += spacing
                }
            }
        }
        .allowsHitTesting(false)
    }
}
```

**Note:** Grid uses Canvas for efficiency (drawing hundreds of dots). This is acceptable since it's a static overlay.

---

### 8. Tool Preview View

```swift
struct ToolPreviewView: View {
    let tool: any AnnotationTool
    let canvas: AnnotationCanvas

    var body: some View {
        // Tools can optionally provide SwiftUI preview
        if let swiftUIPreview = tool as? SwiftUIPreviewable {
            swiftUIPreview.previewView(canvas: canvas)
        } else {
            // Fallback to Canvas-based preview for complex tools
            Canvas { context, size in
                var mutableContext = context
                tool.renderPreview(in: &mutableContext, canvas: canvas)
            }
            .allowsHitTesting(false)
        }
    }
}

protocol SwiftUIPreviewable {
    @ViewBuilder
    func previewView(canvas: AnnotationCanvas) -> some View
}
```

---

## Gesture Handling

### Mouse Events

```swift
extension AnnotationCanvasView {
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragState == .idle {
                    dragState = .active(start: value.startLocation)
                    canvas.activeTool?.onMouseDown(at: value.startLocation, on: canvas)
                }

                canvas.activeTool?.onMouseDrag(to: value.location, on: canvas)
            }
            .onEnded { value in
                defer { dragState = .idle }

                canvas.activeTool?.onMouseUp(at: value.location, on: canvas)

                // Handle tap selection if no tool active
                if canvas.activeTool == nil {
                    handleTapSelection(at: value.startLocation)
                }
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                // Zoom logic (same as before)
            }
    }

    private func handleTapSelection(at location: CGPoint) {
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
```

---

## Benefits of SwiftUI-Only Approach

### ✅ Advantages

1. **Simpler Code**
   - No manual GraphicsContext manipulation
   - Declarative view composition
   - SwiftUI handles transforms automatically

2. **Better Maintainability**
   - Each annotation type is a standalone view
   - Easier to understand and modify
   - Standard SwiftUI patterns

3. **Automatic Optimizations**
   - SwiftUI's view diffing
   - Implicit animation support
   - Better performance for small/medium annotation counts

4. **Easier Testing**
   - Views can be previewed in Xcode
   - SwiftUI Preview support
   - Component isolation

5. **Accessibility**
   - SwiftUI's built-in accessibility
   - VoiceOver support comes free
   - Semantic annotations easier

6. **Future-Proof**
   - Leverage SwiftUI evolution
   - New modifiers/features available
   - Better multiplatform support (iOS/iPadOS)

### ⚠️ Potential Drawbacks

1. **Performance with Many Annotations**
   - Canvas may be faster for 100+ annotations
   - Mitigation: Virtual scrolling, lazy loading
   - Trade-off: Most users won't hit limits

2. **Grid Rendering**
   - Still uses Canvas (acceptable)
   - Pure SwiftUI grid would be too slow

3. **Complex Shapes**
   - Some advanced rendering may need Canvas
   - Hybrid approach possible

---

## Migration Path

### Phase 1: Create New Views (Parallel)
- Implement `AnnotationView` protocol
- Create `ShapeAnnotationView`, `LineAnnotationView`
- Build `SelectionHandlesView`
- **Keep old Canvas code intact**

### Phase 2: Switch Rendering
- Update `AnnotationCanvasView` to use new views
- Remove Canvas-based drawing code
- Test thoroughly

### Phase 3: Cleanup
- Remove `drawSelectionHandles()` from `Annotation` protocol
- Remove unused rendering helpers
- Update documentation

### Phase 4: Optimize
- Add view caching if needed
- Implement lazy loading for many annotations
- Performance profiling

---

## Implementation Checklist

### Core Views
- [ ] `AnnotationView` (protocol dispatch)
- [ ] `ShapeAnnotationView`
- [ ] `LineAnnotationView`
- [ ] `TextAnnotationView`
- [ ] `NumberAnnotationView`
- [ ] `AnnotationTransformModifier`

### Selection System
- [ ] `SelectionHandlesView`
- [ ] `SingleSelectionView`
- [ ] `MultiSelectionView`
- [ ] `ShapeSelectionView`
- [ ] `LineSelectionView`
- [ ] `ResizeHandleView`

### Infrastructure
- [ ] `GridView` (can keep Canvas)
- [ ] `ToolPreviewView`
- [ ] Updated gesture handling
- [ ] Coordinate space helpers

### Testing
- [ ] Unit tests for view models
- [ ] Integration tests for gestures
- [ ] Manual testing for all annotation types
- [ ] Performance testing (50+ annotations)

---

## Open Questions

1. **Animation Performance:** Should we disable implicit animations for performance?
2. **Hit Testing:** Can SwiftUI hit testing replace manual `contains()` checks?
3. **Layer Compositing:** Does ZStack handle z-index correctly with many layers?
4. **Memory Usage:** Is view hierarchy memory overhead acceptable?

---

## Comparison Table

| Aspect | Canvas Approach | SwiftUI-Only Approach |
|--------|----------------|----------------------|
| **Code Complexity** | High (manual drawing) | Low (declarative) |
| **Maintainability** | Medium | High |
| **Performance (10 annotations)** | Excellent | Excellent |
| **Performance (100 annotations)** | Excellent | Good |
| **Performance (1000 annotations)** | Excellent | Poor (needs optimization) |
| **Flexibility** | Very High | High |
| **Testing** | Complex | Simple |
| **Accessibility** | Manual | Automatic |
| **Animation** | Manual | Built-in |
| **Multiplatform** | Medium | High |
| **Learning Curve** | Steep | Gentle |

---

## Recommendation

**Adopt SwiftUI-only approach for the following reasons:**

1. **Simpler is Better:** For a lightweight annotation editor, simplicity trumps max performance
2. **Expected Usage:** Most users will have < 50 annotations per document
3. **Maintainability:** Easier for contributors to understand and extend
4. **Future-Ready:** Better platform support and evolution path
5. **Hybrid Option:** Can always add Canvas back for specific performance-critical parts

**Start with pure SwiftUI. Optimize later if needed.**

---

## See Also

- Current Canvas Architecture: `04-canvas-architecture.md`
- Annotation Model: `AnnotationModel.swift`
- Canvas API: `02-canvas-api.md`
- Tool Protocol: `03-tool-protocol.md`
