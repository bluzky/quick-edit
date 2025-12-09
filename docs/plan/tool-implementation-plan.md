# Tool Implementation Plan

**Last Updated:** December 9, 2025

## Overview

Systematic plan to implement all 10 annotation tools for QuickEdit. Each tool follows a 4-phase process:

1. **Refine Requirements & Specs** - Define behavior, properties, and JSON structure
2. **Implement Behavior** - Create tool class with mouse event handling
3. **Integrate with Canvas** - Register tool, add rendering, wire to UI
4. **Test** - Manual testing and validation

---

## Tool Priority Order

| Priority | Tool | Status | Complexity | Estimated Time |
|----------|------|--------|------------|----------------|
| 1 | Select Tool | **In Progress** | Medium | 2-3 hours |
| 2 | Rectangle Tool | **In Progress** | Low | 1-2 hours |
| 3 | Line Tool | Planned | Medium | 3-4 hours |
| 4 | Text Tool | Planned | High | 4-6 hours |
| 5 | Freehand Tool | Planned | Medium | 3-4 hours |
| 6 | Highlight Tool | Planned | Low | 2-3 hours |
| 7 | Number Tool | Planned | Medium | 2-3 hours |
| 8 | Blur Tool | Planned | High | 4-5 hours |
| 9 | Image Tool | Planned | Medium | 3-4 hours |
| 10 | Note Tool | Planned | Medium | 3-4 hours |

**Total Estimated Time:** 30-40 hours

### Current Status

**SelectTool:**
- ✅ Selection (click to select/deselect)
- ✅ Canvas panning (drag empty space)
- ❌ Move annotations (drag selected) - **TODO**
- ❌ Multi-selection (shift+click) - **TODO**
- ❌ Box selection (drag rectangle) - **TODO**

**RectangleTool:**
- ✅ Draw rectangles with preview
- ✅ Create via canvas API (undoable)
- ❌ Properties panel integration - **TODO**
- ❌ Sync fill/stroke colors from UI - **TODO**

---

## Tool 0A: Complete Select Tool

### Phase 1: Refine Requirements & Specs (15 min)

**Missing Features:**
1. **Move annotations** - Drag selected annotations to new position
2. **Multi-selection** - Shift+click to add/remove from selection
3. **Box selection** - Drag rectangle to select multiple (optional)

**Priority:** Move annotations is critical, others are nice-to-have

**Properties for MoveAnnotationsCommand:**
```swift
final class MoveAnnotationsCommand: CanvasCommand {
    let annotationIDs: Set<UUID>
    let delta: CGPoint  // Movement offset in image space
    private var originalPositions: [UUID: CGPoint] = [:]

    var actionName: String {
        annotationIDs.count == 1 ? "Move Annotation" : "Move \(annotationIDs.count) Annotations"
    }
}
```

**User Interactions:**
- Mouse down on selected annotation → prepare to move
- Mouse drag → move all selected annotations
- Mouse up → commit move via MoveAnnotationsCommand
- Undo → restore original positions

**Acceptance Criteria:**
- [ ] MoveAnnotationsCommand spec reviewed
- [ ] Multi-selection behavior defined
- [ ] Box selection scope defined (Phase 5 or later)

---

### Phase 2: Implement Behavior (1.5 hours)

**Tasks:**

1. **Create MoveAnnotationsCommand** (45 min)
   ```swift
   final class MoveAnnotationsCommand: CanvasCommand {
       let annotationIDs: Set<UUID>
       let delta: CGPoint
       private var originalPositions: [UUID: CGPoint] = [:]

       var actionName: String {
           annotationIDs.count == 1 ? "Move Annotation" : "Move \(annotationIDs.count) Annotations"
       }

       func execute(on canvas: AnnotationCanvas) {
           // Save original positions
           for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
               originalPositions[canvas.annotations[i].id] = canvas.annotations[i].transform.position

               // Apply delta
               canvas.annotations[i].transform.position.x += delta.x
               canvas.annotations[i].transform.position.y += delta.y

               canvas.onAnnotationModified.send(canvas.annotations[i].id)
           }
       }

       func undo(on canvas: AnnotationCanvas) {
           for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
               if let originalPos = originalPositions[canvas.annotations[i].id] {
                   canvas.annotations[i].transform.position = originalPos
                   canvas.onAnnotationModified.send(canvas.annotations[i].id)
               }
           }
       }
   }
   ```

2. **Update SelectTool to move annotations** (30 min)
   ```swift
   private var dragStartPoint: CGPoint?
   private var dragCurrentPoint: CGPoint?
   private var isDraggingAnnotations: Bool = false
   private var initialPanOffset: CGPoint?

   func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
       guard let startPoint = dragStartPoint else { return }
       dragCurrentPoint = point

       if isDraggingAnnotations {
           // Calculate delta in image space
           let startImage = canvas.canvasToImage(startPoint)
           let currentImage = canvas.canvasToImage(point)
           let delta = CGPoint(
               x: currentImage.x - startImage.x,
               y: currentImage.y - startImage.y
           )

           // TODO: Show preview of moved positions
           // For now, annotations will jump on mouse up

       } else {
           // Pan canvas logic (existing)
       }
   }

   func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
       if isDraggingAnnotations {
           // Calculate final delta
           guard let startPoint = dragStartPoint else { return }
           let startImage = canvas.canvasToImage(startPoint)
           let endImage = canvas.canvasToImage(point)
           let delta = CGPoint(
               x: endImage.x - startImage.x,
               y: endImage.y - startImage.y
           )

           // Only create command if moved significantly (>1px)
           if abs(delta.x) > 1 || abs(delta.y) > 1 {
               canvas.moveAnnotations(canvas.selectedAnnotationIDs, by: delta)
           }

           // Apply grid snapping if enabled
           if canvas.snapToGrid {
               canvas.applyGridSnapping(enabled: true, gridSize: canvas.gridSize)
           }
       }

       // Clean up (existing)
   }
   ```

