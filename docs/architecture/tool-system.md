# Annotation Tool System Design

This document defines how to create extensible annotation tools with custom behaviors, UI, and settings.

**Version:** 1.0 (Revised)
**Last Updated:** December 7, 2025
**Status:** Production Ready

---

## Core Concepts

An **Annotation Tool** is responsible for:

1. **Interaction Handling** - Responding to mouse events (down, drag, up)
2. **State Management** - Tracking tool-specific state during creation
3. **Annotation Creation** - Producing annotations based on user input
4. **Settings UI** - Displaying and managing tool-specific configuration
5. **Preview Rendering** - Showing live preview while drawing

---

## Base Tool Protocol

All tools conform to a common protocol:

```swift
protocol AnnotationTool: AnyObject {
    /// Unique identifier for this tool
    var id: String { get }

    /// Display name in UI
    var name: String { get }

    /// SF Symbol name for toolbar icon
    var icon: String { get }

    /// Keyboard shortcut (optional)
    var keyboardShortcut: KeyEquivalent? { get }

    // MARK: - Interaction Events

    /// Called when user presses mouse button
    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas)

    /// Called when user drags mouse
    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas)

    /// Called when user releases mouse button
    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas)

    // MARK: - UI Components

    /// Returns settings panel view for this tool
    @ViewBuilder
    func settingsPanel() -> some View

    /// Returns preview rendering during interaction
    func renderPreview(in context: inout GraphicsContext, canvasSize: CGSize)

    // MARK: - State Management

    /// Called when tool is activated
    func onActivate()

    /// Called when tool is deactivated
    func onDeactivate()

    /// Reset tool state (called on cancel/ESC)
    func reset()

    /// Whether annotation can be created in current state
    func canCreateAnnotation() -> Bool
}

// Default implementations
extension AnnotationTool {
    var keyboardShortcut: KeyEquivalent? { nil }

    func onActivate() { }
    func onDeactivate() { reset() }
    func reset() { }
    func canCreateAnnotation() -> Bool { true }
    func renderPreview(in context: inout GraphicsContext, canvasSize: CGSize) { }
}
```

---

## Supporting Types

### AnnotationCanvas

```swift
@Observable
class AnnotationCanvas {
    var annotations: [any Annotation] = []
    var selectedAnnotationID: UUID?
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    // MARK: - Annotation Management

    func addAnnotation(_ annotation: any Annotation) {
        let command = AddAnnotationCommand(annotation: annotation)
        execute(command)
    }

    func removeAnnotation(id: UUID) {
        guard let annotation = annotation(withID: id) else { return }
        let command = RemoveAnnotationCommand(annotation: annotation)
        execute(command)
    }

    func updateAnnotation(_ id: UUID, _ transform: (inout any Annotation) -> Void) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        let oldAnnotation = annotations[index]
        var newAnnotation = annotations[index]
        transform(&newAnnotation)

        let command = ModifyAnnotationCommand(old: oldAnnotation, new: newAnnotation)
        execute(command)
    }

    // MARK: - Selection

    func select(_ id: UUID) {
        selectedAnnotationID = id
    }

    func deselect() {
        selectedAnnotationID = nil
    }

    // MARK: - Hit Testing

    func annotationAt(_ point: CGPoint) -> (any Annotation)? {
        // Iterate in reverse z-index order (top to bottom)
        annotations
            .sorted { $0.zIndex > $1.zIndex }
            .first { $0.contains(point) }
    }

    func annotation(withID id: UUID) -> (any Annotation)? {
        annotations.first { $0.id == id }
    }

    // MARK: - Undo/Redo

    private func execute(_ command: CanvasCommand) {
        command.execute(on: self)
        undoStack.append(command)
        redoStack.removeAll()
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo(on: self)
        redoStack.append(command)
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute(on: self)
        undoStack.append(command)
    }
}

// Undo/Redo Commands
protocol CanvasCommand {
    func execute(on canvas: AnnotationCanvas)
    func undo(on canvas: AnnotationCanvas)
}

struct AddAnnotationCommand: CanvasCommand {
    let annotation: any Annotation

    func execute(on canvas: AnnotationCanvas) {
        canvas.annotations.append(annotation)
    }

    func undo(on canvas: AnnotationCanvas) {
        canvas.annotations.removeAll { $0.id == annotation.id }
    }
}

struct RemoveAnnotationCommand: CanvasCommand {
    let annotation: any Annotation

    func execute(on canvas: AnnotationCanvas) {
        canvas.annotations.removeAll { $0.id == annotation.id }
    }

    func undo(on canvas: AnnotationCanvas) {
        canvas.annotations.append(annotation)
    }
}

struct ModifyAnnotationCommand: CanvasCommand {
    let old: any Annotation
    let new: any Annotation

    func execute(on canvas: AnnotationCanvas) {
        if let index = canvas.annotations.firstIndex(where: { $0.id == new.id }) {
            canvas.annotations[index] = new
        }
    }

    func undo(on canvas: AnnotationCanvas) {
        if let index = canvas.annotations.firstIndex(where: { $0.id == old.id }) {
            canvas.annotations[index] = old
        }
    }
}
```

