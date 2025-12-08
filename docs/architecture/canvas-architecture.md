# Canvas Architecture

**Version:** 1.0
**Status:** Architecture Complete (Implementation Phase 2 Pending)
**Last Updated:** December 8, 2025

---

## Overview

The `AnnotationCanvas` is the core rendering and interaction system for QuickEdit. It manages:
- Base image display
- Annotation rendering with proper layering (z-index)
- User interaction (mouse events, gestures)
- Selection and manipulation
- Coordinate space transformations
- Zoom and pan
- Hit testing for annotation selection

---

## Canvas Coordinate System

### Image Space vs. Canvas Space

**Image Space:**
- Origin: Top-left corner (0, 0)
- Units: Points (logical pixels, not physical pixels)
- Range: 0 to image width/height
- All annotation coordinates stored in image space
- Independent of zoom/pan state

**Canvas Space:**
- Origin: Top-left corner of visible canvas view
- Units: Points in view coordinates
- Affected by zoom level and pan offset
- Used for mouse events and UI rendering

**Conversion:**
```swift
// Image space to canvas space
func imageToCanvas(_ point: CGPoint) -> CGPoint {
    CGPoint(
        x: (point.x * zoomLevel) + panOffset.x,
        y: (point.y * zoomLevel) + panOffset.y
    )
}

// Canvas space to image space
func canvasToImage(_ point: CGPoint) -> CGPoint {
    CGPoint(
        x: (point.x - panOffset.x) / zoomLevel,
        y: (point.y - panOffset.y) / zoomLevel
    )
}
```

---

## AnnotationCanvas Data Model

```swift
final class AnnotationCanvas: ObservableObject {
    // MARK: - Image
    @Published var baseImage: NSImage?
    @Published var imageSize: CGSize = .zero

    // MARK: - Annotations
    @Published private(set) var annotations: [any Annotation] = []
    @Published var selectedAnnotationIDs: Set<UUID> = []

    // MARK: - View State
    @Published var zoomLevel: CGFloat = 1.0  // 0.1 to 5.0
    @Published var panOffset: CGPoint = .zero
    @Published var showGrid: Bool = false
    @Published var gridSize: CGFloat = 8
    @Published var showAlignmentGuides: Bool = true
    @Published var showRulers: Bool = false

    // MARK: - Undo/Redo
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    // MARK: - Interaction State
    var isDragging: Bool = false
    var dragStartPoint: CGPoint?
    var interactionMode: InteractionMode = .none

    enum InteractionMode {
        case none
        case drawing(tool: any AnnotationTool)
        case selecting
        case moving(annotationIDs: Set<UUID>)
        case resizing(annotationID: UUID, handle: ResizeHandle)
        case panning
    }

    enum ResizeHandle {
        case topLeft, top, topRight
        case left, right
        case bottomLeft, bottom, bottomRight
    }
}
```

---

## Rendering Pipeline

### 1. Layer Ordering

Annotations are rendered in order of increasing `zIndex`:

```swift
func renderAnnotations(in context: inout GraphicsContext, canvasSize: CGSize) {
    // Sort by zIndex (ascending order)
    let sortedAnnotations = annotations.sorted { $0.zIndex < $1.zIndex }

    for annotation in sortedAnnotations {
        guard annotation.visible else { continue }

        // Apply annotation transform
        context.saveGState()
        applyTransform(annotation.transform, to: &context)

        // Render annotation content
        render(annotation, in: &context)

        // Draw selection handles if selected
        if selectedAnnotationIDs.contains(annotation.id) {
            drawSelectionHandles(for: annotation, in: &context)
        }

        context.restoreGState()
    }
}
```

### 2. Rendering Modes

**Display Mode (60 FPS):**
- Full rendering of all visible annotations
- Selection handles and guides
- Grid overlay (if enabled)
- Rulers (if enabled)

**Preview Mode (During Interaction):**
- Existing annotations rendered from cache
- Preview of annotation being created/edited
- Throttled to maintain 60 FPS

**Export Mode:**
- High-quality rendering without UI elements
- No selection handles, grid, or guides
- Render to NSImage at full resolution

### 3. Optimization Strategies

**Viewport Culling:**
```swift
func isVisible(_ annotation: any Annotation, in viewport: CGRect) -> Bool {
    let annotationRect = annotation.bounds.applying(
        transformMatrix(for: annotation.transform)
    )
    return viewport.intersects(annotationRect)
}
```

**Lazy Rendering:**
- Only render annotations within visible viewport
- Cache rendered layers for static annotations
- Invalidate cache on annotation modification

**Z-Index Batching:**
- Group annotations by z-index ranges
- Render each batch to separate layer
- Composite layers for final output

---

## Hit Testing

### Selection Algorithm

When user clicks on canvas:

```swift
func annotationAt(point: CGPoint) -> (any Annotation)? {
    // Convert canvas point to image space
    let imagePoint = canvasToImage(point)

    // Test annotations in reverse z-index order (top to bottom)
    for annotation in annotations.sorted(by: { $0.zIndex > $1.zIndex }) {
        guard annotation.visible && !annotation.locked else { continue }

        if annotation.contains(point: imagePoint) {
            return annotation
        }
    }

    return nil
}
```