3. **Add canvas.moveAnnotations() API** (15 min)
   ```swift
   // In AnnotationCanvas.swift
   func moveAnnotations(_ ids: Set<UUID>, by delta: CGPoint) {
       guard !ids.isEmpty else { return }
       let command = MoveAnnotationsCommand(annotationIDs: ids, delta: delta)
       execute(command)
   }
   ```

**Acceptance Criteria:**
- [ ] MoveAnnotationsCommand compiles and works
- [ ] SelectTool detects drag on selected annotation
- [ ] Annotations move with mouse (at least on release)
- [ ] Move is undoable

---

### Phase 3: Integrate with Canvas (30 min)

**Tasks:**

1. **Add MoveAnnotationsCommand to CanvasCommand.swift** (20 min)
   - Add full implementation
   - Test execute/undo

2. **Add moveAnnotations() API** (10 min)
   - Add to AnnotationCanvas.swift
   - Wire to command execution

**Acceptance Criteria:**
- [ ] Command registered in CanvasCommand.swift
- [ ] Canvas API available
- [ ] SelectTool uses canvas API

---

### Phase 4: Test (30 min)

**Manual Test Cases:**

1. **Basic Move**
   - [ ] Select annotation → drag → moves to new position
   - [ ] Multi-select → drag → all move together
   - [ ] Undo move → annotations return to original positions

2. **Move + Other Operations**
   - [ ] Move, then rotate → both undoable separately
   - [ ] Move, then delete → works correctly
   - [ ] Create, move, undo twice → annotation disappears

3. **Edge Cases**
   - [ ] Move annotation off canvas → still selectable
   - [ ] Tiny drag (1px) → no move command created
   - [ ] Drag without selecting first → pans canvas

4. **Grid Snapping**
   - [ ] Enable grid → move snaps to grid
   - [ ] Disable grid → move freeform

5. **Performance**
   - [ ] Move 50 selected annotations → smooth
   - [ ] Rapid drag movements → responsive

**Acceptance Criteria:**
- [ ] All test cases pass
- [ ] No crashes or visual glitches
- [ ] Undo/redo works correctly

---

## Tool 0B: Complete Rectangle Tool

### Phase 1: Refine Requirements & Specs (10 min)

**Missing Features:**
1. **Properties panel integration** - Use colors from UI settings
2. **Sync tool colors** - When user changes color in properties panel, tool uses new color
3. **Color persistence** - Remember last used colors

**Current State:**
- RectangleTool has hardcoded colors: `.blue.opacity(0.3)` and `.blue`
- Properties panel exists with ColorPicker but doesn't affect tool
- EditorViewModel has `shape.fillColor` and `shape.strokeColor`

**Required Changes:**
- RectangleTool should read colors from EditorViewModel
- Need a way to pass ViewModel properties to tool

**Acceptance Criteria:**
- [ ] Color sync mechanism designed
- [ ] Tool property injection planned

---

### Phase 2: Implement Behavior (45 min)

**Tasks:**

1. **Add color properties to AnnotationCanvas** (15 min)
   ```swift
   // In AnnotationCanvas.swift
   @Published var toolFillColor: Color = .blue.opacity(0.3)
   @Published var toolStrokeColor: Color = .blue
   ```

2. **Update RectangleTool to use canvas colors** (15 min)
   ```swift
   final class RectangleTool: AnnotationTool {
       // Remove hardcoded colors
       // private var fillColor: Color = .blue.opacity(0.3)  // DELETE
       // private var strokeColor: Color = .blue  // DELETE

       func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
           // ...
           let rect = RectangleAnnotation(
               // ... other properties
               fill: canvas.toolFillColor,    // Use from canvas
               stroke: canvas.toolStrokeColor // Use from canvas
           )
           canvas.addAnnotation(rect)
       }

       func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
           // ... existing code
           // Use canvas.toolFillColor and canvas.toolStrokeColor
       }
   }
   ```

3. **Sync EditorViewModel colors to canvas** (15 min)
   ```swift
   // In EditorViewModel
   var shape: ShapeProperties = ShapeProperties() {
       didSet {
           canvas.toolFillColor = shape.fillColor
           canvas.toolStrokeColor = shape.strokeColor
       }
   }

   init() {
       // ... existing code

       // Initial sync
       canvas.toolFillColor = shape.fillColor
       canvas.toolStrokeColor = shape.strokeColor
   }
   ```

**Acceptance Criteria:**
- [ ] Canvas has color properties
- [ ] RectangleTool reads from canvas
- [ ] EditorViewModel syncs to canvas
- [ ] Colors update in real-time

---

