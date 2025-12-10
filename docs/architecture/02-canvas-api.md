# Canvas API Reference

**Last Updated:** December 10, 2025

## Overview

The `AnnotationCanvas` class provides a complete API for managing annotations with full undo/redo support, transform operations, and event publishing. The canvas renders against the `Annotation` model layer (`AnnotationModel.swift`) and treats annotations as the source of truth (no canvas-owned geometry).

**Key Principles:**
- All mutations go through the command pattern (undoable)
- Unidirectional data flow (API → State → Published events)
- No direct state modification allowed from views
- Event publishers for complex state changes

---

## Lifecycle API

### Create Annotations

```swift
func addAnnotation(_ annotation: any Annotation)
```

Creates a new annotation with undo support.

**Example:**
```swift
let rect = ShapeAnnotation(
    zIndex: canvas.annotations.count,
    transform: AnnotationTransform(
        position: CGPoint(x: 100, y: 100),
        scale: CGSize(width: 1, height: 1),
        rotation: .zero
    ),
    size: CGSize(width: 200, height: 150),
    fill: .blue.opacity(0.3),
    stroke: .blue,
    strokeWidth: 2,
    shapeKind: .rectangle,
    cornerRadius: 0
)
canvas.addAnnotation(rect)  // Undoable
```

### Delete Annotations

```swift
func deleteAnnotations(_ ids: Set<UUID>)
func deleteSelected()
```

Deletes annotations with undo support.

**Example:**
```swift
canvas.deleteAnnotations([id1, id2])  // Delete specific IDs
canvas.deleteSelected()                // Delete currently selected
```

---

## History API

### Undo/Redo

```swift
func undo()
func redo()
func clearHistory()

// State
@Published private(set) var canUndo: Bool
@Published private(set) var canRedo: Bool
@Published private(set) var undoActionName: String?
@Published private(set) var redoActionName: String?
```

**Example:**
```swift
// Check if undo available
if canvas.canUndo {
    canvas.undo()
}

// Show action name in UI
Text(canvas.undoActionName ?? "Undo")
```

**History Limit:** 100 commands (configurable in `CommandHistory.maxHistorySize`)

---

## Property Updates

### Batch Updates

```swift
func updateProperties(for ids: Set<UUID>, updates: [String: Any])
```

Update multiple properties in a single undoable operation.

**Supported properties:**
- `"transform"` - AnnotationTransform
- `"size"` - CGSize
- `"visible"` - Bool
- `"locked"` - Bool
- `"zIndex"` - Int
- Shape: `"fill"` (Color), `"stroke"` (Color), `"strokeWidth"` (CGFloat), `"shapeKind"` (ShapeKind), `"cornerRadius"` (CGFloat)
- Line: `"startPoint"` (CGPoint), `"endPoint"` (CGPoint), `"stroke"` (Color), `"strokeWidth"` (CGFloat), `"arrowStartType"` (ArrowType), `"arrowEndType"` (ArrowType), `"arrowSize"` (CGFloat), `"lineStyle"` (LineStyle), `"lineCap"` (LineCap)

**Example:**
```swift
canvas.updateProperties(
    for: [id1, id2],
    updates: [
        "visible": false,
        "locked": true
    ]
)
```

### Convenience Methods

```swift
func updateTransform(for ids: Set<UUID>, transform: AnnotationTransform)
func updateVisibility(for ids: Set<UUID>, visible: Bool)
func updateLocked(for ids: Set<UUID>, locked: Bool)
```

---

## Transform Operations

All transform operations default to selected annotations if no IDs provided.

### Arrangement (Z-Index)

```swift
func arrange(_ action: ArrangeCommand.Action, for ids: Set<UUID>? = nil)
func bringToFront(_ ids: Set<UUID>? = nil)
func sendToBack(_ ids: Set<UUID>? = nil)
func bringForward(_ ids: Set<UUID>? = nil)
func sendBackward(_ ids: Set<UUID>? = nil)
```

**Example:**
```swift
canvas.bringToFront()  // Selected annotations to front
canvas.sendToBack([id1, id2])  // Specific IDs to back
```

### Alignment

```swift
func align(_ alignment: AlignCommand.Alignment, for ids: Set<UUID>? = nil)
func alignLeft(_ ids: Set<UUID>? = nil)
func alignRight(_ ids: Set<UUID>? = nil)
func alignTop(_ ids: Set<UUID>? = nil)
func alignBottom(_ ids: Set<UUID>? = nil)
func alignCenterHorizontal(_ ids: Set<UUID>? = nil)
func alignCenterVertical(_ ids: Set<UUID>? = nil)
func alignCenter(_ ids: Set<UUID>? = nil)
```

**Example:**
```swift
// Align selected to left edge
canvas.alignLeft()

// Align specific annotations
canvas.alignCenter([id1, id2, id3])
```

