# Canvas API Design - Separation of Concerns

**Version:** 2.0
**Status:** Architecture Design
**Last Updated:** December 8, 2025

---

## Overview

This document defines the architecture for **complete separation** between the editing canvas and UI components (toolbars, panels, etc.). The canvas is the central authority that provides APIs for tool management, event notifications, and annotation manipulation. UI components are consumers that call canvas APIs and react to canvas events.

**Key Principle:** Canvas owns the state and behavior. UI components are thin layers that translate user interactions into canvas API calls.

---

## Architecture Diagram

**Critical Principle:** Canvas emits events (source). UI listens to events (observer). Canvas NEVER listens to UI.

```
┌─────────────────────────────────────────────────────────────┐
│                         Application                          │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │  Main Toolbar  │  │ Floating Bar │  │ Properties Panel│ │
│  │  (Your Design) │  │ (3rd Party)  │  │  (Custom UI)    │ │
│  └────────┬───────┘  └──────┬───────┘  └────────┬────────┘ │
│           │                  │                   │          │
│           │ ① Call API       │                   │          │
│           ▼                  ▼                   ▼          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │           AnnotationCanvas (Event Source)                ││
│  │                                                           ││
│  │  ┌──────────────────────────────────────────────────┐  ││
│  │  │  Public API (Commands)                           │  ││
│  │  │  - setActiveTool(_:)                             │  ││
│  │  │  - selectAnnotations(_:)                         │  ││
│  │  │  - updateProperties(_:for:)                      │  ││
│  │  │  - arrange(action:)                              │  ││
│  │  └──────────────────────────────────────────────────┘  ││
│  │                        ↓                                 ││
│  │  ┌──────────────────────────────────────────────────┐  ││
│  │  │  ② Internal State Update (Private)               │  ││
│  │  │  - activeTool changed                            │  ││
│  │  │  - selectedIDs changed                           │  ││
│  │  │  - annotations modified                          │  ││
│  │  └──────────────────────────────────────────────────┘  ││
│  │                        ↓                                 ││
│  │  ┌──────────────────────────────────────────────────┐  ││
│  │  │  ③ Emit Events (Publishers)                      │  ││
│  │  │  - activeTool published                          │  ││
│  │  │  - selectedAnnotationIDs published               │  ││
│  │  │  - onAnnotationAdded emitted                     │  ││
│  │  └──────────────────────────────────────────────────┘  ││
│  └─────────────────────────────────────────────────────────┘│
│           │                  │                   │          │
│           │ ④ Events flow    │                   │          │
│           ▼                  ▼                   ▼          │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │ Toolbar listens│  │ Floating Bar │  │ Properties Panel│ │
│  │ Updates button │  │   listens    │  │     listens     │ │
│  │   highlight    │  │ Updates UI   │  │  Refreshes UI   │ │
│  └────────────────┘  └──────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘

Flow:
  ① User clicks toolbar → Toolbar calls canvas.setActiveTool(tool)
  ② Canvas updates internal state: activeTool = tool
  ③ Canvas emits event: activeTool @Published value changed
  ④ Toolbar listens: canvas.$activeTool.sink { ... update highlight ... }

KEY: Canvas is EVENT SOURCE. UI components are EVENT LISTENERS.
     Canvas NEVER listens to UI events. It only provides APIs.
```

---

## 1. Canvas Public API

### 1.1 Tool Management API

```swift
protocol CanvasToolAPI {
    /// Set the active tool (nil to deactivate all tools)
    func setActiveTool(_ tool: (any AnnotationTool)?)

    /// Get current active tool
    var activeTool: (any AnnotationTool)? { get }

    /// Check if a specific tool type is active
    func isToolActive<T: AnnotationTool>(_ toolType: T.Type) -> Bool
}
```

**Usage Example:**
```swift
// From toolbar button
canvas.setActiveTool(LineTool())

// From keyboard shortcut handler
if event.key == "L" {
    canvas.setActiveTool(LineTool())
}

// Deactivate tool (back to select mode)
canvas.setActiveTool(nil)
```