### Annotation-Specific Hit Testing

Each annotation type implements `contains(point:)`:

**Shape (Rectangle, Circle):**
```swift
func contains(point: CGPoint) -> Bool {
    // Transform point to local space
    let localPoint = inverseTransform(point)

    // Check if point is inside shape bounds
    let rect = CGRect(origin: .zero, size: bounds)

    switch shapeType {
    case .rectangle:
        return rect.contains(localPoint)
    case .circle:
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let radius = min(bounds.width, bounds.height) / 2
        return distance(localPoint, center) <= radius
    // ... other shapes
    }
}
```

**Line:**
```swift
func contains(point: CGPoint) -> Bool {
    // Distance from point to line segment
    let distance = distanceToLineSegment(
        point: point,
        start: startPoint,
        end: endPoint
    )

    // Consider hit if within stroke width + tolerance
    let hitRadius = (strokeWidth / 2) + 5
    return distance <= hitRadius
}
```

**Freehand Path:**
```swift
func contains(point: CGPoint) -> Bool {
    // Check distance to any path segment
    for i in 0..<(path.count - 1) {
        let distance = distanceToLineSegment(
            point: point,
            start: path[i],
            end: path[i + 1]
        )

        if distance <= (strokeWidth / 2) + 5 {
            return true
        }
    }

    return false
}
```

---

## Resize Handle Detection

```swift
struct ResizeHandleLayout {
    static let handleSize: CGFloat = 8       // On-screen size at 100%
    static let handleHitSize: CGFloat = 12   // On-screen hit target at 100%

    static func handleRects(for bounds: CGRect, zoomLevel: CGFloat) -> [ResizeHandle: CGRect] {
        // Keep handles a consistent on-screen size by scaling by inverse zoom
        let w = bounds.width
        let h = bounds.height
        let hs = handleSize / zoomLevel

        return [
            .topLeft: CGRect(x: -hs/2, y: -hs/2, width: hs, height: hs),
            .top: CGRect(x: w/2 - hs/2, y: -hs/2, width: hs, height: hs),
            .topRight: CGRect(x: w - hs/2, y: -hs/2, width: hs, height: hs),
            .left: CGRect(x: -hs/2, y: h/2 - hs/2, width: hs, height: hs),
            .right: CGRect(x: w - hs/2, y: h/2 - hs/2, width: hs, height: hs),
            .bottomLeft: CGRect(x: -hs/2, y: h - hs/2, width: hs, height: hs),
            .bottom: CGRect(x: w/2 - hs/2, y: h - hs/2, width: hs, height: hs),
            .bottomRight: CGRect(x: w - hs/2, y: h - hs/2, width: hs, height: hs)
        ]
    }
}
```

---

## Alignment Guides

### Smart Guides

When moving/resizing annotations, show alignment guides when:

- **Edge alignment:** Annotation edge aligns with another annotation's edge (± 2px tolerance)
- **Center alignment:** Centers align horizontally or vertically
- **Equal spacing:** Gaps between annotations are equal

```swift
func calculateAlignmentGuides(
    for movingAnnotation: any Annotation
) -> [AlignmentGuide] {
    var guides: [AlignmentGuide] = []

    let movingBounds = movingAnnotation.transformedBounds

    for other in annotations where other.id != movingAnnotation.id {
        let otherBounds = other.transformedBounds

        // Check horizontal center alignment
        if abs(movingBounds.midX - otherBounds.midX) < 2 {
            guides.append(.vertical(x: otherBounds.midX, type: .center))
        }

        // Check left edge alignment
        if abs(movingBounds.minX - otherBounds.minX) < 2 {
            guides.append(.vertical(x: otherBounds.minX, type: .leftEdge))
        }

        // ... similar for other alignments
    }

    return guides
}

enum AlignmentGuide {
    case horizontal(y: CGFloat, type: AlignmentType)
    case vertical(x: CGFloat, type: AlignmentType)
}

enum AlignmentType {
    case leftEdge, rightEdge, topEdge, bottomEdge
    case center
}
```

---

## Grid Snapping

```swift
func snapToGrid(_ point: CGPoint, gridSize: CGFloat) -> CGPoint {
    CGPoint(
        x: round(point.x / gridSize) * gridSize,
        y: round(point.y / gridSize) * gridSize
    )
}

func applyGridSnapping(enabled: Bool, gridSize: CGFloat) {
    guard enabled else { return }

    // Snap selection bounding box (works for single + multi-select)
    guard let selectionBounds = selectionBoundingBox(for: selectedAnnotationIDs) else { return }
    let snappedOrigin = snapToGrid(selectionBounds.origin, gridSize: gridSize)
    let delta = CGPoint(
        x: snappedOrigin.x - selectionBounds.origin.x,
        y: snappedOrigin.y - selectionBounds.origin.y
    )

    // Move all selected annotations by the same delta to preserve relative layout
    for id in selectedAnnotationIDs {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { continue }
        annotations[index].transform.position.x += delta.x
        annotations[index].transform.position.y += delta.y
    }
}
```