### Distribution

Requires **3 or more** annotations.

```swift
func distribute(_ direction: DistributeCommand.Direction, for ids: Set<UUID>? = nil)
func distributeHorizontally(_ ids: Set<UUID>? = nil)
func distributeVertically(_ ids: Set<UUID>? = nil)
```

**Example:**
```swift
// Even spacing between 3+ selected
canvas.distributeHorizontally()
```

### Rotation & Flip

```swift
func rotate(_ rotationType: RotateCommand.RotationType, for ids: Set<UUID>? = nil)
func rotate90(_ ids: Set<UUID>? = nil)
func rotateMinus90(_ ids: Set<UUID>? = nil)
func flipHorizontal(_ ids: Set<UUID>? = nil)
func flipVertical(_ ids: Set<UUID>? = nil)
```

**Example:**
```swift
canvas.rotate90()         // Rotate selected 90° clockwise
canvas.flipHorizontal()   // Mirror selected horizontally
```

### Move

```swift
func moveAnnotations(_ ids: Set<UUID>, by delta: CGPoint)
func execute(_ command: CanvasCommand)
```

Move annotations by a delta offset in image space.

**Example:**
```swift
// Move selected annotations by 10 pixels right, 5 down
canvas.moveAnnotations(canvas.selectedAnnotationIDs, by: CGPoint(x: 10, y: 5))

// Undo to return to original position
canvas.undo()

// Commit a handle move
let cmd = MoveControlPointCommand(
    annotationID: id,
    controlPointID: .lineEnd,
    newPosition: CGPoint(x: 120, y: 240)
)
canvas.execute(cmd)
```

**Note:** Delta is in image space (zoom-independent). SelectTool uses this for drag-to-move functionality with live preview.

---

## Selection API

```swift
func selectAnnotations(_ ids: Set<UUID>)
func toggleSelection(for id: UUID)
func clearSelection()

@Published var selectedAnnotationIDs: Set<UUID>
```

**Example:**
```swift
// Select multiple
canvas.selectAnnotations([id1, id2])

// Toggle single
canvas.toggleSelection(for: id)

// Clear all
canvas.clearSelection()

// Observe selection
canvas.$selectedAnnotationIDs.sink { ids in
    print("Selected: \(ids.count)")
}
```

---

## Hit Testing

```swift
func annotation(at canvasPoint: CGPoint) -> (any Annotation)?
func selectionBoundingBox(for ids: Set<UUID>) -> CGRect?
func controlPointHitTest(at canvasPoint: CGPoint) -> (UUID, ControlPointRole)?
func annotation(withID id: UUID) -> (any Annotation)?
```

**Example:**
```swift
// Find annotation at canvas point
if let hit = canvas.annotation(at: tapLocation) {
    canvas.toggleSelection(for: hit.id)
}

// Handle hit (single-select)
if let (id, handle) = canvas.controlPointHitTest(at: cursor) {
    print("Hit handle \(handle) on \(id)")
}

// Get bounds of selection
if let bounds = canvas.selectionBoundingBox(for: canvas.selectedAnnotationIDs) {
    // Draw selection handles
}
```

**Note:** Point is in **canvas space** (screen coordinates). The method handles conversion to image space internally.

---

## Control Points & Selection Rendering

### Control Point Protocol

Each annotation type defines its own control points (draggable handles) for editing:

```swift
protocol Annotation {
    /// Returns the control points for this annotation.
    /// Lines have 2 points (start/end), shapes have 8 (corners/edges).
    func controlPoints() -> [AnnotationControlPoint]

    /// Move a control point to a new position (image space).
    /// The annotation updates its geometry accordingly.
    func moveControlPoint(_ id: ControlPointRole, to position: CGPoint)

    /// Draw custom selection handles for this annotation type.
    /// Each type renders its own selection UI.
    func drawSelectionHandles(in context: inout GraphicsContext, canvas: AnnotationCanvas)
}
```

### Control Point Types

```swift
enum ControlPointRole: Hashable {
    case corner(ResizeHandle)        // Shape corners
    case edge(ResizeHandle)           // Shape edges
    case lineStart                    // Line start point
    case lineEnd                      // Line end point
    case center                       // Future: rotation center
}

enum ResizeHandle: CaseIterable {
    case topLeft, top, topRight
    case left, right
    case bottomLeft, bottom, bottomRight
}
```

### Selection Rendering

**LineAnnotation:**
- Displays 2 circular handles at start/end points
- Draws blue line connecting the points
- Handles are 8pt diameter, zoom-independent
- Draggable for live editing

**ShapeAnnotation:**
- Displays 8 square resize handles (corners + edges)
- Draws blue outline around bounding box
- Handles are 8pt size, zoom-independent
- Draggable for resizing