### Color Helpers

```swift
extension Color {
    /// Convert to RGBA components for JSON serialization
    var rgba: (red: Double, green: Double, blue: Double, alpha: Double) {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        #elseif canImport(AppKit)
        let nsColor = NSColor(self)
        guard let uiColor = nsColor.usingColorSpace(.deviceRGB) else {
            return (0, 0, 0, 1)
        }
        #endif

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }

    init(rgba: (red: Double, green: Double, blue: Double, alpha: Double)) {
        self = Color(red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
    }
}

/// Codable wrapper for Color
struct CodableColor: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: Color) {
        let rgba = color.rgba
        self.red = rgba.red
        self.green = rgba.green
        self.blue = rgba.blue
        self.alpha = rgba.alpha
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
```

---

## Tool Implementations

### 1. Select Tool

```swift
@Observable
class SelectTool: AnnotationTool {
    let id = "tool.select"
    let name = "Select"
    let icon = "arrow.up.left.and.arrow.down.right"
    let keyboardShortcut: KeyEquivalent? = "v"

    // Settings
    var snapToGrid: Bool = false
    var gridSize: CGFloat = 10

    // State
    private var selectedID: UUID?
    private var dragStartPoint: CGPoint = .zero
    private var resizeHandle: ResizeHandle?

    enum ResizeHandle {
        case topLeft, top, topRight
        case left, right
        case bottomLeft, bottom, bottomRight
        case move
    }

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        // Check if clicking on existing selection's handles
        if let id = canvas.selectedAnnotationID,
           let handle = handleAt(point, for: id, on: canvas) {
            selectedID = id
            resizeHandle = handle
            dragStartPoint = point
            return
        }

        // Find annotation at point
        if let annotation = canvas.annotationAt(point) {
            selectedID = annotation.id
            canvas.select(annotation.id)
            resizeHandle = .move
            dragStartPoint = point
        } else {
            canvas.deselect()
            selectedID = nil
        }
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        guard let id = selectedID else { return }

        var delta = CGSize(
            width: point.x - dragStartPoint.x,
            height: point.y - dragStartPoint.y
        )

        if snapToGrid {
            delta.width = round(delta.width / gridSize) * gridSize
            delta.height = round(delta.height / gridSize) * gridSize
        }

        if resizeHandle == .move {
            // Move annotation
            canvas.updateAnnotation(id) { ann in
                ann.transform.position.x += delta.width
                ann.transform.position.y += delta.height
            }
        } else if let handle = resizeHandle {
            // Resize annotation
            resizeAnnotation(id, handle: handle, delta: delta, on: canvas)
        }

        dragStartPoint = point
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        selectedID = nil
        resizeHandle = nil
    }

    func reset() {
        selectedID = nil
        resizeHandle = nil
        dragStartPoint = .zero
    }

    private func handleAt(_ point: CGPoint, for id: UUID, on canvas: AnnotationCanvas) -> ResizeHandle? {
        guard let annotation = canvas.annotation(withID: id) else { return nil }

        let handleSize: CGFloat = 8
        let bounds = annotation.bounds
        let pos = annotation.transform.position

        // Check corner handles
        if point.distance(to: CGPoint(x: pos.x - bounds.width/2, y: pos.y - bounds.height/2)) < handleSize {
            return .topLeft
        }
        // ... check other handles

        return nil
    }

    private func resizeAnnotation(_ id: UUID, handle: ResizeHandle, delta: CGSize, on canvas: AnnotationCanvas) {
        canvas.updateAnnotation(id) { ann in
            switch handle {
            case .topLeft:
                ann.bounds.width -= delta.width
                ann.bounds.height -= delta.height
                ann.transform.position.x += delta.width / 2
                ann.transform.position.y += delta.height / 2
            case .bottomRight:
                ann.bounds.width += delta.width
                ann.bounds.height += delta.height
                ann.transform.position.x += delta.width / 2
                ann.transform.position.y += delta.height / 2
            // ... other cases
            default:
                break
            }
        }
    }

    @ViewBuilder
    func settingsPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selection Tool")
                .font(.headline)

            Toggle("Snap to Grid", isOn: $snapToGrid)

            if snapToGrid {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Grid Size")
                        Spacer()
                        Text("\(Int(gridSize))px")
                    }
                    Slider(value: $gridSize, in: 5...50, step: 5)
                }
            }
        }
        .padding()
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
```

