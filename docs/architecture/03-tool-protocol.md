# Tool Protocol Guide

**Last Updated:** December 9, 2025

## Overview

The tool system uses a protocol-based architecture where each tool handles mouse events and calls canvas APIs to create/modify annotations.

**Key Principles:**
- Tools receive mouse events (down/drag/up)
- Tools call canvas APIs (never mutate state directly)
- Tools can render preview overlays during interaction
- ToolRegistry manages available tools

---

## Tool Protocol

```swift
protocol AnnotationTool: AnyObject {
    var id: String { get }
    var name: String { get }
    var iconName: String { get }

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas)
    func onCancel(on canvas: AnnotationCanvas)

    func activate()
    func deactivate()

    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas)
}
```

### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique identifier (e.g., "rectangle") |
| `name` | String | Display name (e.g., "Rectangle") |
| `iconName` | String | SF Symbol name for toolbar |

### Event Methods

All points are in **canvas space** (screen coordinates).

| Method | When Called | Purpose |
|--------|-------------|---------|
| `onMouseDown(at:on:)` | Mouse/touch begins | Initialize tool state |
| `onMouseDrag(to:on:)` | Mouse/touch moves | Update preview/state |
| `onMouseUp(at:on:)` | Mouse/touch ends | Create annotation |
| `onCancel(on:)` | Escape key pressed | Cancel operation |

### Lifecycle Methods

| Method | When Called | Purpose |
|--------|-------------|---------|
| `activate()` | Tool selected | Initialize tool |
| `deactivate()` | Tool deselected | Clean up state |

### Preview Rendering

```swift
func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas)
```

Called every frame during interaction to draw temporary overlays.

---

## Default Implementations

Optional methods have default implementations:

```swift
extension AnnotationTool {
    func activate() {}
    func deactivate() {}
    func onCancel(on canvas: AnnotationCanvas) {}
    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {}
}
```

---

## Tool Registry

```swift
final class ToolRegistry {
    static let shared = ToolRegistry()

    func register(_ tool: AnnotationTool)
    func tool(withID id: String) -> AnnotationTool?
    func allTools() -> [AnnotationTool]
}
```

**Usage:**
```swift
// Register tool (in ToolRegistry.init())
register(RectangleTool())

// Retrieve tool
let tool = ToolRegistry.shared.tool(withID: "rectangle")

// Activate tool
canvas.setActiveTool(tool)
```

---

## Example: Rectangle Tool

```swift
final class RectangleTool: AnnotationTool {
    let id = "rectangle"
    let name = "Rectangle"
    let iconName = "rectangle"

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var fillColor: Color = .blue.opacity(0.3)
    private var strokeColor: Color = .blue

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        // Convert to image space for annotation coordinates
        let imagePoint = canvas.canvasToImage(point)
        startPoint = imagePoint
        currentPoint = imagePoint
        canvas.onInteractionBegan.send("drawing_rectangle")
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        // Update preview
        let imagePoint = canvas.canvasToImage(point)
        currentPoint = imagePoint
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard let start = startPoint else { return }
        let imagePoint = canvas.canvasToImage(point)

        // Calculate normalized rectangle
        let minX = min(start.x, imagePoint.x)
        let minY = min(start.y, imagePoint.y)
        let width = abs(imagePoint.x - start.x)
        let height = abs(imagePoint.y - start.y)

        // Create annotation
        let rect = RectangleAnnotation(
            zIndex: (canvas.annotations.map(\.zIndex).max() ?? 0) + 1,
            transform: AnnotationTransform(
                position: CGPoint(x: minX, y: minY),
                scale: CGSize(width: 1, height: 1),
                rotation: .zero
            ),
            size: CGSize(width: width, height: height),
            fill: fillColor,
            stroke: strokeColor
        )

        // Add via canvas API (undoable)
        canvas.addAnnotation(rect)

        // Clean up
        startPoint = nil
        currentPoint = nil
        canvas.onInteractionEnded.send("drawing_rectangle")
    }

    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
        guard let start = startPoint, let end = currentPoint else { return }

        // Convert to canvas space for rendering
        let canvasStart = canvas.imageToCanvas(start)
        let canvasEnd = canvas.imageToCanvas(end)

        // Draw preview rectangle
        let rect = CGRect(
            x: min(canvasStart.x, canvasEnd.x),
            y: min(canvasStart.y, canvasEnd.y),
            width: abs(canvasEnd.x - canvasStart.x),
            height: abs(canvasEnd.y - canvasStart.y)
        )

        let path = Path(rect)
        context.fill(path, with: .color(fillColor))
        context.stroke(path, with: .color(strokeColor), lineWidth: 1.5)
    }

    func deactivate() {
        // Clean up state when switching tools
        startPoint = nil
        currentPoint = nil
    }
}
```

---

## Example: Select Tool