---

### 1.2 Selection Management API

```swift
protocol CanvasSelectionAPI {
    /// Current selected annotation IDs
    var selectedAnnotationIDs: Set<UUID> { get }

    /// Select specific annotations (replaces current selection)
    func selectAnnotations(_ ids: Set<UUID>)

    /// Add to current selection
    func addToSelection(_ ids: Set<UUID>)

    /// Remove from selection
    func removeFromSelection(_ ids: Set<UUID>)

    /// Select all annotations
    func selectAll()

    /// Clear selection
    func clearSelection()

    /// Get annotation objects for selected IDs
    func getSelectedAnnotations() -> [any Annotation]

    /// Check if annotation is selected
    func isSelected(_ id: UUID) -> Bool
}
```

**Usage Example:**
```swift
// Select annotation from list view
canvas.selectAnnotations([annotationID])

// Cmd+A handler
canvas.selectAll()

// Update properties panel when selection changes
canvas.onSelectionChanged { selectedIDs in
    propertiesPanel.updateFor(canvas.getSelectedAnnotations())
}
```

---

### 1.3 Annotation Property API

```swift
protocol CanvasPropertyAPI {
    /// Update properties for specific annotations
    func updateProperties<T>(_ properties: T, for annotationIDs: Set<UUID>) where T: AnnotationProperties

    /// Batch update single property
    func updateProperty<T>(keyPath: WritableKeyPath<some Annotation, T>, value: T, for annotationIDs: Set<UUID>)

    /// Get properties for annotation
    func getProperties(for annotationID: UUID) -> (any AnnotationProperties)?
}
```

**Usage Example:**
```swift
// From properties panel - update stroke width
canvas.updateProperty(\.strokeWidth, value: 5.0, for: canvas.selectedAnnotationIDs)

// Bulk color change
let newColor = CodableColor(red: 1, green: 0, blue: 0, alpha: 1)
canvas.updateProperty(\.strokeColor, value: newColor, for: selectedIDs)

// Update entire property struct
canvas.updateProperties(lineProperties, for: [lineID])
```

---

### 1.4 Arrangement API

```swift
enum ArrangementAction {
    case bringToFront
    case sendToBack
    case bringForward
    case sendBackward
    case alignLeft
    case alignRight
    case alignTop
    case alignBottom
    case alignCenterHorizontal
    case alignCenterVertical
    case distributeHorizontally
    case distributeVertically
}

protocol CanvasArrangementAPI {
    /// Apply arrangement action to selected annotations
    func arrange(_ action: ArrangementAction)

    /// Apply arrangement to specific annotations
    func arrange(_ action: ArrangementAction, for annotationIDs: Set<UUID>)

    /// Group selected annotations
    func groupSelected() -> UUID  // Returns group ID

    /// Ungroup annotation
    func ungroup(_ groupID: UUID)

    /// Lock/unlock annotations
    func setLocked(_ locked: Bool, for annotationIDs: Set<UUID>)
}
```

**Usage Example:**
```swift
// From menu: Arrange > Bring to Front
canvas.arrange(.bringToFront)

// From keyboard: Cmd+]
canvas.arrange(.bringForward)

// From align buttons
canvas.arrange(.alignLeft)

// Group selected
let groupID = canvas.groupSelected()
```

---

### 1.5 Annotation Lifecycle API

```swift
protocol CanvasAnnotationAPI {
    /// Add annotation programmatically
    func addAnnotation(_ annotation: any Annotation)

    /// Delete annotations
    func deleteAnnotations(_ ids: Set<UUID>)

    /// Delete selected
    func deleteSelected()

    /// Duplicate annotations
    func duplicate(_ ids: Set<UUID>) -> Set<UUID>  // Returns new IDs

    /// Duplicate selected
    func duplicateSelected() -> Set<UUID>

    /// Get all annotations
    func getAllAnnotations() -> [any Annotation]

    /// Get annotation by ID
    func getAnnotation(_ id: UUID) -> (any Annotation)?

    /// Check if annotation exists
    func hasAnnotation(_ id: UUID) -> Bool
}
```