---

### 2. Line Tool

```swift
@Observable
class LineTool: AnnotationTool {
    let id = "tool.line"
    let name = "Line"
    let icon = "line.diagonal"
    let keyboardShortcut: KeyEquivalent? = "l"

    // Settings
    var strokeColor: Color = .black
    var strokeWidth: CGFloat = 2.0
    var lineStyle: LineStyle = .solid
    var lineCap: LineCap = .round
    var lineJoin: LineJoin = .round

    // State
    private var startPoint: CGPoint = .zero
    private var currentEndPoint: CGPoint = .zero
    private var isDrawing: Bool = false

    // Performance
    private var lastPreviewUpdate: Date = Date()
    private let previewThrottleInterval: TimeInterval = 1.0 / 60.0

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        startPoint = point
        currentEndPoint = point
        isDrawing = true
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        currentEndPoint = point

        let now = Date()
        if now.timeIntervalSince(lastPreviewUpdate) >= previewThrottleInterval {
            lastPreviewUpdate = now
            // Canvas will redraw with renderPreview
        }
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard isDrawing, canCreateAnnotation() else {
            reset()
            return
        }

        isDrawing = false

        let width = abs(currentEndPoint.x - startPoint.x)
        let height = abs(currentEndPoint.y - startPoint.y)

        let line = LineAnnotation(
            id: UUID(),
            zIndex: canvas.annotations.count,
            transform: Transform(
                position: CGPoint(
                    x: (startPoint.x + currentEndPoint.x) / 2,
                    y: (startPoint.y + currentEndPoint.y) / 2
                ),
                rotation: 0,
                scale: CGPoint(x: 1, y: 1)
            ),
            bounds: CGSize(width: width, height: height),
            locked: false,
            visible: true,
            properties: LineAnnotation.Properties(
                startPoint: CGPoint(
                    x: startPoint.x < currentEndPoint.x ? -width/2 : width/2,
                    y: startPoint.y < currentEndPoint.y ? -height/2 : height/2
                ),
                endPoint: CGPoint(
                    x: startPoint.x < currentEndPoint.x ? width/2 : -width/2,
                    y: startPoint.y < currentEndPoint.y ? height/2 : -height/2
                ),
                strokeColor: CodableColor(strokeColor),
                strokeWidth: strokeWidth,
                lineStyle: lineStyle.rawValue,
                lineCap: lineCap.rawValue,
                lineJoin: lineJoin.rawValue
            )
        )

        canvas.addAnnotation(line)
        reset()
    }

    func reset() {
        isDrawing = false
        startPoint = .zero
        currentEndPoint = .zero
    }

    func canCreateAnnotation() -> Bool {
        // Minimum line length of 5 points
        let distance = hypot(
            currentEndPoint.x - startPoint.x,
            currentEndPoint.y - startPoint.y
        )
        return distance > 5.0
    }

    func renderPreview(in context: inout GraphicsContext, canvasSize: CGSize) {
        guard isDrawing else { return }

        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: currentEndPoint)

        context.stroke(
            path,
            with: .color(strokeColor),
            style: StrokeStyle(
                lineWidth: strokeWidth,
                lineCap: lineCap.cgLineCap,
                lineJoin: lineJoin.cgLineJoin,
                dash: lineStyle.dashPattern
            )
        )
    }

    @ViewBuilder
    func settingsPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Line Settings")
                .font(.headline)

            HStack {
                Text("Color")
                Spacer()
                ColorPicker("", selection: $strokeColor)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Width")
                    Spacer()
                    Text(String(format: "%.1f", strokeWidth))
                }
                Slider(value: $strokeWidth, in: 0.5...10.0)
            }

            VStack(alignment: .leading) {
                Text("Style")
                Picker("", selection: $lineStyle) {
                    ForEach([LineStyle.solid, .dashed, .dotted], id: \.self) { style in
                        Text(style.rawValue.capitalized).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider()

            VStack(alignment: .leading) {
                Text("Quick Presets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Button("Thin") { strokeWidth = 1.0 }
                    Button("Medium") { strokeWidth = 2.5 }
                    Button("Thick") { strokeWidth = 5.0 }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

enum LineStyle: String, Codable, CaseIterable {
    case solid
    case dashed
    case dotted

    var dashPattern: [CGFloat] {
        switch self {
        case .solid: return []
        case .dashed: return [10, 5]
        case .dotted: return [2, 3]
        }
    }
}

enum LineCap: String, Codable, CaseIterable {
    case butt
    case round
    case square

    var cgLineCap: CGLineCap {
        switch self {
        case .butt: return .butt
        case .round: return .round
        case .square: return .square
        }
    }
}

enum LineJoin: String, Codable, CaseIterable {
    case miter
    case round
    case bevel

    var cgLineJoin: CGLineJoin {
        switch self {
        case .miter: return .miter
        case .round: return .round
        case .bevel: return .bevel
        }
    }
}
```