---

## Zoom and Pan

### Zoom Levels

```swift
struct ZoomConfig {
    static let minZoom: CGFloat = 0.1   // 10%
    static let maxZoom: CGFloat = 5.0   // 500%
    static let defaultZoom: CGFloat = 1.0
    static let fitToWindowMargin: CGFloat = 20

    static let presetLevels: [CGFloat] = [
        0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 4.0, 5.0
    ]
}

func zoomToFit() {
    guard let image = baseImage else { return }

    let availableSize = CGSize(
        width: canvasSize.width - ZoomConfig.fitToWindowMargin * 2,
        height: canvasSize.height - ZoomConfig.fitToWindowMargin * 2
    )

    let scaleX = availableSize.width / image.size.width
    let scaleY = availableSize.height / image.size.height

    zoomLevel = min(scaleX, scaleY)
    centerImage()
}

func centerImage() {
    guard let image = baseImage else { return }

    let scaledSize = CGSize(
        width: image.size.width * zoomLevel,
        height: image.size.height * zoomLevel
    )

    panOffset = CGPoint(
        x: (canvasSize.width - scaledSize.width) / 2,
        y: (canvasSize.height - scaledSize.height) / 2
    )
}
```

### Zoom Gestures

- **Scroll wheel:** Zoom in/out at cursor position
- **Pinch gesture:** Trackpad pinch to zoom
- **Keyboard:** Cmd+Plus/Minus for zoom, Cmd+0 for 100%, Cmd+9 for fit

---

## Command Pattern for Undo/Redo

```swift
protocol CanvasCommand {
    func execute(on canvas: AnnotationCanvas)
    func undo(on canvas: AnnotationCanvas)
    var description: String { get }
}

// Example: Add Annotation Command
struct AddAnnotationCommand: CanvasCommand {
    let annotation: any Annotation

    func execute(on canvas: AnnotationCanvas) {
        canvas.annotations.append(annotation)
    }

    func undo(on canvas: AnnotationCanvas) {
        canvas.annotations.removeAll { $0.id == annotation.id }
    }

    var description: String { "Add \(annotation.type)" }
}

// Example: Move Annotation Command
struct MoveAnnotationCommand: CanvasCommand {
    let annotationID: UUID
    let oldPosition: CGPoint
    let newPosition: CGPoint

    func execute(on canvas: AnnotationCanvas) {
        if let index = canvas.annotations.firstIndex(where: { $0.id == annotationID }) {
            canvas.annotations[index].transform.position = newPosition
        }
    }

    func undo(on canvas: AnnotationCanvas) {
        if let index = canvas.annotations.firstIndex(where: { $0.id == annotationID }) {
            canvas.annotations[index].transform.position = oldPosition
        }
    }

    var description: String { "Move Annotation" }
}
```

---

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Rendering FPS | 60 | Maintain during interaction |
| Max Annotations | 500+ | With viewport culling |
| Zoom Smoothness | < 16ms | Per frame during zoom |
| Hit Test Latency | < 5ms | On mouse click |
| Undo/Redo | < 10ms | Command execution time |

---

## Integration with UI

### SwiftUI Canvas View

```swift
struct AnnotationCanvasView: View {
    @ObservedObject var canvas: AnnotationCanvas
    @Binding var activeTool: (any AnnotationTool)?

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Render base image
                if let image = canvas.baseImage {
                    let scaledSize = CGSize(
                        width: image.size.width * canvas.zoomLevel,
                        height: image.size.height * canvas.zoomLevel
                    )
                    context.draw(image, in: CGRect(
                        origin: canvas.panOffset,
                        size: scaledSize
                    ))
                }

                // Render grid
                if canvas.showGrid {
                    renderGrid(in: &context, size: size)
                }

                // Render annotations
                canvas.renderAnnotations(in: &context, canvasSize: size)

                // Render alignment guides
                if canvas.showAlignmentGuides {
                    renderGuides(in: &context)
                }

                // Render tool preview
                if let tool = activeTool {
                    tool.renderPreview(in: &context, canvasSize: size)
                }
            }
            .gesture(dragGesture)
            .gesture(magnificationGesture)
            .onTapGesture { location in
                handleTap(at: location)
            }
        }
    }
}
```

---

## Next Steps

1. Implement `AnnotationCanvas` class with basic annotation management
2. Add rendering pipeline with z-index sorting
3. Implement hit testing for all annotation types
4. Add resize handle detection and manipulation
5. Implement alignment guides system
6. Add grid snapping functionality
7. Implement zoom/pan with gesture support
8. Create command pattern for undo/redo
9. Optimize rendering with viewport culling
10. Add performance monitoring and profiling

---

**Status:** Architecture Complete
**Implementation:** Pending (Phase 2)
**Dependencies:** annotation-types.md, tool-system.md