**Usage Example:**
```swift
// Delete selected (Delete key handler)
canvas.deleteSelected()

// Duplicate (Cmd+D handler)
let newIDs = canvas.duplicateSelected()
canvas.selectAnnotations(newIDs)

// Programmatically add annotation
let line = LineAnnotation(...)
canvas.addAnnotation(line)
```

---

### 1.6 Undo/Redo API

```swift
protocol CanvasHistoryAPI {
    /// Undo last action
    func undo()

    /// Redo last undone action
    func redo()

    /// Check if can undo
    var canUndo: Bool { get }

    /// Check if can redo
    var canRedo: Bool { get }

    /// Get undo action description
    var undoActionName: String? { get }

    /// Get redo action description
    var redoActionName: String? { get }

    /// Clear history
    func clearHistory()
}
```

**Usage Example:**
```swift
// Menu items
if canvas.canUndo {
    menu.addItem("Undo \(canvas.undoActionName ?? "")", action: canvas.undo)
}

// Keyboard shortcuts
if cmd.key == "Z" {
    cmd.isShift ? canvas.redo() : canvas.undo()
}
```

---

### 1.7 Canvas State API

```swift
protocol CanvasStateAPI {
    /// Zoom level (0.1 to 10.0)
    var zoomLevel: CGFloat { get set }

    /// Pan offset
    var panOffset: CGPoint { get set }

    /// Zoom to fit image
    func zoomToFit()

    /// Center image
    func centerImage()

    /// Zoom to specific level
    func setZoom(_ level: CGFloat, centerOn point: CGPoint?)

    /// Grid settings
    var showGrid: Bool { get set }
    var gridSize: CGFloat { get set }
    var snapToGrid: Bool { get set }

    /// Guides settings
    var showAlignmentGuides: Bool { get set }
    var showRulers: Bool { get set }

    /// Base image
    var baseImage: NSImage? { get set }
    var imageSize: CGSize { get }
}
```

**Usage Example:**
```swift
// Zoom controls
canvas.setZoom(2.0, centerOn: nil)  // 200%
canvas.zoomToFit()  // Fit to window

// Settings panel
canvas.showGrid = true
canvas.gridSize = 8
canvas.snapToGrid = true
```

---

## 2. Event System

### 2.1 Event Protocol (Optional - Delegate Pattern)

**Note:** This is an OPTIONAL pattern. Canvas emits events via this delegate. Canvas does NOT receive events from UI through delegates.

```swift
protocol CanvasEventDelegate: AnyObject {
    /// Canvas emits: Tool changed
    func canvas(_ canvas: AnnotationCanvas, didChangeTool tool: (any AnnotationTool)?)

    /// Canvas emits: Selection changed
    func canvas(_ canvas: AnnotationCanvas, didChangeSelection selectedIDs: Set<UUID>)

    /// Canvas emits: Annotation added
    func canvas(_ canvas: AnnotationCanvas, didAddAnnotation annotation: any Annotation)

    /// Canvas emits: Annotation modified
    func canvas(_ canvas: AnnotationCanvas, didModifyAnnotation annotationID: UUID)

    /// Canvas emits: Annotation deleted
    func canvas(_ canvas: AnnotationCanvas, didDeleteAnnotations annotationIDs: Set<UUID>)

    /// Canvas emits: Undo/redo state changed
    func canvas(_ canvas: AnnotationCanvas, didChangeHistoryState canUndo: Bool, canRedo: Bool)

    /// Canvas emits: Canvas state changed (zoom, pan, etc.)
    func canvas(_ canvas: AnnotationCanvas, didChangeState: CanvasStateChange)

    /// Canvas emits: Interaction began (mouse down)
    func canvas(_ canvas: AnnotationCanvas, didBeginInteraction mode: InteractionMode)

    /// Canvas emits: Interaction ended (mouse up)
    func canvas(_ canvas: AnnotationCanvas, didEndInteraction mode: InteractionMode)
}

// Canvas implementation
class AnnotationCanvas {
    weak var delegate: CanvasEventDelegate?  // Canvas EMITS to delegate, never receives from it

    func setActiveTool(_ tool: AnnotationTool?) {
        activeTool = tool
        delegate?.canvas(self, didChangeTool: tool)  // Canvas emits event
    }
}

enum CanvasStateChange {
    case zoom(CGFloat)
    case pan(CGPoint)
    case grid(shown: Bool, size: CGFloat)
    case guides(shown: Bool)
}

enum InteractionMode {
    case drawing(toolType: String)
    case selecting
    case moving
    case resizing
    case panning
}
```