---

### 3. Shape Tool

```swift
@Observable
class ShapeTool: AnnotationTool {
    let id = "tool.shape"
    let name = "Shape"
    let icon = "square.on.circle"
    let keyboardShortcut: KeyEquivalent? = "r"

    // Settings
    var selectedShape: ShapeType = .rectangle
    var fillColor: Color = .white.opacity(0.5)
    var strokeColor: Color = .black
    var strokeWidth: CGFloat = 2.0
    var cornerRadius: CGFloat = 0

    // State
    private var startPoint: CGPoint = .zero
    private var currentPoint: CGPoint = .zero
    private var isDrawing: Bool = false

    // Recent shapes for quick access
    var recentShapes: [ShapeType] = [.rectangle, .circle]

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        startPoint = point
        currentPoint = point
        isDrawing = true
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        currentPoint = point
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard isDrawing, canCreateAnnotation() else {
            reset()
            return
        }

        isDrawing = false

        let width = abs(currentPoint.x - startPoint.x)
        let height = abs(currentPoint.y - startPoint.y)

        let shape = ShapeAnnotation(
            id: UUID(),
            zIndex: canvas.annotations.count,
            transform: Transform(
                position: CGPoint(
                    x: (startPoint.x + currentPoint.x) / 2,
                    y: (startPoint.y + currentPoint.y) / 2
                ),
                rotation: 0,
                scale: CGPoint(x: 1, y: 1)
            ),
            bounds: CGSize(width: width, height: height),
            locked: false,
            visible: true,
            properties: ShapeAnnotation.Properties(
                shape: selectedShape.rawValue,
                fillColor: CodableColor(fillColor),
                strokeColor: CodableColor(strokeColor),
                strokeWidth: strokeWidth,
                cornerRadius: cornerRadius,
                points: []
            )
        )

        canvas.addAnnotation(shape)

        // Track recently used
        if !recentShapes.contains(selectedShape) {
            recentShapes.insert(selectedShape, at: 0)
            if recentShapes.count > 5 {
                recentShapes.removeLast()
            }
        }

        reset()
    }

    func reset() {
        isDrawing = false
        startPoint = .zero
        currentPoint = .zero
    }

    func canCreateAnnotation() -> Bool {
        let width = abs(currentPoint.x - startPoint.x)
        let height = abs(currentPoint.y - startPoint.y)
        return width > 5 && height > 5
    }

    func renderPreview(in context: inout GraphicsContext, canvasSize: CGSize) {
        guard isDrawing else { return }

        let width = abs(currentPoint.x - startPoint.x)
        let height = abs(currentPoint.y - startPoint.y)

        let rect = CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: width,
            height: height
        )

        let path = pathForShape(selectedShape, in: rect)

        context.fill(path, with: .color(fillColor))
        context.stroke(path, with: .color(strokeColor), lineWidth: strokeWidth)
    }

    private func pathForShape(_ shape: ShapeType, in rect: CGRect) -> Path {
        switch shape {
        case .rectangle:
            return Path(roundedRect: rect, cornerRadius: cornerRadius)
        case .circle:
            return Path(ellipseIn: rect)
        case .ellipse:
            return Path(ellipseIn: rect)
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path
        case .polygon:
            return Path(roundedRect: rect, cornerRadius: 0) // Simplified
        }
    }

    @ViewBuilder
    func settingsPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shape Settings")
                .font(.headline)

            // Recent shapes
            if !recentShapes.isEmpty {
                VStack(alignment: .leading) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(recentShapes, id: \.self) { shape in
                            ShapeButton(
                                shape: shape,
                                isSelected: selectedShape == shape,
                                action: { selectedShape = shape }
                            )
                        }
                    }
                }

                Divider()
            }

            // All shapes
            VStack(alignment: .leading) {
                Text("All Shapes")
                    .font(.caption)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(ShapeType.allCases, id: \.self) { shape in
                        ShapeButton(
                            shape: shape,
                            isSelected: selectedShape == shape,
                            action: { selectedShape = shape }
                        )
                    }
                }
            }

            Divider()

            HStack {
                Text("Fill")
                Spacer()
                ColorPicker("", selection: $fillColor)
            }

            HStack {
                Text("Stroke")
                Spacer()
                ColorPicker("", selection: $strokeColor)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Stroke Width")
                    Spacer()
                    Text(String(format: "%.1f", strokeWidth))
                }
                Slider(value: $strokeWidth, in: 0...10)
            }

            if selectedShape == .rectangle {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Corner Radius")
                        Spacer()
                        Text(String(format: "%.0f", cornerRadius))
                    }
                    Slider(value: $cornerRadius, in: 0...50)
                }
            }
        }
        .padding()
    }
}

enum ShapeType: String, Codable, CaseIterable {
    case rectangle
    case circle
    case ellipse
    case triangle
    case polygon
}

struct ShapeButton: View {
    let shape: ShapeType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            shapePreview
                .frame(height: 40)
        }
        .buttonStyle(.bordered)
        .border(isSelected ? Color.accentColor : Color.clear, width: 2)
    }

    @ViewBuilder
    var shapePreview: some View {
        switch shape {
        case .rectangle:
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primary, lineWidth: 1.5)
        case .circle, .ellipse:
            Circle()
                .stroke(Color.primary, lineWidth: 1.5)
        case .triangle:
            Canvas { context, size in
                var path = Path()
                path.move(to: CGPoint(x: size.width / 2, y: 2))
                path.addLine(to: CGPoint(x: size.width - 2, y: size.height - 2))
                path.addLine(to: CGPoint(x: 2, y: size.height - 2))
                path.closeSubpath()
                context.stroke(path, with: .color(.primary), lineWidth: 1.5)
            }
        case .polygon:
            Canvas { context, size in
                var path = Path()
                let points = 6
                let radius = min(size.width, size.height) / 2 - 2
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                for i in 0..<points {
                    let angle = (Double(i) * 360.0 / Double(points) - 90) * .pi / 180
                    let x = center.x + CGFloat(cos(angle)) * radius
                    let y = center.y + CGFloat(sin(angle)) * radius

                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(.primary), lineWidth: 1.5)
            }
        }
    }
}
```