### Phase 3: Integrate with Canvas (15 min)

**Tasks:**

1. **Test color sync** (15 min)
   - Change color in properties panel
   - Draw new rectangle
   - Verify it uses new color

**Acceptance Criteria:**
- [ ] Color changes in UI affect new rectangles
- [ ] Preview shows correct color
- [ ] Colors persist across tool switches

---

### Phase 4: Test (20 min)

**Manual Test Cases:**

1. **Color Sync**
   - [ ] Change fill color → draw rectangle → uses new fill
   - [ ] Change stroke color → draw rectangle → uses new stroke
   - [ ] Change both → both update

2. **Color Persistence**
   - [ ] Set custom colors → switch to Select → switch back → colors preserved
   - [ ] Draw multiple rectangles → all use current colors

3. **Default Colors**
   - [ ] Fresh start → default colors work
   - [ ] Reset colors → returns to defaults

4. **Undo/Redo**
   - [ ] Create rectangle with red → change to blue → create another
   - [ ] Undo second → first is still red
   - [ ] Redo → second is blue

**Acceptance Criteria:**
- [ ] All test cases pass
- [ ] UI colors sync immediately
- [ ] No color flickering or delays

---

## Tool 1: Line Tool

### Phase 1: Refine Requirements & Specs (30 min)

**Core Requirements:**
- Draw straight lines between two points
- Support arrow heads (none, start, end, both)
- Configurable stroke color and width
- Optional dash pattern

**Properties:**
```swift
struct LineAnnotation {
    // Base (inherited)
    id: UUID
    zIndex: Int
    visible: Bool
    locked: Bool
    transform: AnnotationTransform
    size: CGSize

    // Line-specific
    startPoint: CGPoint      // Relative to position
    endPoint: CGPoint        // Relative to position
    stroke: Color
    strokeWidth: CGFloat     // Default: 2.0
    dashPattern: [CGFloat]?  // nil = solid, [5,3] = dashed
    arrowStart: Bool         // Default: false
    arrowEnd: Bool           // Default: false
    arrowSize: CGFloat       // Default: 8.0
}
```

**JSON Structure:**
```json
{
  "type": "line",
  "startPoint": { "x": 0.0, "y": 0.0 },
  "endPoint": { "x": 100.0, "y": 100.0 },
  "stroke": { "r": 0.0, "g": 0.0, "b": 0.0, "a": 1.0 },
  "strokeWidth": 2.0,
  "dashPattern": null,
  "arrowStart": false,
  "arrowEnd": true,
  "arrowSize": 8.0
}
```

**User Interactions:**
- Click: Set start point
- Drag: Update end point with live preview
- Release: Create line annotation
- Shift+Drag: Constrain to 45° angles

**Acceptance Criteria:**
- [ ] Spec document reviewed
- [ ] JSON structure defined
- [ ] Properties identified
- [ ] UI mockup for properties panel

---

### Phase 2: Implement Behavior (1.5 hours)

**Tasks:**

1. **Create LineAnnotation struct** (30 min)
   - Implement Annotation protocol
   - Add line-specific properties
   - Implement `contains(point:)` for hit testing
   - Implement `bounds` calculation

2. **Create LineTool class** (45 min)
   - Implement AnnotationTool protocol
   - Mouse down: Capture start point (in image space)
   - Mouse drag: Update end point
   - Mouse up: Create LineAnnotation via canvas.addAnnotation()
   - Implement preview rendering with stroke and arrows
   - Add shift-key constraint for 45° angles

3. **Arrow head rendering** (15 min)
   - Helper function to draw arrow triangle
   - Calculate rotation based on line angle
   - Apply at start/end based on flags

**Code Structure:**
```swift
final class LineTool: AnnotationTool {
    let id = "line"
    let name = "Line"
    let iconName = "line.diagonal"

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var strokeColor: Color = .black
    private var strokeWidth: CGFloat = 2.0
    private var arrowEnd: Bool = false

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas)
    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas)
    func deactivate()

    private func drawArrow(in context: inout GraphicsContext,
                          at point: CGPoint,
                          angle: Angle,
                          size: CGFloat,
                          color: Color)
}
```

**Acceptance Criteria:**
- [ ] LineAnnotation compiles
- [ ] LineTool compiles
- [ ] Preview shows line during drag
- [ ] Arrow heads render correctly
- [ ] Hit testing works

---

### Phase 3: Integrate with Canvas (45 min)

**Tasks:**

1. **Register tool** (5 min)
   ```swift
   // In ToolRegistry.init()
   register(LineTool())
   ```

2. **Add rendering to AnnotationCanvasView** (20 min)
   ```swift
   private func drawLine(_ annotation: LineAnnotation, in context: inout GraphicsContext) {
       // Apply transform
       // Draw line with stroke
       // Draw arrows if needed
   }
   ```

3. **Wire to UI** (20 min)
   - Update ToolIdentifier enum: add `.line` case
   - Map to LineTool in `createTool()`
   - Update MainToolbar items
   - Add properties panel for line settings

**Acceptance Criteria:**
- [ ] Tool appears in toolbar
- [ ] Tool activates when clicked
- [ ] Lines render on canvas
- [ ] Properties panel shows line options
- [ ] Undo/redo works

---

### Phase 4: Test (30 min)

**Manual Test Cases:**