### 2.2 Combine Publishers (Recommended Approach)

**Canvas EMITS events**. UI LISTENS to events. Canvas never subscribes to UI events.

```swift
final class AnnotationCanvas: ObservableObject {
    // Published properties (Canvas EMITS changes. UI OBSERVES changes.)
    @Published private(set) var activeTool: (any AnnotationTool)?
    @Published private(set) var selectedAnnotationIDs: Set<UUID> = []
    @Published private(set) var canUndo: Bool = false
    @Published private(set) var canRedo: Bool = false

    // Event publishers - Canvas EMITS events via .send()
    // UI SUBSCRIBES via .sink()
    let onAnnotationAdded = PassthroughSubject<any Annotation, Never>()
    let onAnnotationModified = PassthroughSubject<UUID, Never>()
    let onAnnotationDeleted = PassthroughSubject<Set<UUID>, Never>()
    let onInteractionBegan = PassthroughSubject<InteractionMode, Never>()
    let onInteractionEnded = PassthroughSubject<InteractionMode, Never>()

    // Canvas provides APIs for UI to call
    func setActiveTool(_ tool: AnnotationTool?) {
        activeTool = tool  // Updates published property - this emits event
        // UI will observe via canvas.$activeTool.sink { ... }
    }

    func addAnnotation(_ annotation: any Annotation) {
        annotations.append(annotation)
        onAnnotationAdded.send(annotation)  // Canvas emits event
        // UI will observe via canvas.onAnnotationAdded.sink { ... }
    }
}
```

**Event Flow Example:**
```swift
// ❌ WRONG: Canvas listening to UI
// toolbar.onToolSelected.sink { tool in
//     canvas.setActiveTool(tool)
// }

// ✅ CORRECT: UI calls canvas API, then listens to canvas events
toolbar.buttonClicked = { tool in
    canvas.setActiveTool(tool)  // UI calls canvas API
}

canvas.$activeTool.sink { tool in  // UI listens to canvas event
    toolbar.updateHighlight(for: tool)
}
```

**Usage Example:**
```swift
// SwiftUI view: UI calls canvas APIs and listens to canvas events
struct ContentView: View {
    @StateObject private var canvas = AnnotationCanvas()
    @State private var currentTool: AnnotationTool?

    var body: some View {
        VStack {
            // Toolbar calls canvas API (command)
            ToolbarView(onToolSelected: { tool in
                canvas.setActiveTool(tool)  // UI → Canvas (API call)
            })

            CanvasView(canvas: canvas)

            PropertiesPanel(selectedAnnotations: canvas.getSelectedAnnotations())
        }
        // UI listens to canvas events (observation)
        .onReceive(canvas.$activeTool) { newTool in  // Canvas → UI (event)
            currentTool = newTool
            // Update UI based on canvas state change
        }
        .onReceive(canvas.$selectedAnnotationIDs) { ids in  // Canvas → UI (event)
            // Refresh properties panel when selection changes
        }
        .onReceive(canvas.onAnnotationAdded) { annotation in  // Canvas → UI (event)
            showNotification("Added \(annotation.type)")
        }
    }
}

// Custom toolbar: Only listens to canvas, never emits events that canvas listens to
class FloatingToolbar: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    func connectToCanvas(_ canvas: AnnotationCanvas) {
        // UI listens to canvas events (one-way: Canvas → UI)
        canvas.$activeTool
            .sink { [weak self] tool in
                self?.updateHighlight(for: tool)  // Update toolbar UI
            }
            .store(in: &cancellables)

        canvas.onInteractionBegan
            .sink { mode in
                print("Canvas event received: \(mode)")
            }
            .store(in: &cancellables)
    }

    // When user clicks toolbar button
    func toolButtonClicked(_ tool: AnnotationTool, canvas: AnnotationCanvas) {
        // UI calls canvas API (one-way: UI → Canvas)
        canvas.setActiveTool(tool)
        // Then canvas will emit event, which we'll receive in the sink above
    }
}
```

