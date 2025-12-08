# Tool System Design - Review & Recommendations

**Reviewed:** December 7, 2025
**Document:** `tool-system.md` (draft)
**Status:** Strong foundation with critical fixes needed

---

## Overall Assessment

**Strengths:**
- ✅ Clear protocol-based architecture
- ✅ Good separation of concerns (interaction, state, settings, UI)
- ✅ Comprehensive examples covering multiple tool types
- ✅ Extensibility well-demonstrated
- ✅ Lifecycle documentation helpful

**Critical Issues:**
- ❌ SwiftUI state management won't work as written
- ❌ Settings binding pattern is broken
- ❌ Missing key type definitions
- ❌ Performance considerations not addressed

---

## Critical Fix #1: SwiftUI State Management

### ❌ Current Approach (Broken):

```swift
protocol AnnotationTool: AnyObject {
    var settings: ToolSettings { get set }
}

@ViewBuilder
func settingsPanel() -> some View {
    Slider(value: {
        if var s = settings as? LineToolSettings {
            return s.strokeWidth
        }
        return 1.0
    }(), in: 0.5...10.0)
}
```

**Problems:**
- Closures return values, not bindings
- No way to update settings from UI
- Won't compile or trigger view updates

### ✅ Fixed Approach:

```swift
// Option 1: Use @Observable (Swift 5.9+, recommended)
@Observable
class LineTool: AnnotationTool {
    let id = "tool.line"
    let name = "Line"
    let icon = "line.diagonal"

    var settings = LineToolSettings()  // No protocol needed

    // ... rest of implementation

    @ViewBuilder
    func settingsPanel() -> some View {
        VStack {
            // Direct binding works with @Observable
            Slider(value: $settings.strokeWidth, in: 0.5...10.0)
            ColorPicker("Color", selection: $settings.strokeColor)
        }
    }
}

struct LineToolSettings {
    var strokeColor: Color = .black
    var strokeWidth: CGFloat = 2.0
    var lineStyle: LineStyle = .solid
}

// Option 2: Use ObservableObject (if targeting older Swift)
class LineTool: AnnotationTool, ObservableObject {
    let id = "tool.line"
    let name = "Line"
    let icon = "line.diagonal"

    @Published var settings = LineToolSettings()

    @ViewBuilder
    func settingsPanel() -> some View {
        VStack {
            Slider(value: $settings.strokeWidth, in: 0.5...10.0)
            ColorPicker("Color", selection: $settings.strokeColor)
        }
    }
}
```

**Key Changes:**
- Use `@Observable` macro (macOS 14+) or `ObservableObject` with `@Published`
- Remove `ToolSettings` protocol - it's not needed
- Direct property access with `$` for bindings
- No casting or copying needed

---

## Critical Fix #2: Protocol Design

### ❌ Current:

```swift
protocol AnnotationTool: AnyObject {
    var settings: ToolSettings { get set }
}

protocol ToolSettings {
    func copy() -> ToolSettings
}
```

**Problems:**
- Type erasure makes settings access clunky
- Requires casting everywhere
- `copy()` method rarely needed

### ✅ Recommended:

```swift
// Remove ToolSettings protocol entirely
// Use associated types if truly needed for generic code

protocol AnnotationTool: AnyObject {
    /// Unique identifier for this tool
    var id: String { get }

    /// Display name in UI
    var name: String { get }

    /// SF Symbol name for toolbar icon
    var icon: String { get }

    // MARK: - Interaction Events

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas)
    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas)

    // MARK: - UI Components

    @ViewBuilder
    func settingsPanel() -> some View

    func renderPreview(in context: inout GraphicsContext, canvasSize: CGSize)

    // MARK: - Lifecycle

    func onActivate()
    func onDeactivate()
}

// Default implementations
extension AnnotationTool {
    func onActivate() { }
    func onDeactivate() { }
    func renderPreview(in context: inout GraphicsContext, canvasSize: CGSize) { }
}
```

---

## Critical Fix #3: Missing Type Definitions

The document references but doesn't define:

```swift
// Add these to the document or reference where they're defined

/// Canvas that manages annotations and rendering
class AnnotationCanvas: ObservableObject {
    @Published var annotations: [any Annotation] = []
    @Published var selectedAnnotationID: UUID?

    func addAnnotation(_ annotation: any Annotation) {
        // Add to annotations array
        // Save undo state
    }

    func annotationAt(_ point: CGPoint) -> (any Annotation)? {
        // Hit testing
    }

    func select(_ id: UUID) {
        selectedAnnotationID = id
    }

    func updateAnnotation(_ id: UUID, _ transform: (inout any Annotation) -> Void) {
        // Find and update annotation
    }
}

/// Transform for position, rotation, scale
struct Transform: Codable {
    var position: CGPoint
    var rotation: CGFloat
    var scale: CGPoint
}

/// Base annotation protocol
protocol Annotation: Identifiable, Codable {
    var id: UUID { get }
    var type: String { get }
    var zIndex: Int { get set }
    var transform: Transform { get set }
    var bounds: CGSize { get set }
    var locked: Bool { get set }
    var visible: Bool { get set }

    func render(in context: inout GraphicsContext, imageSize: CGSize)
}

/// Line annotation
struct LineAnnotation: Annotation {
    let id: UUID
    let type = "line"
    var zIndex: Int
    var transform: Transform
    var bounds: CGSize
    var locked: Bool
    var visible: Bool
    var properties: Properties

    struct Properties: Codable {
        var startPoint: CGPoint
        var endPoint: CGPoint
        var strokeColor: CodableColor
        var strokeWidth: CGFloat
        var lineStyle: String
        var lineCap: String
        var lineJoin: String
    }

    func render(in context: inout GraphicsContext, imageSize: CGSize) {
        // Rendering logic
    }
}

/// Codable Color wrapper
struct CodableColor: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(_ color: Color) {
        // Convert Color to RGBA
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
```

---

## Critical Fix #4: Color to RGBA Conversion

SwiftUI `Color` is not directly Codable. Need helper:

```swift
extension Color {
    /// Convert to RGBA components for JSON
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        #elseif canImport(AppKit)
        let nsColor = NSColor(self)
        let uiColor = nsColor.usingColorSpace(.deviceRGB) ?? nsColor
        #endif

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }

    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self = Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
}

// Store in annotation:
struct LineToolSettings {
    var strokeColor: Color = .black

    var strokeColorRGBA: (CGFloat, CGFloat, CGFloat, CGFloat) {
        strokeColor.rgba
    }
}
```

---

## Performance Recommendations

### 1. Throttle Preview Rendering

```swift
class LineTool: AnnotationTool {
    private var lastPreviewUpdate: Date = Date()
    private let previewThrottleInterval: TimeInterval = 1.0 / 60.0  // 60 FPS max

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        currentEndPoint = point

        let now = Date()
        if now.timeIntervalSince(lastPreviewUpdate) >= previewThrottleInterval {
            // Trigger canvas redraw
            lastPreviewUpdate = now
        }
    }
}
```

### 2. Optimize renderPreview

```swift
func renderPreview(in context: inout GraphicsContext, canvasSize: CGSize) {
    guard isDrawing else { return }

    // Cache path if it hasn't changed
    if previewPathCache == nil || previewNeedsUpdate {
        previewPathCache = buildPreviewPath()
        previewNeedsUpdate = false
    }

    if let path = previewPathCache {
        context.stroke(path, with: .color(settings.strokeColor), lineWidth: settings.strokeWidth)
    }
}
```

---

## Recommended Architecture Changes

### 1. Tool Registry with Type Safety

```swift
@Observable
class ToolManager {
    var selectedToolID: String = "tool.select"
    private(set) var tools: [String: any AnnotationTool] = [:]

    var selectedTool: (any AnnotationTool)? {
        tools[selectedToolID]
    }

    init() {
        registerDefaultTools()
    }

    private func registerDefaultTools() {
        register(SelectTool())
        register(LineTool())
        register(ShapeTool())
        // ... etc
    }

    func register(_ tool: any AnnotationTool) {
        tools[tool.id] = tool
    }

    func selectTool(_ toolID: String) {
        selectedTool?.onDeactivate()
        selectedToolID = toolID
        selectedTool?.onActivate()
    }

    func toolsByCategory() -> [String: [any AnnotationTool]] {
        [
            "Selection": [tools["tool.select"]!],
            "Drawing": [tools["tool.line"]!, tools["tool.shape"]!, tools["tool.freehand"]!],
            "Text": [tools["tool.text"]!, tools["tool.number"]!],
            "Effects": [tools["tool.highlight"]!, tools["tool.blur"]!],
            "Other": [tools["tool.note"]!]
        ]
    }
}
```

### 2. Keyboard Shortcuts