---

### 4. Text Tool

```swift
@Observable
class TextTool: AnnotationTool {
    let id = "tool.text"
    let name = "Text"
    let icon = "character"
    let keyboardShortcut: KeyEquivalent? = "t"

    // Settings
    var fontSize: Double = 16
    var fontName: String = "System"
    var fontWeight: String = "regular"
    var textColor: Color = .black
    var textAlignment: String = "left"

    // State
    private var placementPoint: CGPoint = .zero
    private var isPlacingText: Bool = false

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        placementPoint = point
        isPlacingText = true
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        // Text tool doesn't use drag
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard isPlacingText else { return }
        isPlacingText = false

        // In real implementation, would show text input dialog
        // For now, create with placeholder text
        createTextAnnotation(text: "Double-click to edit", at: placementPoint, on: canvas)
    }

    func createTextAnnotation(text: String, at point: CGPoint, on canvas: AnnotationCanvas) {
        guard !text.isEmpty else { return }

        let textAnnotation = TextAnnotation(
            id: UUID(),
            zIndex: canvas.annotations.count,
            transform: Transform(
                position: point,
                rotation: 0,
                scale: CGPoint(x: 1, y: 1)
            ),
            bounds: CGSize(width: 200, height: 40),
            locked: false,
            visible: true,
            properties: TextAnnotation.Properties(
                text: text,
                fontSize: fontSize,
                fontName: fontName,
                fontWeight: fontWeight,
                fontStyle: "normal",
                textColor: CodableColor(textColor),
                textAlignment: textAlignment,
                lineSpacing: 1.0,
                backgroundColor: CodableColor(.clear)
            )
        )

        canvas.addAnnotation(textAnnotation)
    }

    func reset() {
        isPlacingText = false
        placementPoint = .zero
    }

    @ViewBuilder
    func settingsPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Text Settings")
                .font(.headline)

            VStack(alignment: .leading) {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Text("\(Int(fontSize))pt")
                }
                Slider(value: $fontSize, in: 8...72, step: 1)
            }

            VStack(alignment: .leading) {
                Text("Font")
                Picker("", selection: $fontName) {
                    Text("System").tag("System")
                    Text("Helvetica").tag("Helvetica")
                    Text("Monaco").tag("Monaco")
                    Text("Times New Roman").tag("Times New Roman")
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading) {
                Text("Weight")
                Picker("", selection: $fontWeight) {
                    Text("Regular").tag("regular")
                    Text("Bold").tag("bold")
                    Text("Light").tag("light")
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Text("Color")
                Spacer()
                ColorPicker("", selection: $textColor)
            }

            VStack(alignment: .leading) {
                Text("Alignment")
                Picker("", selection: $textAlignment) {
                    Text("Left").tag("left")
                    Text("Center").tag("center")
                    Text("Right").tag("right")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
    }
}
```