---

## 3. Tool Integration

### 3.1 Tool Protocol (Revised)

```swift
protocol AnnotationTool: AnyObject {
    var id: String { get }
    var name: String { get }
    var icon: String { get }

    // Canvas calls these methods
    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas)
    func onCancel(on canvas: AnnotationCanvas)

    // Tool state
    func activate()
    func deactivate()

    // Preview rendering
    func renderPreview(in context: inout GraphicsContext)
}
```

### 3.2 Tool-Canvas Communication

**Key Rule:** Tools DO NOT modify canvas state directly. They use canvas commands.

```swift
class LineTool: AnnotationTool {
    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        startPoint = point
        currentPoint = point
        canvas.onInteractionBegan.send(.drawing(toolType: "line"))
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        currentPoint = point
        // Canvas will call renderPreview automatically
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard let start = startPoint else { return }

        // Create annotation
        let line = LineAnnotation(
            startPoint: start,
            endPoint: point,
            properties: getProperties()
        )

        // Add via canvas API (this handles undo/redo automatically)
        canvas.addAnnotation(line)

        // Cleanup
        startPoint = nil
        currentPoint = nil
        canvas.onInteractionEnded.send(.drawing(toolType: "line"))
    }

    func renderPreview(in context: inout GraphicsContext) {
        guard let start = startPoint, let end = currentPoint else { return }

        // Draw preview line
        context.stroke(
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            },
            with: .color(.blue),
            lineWidth: 2
        )
    }
}
```

---

## 4. UI Component Integration Examples

### 4.1 Main Toolbar (Built-in)

```swift
struct MainToolbar: View {
    @ObservedObject var canvas: AnnotationCanvas

    var body: some View {
        HStack {
            ForEach(ToolRegistry.allTools) { tool in
                ToolButton(tool: tool) {
                    // User clicks → UI calls canvas API
                    canvas.setActiveTool(tool)
                }
                // UI observes canvas state to update highlight
                .highlighted(canvas.activeTool?.id == tool.id)
            }
        }
    }
}

// Equivalent with explicit event listening:
struct MainToolbarWithExplicitListening: View {
    @ObservedObject var canvas: AnnotationCanvas
    @State private var highlightedToolID: String?

    var body: some View {
        HStack {
            ForEach(ToolRegistry.allTools) { tool in
                ToolButton(tool: tool) {
                    canvas.setActiveTool(tool)  // UI → Canvas (command)
                }
                .highlighted(highlightedToolID == tool.id)
            }
        }
        .onReceive(canvas.$activeTool) { tool in  // Canvas → UI (event)
            highlightedToolID = tool?.id
        }
    }
}
```

### 4.2 Floating Toolbar (Third-Party)

```swift
class FloatingToolbarController {
    let canvas: AnnotationCanvas
    let window: NSWindow
    private var cancellables = Set<AnyCancellable>()

    init(canvas: AnnotationCanvas) {
        self.canvas = canvas
        self.window = createFloatingWindow()

        // UI listens to canvas events (Canvas → UI)
        canvas.$activeTool
            .sink { [weak self] tool in
                self?.updateUI(for: tool)  // Update toolbar highlight
            }
            .store(in: &cancellables)

        canvas.$selectedAnnotationIDs
            .sink { [weak self] ids in
                self?.updateSelectionUI(ids)  // Update toolbar for selection
            }
            .store(in: &cancellables)
    }

    // User clicks toolbar button
    func toolButtonClicked(_ tool: AnnotationTool) {
        // UI calls canvas API (UI → Canvas)
        canvas.setActiveTool(tool)
        // Canvas will emit event, which we'll receive in the sink above
    }

    // Canvas NEVER calls methods on this toolbar
    // This toolbar NEVER emits events that canvas listens to
    // One-way flow: UI → Canvas API calls, Canvas → UI events
}
```