1. **Basic Drawing**
   - [ ] Click and drag creates line
   - [ ] Line appears after release
   - [ ] Preview shows during drag

2. **Arrow Heads**
   - [ ] Toggle arrow start → renders at start
   - [ ] Toggle arrow end → renders at end
   - [ ] Arrow size changes affect rendering

3. **Stroke Properties**
   - [ ] Change color → line color updates
   - [ ] Change width → line thickness updates
   - [ ] Dash pattern → dashed line renders

4. **Transforms**
   - [ ] Select line → handles appear
   - [ ] Rotate 90° → line rotates
   - [ ] Flip horizontal → line flips
   - [ ] Scale → line scales

5. **Undo/Redo**
   - [ ] Undo after create → line disappears
   - [ ] Redo → line reappears
   - [ ] Undo property change → reverts

6. **Selection**
   - [ ] Click on line → selects
   - [ ] Click near line (within threshold) → selects
   - [ ] Delete selected → line removed

**Edge Cases:**
- [ ] Zero-length line (click without drag)
- [ ] Very long line (across entire canvas)
- [ ] Line with extreme rotation
- [ ] Line with negative scale (flip)

---

## Tool 2: Text Tool

### Phase 1: Refine Requirements & Specs (45 min)

**Core Requirements:**
- Place text at a position with click
- Support multiline text
- Font family, size, weight, style
- Text color and optional background
- Text alignment (left, center, right)
- Auto-size or fixed width

**Properties:**
```swift
struct TextAnnotation {
    // Base
    id: UUID
    zIndex: Int
    visible: Bool
    locked: Bool
    transform: AnnotationTransform
    size: CGSize  // Text bounding box

    // Text-specific
    text: String
    fontName: String         // Default: "Helvetica"
    fontSize: CGFloat        // Default: 16.0
    fontWeight: Font.Weight  // Default: .regular
    textColor: Color         // Default: .black
    backgroundColor: Color?  // Default: nil (transparent)
    alignment: TextAlignment // left, center, right
    lineSpacing: CGFloat     // Default: 0
    maxWidth: CGFloat?       // nil = auto-size
}
```

**JSON Structure:**
```json
{
  "type": "text",
  "text": "Hello World",
  "fontName": "Helvetica",
  "fontSize": 16.0,
  "fontWeight": "regular",
  "textColor": { "r": 0.0, "g": 0.0, "b": 0.0, "a": 1.0 },
  "backgroundColor": null,
  "alignment": "left",
  "lineSpacing": 0.0,
  "maxWidth": null
}
```

**User Interactions:**
- Click: Place text annotation and show text editor
- Type: Edit text with live update
- Esc/Click outside: Commit text
- Double-click existing: Re-enter edit mode

**Acceptance Criteria:**
- [ ] Spec document reviewed
- [ ] JSON structure defined
- [ ] Properties identified
- [ ] UI mockup for text editor overlay

---

### Phase 2: Implement Behavior (2.5 hours)

**Tasks:**

1. **Create TextAnnotation struct** (45 min)
   - Implement Annotation protocol
   - Text-specific properties
   - Calculate bounds from text metrics
   - Hit testing with text rect

2. **Create TextTool class** (1 hour)
   - Mouse down: Place text annotation
   - Show text editor overlay at position
   - Track editing state
   - Update annotation text on change
   - Commit on Esc/click outside

3. **Text editor overlay** (45 min)
   - SwiftUI TextField or TextEditor
   - Position at annotation location
   - Style with font properties
   - Auto-focus on show
   - Dismiss handlers

**Code Structure:**
```swift
final class TextTool: AnnotationTool {
    let id = "text"
    let name = "Text"
    let iconName = "textformat"

    private var editingAnnotationID: UUID?
    private var textEditorPosition: CGPoint?

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas)
}

struct TextEditorOverlay: View {
    @Binding var text: String
    let position: CGPoint
    let font: Font
    let color: Color
    let onCommit: () -> Void
}
```

**Acceptance Criteria:**
- [ ] TextAnnotation compiles
- [ ] TextTool compiles
- [ ] Text editor shows on click
- [ ] Text updates live
- [ ] Editor commits on dismiss

---

### Phase 3: Integrate with Canvas (1 hour)

**Tasks:**

1. **Register tool** (5 min)
2. **Add rendering** (30 min)
   - Render text with font/color
   - Apply background if set
   - Handle multiline wrapping
3. **Text editor overlay in ContentView** (25 min)
   - ZStack overlay for editor
   - Position based on canvas coordinates
   - Wire commit to canvas API

**Acceptance Criteria:**
- [ ] Tool in toolbar
- [ ] Text renders with correct font
- [ ] Background renders if set
- [ ] Editor overlay shows/hides
- [ ] Undo/redo works

---

### Phase 4: Test (45 min)

**Manual Test Cases:**

1. **Basic Text Entry**
   - [ ] Click → editor appears
   - [ ] Type text → shows in editor
   - [ ] Press Esc → commits text
   - [ ] Text appears on canvas

2. **Text Properties**
   - [ ] Change font → text font updates
   - [ ] Change size → text size updates
   - [ ] Change color → text color updates
   - [ ] Add background → background renders

3. **Multiline Text**
   - [ ] Enter newlines → renders multiline
   - [ ] Fixed width → wraps text
   - [ ] Auto-width → expands horizontally