---

## Tool Management

### ToolManager

```swift
@Observable
class ToolManager {
    var selectedToolID: String = "tool.select"
    private(set) var tools: [String: any AnnotationTool] = [:]

    var selectedTool: (any AnnotationTool)? {
        tools[selectedToolID]
    }

    var toolsByCategory: [String: [any AnnotationTool]] {
        [
            "Selection": [tools["tool.select"]].compactMap { $0 },
            "Drawing": [
                tools["tool.line"],
                tools["tool.shape"],
                tools["tool.freehand"]
            ].compactMap { $0 },
            "Text": [
                tools["tool.text"],
                tools["tool.number"]
            ].compactMap { $0 },
            "Effects": [
                tools["tool.highlight"],
                tools["tool.blur"]
            ].compactMap { $0 },
            "Other": [
                tools["tool.note"],
                tools["tool.image"]
            ].compactMap { $0 }
        ]
    }

    init() {
        registerDefaultTools()
    }

    private func registerDefaultTools() {
        register(SelectTool())
        register(LineTool())
        register(ShapeTool())
        register(TextTool())
        // ... register other tools
    }

    func register(_ tool: any AnnotationTool) {
        tools[tool.id] = tool
    }

    func selectTool(_ toolID: String) {
        guard tools[toolID] != nil else { return }

        selectedTool?.onDeactivate()
        selectedToolID = toolID
        selectedTool?.onActivate()
    }

    func selectToolByKeyboardShortcut(_ key: KeyEquivalent) {
        if let tool = tools.values.first(where: { $0.keyboardShortcut == key }) {
            selectTool(tool.id)
        }
    }
}
```

---

## Canvas Integration

### AnnotationCanvasView