### 4.3 Properties Panel (Context-Aware)

```swift
struct PropertiesPanel: View {
    @ObservedObject var canvas: AnnotationCanvas
    @State private var selectedAnnotations: [any Annotation] = []

    var body: some View {
        VStack {
            if selectedAnnotations.isEmpty {
                Text("No selection")
            } else if selectedAnnotations.count == 1 {
                SingleAnnotationProperties(annotation: selectedAnnotations[0]) { property, value in
                    canvas.updateProperty(property, value: value, for: [selectedAnnotations[0].id])
                }
            } else {
                MultiAnnotationProperties(annotations: selectedAnnotations) { property, value in
                    canvas.updateProperty(property, value: value, for: Set(selectedAnnotations.map(\.id)))
                }
            }
        }
        .onChange(of: canvas.selectedAnnotationIDs) { _, _ in
            selectedAnnotations = canvas.getSelectedAnnotations()
        }
    }
}
```

### 4.4 Inspector/Outliner View

```swift
struct InspectorView: View {
    @ObservedObject var canvas: AnnotationCanvas
    @State private var annotations: [any Annotation] = []

    var body: some View {
        List(annotations) { annotation in
            AnnotationRow(annotation: annotation)
                .onTapGesture {
                    canvas.selectAnnotations([annotation.id])
                }
                .contextMenu {
                    Button("Delete") {
                        canvas.deleteAnnotations([annotation.id])
                    }
                    Button("Duplicate") {
                        _ = canvas.duplicate([annotation.id])
                    }
                    Button("Bring to Front") {
                        canvas.arrange(.bringToFront, for: [annotation.id])
                    }
                }
        }
        .onReceive(canvas.onAnnotationAdded) { _ in
            refreshList()
        }
        .onReceive(canvas.onAnnotationDeleted) { _ in
            refreshList()
        }
    }

    func refreshList() {
        annotations = canvas.getAllAnnotations()
    }
}
```

---

## 5. Keyboard Shortcuts & Menu Integration

```swift
struct ContentView: View {
    @State private var canvas = AnnotationCanvas()

    var body: some View {
        CanvasView(canvas: canvas)
            .onKeyPress(.delete) {
                canvas.deleteSelected()
                return .handled
            }
            .onKeyPress("z", modifiers: .command) {
                canvas.undo()
                return .handled
            }
            .onKeyPress("z", modifiers: [.command, .shift]) {
                canvas.redo()
                return .handled
            }
            .onKeyPress("a", modifiers: .command) {
                canvas.selectAll()
                return .handled
            }
            .onKeyPress("d", modifiers: .command) {
                _ = canvas.duplicateSelected()
                return .handled
            }
            .onKeyPress("[", modifiers: .command) {
                canvas.arrange(.sendBackward)
                return .handled
            }
            .onKeyPress("]", modifiers: .command) {
                canvas.arrange(.bringForward)
                return .handled
            }
}

// Menu integration
struct AppMenus {
    let canvas: AnnotationCanvas

    func buildEditMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")

        menu.addItem(title: "Undo", action: #selector(canvas.undo), keyEquivalent: "z")
        menu.addItem(title: "Redo", action: #selector(canvas.redo), keyEquivalent: "Z")
        menu.addItem(.separator())
        menu.addItem(title: "Select All", action: #selector(canvas.selectAll), keyEquivalent: "a")
        menu.addItem(title: "Delete", action: #selector(canvas.deleteSelected), keyEquivalent: "⌫")

        return menu
    }

    func buildArrangeMenu() -> NSMenu {
        let menu = NSMenu(title: "Arrange")

        menu.addItem(title: "Bring to Front", action: #selector(bringToFront))
        menu.addItem(title: "Send to Back", action: #selector(sendToBack))
        menu.addItem(.separator())
        menu.addItem(title: "Align Left", action: #selector(alignLeft))
        menu.addItem(title: "Align Right", action: #selector(alignRight))

        return menu
    }

    @objc func bringToFront() {
        canvas.arrange(.bringToFront)
    }
}
```