4. **Edit Existing**
   - [ ] Double-click text → editor appears
   - [ ] Edit text → updates annotation
   - [ ] Commit → saves changes

5. **Transforms**
   - [ ] Rotate text → rotates correctly
   - [ ] Scale text → size changes (not font size)
   - [ ] Flip text → mirrors

6. **Undo/Redo**
   - [ ] Undo create → text disappears
   - [ ] Undo edit → reverts to old text
   - [ ] Redo → reapplies changes

---

## Tool 3: Freehand Tool

### Phase 1: Refine Requirements & Specs (30 min)

**Core Requirements:**
- Draw smooth freehand strokes
- Support pressure sensitivity (if available)
- Stroke smoothing algorithm
- Configurable stroke color and width

**Properties:**
```swift
struct FreehandAnnotation {
    // Base
    id: UUID
    zIndex: Int
    visible: Bool
    locked: Bool
    transform: AnnotationTransform
    size: CGSize  // Bounding box

    // Freehand-specific
    points: [CGPoint]        // Stroke path points
    stroke: Color
    strokeWidth: CGFloat
    smoothing: CGFloat       // 0.0-1.0, higher = smoother
    pressureValues: [CGFloat]? // Optional pressure per point
}
```

**JSON Structure:**
```json
{
  "type": "freehand",
  "points": [
    { "x": 10.0, "y": 20.0 },
    { "x": 15.0, "y": 25.0 },
    { "x": 20.0, "y": 22.0 }
  ],
  "stroke": { "r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0 },
  "strokeWidth": 3.0,
  "smoothing": 0.5,
  "pressureValues": null
}
```

**User Interactions:**
- Mouse down: Start stroke
- Mouse drag: Capture points continuously
- Mouse up: Finish stroke with smoothing
- Preview shows raw points during drag

**Acceptance Criteria:**
- [ ] Spec reviewed
- [ ] Smoothing algorithm chosen (Catmull-Rom spline)
- [ ] JSON structure defined
- [ ] Performance considerations documented

---

### Phase 2: Implement Behavior (2 hours)

**Tasks:**

1. **Create FreehandAnnotation struct** (30 min)
   - Point array storage
   - Bounding box calculation from points
   - Hit testing using path

2. **Create FreehandTool class** (1 hour)
   - Capture points on drag
   - Throttle point capture (every 5-10px)
   - Apply smoothing on mouse up
   - Create annotation via canvas API

3. **Smoothing algorithm** (30 min)
   - Implement Catmull-Rom spline
   - Reduce point count while preserving shape
   - Configurable smoothing factor

**Code Structure:**
```swift
final class FreehandTool: AnnotationTool {
    let id = "freehand"
    let name = "Freehand"
    let iconName = "pencil"

    private var points: [CGPoint] = []
    private var strokeColor: Color = .black
    private var strokeWidth: CGFloat = 3.0

    func smoothPoints(_ points: [CGPoint], factor: CGFloat) -> [CGPoint]
}
```

**Acceptance Criteria:**
- [ ] Smooth curves render
- [ ] Performance acceptable (60fps)
- [ ] Points captured efficiently

---

### Phase 3: Integrate with Canvas (45 min)

**Tasks:**
1. Register tool (5 min)
2. Add path rendering (25 min)
3. Wire to UI (15 min)

**Acceptance Criteria:**
- [ ] Freehand strokes render smoothly
- [ ] Preview shows during drawing
- [ ] Undo/redo works

---

### Phase 4: Test (30 min)

**Manual Test Cases:**
1. **Drawing**
   - [ ] Draw smooth curve
   - [ ] Draw sharp corners
   - [ ] Draw closed loop
   - [ ] Draw very long stroke

2. **Smoothing**
   - [ ] Smoothing = 0 → jagged
   - [ ] Smoothing = 1 → very smooth
   - [ ] Smoothing preserves general shape

3. **Performance**
   - [ ] No lag during fast drawing
   - [ ] Large number of points handled

4. **Transforms**
   - [ ] Rotate stroke
   - [ ] Scale stroke
   - [ ] Flip stroke

---

## Tool 4: Highlight Tool

### Phase 1: Refine Requirements & Specs (20 min)

**Core Requirements:**
- Draw translucent highlight rectangles
- Common highlighter colors (yellow, green, pink)
- Subtle appearance (low opacity)

**Properties:**
```swift
struct HighlightAnnotation {
    // Base
    id: UUID
    zIndex: Int
    visible: Bool
    locked: Bool
    transform: AnnotationTransform
    size: CGSize

    // Highlight-specific
    fill: Color  // Typically opacity 0.3-0.4
}
```

**JSON Structure:**
```json
{
  "type": "highlight",
  "fill": { "r": 1.0, "g": 1.0, "b": 0.0, "a": 0.35 }
}
```

**User Interactions:**
- Same as rectangle tool
- Default opacity: 0.35
- No stroke (unlike rectangle)

**Acceptance Criteria:**
- [ ] Spec reviewed (very similar to rectangle)
- [ ] Default colors chosen
- [ ] JSON structure defined

---

### Phase 2: Implement Behavior (1 hour)

**Tasks:**

1. **Create HighlightAnnotation struct** (20 min)
   - Similar to RectangleAnnotation
   - Only fill, no stroke

