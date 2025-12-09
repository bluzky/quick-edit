# Canvas Architecture

**Last Updated:** December 9, 2025

## Overview

The canvas system implements a robust, maintainable architecture with command pattern for undo/redo, protocol-based tools, and unidirectional data flow.

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
                    │  (Model + APIs)      │
                    └──────────┬───────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼────────┐    ┌────────▼────────┐    ┌──────▼──────┐
│ CommandHistory │    │  ToolRegistry   │    │  Published  │
│  Undo/Redo     │    │  Tool Mgmt      │    │  State      │
└───────┬────────┘    └────────┬────────┘    └──────┬──────┘
        │                      │                     │
┌───────▼──────────────────────▼─────────────────────▼──────┐
│                  Canvas State                              │
│  - annotations: [Annotation]                               │
│  - selectedAnnotationIDs: Set<UUID>                        │
│  - panOffset, zoomLevel, activeTool, etc.                  │
└────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. AnnotationCanvas (Model)

**Responsibilities:**
- Stores all canvas state (`@Published` properties)
- Provides 30+ public APIs for manipulation
- Manages command history (undo/redo)
- Publishes events for complex state changes
- Handles coordinate conversions

**Key Properties:**
```swift
@Published internal var annotations: [any Annotation]
@Published var selectedAnnotationIDs: Set<UUID>
@Published var panOffset: CGPoint
@Published var zoomLevel: CGFloat
@Published private(set) var activeTool: (any AnnotationTool)?
@Published private(set) var canUndo: Bool
@Published private(set) var canRedo: Bool
```

**Architecture Role:** Single source of truth

---

### 2. AnnotationCanvasView (View)

**Responsibilities:**
- Renders annotations with transforms
- Forwards mouse events to active tool
- Draws selection handles
- Triggers canvas redraws for preview

**Key Features:**
```swift
@ObservedObject var canvas: AnnotationCanvas

var body: some View {
    Canvas { context, size in
        // Draw annotations with transforms
        // Draw selection handles
        // Draw tool preview
    }
    .gesture(dragGesture)
}
```

**Architecture Role:** Passive observer, event forwarder

---

### 3. CommandHistory (Undo/Redo)

**Responsibilities:**
- Manages undo/redo stacks
- Executes commands
- Limits history size (100 items)

```swift
final class CommandHistory {
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    func execute(_ command: CanvasCommand, on canvas: AnnotationCanvas)
    func undo(on canvas: AnnotationCanvas)
    func redo(on canvas: AnnotationCanvas)
}
```

**Architecture Role:** Command manager

---

### 4. CanvasCommand (Protocol)

**Responsibilities:**
- Encapsulates undoable operations
- Stores state for undo

```swift
protocol CanvasCommand: AnyObject {
    var actionName: String { get }
    func execute(on canvas: AnnotationCanvas)
    func undo(on canvas: AnnotationCanvas)
}
```

**Implementations:**
- `AddAnnotationCommand` - Create
- `DeleteAnnotationsCommand` - Delete
- `UpdatePropertiesCommand` - Modify properties
- `BatchCommand` - Group operations
- `ArrangeCommand` - Z-index changes
- `AlignCommand` - Alignment
- `DistributeCommand` - Even spacing
- `RotateCommand` - Rotation/flip

**Architecture Role:** Mutation encapsulation

---

### 5. AnnotationTool (Protocol)

**Responsibilities:**
- Handle mouse events
- Call canvas APIs
- Render preview overlays

```swift
protocol AnnotationTool: AnyObject {
    var id: String { get }
    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas)
    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas)
}
```

**Implementations:**
- `SelectTool` - Selection and panning
- `RectangleTool` - Draw rectangles

**Architecture Role:** User interaction handlers

---

### 6. ToolRegistry (Singleton)

**Responsibilities:**
- Register available tools
- Retrieve tools by ID

```swift
final class ToolRegistry {
    static let shared = ToolRegistry()
    func register(_ tool: AnnotationTool)
    func tool(withID id: String) -> AnnotationTool?
}
```

**Architecture Role:** Tool factory

---

## Data Flow

### Unidirectional Flow