---

## 6. Extension Points

### 6.1 Custom Tools

Third-party developers can create custom tools:

```swift
// Third-party tool
class CustomStampTool: AnnotationTool {
    var id = "com.vendor.stamp-tool"
    var name = "Stamp"
    var icon = "stamp"

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        let stamp = StampAnnotation(position: point, image: myStamp)
        canvas.addAnnotation(stamp)
    }
}

// Register and use
ToolRegistry.register(CustomStampTool())

// Any UI can now use it
canvas.setActiveTool(ToolRegistry.tool(withID: "com.vendor.stamp-tool"))
```

### 6.2 Custom Event Handlers

```swift
class AnalyticsPlugin {
    func attachToCanvas(_ canvas: AnnotationCanvas) {
        canvas.onAnnotationAdded
            .sink { annotation in
                Analytics.track("annotation_created", type: annotation.type)
            }

        canvas.onInteractionBegan
            .sink { mode in
                Analytics.track("interaction_started", mode: "\(mode)")
            }
    }
}
```

### 6.3 Custom Arrangement Actions

```swift
extension ArrangementAction {
    static let distributeGrid = ArrangementAction(
        name: "Distribute in Grid",
        apply: { annotations, canvas in
            // Custom grid distribution logic
            // Uses canvas.updateProperty to move annotations
        }
    )
}

// Add custom action to menu
canvas.arrange(.distributeGrid)
```

---

## 7. Implementation Checklist

**Phase 2 - Canvas Foundation:**
- [ ] Define all API protocols
- [ ] Implement AnnotationCanvas core class
- [ ] Implement event system (delegates or publishers)
- [ ] Create basic tool integration
- [ ] Test with one toolbar implementation

**Phase 3 - Full API:**
- [ ] Implement all selection APIs
- [ ] Implement property update APIs
- [ ] Implement arrangement APIs
- [ ] Implement undo/redo system
- [ ] Add comprehensive events

**Phase 4 - Extension System:**
- [ ] Tool registration system
- [ ] Custom event hooks
- [ ] Plugin architecture
- [ ] Third-party toolbar example

---

## 8. Benefits of This Architecture

### ✅ Unidirectional Event Flow
- **UI → Canvas:** Command (API calls)
- **Canvas → UI:** Notification (events)
- Canvas never listens to UI events
- No circular dependencies or event loops

### ✅ Separation of Concerns
- Canvas handles state and logic
- UI handles presentation and user input
- Clear boundaries between components
- Canvas is completely UI-agnostic

### ✅ Testability
- Canvas can be tested without UI
- Mock canvas for UI testing
- Tools can be tested in isolation

### ✅ Extensibility
- Custom toolbars without modifying canvas
- Third-party tools integrate seamlessly
- Multiple UIs can share one canvas

### ✅ Maintainability
- Changes to UI don't affect canvas
- Canvas evolution doesn't break UIs
- Clear API contract

### ✅ Flexibility
- Floating toolbars
- Context menus
- Keyboard shortcuts
- Inspector panels
- All share same canvas APIs

---

## 9. Migration Path

**Current State (Phase 1):**
- Tight coupling: `EditorViewModel` contains both UI and tool logic
- Direct property access

**Phase 2 Migration:**
1. Create `AnnotationCanvas` class with APIs
2. Move annotation array to canvas
3. Move tool logic to canvas
4. Update UI to call canvas APIs

**Phase 3 Completion:**
1. Remove direct state access from UI
2. All mutations through canvas APIs only
3. UI subscribes to canvas events
4. Complete decoupling achieved

---

**Status:** Architecture Design Complete
**Next Step:** Review and approval before Phase 2 implementation
**Dependencies:** annotation-types.md, tool-system.md, canvas-architecture.md