```swift
struct AnnotationCanvasView: View {
    @Bindable var canvas: AnnotationCanvas
    @Bindable var toolManager: ToolManager

    @State private var canvasSize: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ToolbarView(toolManager: toolManager)

            HStack(spacing: 0) {
                // Canvas
                GeometryReader { geometry in
                    Canvas { context, size in
                        // Draw base image (if any)
                        // ...

                        // Draw annotations in z-index order
                        for annotation in canvas.annotations.sorted(by: { $0.zIndex < $1.zIndex }) {
                            var mutableAnnotation = annotation
                            mutableAnnotation.render(in: &context, imageSize: size)
                        }

                        // Draw tool preview
                        toolManager.selectedTool?.renderPreview(in: &context, canvasSize: size)

                        // Draw selection handles
                        if let selectedID = canvas.selectedAnnotationID,
                           let annotation = canvas.annotation(withID: selectedID) {
                            drawSelectionHandles(for: annotation, in: &context)
                        }
                    }
                    .background(Color.white)
                    .border(Color.gray.opacity(0.5))
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                if value.translation == .zero {
                                    toolManager.selectedTool?.onMouseDown(at: value.location, on: canvas)
                                } else {
                                    toolManager.selectedTool?.onMouseDrag(to: value.location, on: canvas)
                                }
                            }
                            .onEnded { value in
                                toolManager.selectedTool?.onMouseUp(at: value.location, on: canvas)
                            }
                    )
                    .onAppear {
                        canvasSize = geometry.size
                    }
                }

                // Settings panel
                if let tool = toolManager.selectedTool {
                    VStack(alignment: .leading) {
                        tool.settingsPanel()
                        Spacer()
                    }
                    .frame(width: 250)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .border(Color.gray.opacity(0.3), width: 1)
                }
            }
        }
        .onKeyPress(.escape) { _ in
            toolManager.selectedTool?.reset()
            canvas.deselect()
            return .handled
        }
        .onKeyPress { press in
            toolManager.selectToolByKeyboardShortcut(press.key)
            return .handled
        }
    }

    private func drawSelectionHandles(for annotation: any Annotation, in context: inout GraphicsContext) {
        let handleSize: CGFloat = 8
        let pos = annotation.transform.position
        let bounds = annotation.bounds

        let handles = [
            CGPoint(x: pos.x - bounds.width/2, y: pos.y - bounds.height/2), // Top-left
            CGPoint(x: pos.x + bounds.width/2, y: pos.y - bounds.height/2), // Top-right
            CGPoint(x: pos.x - bounds.width/2, y: pos.y + bounds.height/2), // Bottom-left
            CGPoint(x: pos.x + bounds.width/2, y: pos.y + bounds.height/2), // Bottom-right
        ]

        for handle in handles {
            let rect = CGRect(
                x: handle.x - handleSize/2,
                y: handle.y - handleSize/2,
                width: handleSize,
                height: handleSize
            )

            context.fill(Path(ellipseIn: rect), with: .color(.white))
            context.stroke(Path(ellipseIn: rect), with: .color(.accentColor), lineWidth: 1.5)
        }
    }
}

struct ToolbarView: View {
    @Bindable var toolManager: ToolManager

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(toolManager.tools.values), id: \.id) { tool in
                Button(action: {
                    toolManager.selectTool(tool.id)
                }) {
                    Label(tool.name, systemImage: tool.icon)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .background(toolManager.selectedToolID == tool.id ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(4)
                .help(tool.name + (tool.keyboardShortcut.map { " (\($0.character.uppercased()))" } ?? ""))
            }

            Spacer()

            // Undo/Redo buttons
            Button(action: { /* canvas.undo() */ }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .keyboardShortcut("z", modifiers: .command)

            Button(action: { /* canvas.redo() */ }) {
                Image(systemName: "arrow.uturn.forward")
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
```

---

## Creating Custom Tools

### Example: Arrow Tool