2. **Create HighlightTool class** (40 min)
   - Copy RectangleTool logic
   - Remove stroke
   - Force opacity range 0.2-0.5

**Code Structure:**
```swift
final class HighlightTool: AnnotationTool {
    let id = "highlight"
    let name = "Highlight"
    let iconName = "highlighter"

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var fillColor: Color = .yellow.opacity(0.35)
}
```

**Acceptance Criteria:**
- [ ] Highlight tool works like rectangle
- [ ] No stroke rendered
- [ ] Opacity enforced

---

### Phase 3: Integrate with Canvas (30 min)

**Tasks:**
1. Register tool (5 min)
2. Add rendering (15 min)
3. Wire to UI (10 min)

**Acceptance Criteria:**
- [ ] Tool in toolbar
- [ ] Highlights render translucent
- [ ] Undo/redo works

---

### Phase 4: Test (20 min)

**Manual Test Cases:**
1. [ ] Draw highlight over text
2. [ ] Highlight opacity correct
3. [ ] Multiple overlapping highlights
4. [ ] Transform highlight

---

## Tool 5: Number Tool

### Phase 1: Refine Requirements & Specs (25 min)

**Core Requirements:**
- Auto-incrementing numbered markers
- Circular background with number text
- Sequential numbering (1, 2, 3...)
- Configurable colors and size

**Properties:**
```swift
struct NumberAnnotation {
    // Base
    id: UUID
    zIndex: Int
    visible: Bool
    locked: Bool
    transform: AnnotationTransform
    size: CGSize  // Circle diameter

    // Number-specific
    number: Int
    backgroundColor: Color  // Circle fill
    textColor: Color        // Number color
    fontSize: CGFloat
}
```

**JSON Structure:**
```json
{
  "type": "number",
  "number": 1,
  "backgroundColor": { "r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0 },
  "textColor": { "r": 1.0, "g": 1.0, "b": 1.0, "a": 1.0 },
  "fontSize": 16.0
}
```

**User Interactions:**
- Click: Place numbered marker
- Numbers auto-increment (1, 2, 3...)
- Can manually edit number in properties

**Acceptance Criteria:**
- [ ] Auto-increment logic defined
- [ ] JSON structure defined
- [ ] Size calculation documented

---

### Phase 2: Implement Behavior (1.5 hours)

**Tasks:**

1. **Create NumberAnnotation struct** (30 min)
   - Circular bounds
   - Number property
   - Text centering logic

2. **Create NumberTool class** (45 min)
   - Click to place
   - Get next number from canvas
   - Fixed size (e.g., 32x32)

3. **Canvas helper** (15 min)
   - `getNextNumberAnnotationValue()` method
   - Counts existing number annotations

**Code Structure:**
```swift
final class NumberTool: AnnotationTool {
    let id = "number"
    let name = "Number"
    let iconName = "number.circle"

    private var backgroundColor: Color = .red
    private var textColor: Color = .white
}
```

**Acceptance Criteria:**
- [ ] Numbers auto-increment
- [ ] Circle renders with number
- [ ] Hit testing works on circle

---

### Phase 3: Integrate with Canvas (30 min)

**Tasks:**
1. Register tool (5 min)
2. Add rendering (20 min)
3. Wire to UI (5 min)

**Acceptance Criteria:**
- [ ] Tool in toolbar
- [ ] Numbers increment correctly
- [ ] Undo/redo works (number sequence preserved)

---

### Phase 4: Test (25 min)

**Manual Test Cases:**
1. [ ] Place 5 numbers → 1,2,3,4,5
2. [ ] Delete #3, add new → becomes #6 (not #3)
3. [ ] Undo add → next number still correct
4. [ ] Change colors → renders with new colors
5. [ ] Transform number marker

---

## Tool 6: Blur Tool

### Phase 1: Refine Requirements & Specs (40 min)

**Core Requirements:**
- Apply gaussian blur to rectangular region
- Blur intensity control
- Real-time preview (challenging)
- Render blur at export time

**Properties:**
```swift
struct BlurAnnotation {
    // Base
    id: UUID
    zIndex: Int
    visible: Bool
    locked: Bool
    transform: AnnotationTransform
    size: CGSize

    // Blur-specific
    blurRadius: CGFloat  // Default: 10.0
    style: BlurStyle     // gaussian, pixelate, etc.
}

enum BlurStyle {
    case gaussian
    case pixelate
    case mosaic
}
```

**JSON Structure:**
```json
{
  "type": "blur",
  "blurRadius": 10.0,
  "style": "gaussian"
}
```

**User Interactions:**
- Draw rectangle like shape tool
- Preview shows blurred region
- Blur slider adjusts intensity

**Technical Considerations:**
- **Challenge:** Real-time blur is expensive
- **Solution:** Use CIFilter for blur rendering
- **Approach:** Apply blur during export, show placeholder during editing

**Acceptance Criteria:**
- [ ] Blur rendering strategy decided
- [ ] Performance acceptable
- [ ] JSON structure defined
- [ ] Export integration planned

---

### Phase 2: Implement Behavior (2.5 hours)

**Tasks:**

1. **Create BlurAnnotation struct** (30 min)
   - Properties for blur config
   - Rectangle-like bounds

