# Canvas Architecture Fixes - Implementation Plan

## Overview

This plan addresses four critical gaps in the QuickEdit canvas implementation based on code review findings:

1. **Command Pattern + Undo/Redo** - Wrap all mutations for history management
2. **Protocol-Based Tool Integration** - Enable tools to create annotations via mouse events
3. **Event Flow Fixes** - Eliminate direct state modification violations
4. **Core CRUD APIs** - Add missing lifecycle and manipulation methods

**User Decisions:**
- Property API: Batch `updateProperties` approach (not KeyPath-based)
- Tool Design: Protocol-based with `onMouseDown/Drag/Up` methods
- Priority: ALL FOUR components are MVP-critical

**Implementation Strategy:** Each phase is small, independently implementable and testable

---

## Small Phases - Implement & Test Separately

### Phase 1A: Command Protocol & History Manager (30 min)

**Goal:** Create foundation without any command implementations yet

**Create:** `quickedit/CanvasCommand.swift`

```swift
protocol CanvasCommand: AnyObject {
    var actionName: String { get }
    func execute(on canvas: AnnotationCanvas)
    func undo(on canvas: AnnotationCanvas)
}

final class CommandHistory {
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []
    private let maxHistorySize: Int = 100

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var undoActionName: String? { undoStack.last?.actionName }
    var redoActionName: String? { redoStack.last?.actionName }

    func execute(_ command: CanvasCommand, on canvas: AnnotationCanvas) {
        command.execute(on: canvas)
        undoStack.append(command)
        redoStack.removeAll()
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
    }

    func undo(on canvas: AnnotationCanvas) {
        guard let command = undoStack.popLast() else { return }
        command.undo(on: canvas)
        redoStack.append(command)
    }

    func redo(on canvas: AnnotationCanvas) {
        guard let command = redoStack.popLast() else { return }
        command.execute(on: canvas)
        undoStack.append(command)
    }

    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
```

**Test:**
- Build succeeds
- CommandHistory can be instantiated
- Stack operations work (push/pop)

---

### Phase 1B: AddAnnotationCommand Implementation (30 min)

**Goal:** Implement simplest command for adding annotations

**Add to:** `quickedit/CanvasCommand.swift`

```swift
final class AddAnnotationCommand: CanvasCommand {
    let annotation: any Annotation
    var actionName: String { "Add \(type(of: annotation))" }

    init(annotation: any Annotation) {
        self.annotation = annotation
    }

    func execute(on canvas: AnnotationCanvas) {
        canvas.annotations.append(annotation)
        canvas.onAnnotationAdded.send(annotation)
    }

    func undo(on canvas: AnnotationCanvas) {
        canvas.annotations.removeAll { $0.id == annotation.id }
        canvas.onAnnotationDeleted.send([annotation.id])
    }
}
```

**Test:**
- Create command with RectangleAnnotation
- Execute adds to canvas.annotations
- Undo removes from canvas.annotations
- Events are emitted correctly

---

### Phase 1C: Integrate CommandHistory into Canvas (30 min)

**Goal:** Add history manager to canvas, expose undo/redo state

**Modify:** `AnnotationCanvas.swift` after line 138

```swift
// MARK: - Command History
private let commandHistory = CommandHistory()
@Published private(set) var canUndo: Bool = false
@Published private(set) var canRedo: Bool = false
@Published private(set) var undoActionName: String?
@Published private(set) var redoActionName: String?

internal func execute(_ command: CanvasCommand) {
    commandHistory.execute(command, on: self)
    updateHistoryState()
}

private func updateHistoryState() {
    canUndo = commandHistory.canUndo
    canRedo = commandHistory.canRedo
    undoActionName = commandHistory.undoActionName
    redoActionName = commandHistory.redoActionName
}
```

**Test:**
- Canvas has commandHistory instance
- execute() method works
- Published properties update correctly
- canUndo/canRedo reflect stack state

---

### Phase 2A: Canvas addAnnotation() API (20 min)

**Goal:** Public API that uses command pattern

**Add to:** `AnnotationCanvas.swift`

```swift
// MARK: - Annotation Lifecycle API

func addAnnotation(_ annotation: any Annotation) {
    let command = AddAnnotationCommand(annotation: annotation)
    execute(command)
}
```

**Fix line 335:** Replace `annotations = [first, second, third]` with:
```swift
private func seedDemoAnnotations() {
    let first = RectangleAnnotation(...)
    let second = RectangleAnnotation(...)
    let third = RectangleAnnotation(...)

    addAnnotation(first)
    addAnnotation(second)
    addAnnotation(third)
}
```

**Test:**
- Call `canvas.addAnnotation(rect)`
- Annotation appears in canvas.annotations
- canUndo becomes true
- Demo data loads correctly

---

### Phase 2B: Canvas undo/redo APIs (20 min)

**Goal:** Public undo/redo methods

**Add to:** `AnnotationCanvas.swift`