```swift
final class SelectTool: AnnotationTool {
    let id = "select"
    let name = "Select"
    let iconName = "cursorarrow"

    private var dragStartPoint: CGPoint?
    private var isDraggingAnnotations: Bool = false
    private var initialPanOffset: CGPoint?

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        dragStartPoint = point

        // Hit test (point is in canvas space)
        if let hit = canvas.annotation(at: point) {
            if canvas.selectedAnnotationIDs.contains(hit.id) {
                // Prepare to drag selected
                isDraggingAnnotations = true
            } else {
                // Select annotation
                canvas.toggleSelection(for: hit.id)
                isDraggingAnnotations = false
            }
        } else {
            // Prepare to pan canvas
            canvas.clearSelection()
            isDraggingAnnotations = false
            initialPanOffset = canvas.panOffset
        }
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        guard let startPoint = dragStartPoint else { return }

        if isDraggingAnnotations {
            // TODO: Move selected annotations
        } else {
            // Pan canvas
            if let initialOffset = initialPanOffset {
                let delta = CGPoint(
                    x: point.x - startPoint.x,
                    y: point.y - startPoint.y
                )
                canvas.setPanOffset(CGPoint(
                    x: initialOffset.x + delta.x,
                    y: initialOffset.y + delta.y
                ))
            }
        }
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        // Apply grid snapping if dragging annotations
        if isDraggingAnnotations && canvas.snapToGrid {
            canvas.applyGridSnapping(enabled: true, gridSize: canvas.gridSize)
        }

        // Clean up
        dragStartPoint = nil
        isDraggingAnnotations = false
        initialPanOffset = nil
    }

    func deactivate() {
        dragStartPoint = nil
        isDraggingAnnotations = false
        initialPanOffset = nil
    }
}
```

---

## Implementation Checklist

When creating a new tool:

1. **Define tool class** implementing `AnnotationTool`
2. **Add state properties** for tracking interaction (private)
3. **Implement mouse handlers:**
   - `onMouseDown` - Initialize state
   - `onMouseDrag` - Update state
   - `onMouseUp` - Create annotation via canvas API
4. **Implement preview rendering** (optional)
5. **Implement deactivate** to clean up state
6. **Register tool** in `ToolRegistry.init()`
7. **Map to UI** in `ToolIdentifier.createTool()` (ContentView.swift)

---

## Integration Steps

### 1. Register Tool

```swift
// In ToolRegistry.init()
private init() {
    register(SelectTool())
    register(RectangleTool())
    register(YourNewTool())  // Add here
}
```

### 2. Map to UI Enum

```swift
// In ContentView.swift
enum ToolIdentifier: String, CaseIterable {
    case select, shape, yourNew  // Add case

    func createTool() -> (any AnnotationTool)? {
        switch self {
        case .select:
            return ToolRegistry.shared.tool(withID: "select")
        case .shape:
            return ToolRegistry.shared.tool(withID: "rectangle")
        case .yourNew:
            return ToolRegistry.shared.tool(withID: "your-new-tool")  // Add mapping
        default:
            return nil
        }
    }
}
```

### 3. Add Toolbar Button

```swift
// In MainToolbar items
MainToolbarItem(
    tool: .yourNew,
    title: "Your Tool",
    systemName: "icon.name",
    category: .drawing,
    action: nil
)
```

---

## Coordinate Spaces

**Critical:** Understand coordinate conversion!

| Space | Description | When to Use |
|-------|-------------|-------------|
| Canvas Space | Screen coordinates with zoom/pan | Mouse events, rendering |
| Image Space | Annotation data coordinates | Storing positions/sizes |

**Conversion:**
```swift
// Mouse events come in canvas space
func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
    // Convert to image space for annotation data
    let imagePoint = canvas.canvasToImage(point)

    // Store in image space
    annotation.transform.position = imagePoint
}

// Rendering needs canvas space
func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
    // Convert from image space to canvas space
    let canvasPoint = canvas.imageToCanvas(annotation.transform.position)

    // Draw at canvas coordinates
    context.fill(Path(CGRect(origin: canvasPoint, size: size)))
}
```

**Hit Testing:**
```swift
// annotation(at:) expects canvas space
if let hit = canvas.annotation(at: canvasPoint) {
    // Hit testing handles conversion internally
}
```

---

## Best Practices

1. **Use Canvas APIs**
   - ✅ `canvas.addAnnotation(rect)`
   - ❌ `canvas.annotations.append(rect)`

2. **Store Image Space Coordinates**
   - Annotation positions are zoom-independent
   - Convert canvas → image when storing

3. **Render in Canvas Space**
   - Convert image → canvas when drawing
   - Account for zoom/pan

4. **Clean Up State**
   - Implement `deactivate()` to reset tool state
   - Prevents leaks when switching tools

5. **Handle Edge Cases**
   - Zero-size shapes (ignore or minimum size)
   - Clicks vs drags (distance threshold)
   - Null checks for optional state

---

## Preview Rendering

**Force Redraw:** Canvas needs to redraw during drag to show preview.

**AnnotationCanvasView handles this:**
```swift
@State private var redrawTrigger: Int = 0

Canvas { context, size in
    let _ = redrawTrigger  // Depend on trigger

    // ... drawing code

    // Tool preview
    if let tool = canvas.activeTool {
        tool.renderPreview(in: &context, canvas: canvas)
    }
}
```

```swift
.onChanged { value in
    if canvas.activeTool != nil {
        canvas.activeTool?.onMouseDrag(to: value.location, on: canvas)
        redrawTrigger += 1  // Force redraw
    }
}
```

---

## See Also

- Canvas API: `02-canvas-api.md`
- Architecture: `04-canvas-architecture.md`
- Implementation Plan: `/docs/implementation-plan.md`