2. **Create BlurTool class** (45 min)
   - Same drawing as rectangle
   - Default blur radius
   - Visual indicator (dashed rect?)

3. **Blur rendering** (1.25 hours)
   - Extract image region
   - Apply CIGaussianBlur filter
   - Composite back to canvas
   - Cache blurred result

**Code Structure:**
```swift
final class BlurTool: AnnotationTool {
    let id = "blur"
    let name = "Blur"
    let iconName = "circle.dotted"

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var blurRadius: CGFloat = 10.0
}

extension AnnotationCanvasView {
    func applyBlur(to image: NSImage,
                   in rect: CGRect,
                   radius: CGFloat) -> NSImage
}
```

**Acceptance Criteria:**
- [ ] Blur filter works
- [ ] Performance acceptable
- [ ] Placeholder renders during edit

---

### Phase 3: Integrate with Canvas (1 hour)

**Tasks:**
1. Register tool (5 min)
2. Add blur rendering (40 min)
3. Wire to UI (15 min)

**Acceptance Criteria:**
- [ ] Tool in toolbar
- [ ] Blur applied to region
- [ ] Export includes blur
- [ ] Undo/redo works

---

### Phase 4: Test (30 min)

**Manual Test Cases:**
1. [ ] Draw blur region → area blurred
2. [ ] Adjust radius → blur intensity changes
3. [ ] Multiple blur regions
4. [ ] Transform blur region
5. [ ] Export → blur persists in image
6. [ ] Performance with large blur areas

---

## Tool 7: Image Tool

### Phase 1: Refine Requirements & Specs (30 min)

**Core Requirements:**
- Place images on canvas
- Support drag-and-drop
- Support file picker
- Scale and rotate images
- Choose between embed or reference

**Properties:**
```swift
struct ImageAnnotation {
    // Base
    id: UUID
    zIndex: Int
    visible: Bool
    locked: Bool
    transform: AnnotationTransform
    size: CGSize

    // Image-specific
    imageData: Data?         // Embedded base64
    imageURL: URL?           // File reference
    storageMode: ImageStorageMode
}

enum ImageStorageMode {
    case embedded
    case referenced
}
```

**JSON Structure:**
```json
{
  "type": "image",
  "imageData": "base64encodedstring...",
  "imageURL": null,
  "storageMode": "embedded"
}
```

**User Interactions:**
- Click: Show file picker
- Drag file: Place image at drop location
- Resize handles: Scale image
- Maintain aspect ratio by default

**Acceptance Criteria:**
- [ ] Storage modes defined
- [ ] File picker integration planned
- [ ] Drag-and-drop planned
- [ ] JSON structure defined

---

### Phase 2: Implement Behavior (2 hours)

**Tasks:**

1. **Create ImageAnnotation struct** (30 min)
   - Image data handling
   - URL vs embedded logic
   - Load image from data/URL

2. **Create ImageTool class** (1 hour)
   - Show file picker on click
   - Load image
   - Calculate initial size
   - Place at click location

3. **Drag-and-drop support** (30 min)
   - CanvasView accepts drops
   - Extract image from drop
   - Create annotation at drop point

**Code Structure:**
```swift
final class ImageTool: AnnotationTool {
    let id = "image"
    let name = "Image"
    let iconName = "photo"

    func showFilePicker(completion: @escaping (NSImage?) -> Void)
}
```

**Acceptance Criteria:**
- [ ] File picker opens
- [ ] Image loads and displays
- [ ] Drag-and-drop works
- [ ] Aspect ratio maintained

---

### Phase 3: Integrate with Canvas (45 min)

**Tasks:**
1. Register tool (5 min)
2. Add image rendering (25 min)
3. Wire to UI and drag-drop (15 min)

**Acceptance Criteria:**
- [ ] Tool in toolbar
- [ ] Images render correctly
- [ ] File picker works
- [ ] Drag-drop works
- [ ] Undo/redo works

---

### Phase 4: Test (30 min)

**Manual Test Cases:**
1. [ ] Click tool → file picker opens
2. [ ] Select image → places on canvas
3. [ ] Drag image file → places at drop point
4. [ ] Scale image → maintains aspect
5. [ ] Rotate image → renders correctly
6. [ ] Large images → performance OK
7. [ ] Export with embedded images
8. [ ] Export with referenced images

---

## Tool 8: Note Tool

### Phase 1: Refine Requirements & Specs (25 min)

**Core Requirements:**
- Sticky note style annotations
- Yellow background by default
- Multiline text with fixed width
- Pin icon indicates it's a note

**Properties:**
```swift
struct NoteAnnotation {
    // Base
    id: UUID
    zIndex: Int
    visible: Bool
    locked: Bool
    transform: AnnotationTransform
    size: CGSize  // Fixed width, auto height

    // Note-specific
    text: String
    backgroundColor: Color   // Default: yellow
    textColor: Color         // Default: black
    fontSize: CGFloat
    showPin: Bool           // Pin icon in corner
}
```

**JSON Structure:**
```json
{
  "type": "note",
  "text": "Remember to...",
  "backgroundColor": { "r": 1.0, "g": 1.0, "b": 0.6, "a": 1.0 },
  "textColor": { "r": 0.0, "g": 0.0, "b": 0.0, "a": 1.0 },
  "fontSize": 14.0,
  "showPin": true
}
```