```swift
// MARK: - History API

func undo() {
    commandHistory.undo(on: self)
    updateHistoryState()
}

func redo() {
    commandHistory.redo(on: self)
    updateHistoryState()
}

func clearHistory() {
    commandHistory.clear()
    updateHistoryState()
}
```

**Update:** `ContentView.swift` lines 486-488
```swift
MainToolbar(
    canvas: canvas,
    onColor: { showingColorSheet = true },
    onUndo: { canvas.undo() },
    onRedo: { canvas.redo() },
    onSettings: { showingSettingsSheet = true }
)
```

**Test:**
- Add annotation → undo → annotation removed
- Redo → annotation back
- canUndo/canRedo toggle correctly
- Toolbar undo/redo buttons work

---

### Phase 2C: DeleteAnnotationsCommand (30 min)

**Goal:** Implement delete with undo support

**Add to:** `CanvasCommand.swift`

```swift
final class DeleteAnnotationsCommand: CanvasCommand {
    let annotationIDs: Set<UUID>
    private var savedAnnotations: [any Annotation] = []

    var actionName: String {
        annotationIDs.count == 1 ? "Delete Annotation" : "Delete \(annotationIDs.count) Annotations"
    }

    init(annotationIDs: Set<UUID>) {
        self.annotationIDs = annotationIDs
    }

    func execute(on canvas: AnnotationCanvas) {
        savedAnnotations = canvas.annotations.filter { annotationIDs.contains($0.id) }
        canvas.annotations.removeAll { annotationIDs.contains($0.id) }
        canvas.onAnnotationDeleted.send(annotationIDs)
        canvas.selectedAnnotationIDs.subtract(annotationIDs)
    }

    func undo(on canvas: AnnotationCanvas) {
        canvas.annotations.append(contentsOf: savedAnnotations)
        canvas.annotations.sort { $0.zIndex < $1.zIndex }
        for annotation in savedAnnotations {
            canvas.onAnnotationAdded.send(annotation)
        }
    }
}
```

**Add to:** `AnnotationCanvas.swift`

```swift
func deleteAnnotations(_ ids: Set<UUID>) {
    guard !ids.isEmpty else { return }
    let command = DeleteAnnotationsCommand(annotationIDs: ids)
    execute(command)
}

func deleteSelected() {
    guard !selectedAnnotationIDs.isEmpty else { return }
    deleteAnnotations(selectedAnnotationIDs)
}
```

**Test:**
- Delete annotation → removed
- Undo → annotation restored with correct z-index
- Delete multiple → all removed
- Selection cleared after delete

---

### Phase 2D: UpdatePropertiesCommand (45 min)

**Goal:** Generic property updates with undo

**Add to:** `CanvasCommand.swift`

```swift
final class UpdatePropertiesCommand: CanvasCommand {
    let annotationID: UUID
    private var oldProperties: [String: Any] = [:]
    private var newProperties: [String: Any] = [:]

    var actionName: String { "Update Properties" }

    init(annotationID: UUID, updates: [String: Any]) {
        self.annotationID = annotationID
        self.newProperties = updates
    }

    func execute(on canvas: AnnotationCanvas) {
        guard let index = canvas.annotations.firstIndex(where: { $0.id == annotationID }) else { return }
        let annotation = canvas.annotations[index]
        oldProperties = captureProperties(from: annotation)
        applyProperties(newProperties, to: &canvas.annotations[index])
        canvas.onAnnotationModified.send(annotationID)
    }

    func undo(on canvas: AnnotationCanvas) {
        guard let index = canvas.annotations.firstIndex(where: { $0.id == annotationID }) else { return }
        applyProperties(oldProperties, to: &canvas.annotations[index])
        canvas.onAnnotationModified.send(annotationID)
    }

    private func captureProperties(from annotation: any Annotation) -> [String: Any] {
        var props: [String: Any] = [:]
        props["transform"] = annotation.transform
        props["size"] = annotation.size
        props["visible"] = annotation.visible
        props["locked"] = annotation.locked
        props["zIndex"] = annotation.zIndex
        return props
    }

    private func applyProperties(_ properties: [String: Any], to annotation: inout any Annotation) {
        if let transform = properties["transform"] as? AnnotationTransform {
            annotation.transform = transform
        }
        if let size = properties["size"] as? CGSize {
            annotation.size = size
        }
        if let visible = properties["visible"] as? Bool {
            annotation.visible = visible
        }
        if let locked = properties["locked"] as? Bool {
            annotation.locked = locked
        }
        if let zIndex = properties["zIndex"] as? Int {
            annotation.zIndex = zIndex
        }
    }
}

final class BatchCommand: CanvasCommand {
    let commands: [CanvasCommand]
    let actionName: String

    init(actionName: String, commands: [CanvasCommand]) {
        self.actionName = actionName
        self.commands = commands
    }

    func execute(on canvas: AnnotationCanvas) {
        for command in commands {
            command.execute(on: canvas)
        }
    }

    func undo(on canvas: AnnotationCanvas) {
        for command in commands.reversed() {
            command.undo(on: canvas)
        }
    }
}
```