**Multi-Selection:**
- ❌ **Not yet implemented** - Shift+click to add/remove from selection
- Single-selection only (click selects one, deselects others)
- Future: Will show bounding box outline only (no individual handles)

### Example: Custom Annotation Type

To add a custom annotation with unique selection behavior:

```swift
final class CustomAnnotation: Annotation {
    // ... required properties ...

    func controlPoints() -> [AnnotationControlPoint] {
        // Return your custom control points
        return [/* ... */]
    }

    func moveControlPoint(_ id: ControlPointRole, to position: CGPoint) {
        // Update your geometry when a control point moves
    }

    func drawSelectionHandles(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
        // Draw your custom selection UI
        // Example: Bezier curve with 4 control points
        // Example: Polygon with N vertices
    }
}
```

---

## Coordinate Conversion

```swift
func imageToCanvas(_ point: CGPoint) -> CGPoint
func canvasToImage(_ point: CGPoint) -> CGPoint
func canvasRect(for annotation: any Annotation) -> CGRect
```

**Coordinate Spaces:**
- **Image Space:** Annotation data coordinates (zoom-independent)
- **Canvas Space:** Screen rendering coordinates (includes zoom/pan)

**Example:**
```swift
// Convert tap location to image space
let imagePoint = canvas.canvasToImage(tapLocation)

// Get screen rect for annotation
let rect = canvas.canvasRect(for: annotation)
```

---

## Pan & Zoom

```swift
func pan(by delta: CGPoint)
func setPanOffset(_ offset: CGPoint)
func setZoom(_ level: CGFloat, centerOn anchor: CGPoint?)

@Published var panOffset: CGPoint
@Published var zoomLevel: CGFloat
```

**Example:**
```swift
// Pan canvas
canvas.pan(by: CGPoint(x: 10, y: -20))

// Zoom centered on point
canvas.setZoom(2.0, centerOn: tapLocation)
```

---

## Grid & Snapping

```swift
func applyGridSnapping(enabled: Bool, gridSize: CGFloat)

@Published var showGrid: Bool
@Published var snapToGrid: Bool
@Published var gridSize: CGFloat
```

**Example:**
```swift
// Enable grid
canvas.showGrid = true
canvas.gridSize = 16

// Snap selected annotations
if canvas.snapToGrid {
    canvas.applyGridSnapping(enabled: true, gridSize: canvas.gridSize)
}
```

---

## Tool Management

```swift
func setActiveTool(_ tool: (any AnnotationTool)?)
func isToolActive(_ toolID: String) -> Bool

@Published private(set) var activeTool: (any AnnotationTool)?
```

**Example:**
```swift
// Activate tool
let rectTool = ToolRegistry.shared.tool(withID: "rectangle")
canvas.setActiveTool(rectTool)

// Check active
if canvas.isToolActive("select") {
    // Select tool is active
}
```

---

## Event Publishers

```swift
let onAnnotationAdded = PassthroughSubject<any Annotation, Never>()
let onAnnotationModified = PassthroughSubject<UUID, Never>()
let onAnnotationDeleted = PassthroughSubject<Set<UUID>, Never>()
let onInteractionBegan = PassthroughSubject<String, Never>()
let onInteractionEnded = PassthroughSubject<String, Never>()
```

**Example:**
```swift
canvas.onAnnotationAdded.sink { annotation in
    print("Added: \(annotation.id)")
}

canvas.onAnnotationModified.sink { id in
    print("Modified: \(id)")
}
```

---

## State Properties

```swift
// Canvas
@Published var canvasSize: CGSize
@Published var imageSize: CGSize

// Annotations
@Published internal var annotations: [any Annotation]

// Settings
@Published var showAlignmentGuides: Bool
@Published var showRulers: Bool
```

---

## Complete Example

```swift
// Create canvas
let canvas = AnnotationCanvas()

// Add annotation
let rect = RectangleAnnotation(...)
canvas.addAnnotation(rect)

// Transform
canvas.rotate90()
canvas.alignCenter()

// Undo
canvas.undo()

// Select and delete
canvas.selectAnnotations([rect.id])
canvas.deleteSelected()

// Undo delete
canvas.undo()
```

---

## Architecture Notes

**Command Pattern:**
- Every mutation wrapped in a `CanvasCommand`
- Execute adds to undo stack, clears redo stack
- Undo/redo replay commands

**Unidirectional Flow:**
```
UI Action → Canvas API → Command Execution → State Update → Published Events → UI Update
```

**No Direct Mutations:**
```swift
// ❌ WRONG
canvas.annotations.append(rect)

// ✅ CORRECT
canvas.addAnnotation(rect)
```

---

## See Also

- Annotation JSON: `01-annotation-json.md`
- Tool Protocol: `03-tool-protocol.md`
- Architecture: `04-canvas-architecture.md`