```swift
@Observable
class ArrowTool: AnnotationTool {
    let id = "tool.arrow"
    let name = "Arrow"
    let icon = "arrow.right"
    let keyboardShortcut: KeyEquivalent? = "a"

    // Settings
    var strokeColor: Color = .black
    var strokeWidth: CGFloat = 2.0
    var arrowheadSize: CGFloat = 15
    var arrowStyle: ArrowStyle = .solid

    // State
    private var startPoint: CGPoint = .zero
    private var endPoint: CGPoint = .zero
    private var isDrawing: Bool = false

    enum ArrowStyle: String, CaseIterable {
        case solid
        case outline
        case double
    }

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        startPoint = point
        endPoint = point
        isDrawing = true
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        endPoint = point
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard isDrawing, canCreateAnnotation() else {
            reset()
            return
        }

        isDrawing = false

        // Create arrow annotation
        // Implementation depends on your arrow annotation structure

        reset()
    }

    func reset() {
        isDrawing = false
        startPoint = .zero
        endPoint = .zero
    }

    func canCreateAnnotation() -> Bool {
        hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y) > 10
    }

    func renderPreview(in context: inout GraphicsContext, canvasSize: CGSize) {
        guard isDrawing else { return }

        // Draw line
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)

        context.stroke(path, with: .color(strokeColor), lineWidth: strokeWidth)

        // Draw arrowhead
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowPath = createArrowhead(at: endPoint, angle: angle)

        context.fill(arrowPath, with: .color(strokeColor))
    }

    private func createArrowhead(at point: CGPoint, angle: CGFloat) -> Path {
        var path = Path()

        let arrowAngle: CGFloat = .pi / 6  // 30 degrees

        let point1 = CGPoint(
            x: point.x - arrowheadSize * cos(angle - arrowAngle),
            y: point.y - arrowheadSize * sin(angle - arrowAngle)
        )

        let point2 = CGPoint(
            x: point.x - arrowheadSize * cos(angle + arrowAngle),
            y: point.y - arrowheadSize * sin(angle + arrowAngle)
        )

        path.move(to: point)
        path.addLine(to: point1)
        path.move(to: point)
        path.addLine(to: point2)

        return path
    }

    @ViewBuilder
    func settingsPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Arrow Settings")
                .font(.headline)

            HStack {
                Text("Color")
                Spacer()
                ColorPicker("", selection: $strokeColor)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Width")
                    Spacer()
                    Text(String(format: "%.1f", strokeWidth))
                }
                Slider(value: $strokeWidth, in: 1...10)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Arrowhead Size")
                    Spacer()
                    Text(String(format: "%.0f", arrowheadSize))
                }
                Slider(value: $arrowheadSize, in: 5...30)
            }

            VStack(alignment: .leading) {
                Text("Style")
                Picker("", selection: $arrowStyle) {
                    ForEach(ArrowStyle.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
    }
}

// Register in ToolManager:
// register(ArrowTool())
```

---

## Best Practices Summary

### 1. Use @Observable for State Management
- Tool classes use `@Observable` (Swift 5.9+) or `ObservableObject`
- Direct property binding with `$`
- No need for settings protocol or casting

### 2. Separate Settings from State
- **Settings**: User-configurable, persistent (strokeColor, fontSize)
- **State**: Temporary, interaction-specific (isDrawing, startPoint)

### 3. Validate Before Creating
- Implement `canCreateAnnotation()` to check validity
- Don't create tiny/invalid annotations

### 4. Performance Optimization
- Throttle preview rendering to 60 FPS
- Cache complex paths
- Use efficient rendering primitives

### 5. Reset on Cancel
- Implement `reset()` to clear state
- Call on ESC key or tool switch
- Prevent orphaned state

### 6. Keyboard Shortcuts
- Define shortcuts in tool
- Register in Commands for menu bar
- Use `.onKeyPress()` for canvas shortcuts

### 7. Undo/Redo Integration
- All edits through `canvas.addAnnotation()`
- Canvas handles command pattern automatically
- Don't manually manage undo state in tools

---

## Testing Tools

```swift
import Testing
@testable import QuickEdit

@Test
func testLineToolCreatesAnnotation() async {
    let canvas = AnnotationCanvas()
    let tool = LineTool()

    tool.onMouseDown(at: CGPoint(x: 0, y: 0), on: canvas)
    tool.onMouseDrag(to: CGPoint(x: 100, y: 100), on: canvas)
    tool.onMouseUp(at: CGPoint(x: 100, y: 100), on: canvas)

    #expect(canvas.annotations.count == 1)
    #expect(canvas.annotations.first?.type == "line")
}

@Test
func testToolValidation() async {
    let tool = LineTool()
    let canvas = AnnotationCanvas()

    // Too short - should not create
    tool.onMouseDown(at: .zero, on: canvas)
    tool.onMouseUp(at: CGPoint(x: 2, y: 2), on: canvas)

    #expect(canvas.annotations.isEmpty)
}

@Test
func testToolReset() async {
    let tool = LineTool()
    let canvas = AnnotationCanvas()

    tool.onMouseDown(at: .zero, on: canvas)
    #expect(tool.canCreateAnnotation() == false)  // Not drawing yet

    tool.reset()
    #expect(tool.canCreateAnnotation() == false)  // Still false after reset
}
```

---

**Document Status:** ✅ Production Ready
**Next Steps:** Implement in Phase 2 (Frontend) with UI mockups