**Add to:** `AnnotationCanvas.swift`

```swift
func updateProperties(for annotationIDs: Set<UUID>, updates: [String: Any]) {
    guard !annotationIDs.isEmpty else { return }

    var commands: [CanvasCommand] = []
    for id in annotationIDs {
        commands.append(UpdatePropertiesCommand(annotationID: id, updates: updates))
    }

    let batch = BatchCommand(actionName: "Update Properties", commands: commands)
    execute(batch)
}

// Convenience methods
func updateTransform(for ids: Set<UUID>, transform: AnnotationTransform) {
    updateProperties(for: ids, updates: ["transform": transform])
}

func updateVisibility(for ids: Set<UUID>, visible: Bool) {
    updateProperties(for: ids, updates: ["visible": visible])
}

func updateLocked(for ids: Set<UUID>, locked: Bool) {
    updateProperties(for: ids, updates: ["locked": locked])
}
```

**Test:**
- Update single property → changes applied
- Undo → reverts to old value
- Update multiple annotations → batch command works
- Batch undo in single operation

---

### Phase 2E: ArrangeCommand + Comprehensive Transform APIs (45 min)

**Goal:** Z-index, alignment, rotation, flip with undo

**Add to:** `CanvasCommand.swift`

```swift
// MARK: - Arrange Command (Z-Index)

final class ArrangeCommand: CanvasCommand {
    enum Action {
        case bringToFront, sendToBack, bringForward, sendBackward
    }

    let annotationIDs: Set<UUID>
    let action: Action
    private var oldZIndices: [UUID: Int] = [:]

    var actionName: String {
        switch action {
        case .bringToFront: return "Bring to Front"
        case .sendToBack: return "Send to Back"
        case .bringForward: return "Bring Forward"
        case .sendBackward: return "Send Backward"
        }
    }

    init(annotationIDs: Set<UUID>, action: Action) {
        self.annotationIDs = annotationIDs
        self.action = action
    }

    func execute(on canvas: AnnotationCanvas) {
        for annotation in canvas.annotations where annotationIDs.contains(annotation.id) {
            oldZIndices[annotation.id] = annotation.zIndex
        }

        let maxZ = canvas.annotations.map(\.zIndex).max() ?? 0
        let minZ = canvas.annotations.map(\.zIndex).min() ?? 0

        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            switch action {
            case .bringToFront: canvas.annotations[i].zIndex = maxZ + 1
            case .sendToBack: canvas.annotations[i].zIndex = minZ - 1
            case .bringForward: canvas.annotations[i].zIndex += 1
            case .sendBackward: canvas.annotations[i].zIndex -= 1
            }
            canvas.onAnnotationModified.send(canvas.annotations[i].id)
        }
    }

    func undo(on canvas: AnnotationCanvas) {
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            if let oldZ = oldZIndices[canvas.annotations[i].id] {
                canvas.annotations[i].zIndex = oldZ
                canvas.onAnnotationModified.send(canvas.annotations[i].id)
            }
        }
    }
}

// MARK: - Alignment Command

final class AlignCommand: CanvasCommand {
    enum Alignment {
        case left, right, top, bottom
        case centerHorizontal, centerVertical
        case center  // Both horizontal and vertical
    }

    let annotationIDs: Set<UUID>
    let alignment: Alignment
    private var oldPositions: [UUID: CGPoint] = [:]

    var actionName: String {
        switch alignment {
        case .left: return "Align Left"
        case .right: return "Align Right"
        case .top: return "Align Top"
        case .bottom: return "Align Bottom"
        case .centerHorizontal: return "Align Center Horizontally"
        case .centerVertical: return "Align Center Vertically"
        case .center: return "Align Center"
        }
    }

    init(annotationIDs: Set<UUID>, alignment: Alignment) {
        self.annotationIDs = annotationIDs
        self.alignment = alignment
    }

    func execute(on canvas: AnnotationCanvas) {
        let annotations = canvas.annotations.filter { annotationIDs.contains($0.id) }
        guard !annotations.isEmpty else { return }

        // Save old positions
        for annotation in annotations {
            oldPositions[annotation.id] = annotation.transform.position
        }

        // Calculate bounds of all selected annotations
        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for annotation in annotations {
            let pos = annotation.transform.position
            let size = annotation.size
            minX = min(minX, pos.x)
            maxX = max(maxX, pos.x + size.width)
            minY = min(minY, pos.y)
            maxY = max(maxY, pos.y + size.height)
        }

        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2

        // Apply alignment
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            var transform = canvas.annotations[i].transform
            let size = canvas.annotations[i].size

            switch alignment {
            case .left:
                transform.position.x = minX
            case .right:
                transform.position.x = maxX - size.width
            case .top:
                transform.position.y = minY
            case .bottom:
                transform.position.y = maxY - size.height
            case .centerHorizontal:
                transform.position.x = centerX - size.width / 2
            case .centerVertical:
                transform.position.y = centerY - size.height / 2
            case .center:
                transform.position.x = centerX - size.width / 2
                transform.position.y = centerY - size.height / 2
            }

            canvas.annotations[i].transform = transform
            canvas.onAnnotationModified.send(canvas.annotations[i].id)
        }
    }

    func undo(on canvas: AnnotationCanvas) {
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            if let oldPos = oldPositions[canvas.annotations[i].id] {
                canvas.annotations[i].transform.position = oldPos
                canvas.onAnnotationModified.send(canvas.annotations[i].id)
            }
        }
    }
}

// MARK: - Distribute Command

final class DistributeCommand: CanvasCommand {
    enum Direction {
        case horizontal, vertical
    }

    let annotationIDs: Set<UUID>
    let direction: Direction
    private var oldPositions: [UUID: CGPoint] = [:]

    var actionName: String {
        direction == .horizontal ? "Distribute Horizontally" : "Distribute Vertically"
    }

    init(annotationIDs: Set<UUID>, direction: Direction) {
        self.annotationIDs = annotationIDs
        self.direction = direction
    }

    func execute(on canvas: AnnotationCanvas) {
        var annotations = canvas.annotations.filter { annotationIDs.contains($0.id) }
        guard annotations.count >= 3 else { return }  // Need at least 3 items

        // Save old positions
        for annotation in annotations {
            oldPositions[annotation.id] = annotation.transform.position
        }

        // Sort by position
        annotations.sort { first, second in
            direction == .horizontal
                ? first.transform.position.x < second.transform.position.x
                : first.transform.position.y < second.transform.position.y
        }

        let first = annotations.first!
        let last = annotations.last!

        let totalSpace = direction == .horizontal
            ? (last.transform.position.x + last.size.width) - first.transform.position.x
            : (last.transform.position.y + last.size.height) - first.transform.position.y

        let totalItemSize = annotations.dropFirst().dropLast().reduce(0.0) { sum, annotation in
            sum + (direction == .horizontal ? annotation.size.width : annotation.size.height)
        }

        let spacing = (totalSpace - totalItemSize - (direction == .horizontal ? first.size.width : first.size.height) - (direction == .horizontal ? last.size.width : last.size.height)) / CGFloat(annotations.count - 1)

        // Distribute items
        var currentPos = direction == .horizontal
            ? first.transform.position.x + first.size.width + spacing
            : first.transform.position.y + first.size.height + spacing

        for i in 1..<(annotations.count - 1) {
            let annotation = annotations[i]
            if let index = canvas.annotations.firstIndex(where: { $0.id == annotation.id }) {
                if direction == .horizontal {
                    canvas.annotations[index].transform.position.x = currentPos
                    currentPos += annotation.size.width + spacing
                } else {
                    canvas.annotations[index].transform.position.y = currentPos
                    currentPos += annotation.size.height + spacing
                }
                canvas.onAnnotationModified.send(annotation.id)
            }
        }
    }

    func undo(on canvas: AnnotationCanvas) {
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            if let oldPos = oldPositions[canvas.annotations[i].id] {
                canvas.annotations[i].transform.position = oldPos
                canvas.onAnnotationModified.send(canvas.annotations[i].id)
            }
        }
    }
}

// MARK: - Rotate Command

final class RotateCommand: CanvasCommand {
    enum RotationType {
        case rotate90, rotateMinus90
        case flipHorizontal, flipVertical
    }

    let annotationIDs: Set<UUID>
    let rotationType: RotationType
    private var oldTransforms: [UUID: AnnotationTransform] = [:]

    var actionName: String {
        switch rotationType {
        case .rotate90: return "Rotate 90°"
        case .rotateMinus90: return "Rotate -90°"
        case .flipHorizontal: return "Flip Horizontal"
        case .flipVertical: return "Flip Vertical"
        }
    }

    init(annotationIDs: Set<UUID>, rotationType: RotationType) {
        self.annotationIDs = annotationIDs
        self.rotationType = rotationType
    }

    func execute(on canvas: AnnotationCanvas) {
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            // Save old transform
            oldTransforms[canvas.annotations[i].id] = canvas.annotations[i].transform

            var transform = canvas.annotations[i].transform

            switch rotationType {
            case .rotate90:
                transform.rotation = Angle(degrees: transform.rotation.degrees + 90)
            case .rotateMinus90:
                transform.rotation = Angle(degrees: transform.rotation.degrees - 90)
            case .flipHorizontal:
                transform.scale.width *= -1
            case .flipVertical:
                transform.scale.height *= -1
            }

            canvas.annotations[i].transform = transform
            canvas.onAnnotationModified.send(canvas.annotations[i].id)
        }
    }

    func undo(on canvas: AnnotationCanvas) {
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            if let oldTransform = oldTransforms[canvas.annotations[i].id] {
                canvas.annotations[i].transform = oldTransform
                canvas.onAnnotationModified.send(canvas.annotations[i].id)
            }
        }
    }
}
```