**User Interactions:**
- Click: Place note with text editor
- Fixed width (e.g., 200px)
- Auto-height based on text
- Pin icon in top-left corner

**Acceptance Criteria:**
- [ ] Sticky note design reviewed
- [ ] JSON structure defined
- [ ] Pin icon asset identified

---

### Phase 2: Implement Behavior (1.5 hours)

**Tasks:**

1. **Create NoteAnnotation struct** (30 min)
   - Text wrapping logic
   - Height calculation
   - Pin icon rendering

2. **Create NoteTool class** (45 min)
   - Similar to TextTool
   - Fixed width
   - Show text editor
   - Auto-calculate height

3. **Pin icon** (15 min)
   - SF Symbol or custom
   - Position in corner
   - Scale with note

**Code Structure:**
```swift
final class NoteTool: AnnotationTool {
    let id = "note"
    let name = "Note"
    let iconName = "note.text"

    private var backgroundColor: Color = Color(red: 1.0, green: 1.0, blue: 0.6)
    private var noteWidth: CGFloat = 200
}
```

**Acceptance Criteria:**
- [ ] Note appears like sticky note
- [ ] Text editor works
- [ ] Height adjusts to content
- [ ] Pin icon renders

---

### Phase 3: Integrate with Canvas (30 min)

**Tasks:**
1. Register tool (5 min)
2. Add rendering with pin (20 min)
3. Wire to UI (5 min)

**Acceptance Criteria:**
- [ ] Tool in toolbar
- [ ] Note renders with background
- [ ] Pin icon shows
- [ ] Undo/redo works

---

### Phase 4: Test (25 min)

**Manual Test Cases:**
1. [ ] Place note → yellow background
2. [ ] Type text → height adjusts
3. [ ] Long text → wraps correctly
4. [ ] Pin icon visible
5. [ ] Transform note
6. [ ] Change background color
7. [ ] Multiple notes

---

## Cross-Tool Testing (2 hours)

After all tools implemented, perform comprehensive integration testing:

### Test Suite

1. **Tool Switching**
   - [ ] Switch between all tools
   - [ ] No state leaks between tools
   - [ ] Previous tool deactivates

2. **Mixed Annotations**
   - [ ] Create one of each type
   - [ ] All render correctly
   - [ ] Z-order works with mix
   - [ ] Selection works on all types

3. **Undo/Redo Full Stack**
   - [ ] Create 10 annotations (mix of types)
   - [ ] Undo all → canvas empty
   - [ ] Redo all → all back

4. **Transform All Types**
   - [ ] Rotate each annotation type
   - [ ] Scale each type
   - [ ] Flip each type
   - [ ] Verify rendering correct

5. **JSON Serialization**
   - [ ] Export canvas with all types
   - [ ] Verify JSON structure
   - [ ] Import JSON
   - [ ] All annotations restored

6. **Performance**
   - [ ] 100+ annotations of each type
   - [ ] Canvas remains responsive
   - [ ] Undo/redo fast
   - [ ] Rendering smooth

7. **Edge Cases**
   - [ ] Very large annotations
   - [ ] Very small annotations
   - [ ] Annotations outside canvas
   - [ ] Overlapping annotations

---

## Implementation Schedule

### Week 1
- **Day 1 (AM):** Complete Select Tool (Tool 0A) - Move annotations
- **Day 1 (PM):** Complete Rectangle Tool (Tool 0B) - Properties integration
- **Day 2:** Line Tool (complete all 4 phases)
- **Day 3-4:** Text Tool (complete all 4 phases)
- **Day 5:** Freehand Tool (Phases 1-2)

### Week 2
- **Day 1:** Freehand Tool (Phases 3-4)
- **Day 2:** Highlight Tool (complete)
- **Day 3:** Number Tool (complete)
- **Day 4:** Blur Tool (Phases 1-2)
- **Day 5:** Blur Tool (Phases 3-4)

### Week 3
- **Day 1:** Image Tool (complete)
- **Day 2:** Note Tool (complete)
- **Day 3-4:** Cross-tool testing
- **Day 5:** Bug fixes and polish

---

## Success Criteria

**Each Tool Must:**
- [ ] Follow 4-phase implementation process
- [ ] Have complete JSON specification
- [ ] Render correctly with transforms
- [ ] Support undo/redo
- [ ] Pass manual test suite
- [ ] Build with 0 errors, 0 warnings
- [ ] Integrate with properties panel
- [ ] Work with existing canvas APIs

**Overall System Must:**
- [ ] Support all 10 annotation types
- [ ] Serialize/deserialize all types to JSON
- [ ] Handle mixed annotations on canvas
- [ ] Maintain performance with 100+ annotations
- [ ] Pass comprehensive test suite
- [ ] Have complete documentation

---

## Notes

- SelectTool and RectangleTool need completion before new tools
- MoveAnnotationsCommand is a new command type (9th command)
- No other canvas APIs needed (all tools use existing CRUD/transform APIs)
- Focus on tool-specific behavior and rendering
- Properties panels can be added incrementally
- JSON serialization will be batch-implemented after all tools complete

**Current Status:** 0/10 tools fully complete (Select and Rectangle are ~80% done)
**Next Up:** Tool 0A → Select Tool → Phase 1 (Move Annotations)