```
User Action
    ↓
UI Event (button click, mouse down)
    ↓
Canvas API Call (addAnnotation, rotate90, etc.)
    ↓
Command Created & Executed
    ↓
Canvas State Updated (@Published properties)
    ↓
SwiftUI Observes Changes
    ↓
View Redraws Automatically
```

**Critical:** Views **never** mutate canvas state directly!

---

## Event Flow Examples

### Example 1: Drawing Rectangle

```
1. User drags with RectangleTool active
2. CanvasView.dragGesture forwards to tool.onMouseDrag()
3. Tool updates internal state (currentPoint)
4. CanvasView increments redrawTrigger
5. Canvas redraws, calling tool.renderPreview()
6. Preview rectangle appears on screen
7. User releases mouse
8. Tool.onMouseUp() creates RectangleAnnotation
9. Tool calls canvas.addAnnotation(rect)
10. Canvas wraps in AddAnnotationCommand
11. Command executes: annotations.append(rect)
12. Canvas publishes onAnnotationAdded event
13. SwiftUI redraws (new annotation visible)
14. Command added to undo stack
```

### Example 2: Undo Operation

```
1. User clicks Undo button
2. UI calls canvas.undo()
3. Canvas calls commandHistory.undo()
4. CommandHistory pops last command
5. Command.undo() executes (e.g., removes annotation)
6. Canvas state updates (annotation removed)
7. Canvas updates canUndo/canRedo flags
8. SwiftUI redraws (annotation gone)
9. Command moved to redo stack
```

### Example 3: Rotation

```
1. User calls canvas.rotate90()
2. Canvas creates RotateCommand
3. Command captures old transforms
4. Command.execute() modifies transform.rotation
5. Canvas publishes onAnnotationModified events
6. AnnotationCanvasView observes change
7. drawRectangle() applies transform during rendering
8. Rectangle appears rotated on screen
9. Command in undo stack (can be undone)
```

---

## Coordinate Spaces

### Two Coordinate Systems

**Image Space (Data):**
- Annotation positions stored here
- Zoom-independent
- Origin: top-left of image

**Canvas Space (Screen):**
- Mouse events occur here
- Includes zoom and pan
- Origin: top-left of view

### Conversion

```swift
// Canvas → Image (for storing data)
let imagePoint = canvas.canvasToImage(mouseLocation)
annotation.transform.position = imagePoint

// Image → Canvas (for rendering)
let canvasPoint = canvas.imageToCanvas(annotation.transform.position)
context.fill(Path(CGRect(origin: canvasPoint, size: size)))
```

**Formula:**
```swift
// Image to Canvas
canvasPoint.x = (imagePoint.x * zoomLevel) + panOffset.x
canvasPoint.y = (imagePoint.y * zoomLevel) + panOffset.y

// Canvas to Image
imagePoint.x = (canvasPoint.x - panOffset.x) / zoomLevel
imagePoint.y = (canvasPoint.y - panOffset.y) / zoomLevel
```

---

## Transform System

Annotations have a full transform:

```swift
struct AnnotationTransform {
    var position: CGPoint  // Top-left anchor
    var scale: CGSize      // Width/height multipliers (can be negative)
    var rotation: Angle    // Rotation in degrees
}
```

### Transform Order (Rendering)

1. **Translate to anchor** (position)
2. **Translate to center**
3. **Rotate** around center
4. **Scale** (including flip if negative)
5. **Translate back**

```swift
// In AnnotationCanvasView.drawRectangle()
contextCopy.translateBy(x: centerX, y: centerY)
contextCopy.rotate(by: transform.rotation)
contextCopy.translateBy(x: -scaledSize.width / 2, y: -scaledSize.height / 2)
```

---

## Command Pattern Details

### Command Interface

```swift
protocol CanvasCommand: AnyObject {
    var actionName: String { get }
    func execute(on canvas: AnnotationCanvas)
    func undo(on canvas: AnnotationCanvas)
}
```

### Command Lifecycle

**Execute:**
1. Command modifies canvas state
2. Command added to undo stack
3. Redo stack cleared

**Undo:**
1. Command popped from undo stack
2. Command.undo() restores old state
3. Command moved to redo stack

**Redo:**
1. Command popped from redo stack
2. Command.execute() reapplies changes
3. Command moved back to undo stack

### State Capture

Commands capture old state before modification:

```swift
class DeleteAnnotationsCommand: CanvasCommand {
    let annotationIDs: Set<UUID>
    private var savedAnnotations: [any Annotation] = []  // Captured

    func execute(on canvas: AnnotationCanvas) {
        // Save before deleting
        savedAnnotations = canvas.annotations.filter { annotationIDs.contains($0.id) }
        canvas.annotations.removeAll { annotationIDs.contains($0.id) }
    }

    func undo(on canvas: AnnotationCanvas) {
        // Restore saved
        canvas.annotations.append(contentsOf: savedAnnotations)
    }
}
```

---

## Event Publishers

Canvas emits events for complex changes:

```swift
let onAnnotationAdded = PassthroughSubject<any Annotation, Never>()
let onAnnotationModified = PassthroughSubject<UUID, Never>()
let onAnnotationDeleted = PassthroughSubject<Set<UUID>, Never>()
```

**When to Use:**
- External systems need notification
- UI needs to react beyond @Published
- Logging/analytics

**Example:**
```swift
canvas.onAnnotationAdded.sink { annotation in
    analytics.log("annotation_added", type: annotation.type)
}
```

---

## Access Control

Strategic use of access levels:

| Component | Level | Reason |
|-----------|-------|--------|
| `annotations` | `internal` | Commands can modify, external code cannot |
| `activeTool` | `private(set)` | Only canvas sets tool |
| Canvas APIs | `public` | External callers use APIs |
| Command internals | `private` | Implementation detail |

---

## Thread Safety

**Main Thread:**
- All canvas operations run on main thread
- `@Published` properties update UI
- `DispatchQueue.main.async` for tool activation

**No Background Work:**
- Simple operations (draw/select/undo)
- No need for threading complexity

---

## Performance Considerations

**Undo Stack Limit:**
- Max 100 commands (configurable)
- Prevents unbounded memory growth

**Redraw Optimization:**
- SwiftUI Canvas redraws efficiently
- Only redraws when state changes
- Explicit trigger for tool preview

**Hit Testing:**
- Sorted by z-index (highest first)
- Early return on first hit
- Locked/invisible annotations skipped

---

## Error Handling

**Defensive Programming:**
- Guard statements for nil checks
- Empty set checks before operations
- Coordinate space validation

**Example:**
```swift
func deleteAnnotations(_ ids: Set<UUID>) {
    guard !ids.isEmpty else { return }  // Early return
    let command = DeleteAnnotationsCommand(annotationIDs: ids)
    execute(command)
}
```

---

## Testing Strategy

**Unit Tests:**
- Command execute/undo/redo
- Coordinate conversions
- Hit testing accuracy

**Integration Tests:**
- Tool → Canvas API → State
- Undo/redo full cycles

**Manual Tests:**
- Mouse event handling
- Preview rendering
- Transform rendering

---

## Future Enhancements

**Potential Additions:**
- Serialization (save/load JSON)
- Multi-selection drag (move annotations)
- Grouping (nested transforms)
- Layers panel
- More annotation types (line, text, freehand)

**Architecture Supports:**
- New tools (just implement protocol)
- New commands (just implement protocol)
- New annotation types (just implement protocol)

---

## Design Patterns Used

1. **Command Pattern** - Undo/redo
2. **Protocol-Oriented** - Tools, annotations, commands
3. **Observer Pattern** - `@Published`, Combine publishers
4. **Singleton** - ToolRegistry
5. **Factory** - ToolRegistry tool creation
6. **Strategy** - Different tools, different strategies

---

## Key Architectural Decisions

### Why Command Pattern?
- ✅ Undo/redo "for free"
- ✅ History management
- ✅ Batch operations
- ✅ Action naming for UI

### Why Protocol-Based Tools?
- ✅ Easy to add new tools
- ✅ Testable in isolation
- ✅ Clean separation of concerns
- ✅ Type-safe but flexible

### Why No View → State Mutation?
- ✅ Predictable state updates
- ✅ Single source of truth
- ✅ Easier debugging
- ✅ Undo/redo works correctly

---

## See Also

- Annotation JSON: `01-annotation-json.md`
- Canvas API: `02-canvas-api.md`
- Tool Protocol: `03-tool-protocol.md`
- Implementation Plan: `/docs/implementation-plan.md`