**Add to:** `AnnotationCanvas.swift`

```swift
// MARK: - Arrangement API (Z-Index)

func arrange(_ action: ArrangeCommand.Action, for ids: Set<UUID>? = nil) {
    let targetIDs = ids ?? selectedAnnotationIDs
    guard !targetIDs.isEmpty else { return }
    let command = ArrangeCommand(annotationIDs: targetIDs, action: action)
    execute(command)
}

func bringToFront(_ ids: Set<UUID>? = nil) {
    arrange(.bringToFront, for: ids)
}

func sendToBack(_ ids: Set<UUID>? = nil) {
    arrange(.sendToBack, for: ids)
}

func bringForward(_ ids: Set<UUID>? = nil) {
    arrange(.bringForward, for: ids)
}

func sendBackward(_ ids: Set<UUID>? = nil) {
    arrange(.sendBackward, for: ids)
}

// MARK: - Alignment API

func align(_ alignment: AlignCommand.Alignment, for ids: Set<UUID>? = nil) {
    let targetIDs = ids ?? selectedAnnotationIDs
    guard !targetIDs.isEmpty else { return }
    let command = AlignCommand(annotationIDs: targetIDs, alignment: alignment)
    execute(command)
}

func alignLeft(_ ids: Set<UUID>? = nil) {
    align(.left, for: ids)
}

func alignRight(_ ids: Set<UUID>? = nil) {
    align(.right, for: ids)
}

func alignTop(_ ids: Set<UUID>? = nil) {
    align(.top, for: ids)
}

func alignBottom(_ ids: Set<UUID>? = nil) {
    align(.bottom, for: ids)
}

func alignCenterHorizontal(_ ids: Set<UUID>? = nil) {
    align(.centerHorizontal, for: ids)
}

func alignCenterVertical(_ ids: Set<UUID>? = nil) {
    align(.centerVertical, for: ids)
}

func alignCenter(_ ids: Set<UUID>? = nil) {
    align(.center, for: ids)
}

// MARK: - Distribution API

func distribute(_ direction: DistributeCommand.Direction, for ids: Set<UUID>? = nil) {
    let targetIDs = ids ?? selectedAnnotationIDs
    guard targetIDs.count >= 3 else { return }  // Need at least 3 items
    let command = DistributeCommand(annotationIDs: targetIDs, direction: direction)
    execute(command)
}

func distributeHorizontally(_ ids: Set<UUID>? = nil) {
    distribute(.horizontal, for: ids)
}

func distributeVertically(_ ids: Set<UUID>? = nil) {
    distribute(.vertical, for: ids)
}

// MARK: - Rotation & Flip API

func rotate(_ rotationType: RotateCommand.RotationType, for ids: Set<UUID>? = nil) {
    let targetIDs = ids ?? selectedAnnotationIDs
    guard !targetIDs.isEmpty else { return }
    let command = RotateCommand(annotationIDs: targetIDs, rotationType: rotationType)
    execute(command)
}

func rotate90(_ ids: Set<UUID>? = nil) {
    rotate(.rotate90, for: ids)
}

func rotateMinus90(_ ids: Set<UUID>? = nil) {
    rotate(.rotateMinus90, for: ids)
}

func flipHorizontal(_ ids: Set<UUID>? = nil) {
    rotate(.flipHorizontal, for: ids)
}

func flipVertical(_ ids: Set<UUID>? = nil) {
    rotate(.flipVertical, for: ids)
}
```