```swift
struct AnnotationCanvasView: View {
    @ObservedObject var toolManager: ToolManager

    var body: some View {
        // ... canvas content
            .onKeyPress(.init("v")) { _ in
                toolManager.selectTool("tool.select")
                return .handled
            }
            .onKeyPress(.init("l")) { _ in
                toolManager.selectTool("tool.line")
                return .handled
            }
            .onKeyPress(.init("r")) { _ in
                toolManager.selectTool("tool.shape")
                return .handled
            }
            // ... etc
    }
}

// Or use Commands for menu bar shortcuts:
struct ToolCommands: Commands {
    @ObservedObject var toolManager: ToolManager

    var body: some Commands {
        CommandMenu("Tools") {
            Button("Select Tool") {
                toolManager.selectTool("tool.select")
            }
            .keyboardShortcut("v")

            Button("Line Tool") {
                toolManager.selectTool("tool.line")
            }
            .keyboardShortcut("l")

            // ... etc
        }
    }
}
```

---

## Additional Best Practices

### 1. Tool State Reset

```swift
protocol AnnotationTool: AnyObject {
    /// Reset tool state (called on deactivate or cancel)
    func reset()
}

extension LineTool {
    func reset() {
        isDrawing = false
        startPoint = .zero
        currentEndPoint = .zero
        previewPathCache = nil
    }

    func onDeactivate() {
        reset()
    }
}
```

### 2. Escape Key to Cancel

```swift
struct AnnotationCanvasView: View {
    var body: some View {
        // ... canvas
            .onKeyPress(.escape) { _ in
                toolManager.selectedTool?.reset()
                return .handled
            }
    }
}
```

### 3. Tool Validation

```swift
protocol AnnotationTool {
    /// Validate that annotation can be created
    func canCreateAnnotation() -> Bool
}

extension LineTool {
    func canCreateAnnotation() -> Bool {
        // Don't create if line is too short
        let distance = hypot(
            currentEndPoint.x - startPoint.x,
            currentEndPoint.y - startPoint.y
        )
        return distance > 5.0  // Minimum 5 points
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard isDrawing, canCreateAnnotation() else {
            reset()
            return
        }

        // Create annotation...
    }
}
```

---

## Documentation Improvements Needed

### 1. Add Canvas Specification

Create separate `canvas-architecture.md` document defining:
- `AnnotationCanvas` class and responsibilities
- Hit testing algorithm
- Z-index rendering order
- Selection state management
- Coordinate space conversions

### 2. Add Type Definitions Reference

Either inline in this doc or reference `annotation-types.md`:
- All annotation struct definitions
- Transform, Bounds types
- Codable color wrapper

### 3. Add Testing Guidance

```swift
// Example test for LineTool
@Test func testLineToolCreatesAnnotation() async throws {
    let canvas = AnnotationCanvas()
    let tool = LineTool()

    tool.onMouseDown(at: CGPoint(x: 0, y: 0), on: canvas)
    tool.onMouseDrag(to: CGPoint(x: 100, y: 100), on: canvas)
    tool.onMouseUp(at: CGPoint(x: 100, y: 100), on: canvas)

    #expect(canvas.annotations.count == 1)
    #expect(canvas.annotations.first?.type == "line")
}
```

---

## Summary of Required Changes

### Must Fix (Blocking):
1. ✅ Fix SwiftUI state management (use `@Observable` or `ObservableObject`)
2. ✅ Remove broken `ToolSettings` protocol
3. ✅ Define all referenced types (`AnnotationCanvas`, `Transform`, annotation structs)
4. ✅ Fix Color to RGBA conversion for JSON

### Should Fix (Important):
1. ⚠️ Add performance throttling for preview rendering
2. ⚠️ Add keyboard shortcut implementation
3. ⚠️ Add tool state reset/cancel mechanism
4. ⚠️ Add validation before annotation creation

### Nice to Have (Enhancement):
1. 💡 Add tool categories/grouping
2. 💡 Add testing examples
3. 💡 Add accessibility support (VoiceOver labels)
4. 💡 Add tool tips/help text

---

## Recommendation: Proceed After Fixes

**Status:** Draft requires critical fixes before implementation

**Action Items:**
1. Update all code examples with proper SwiftUI state management
2. Define `AnnotationCanvas` architecture
3. Add type definitions or references to `annotation-types.md`
4. Add performance and validation best practices
5. Test with actual SwiftUI implementation

Once these fixes are applied, the tool system design will be production-ready for Phase 2 (Frontend) implementation.

---

**Reviewed by:** Claude (Architecture Review)
**Next Step:** Update tool-system.md with fixes, then create canvas-architecture.md