**Test:**
- **Z-Index:** Bring to front/back, forward/backward with undo
- **Alignment:** Align left/right/top/bottom/center with undo
- **Distribution:** Distribute 3+ items horizontally/vertically with undo
- **Rotation:** Rotate ±90° with undo
- **Flip:** Flip horizontal/vertical with undo

---

### Phase 3A: Tool Protocol Definition (20 min)

**Goal:** Define protocol without implementations

**Create:** `quickedit/AnnotationTool.swift`

```swift
import SwiftUI

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

extension AnnotationTool {
    func activate() {}
    func deactivate() {}
    func onCancel(on canvas: AnnotationCanvas) {}
    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {}
}

final class ToolRegistry {
    static let shared = ToolRegistry()

    private var tools: [String: AnnotationTool] = [:]

    private init() {}

    func register(_ tool: AnnotationTool) {
        tools[tool.id] = tool
    }

    func tool(withID id: String) -> AnnotationTool? {
        tools[id]
    }

    func allTools() -> [AnnotationTool] {
        Array(tools.values)
    }
}
```

**Test:**
- Build succeeds
- ToolRegistry can register/retrieve tools
- Protocol compiles

---

### Phase 3B: SelectTool Implementation (30 min)

**Goal:** Simplest tool - selection only

**Add to:** `AnnotationTool.swift`

```swift
final class SelectTool: AnnotationTool {
    let id = "select"
    let name = "Select"
    let iconName = "cursorarrow"

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        if let hit = canvas.annotation(at: point) {
            canvas.toggleSelection(for: hit.id)
        } else {
            canvas.clearSelection()
        }
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        // TODO: Drag to move selected
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        if canvas.snapToGrid {
            canvas.applyGridSnapping(enabled: true, gridSize: canvas.gridSize)
        }
    }
}
```

**Register in:** `ToolRegistry.init()`

```swift
private init() {
    register(SelectTool())
}
```

**Test:**
- Create SelectTool instance
- Call onMouseDown with annotation location → selects
- Call with empty space → clears selection
- Registry returns SelectTool by ID

---

### Phase 3C: RectangleTool with Preview (45 min)

**Goal:** Full tool with mouse events and preview rendering

**Add to:** `AnnotationTool.swift`

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
        let imagePoint = canvas.canvasToImage(point)
        startPoint = imagePoint
        currentPoint = imagePoint
        canvas.onInteractionBegan.send("drawing_rectangle")
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        let imagePoint = canvas.canvasToImage(point)
        currentPoint = imagePoint
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard let start = startPoint else { return }
        let imagePoint = canvas.canvasToImage(point)

        let minX = min(start.x, imagePoint.x)
        let minY = min(start.y, imagePoint.y)
        let width = abs(imagePoint.x - start.x)
        let height = abs(imagePoint.y - start.y)

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

        canvas.addAnnotation(rect)

        startPoint = nil
        currentPoint = nil
        canvas.onInteractionEnded.send("drawing_rectangle")
    }

    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
        guard let start = startPoint, let end = currentPoint else { return }

        let canvasStart = canvas.imageToCanvas(start)
        let canvasEnd = canvas.imageToCanvas(end)

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
        startPoint = nil
        currentPoint = nil
    }
}
```

**Register in:** `ToolRegistry.init()`

```swift
private init() {
    register(SelectTool())
    register(RectangleTool())
}
```

**Test:**
- Mouse down → captures start point
- Mouse drag → updates current point
- Mouse up → creates RectangleAnnotation
- Preview renders during drag
- Deactivate clears state

---

### Phase 3D: Canvas Tool Management (20 min)

**Goal:** Update canvas to use protocol-based tools

**Modify:** `AnnotationCanvas.swift`

**Change line 127:**
```swift
@Published private(set) var activeTool: (any AnnotationTool)? = nil
```

**Update lines 167-173:**
```swift
func setActiveTool(_ tool: (any AnnotationTool)?) {
    activeTool?.deactivate()
    activeTool = tool
    tool?.activate()
}

func isToolActive(_ toolID: String) -> Bool {
    activeTool?.id == toolID
}
```

**Test:**
- Set tool → activeTool property updates
- Published property notifies observers
- Deactivate called on old tool
- Activate called on new tool
- isToolActive returns correct result

---

### Phase 4A: Add Pan APIs (15 min)

**Goal:** Canvas API for pan operations

**Add to:** `AnnotationCanvas.swift` after line 267

```swift
// MARK: - Pan API

func pan(by delta: CGPoint) {
    panOffset.x += delta.x
    panOffset.y += delta.y
}

func setPanOffset(_ offset: CGPoint) {
    panOffset = offset
}
```

**Test:**
- Call pan() → panOffset changes
- Call setPanOffset() → panOffset set directly
- Published property notifies observers

---

### Phase 4B: Fix PanOffset Violation (15 min)

**Goal:** View uses API instead of direct mutation

**Modify:** `AnnotationCanvasView.swift` lines 51-54

**Replace:**
```swift
canvas.panOffset = CGPoint(
    x: initialPanOffset.x + value.translation.width,
    y: initialPanOffset.y + value.translation.height
)
```

**With:**
```swift
canvas.setPanOffset(CGPoint(
    x: initialPanOffset.x + value.translation.width,
    y: initialPanOffset.y + value.translation.height
))
```

**Test:**
- Drag canvas → pan works
- Canvas API called (not direct mutation)
- View observes changes via @Published

---

### Phase 4C: Tool Event Forwarding (30 min)

**Goal:** View forwards mouse events to active tool

**Modify:** `AnnotationCanvasView.swift`

**Update dragGesture (lines 43-63):**
```swift
private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 0)
        .onChanged { value in
            if !isDragging {
                isDragging = true
                initialPanOffset = canvas.panOffset

                if let tool = canvas.activeTool {
                    tool.onMouseDown(at: value.startLocation, on: canvas)
                }
            }

            if canvas.activeTool != nil {
                canvas.activeTool?.onMouseDrag(to: value.location, on: canvas)
            } else {
                canvas.setPanOffset(CGPoint(
                    x: initialPanOffset.x + value.translation.width,
                    y: initialPanOffset.y + value.translation.height
                ))
            }
        }
        .onEnded { value in
            defer { isDragging = false }

            if let tool = canvas.activeTool {
                tool.onMouseUp(at: value.location, on: canvas)
            }
        }
}
```

**Update handleTap (lines 80-90):**
```swift
private func handleTap(at location: CGPoint) {
    if let tool = canvas.activeTool {
        tool.onMouseDown(at: location, on: canvas)
        tool.onMouseUp(at: location, on: canvas)
    }
}
```

**Test:**
- With tool active: events forwarded to tool
- Without tool: canvas pans
- Tool creates annotations on interaction
- Tap vs drag distinguished correctly

---

### Phase 4D: Tool Preview Rendering (15 min)

**Goal:** Render tool preview during interaction

**Modify:** `AnnotationCanvasView.swift` after line 33

**Add after drawSelectionHandles:**
```swift
drawAnnotations(in: &context)
drawSelectionHandles(in: &context)

// Tool preview
if let tool = canvas.activeTool {
    tool.renderPreview(in: &context, canvas: canvas)
}
```

**Test:**
- Activate RectangleTool
- Drag → preview rectangle renders
- Release → preview disappears, annotation created
- Preview updates smoothly during drag

---

### Phase 5: UI Migration (30 min)

**Goal:** Update ContentView to use protocol tools

**Modify:** `ContentView.swift`

**Rename enum (line 183):**
```swift
enum ToolIdentifier: String, CaseIterable {
    case select, freehand, highlight, blur, line, shape, text, number, image, note

    var label: String { /* keep existing */ }
    var systemImage: String { /* keep existing */ }

    func createTool() -> (any AnnotationTool)? {
        switch self {
        case .select:
            return ToolRegistry.shared.tool(withID: "select")
        case .shape:
            return ToolRegistry.shared.tool(withID: "rectangle")
        default:
            return nil  // TODO: Implement other tools
        }
    }
}
```

**Update MainToolbar (lines 936-943):**
```swift
private func toolbarGroup(title: String, category: ToolCategory) -> some View {
    HStack(spacing: UIConstants.toolSpacing) {
        ForEach(items.filter { $0.category == category }) { item in
            ToolbarButton(item: item, selectedTool: Binding(
                get: { canvas.activeTool?.id },
                set: { toolID in
                    if let toolID = toolID,
                       let tool = ToolRegistry.shared.tool(withID: toolID) {
                        canvas.setActiveTool(tool)
                    }
                }
            ))
        }
    }
}
```

**Update ToolbarButton isSelected (lines 952-955):**
```swift
var isSelected: Bool {
    guard let tool = item.tool else { return false }
    if let toolID = ToolIdentifier(rawValue: tool.rawValue)?.createTool()?.id {
        return toolID == selectedTool
    }
    return false
}
```

**Update EditorViewModel (lines 390-404):**
```swift
canvas.$activeTool
    .compactMap { $0?.id }
    .removeDuplicates()
    .receive(on: RunLoop.main)
    .sink { [weak self] toolID in
        guard let self else { return }
        // Map tool ID back to enum for UI
        if let identifier = ToolIdentifier.allCases.first(where: {
            $0.createTool()?.id == toolID
        }) {
            if self.selectedTool.rawValue != identifier.rawValue {
                self.selectedTool = identifier
            }
        }
    }
    .store(in: &cancellables)
```

**Test:**
- Click Select tool → SelectTool activates
- Click Shape tool → RectangleTool activates
- Toolbar highlights correct button
- Tool switching works
- EditorViewModel syncs correctly

---

## Summary by Phase

| Phase | Time | Files | Description |
|-------|------|-------|-------------|
| 1A | 30 min | NEW `CanvasCommand.swift` | Protocol + CommandHistory |
| 1B | 30 min | ADD to `CanvasCommand.swift` | AddAnnotationCommand |
| 1C | 30 min | MODIFY `AnnotationCanvas.swift` | Integrate history manager |
| 2A | 20 min | MODIFY `AnnotationCanvas.swift` | addAnnotation() API + fix demo data |
| 2B | 20 min | MODIFY `AnnotationCanvas.swift` + `ContentView.swift` | undo/redo APIs + wire toolbar |
| 2C | 30 min | ADD to `CanvasCommand.swift` + `AnnotationCanvas.swift` | DeleteAnnotationsCommand + API |
| 2D | 45 min | ADD to `CanvasCommand.swift` + `AnnotationCanvas.swift` | UpdatePropertiesCommand + BatchCommand + APIs |
| 2E | 45 min | ADD to `CanvasCommand.swift` + `AnnotationCanvas.swift` | ArrangeCommand + AlignCommand + DistributeCommand + RotateCommand + comprehensive transform APIs |
| 3A | 20 min | NEW `AnnotationTool.swift` | Protocol + ToolRegistry |
| 3B | 30 min | ADD to `AnnotationTool.swift` | SelectTool implementation |
| 3C | 45 min | ADD to `AnnotationTool.swift` | RectangleTool with preview |
| 3D | 20 min | MODIFY `AnnotationCanvas.swift` | Update tool management |
| 4A | 15 min | MODIFY `AnnotationCanvas.swift` | Add pan APIs |
| 4B | 15 min | MODIFY `AnnotationCanvasView.swift` | Fix panOffset violation |
| 4C | 30 min | MODIFY `AnnotationCanvasView.swift` | Tool event forwarding |
| 4D | 15 min | MODIFY `AnnotationCanvasView.swift` | Tool preview rendering |
| 5 | 30 min | MODIFY `ContentView.swift` | UI migration to protocol tools |

**Total: ~7.25 hours** (15 small phases)

---

## Critical Files

| File | Type | Phases | Total Changes |
|------|------|--------|---------------|
| `quickedit/CanvasCommand.swift` | **NEW** | 1A, 1B, 2C, 2D, 2E | ~350 lines |
| `quickedit/AnnotationCanvas.swift` | **MODIFY** | 1C, 2A, 2B, 2C, 2D, 2E, 3D, 4A | +180 lines |
| `quickedit/AnnotationTool.swift` | **NEW** | 3A, 3B, 3C | ~180 lines |
| `quickedit/AnnotationCanvasView.swift` | **MODIFY** | 4B, 4C, 4D | ~60 lines changed |
| `quickedit/ContentView.swift` | **MODIFY** | 2B, 5 | ~50 lines changed |

---

## Quick Reference Checklist

**Phase 1: Command Foundation (90 min)**
- [ ] 1A: Protocol + CommandHistory _(30 min)_
- [ ] 1B: AddAnnotationCommand _(30 min)_
- [ ] 1C: Integrate into Canvas _(30 min)_

**Phase 2: CRUD APIs (2h 40min)**
- [ ] 2A: addAnnotation() API _(20 min)_
- [ ] 2B: undo/redo APIs _(20 min)_
- [ ] 2C: DeleteAnnotationsCommand _(30 min)_
- [ ] 2D: UpdatePropertiesCommand + Batch _(45 min)_
- [ ] 2E: ArrangeCommand + AlignCommand + DistributeCommand + RotateCommand _(45 min)_

**Phase 3: Tool Protocol (1h 55min)**
- [ ] 3A: Protocol + ToolRegistry _(20 min)_
- [ ] 3B: SelectTool _(30 min)_
- [ ] 3C: RectangleTool with preview _(45 min)_
- [ ] 3D: Canvas tool management _(20 min)_

**Phase 4: Event Flow (1h 15min)**
- [ ] 4A: Add pan APIs _(15 min)_
- [ ] 4B: Fix panOffset violation _(15 min)_
- [ ] 4C: Tool event forwarding _(30 min)_
- [ ] 4D: Tool preview rendering _(15 min)_

**Phase 5: UI Migration (30 min)**
- [ ] 5: Migrate ContentView to protocol tools _(30 min)_

---

## Key Architecture Principles

**Unidirectional Event Flow:**
```
User Action → UI calls Canvas API → Canvas updates state → Canvas emits events → UI observes
```

**Canvas NEVER listens to UI/Tool events** - only emits via @Published and PassthroughSubject

**All mutations through command pattern:**
```swift
// ❌ WRONG:
canvas.annotations.append(annotation)

// ✅ CORRECT:
canvas.addAnnotation(annotation)  // Wraps in command
```

**Tools use canvas APIs:**
```swift
// ✅ CORRECT:
tool.onMouseUp(at: point, on: canvas)
canvas.addAnnotation(annotation)  // Tool calls API
```

---

## Testing After Each Phase

- **1A-1C:** Build succeeds, history manager works
- **2A:** addAnnotation creates + canUndo works
- **2B:** Toolbar undo/redo functional
- **2C:** Delete + undo restores
- **2D:** Property updates + batch undo
- **2E:** Z-index arrangement + alignment + distribution + rotation/flip + undo
- **3A-3B:** SelectTool selects annotations
- **3C:** RectangleTool draws with preview
- **3D:** Tool switching works
- **4A-4B:** Pan via API (not direct)
- **4C:** Tools receive mouse events
- **4D:** Preview renders during drag
- **5:** UI uses protocol tools

---

## Success Criteria

1. ✅ All mutations wrapped in commands
2. ✅ Undo/redo works for create/delete/modify/arrange
3. ✅ Tools create annotations via mouse events
4. ✅ No direct state modification in views
5. ✅ Unidirectional event flow (UI → Canvas → UI)
6. ✅ Build succeeds (0 errors, 0 warnings)
7. ✅ Can draw, select, delete, undo, redo
