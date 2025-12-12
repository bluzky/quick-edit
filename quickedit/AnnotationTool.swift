//
//  AnnotationTool.swift
//  quickedit
//
//  Protocol-based tool system for creating and manipulating annotations via mouse events.
//  All tools implement this protocol and register with ToolRegistry.
//

import SwiftUI
import Combine
import AppKit

// MARK: - Tool Protocol

/// Protocol for annotation tools that handle mouse events and create/modify annotations
protocol AnnotationTool: AnyObject {
    /// Unique identifier for the tool (e.g., "select", "rectangle")
    var id: String { get }

    /// Human-readable name for UI (e.g., "Select", "Rectangle")
    var name: String { get }

    /// SF Symbol name for toolbar icon
    var iconName: String { get }

    /// Called when mouse button is pressed down
    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas)

    /// Called when mouse is dragged while button is held
    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas)

    /// Called when mouse button is released
    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas)

    /// Called when the operation should be cancelled (e.g., Escape key)
    func onCancel(on canvas: AnnotationCanvas)

    /// Called when this tool becomes active
    func activate()

    /// Called when this tool is deactivated (switching to another tool)
    func deactivate()

    /// Return SwiftUI view for preview overlay during interaction (e.g., shape being drawn)
    @ViewBuilder
    func previewView(canvas: AnnotationCanvas) -> AnyView
}

// MARK: - Protocol Defaults

/// Default implementations for optional protocol methods
extension AnnotationTool {
    func activate() {}
    func deactivate() {}
    func onCancel(on canvas: AnnotationCanvas) {}
    func previewView(canvas: AnnotationCanvas) -> AnyView {
        AnyView(EmptyView())
    }
}

// MARK: - Select Tool

/// Tool for selecting and manipulating annotations
final class SelectTool: AnnotationTool {
    let id = "select"
    let name = "Select"
    let iconName = "cursorarrow"

    private var dragStartPoint: CGPoint?
    private var isDraggingAnnotations: Bool = false
    private var initialPanOffset: CGPoint?
    private var originalPositions: [UUID: CGPoint] = [:]  // Track original positions for live preview
    private var activeControlPoint: (annotationID: UUID, controlID: ControlPointRole)?
    private var controlPointSnapshots: [UUID: AnnotationSnapshot] = [:]

    // Double-click detection
    private var lastClickTime: Date?
    private var lastClickedAnnotationID: UUID?
    private let doubleClickInterval: TimeInterval = 0.5  // 500ms

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        dragStartPoint = point

        // Check if Shift or Cmd key is pressed for multi-select
        let isAdditiveSelection = NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)

        // First check if user grabbed a visible control point on selected annotations
        if let hit = canvas.controlPointHitTest(at: point) {
            activeControlPoint = hit
            if controlPointSnapshots[hit.0] == nil {
                controlPointSnapshots[hit.0] = canvas.snapshot(for: hit.0)
            }
            canvas.onInteractionBegan.send("adjusting_handle")
            return
        }

        // Hit test to find annotation at point (point is in canvas space)
        if let hit = canvas.annotation(at: point) {
            // Check for double-click on shapes
            let now = Date()
            if let lastClick = lastClickTime,
               let lastID = lastClickedAnnotationID,
               lastID == hit.id,
               now.timeIntervalSince(lastClick) < doubleClickInterval,
               hit is ShapeAnnotation {
                // Double-click detected on a shape - enter text editing mode
                canvas.beginEditingText(for: hit.id)
                lastClickTime = nil
                lastClickedAnnotationID = nil
                return
            }

            // Update double-click tracking
            lastClickTime = now
            lastClickedAnnotationID = hit.id

            // If clicking an unselected annotation, select it
            if !canvas.selectedAnnotationIDs.contains(hit.id) {
                canvas.toggleSelection(for: hit.id, additive: isAdditiveSelection)
            } else if isAdditiveSelection {
                // Shift/Cmd clicking an already selected annotation deselects it
                canvas.toggleSelection(for: hit.id, additive: true)
                return
            }

            // Now prepare to drag (works for both previously selected and newly selected)
            isDraggingAnnotations = true

            // Save original positions of all selected annotations
            originalPositions.removeAll()
            for annotation in canvas.annotations where canvas.selectedAnnotationIDs.contains(annotation.id) {
                originalPositions[annotation.id] = annotation.transform.position
            }
        } else {
            // Clicking empty space
            if !isAdditiveSelection {
                // Clear selection only if not holding modifier keys
                canvas.clearSelection()
            }
            isDraggingAnnotations = false
            initialPanOffset = canvas.panOffset
            lastClickTime = nil
            lastClickedAnnotationID = nil
        }
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        if let activeHandle = activeControlPoint {
            let imagePoint = canvas.canvasToImage(point)
            let target = canvas.snapToGrid ? canvas.snapToGrid(imagePoint, gridSize: canvas.gridSize) : imagePoint
            if let index = canvas.annotationIndex(for: activeHandle.annotationID) {
                canvas.annotations[index].moveControlPoint(activeHandle.controlID, to: target)
                canvas.onAnnotationModified.send(activeHandle.annotationID)
            }
            return
        }

        guard let startPoint = dragStartPoint else { return }

        if isDraggingAnnotations {
            // Live preview: directly update annotation positions during drag
            let startImage = canvas.canvasToImage(startPoint)
            let currentImage = canvas.canvasToImage(point)
            let delta = CGPoint(
                x: currentImage.x - startImage.x,
                y: currentImage.y - startImage.y
            )

            // Temporarily move annotations (direct mutation for preview)
            for i in canvas.annotations.indices where canvas.selectedAnnotationIDs.contains(canvas.annotations[i].id) {
                if let originalPos = originalPositions[canvas.annotations[i].id] {
                    canvas.annotations[i].transform.position = CGPoint(
                        x: originalPos.x + delta.x,
                        y: originalPos.y + delta.y
                    )
                }
            }
        } else {
            // Pan the canvas
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
        defer {
            dragStartPoint = nil
            isDraggingAnnotations = false
            initialPanOffset = nil
            originalPositions.removeAll()
            if activeControlPoint == nil {
                controlPointSnapshots.removeAll()
            }
        }

        if let activeHandle = activeControlPoint {
            let imagePoint = canvas.canvasToImage(point)
            let target = canvas.snapToGrid ? canvas.snapToGrid(imagePoint, gridSize: canvas.gridSize) : imagePoint

            // Restore original state before issuing command for correct undo/redo
            if let snapshot = controlPointSnapshots[activeHandle.annotationID] {
                canvas.applySnapshot(snapshot, to: activeHandle.annotationID)
            }

            let command = MoveControlPointCommand(
                annotationID: activeHandle.annotationID,
                controlPointID: activeHandle.controlID,
                newPosition: target
            )
            canvas.execute(command)
            canvas.onInteractionEnded.send("adjusting_handle")

            activeControlPoint = nil
            return
        }

        if isDraggingAnnotations {
            // Calculate final delta in image space
            guard let startPoint = dragStartPoint else { return }
            let startImage = canvas.canvasToImage(startPoint)
            let endImage = canvas.canvasToImage(point)
            var delta = CGPoint(
                x: endImage.x - startImage.x,
                y: endImage.y - startImage.y
            )

            // Reset to original positions before creating command
            for i in canvas.annotations.indices where canvas.selectedAnnotationIDs.contains(canvas.annotations[i].id) {
                if let originalPos = originalPositions[canvas.annotations[i].id] {
                    canvas.annotations[i].transform.position = originalPos
                }
            }

            // Apply grid snapping to the delta BEFORE creating command
            if canvas.snapToGrid {
                // Calculate where selection would end up
                if let selectionBounds = canvas.selectionBoundingBox(for: canvas.selectedAnnotationIDs) {
                    let wouldBeOrigin = CGPoint(
                        x: selectionBounds.origin.x + delta.x,
                        y: selectionBounds.origin.y + delta.y
                    )
                    let snappedOrigin = canvas.snapToGrid(wouldBeOrigin, gridSize: canvas.gridSize)

                    // Adjust delta to include snap
                    delta = CGPoint(
                        x: snappedOrigin.x - selectionBounds.origin.x,
                        y: snappedOrigin.y - selectionBounds.origin.y
                    )
                }
            }

            // Only create command if moved significantly (>1px to avoid micro-movements)
            if abs(delta.x) > 1 || abs(delta.y) > 1 {
                canvas.moveAnnotations(canvas.selectedAnnotationIDs, by: delta)
            }
        }
    }

    func deactivate() {
        // Clean up state when tool is deactivated
        dragStartPoint = nil
        isDraggingAnnotations = false
        initialPanOffset = nil
        originalPositions.removeAll()
        activeControlPoint = nil
        controlPointSnapshots.removeAll()
    }
}

// MARK: - Shape Tool

/// Tool for drawing multi-shape annotations
final class ShapeTool: AnnotationTool {
    let id = "shape"
    let name = "Shape"
    let iconName = "square.on.circle"

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var fillColor: Color = .blue.opacity(0.3)
    private var strokeColor: Color = .blue
    private var strokeWidth: CGFloat = 1.5
    private var cornerRadius: CGFloat = 10
    private var shapeKind: ShapeKind = .rectangle

    // Text properties
    private var text: String = ""
    private var textColor: Color = .black
    private var fontFamily: String = "System"
    private var fontSize: CGFloat = 16
    private var horizontalAlignment: HorizontalTextAlignment = .center
    private var verticalAlignment: VerticalTextAlignment = .middle

    func updateStyle(
        fill: Color,
        stroke: Color,
        strokeWidth: CGFloat,
        cornerRadius: CGFloat,
        shapeKind: ShapeKind,
        text: String,
        textColor: Color,
        fontFamily: String,
        fontSize: CGFloat,
        horizontalAlignment: HorizontalTextAlignment,
        verticalAlignment: VerticalTextAlignment
    ) {
        self.fillColor = fill
        self.strokeColor = stroke
        self.strokeWidth = strokeWidth
        self.cornerRadius = cornerRadius
        self.shapeKind = shapeKind
        self.text = text
        self.textColor = textColor
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
    }

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        let imagePoint = canvas.canvasToImage(point)
        startPoint = imagePoint
        currentPoint = imagePoint
        canvas.onInteractionBegan.send("drawing_shape")
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        let imagePoint = canvas.canvasToImage(point)
        currentPoint = imagePoint
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard let start = startPoint else { return }
        let imagePoint = canvas.canvasToImage(point)

        let constrained = isShiftPressed()
        let normalized = normalizedRect(start: start, end: imagePoint, constrainSquare: constrained)
        let minX = normalized.origin.x
        let minY = normalized.origin.y
        let width = normalized.size.width
        let height = normalized.size.height

        // Ignore tiny shapes
        guard width > 0.5, height > 0.5 else {
            resetState(on: canvas)
            return
        }

        let shape = ShapeAnnotation(
            zIndex: (canvas.annotations.map(\.zIndex).max() ?? 0) + 1,
            transform: AnnotationTransform(
                position: CGPoint(x: minX, y: minY),
                scale: CGSize(width: 1, height: 1),
                rotation: .zero
            ),
            size: CGSize(width: width, height: height),
            fill: fillColor,
            stroke: strokeColor,
            strokeWidth: strokeWidth,
            shapeKind: shapeKind,
            cornerRadius: shapeKind.supportsCornerRadius ? cornerRadius : 0,
            text: text,
            textColor: textColor,
            fontFamily: fontFamily,
            fontSize: fontSize,
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment
        )

        canvas.addAnnotation(shape)
        resetState(on: canvas)
    }

    func previewView(canvas: AnnotationCanvas) -> AnyView {
        guard let start = startPoint, let end = currentPoint else {
            return AnyView(EmptyView())
        }

        let constrained = isShiftPressed()
        let normalized = normalizedRect(start: start, end: end, constrainSquare: constrained)
        let minX = normalized.origin.x
        let minY = normalized.origin.y
        let width = normalized.size.width
        let height = normalized.size.height

        // Create a temporary preview shape
        let previewShape = ShapeAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: minX, y: minY),
                scale: CGSize(width: 1, height: 1),
                rotation: .zero
            ),
            size: CGSize(width: width, height: height),
            fill: fillColor,
            stroke: strokeColor,
            strokeWidth: strokeWidth,
            shapeKind: shapeKind,
            cornerRadius: shapeKind.supportsCornerRadius ? cornerRadius : 0,
            text: text,
            textColor: textColor,
            fontFamily: fontFamily,
            fontSize: fontSize,
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment
        )

        return AnyView(
            ShapeAnnotationView(annotation: previewShape)
                .opacity(0.7)  // Slightly transparent to indicate preview
        )
    }

    func deactivate() {
        startPoint = nil
        currentPoint = nil
    }

    private func resetState(on canvas: AnnotationCanvas) {
        startPoint = nil
        currentPoint = nil
        canvas.onInteractionEnded.send("drawing_shape")
    }

    private func normalizedRect(start: CGPoint, end: CGPoint, constrainSquare: Bool) -> CGRect {
        var width = end.x - start.x
        var height = end.y - start.y

        if constrainSquare {
            let maxSide = max(abs(width), abs(height))
            width = width >= 0 ? maxSide : -maxSide
            height = height >= 0 ? maxSide : -maxSide
        }

        let origin = CGPoint(
            x: width >= 0 ? start.x : start.x + width,
            y: height >= 0 ? start.y : start.y + height
        )

        return CGRect(origin: origin, size: CGSize(width: abs(width), height: abs(height)))
    }

    private func isShiftPressed() -> Bool {
        NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
    }
}

// MARK: - Line Tool

/// Tool for drawing straight lines with optional arrow heads
final class LineTool: AnnotationTool {
    let id = "line"
    let name = "Line"
    let iconName = "line.diagonal"

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?

    // Styling
    private var strokeColor: Color = .black
    private var strokeWidth: CGFloat = 2.5
    private var arrowStartType: ArrowType = .none
    private var arrowEndType: ArrowType = .open
    private var arrowSize: CGFloat = 10
    private var lineStyle: LineStyle = .solid
    private var lineCap: LineCap = .round

    func updateStyle(
        stroke: Color,
        strokeWidth: CGFloat,
        arrowStartType: ArrowType,
        arrowEndType: ArrowType,
        arrowSize: CGFloat,
        lineStyle: LineStyle,
        lineCap: LineCap
    ) {
        self.strokeColor = stroke
        self.strokeWidth = strokeWidth
        self.arrowStartType = arrowStartType
        self.arrowEndType = arrowEndType
        self.arrowSize = arrowSize
        self.lineStyle = lineStyle
        self.lineCap = lineCap
    }

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        let imagePoint = canvas.canvasToImage(point)
        startPoint = imagePoint
        currentPoint = imagePoint
        canvas.onInteractionBegan.send("drawing_line")
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        let imagePoint = canvas.canvasToImage(point)
        currentPoint = imagePoint
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard let start = startPoint else { return }
        let imagePoint = canvas.canvasToImage(point)

        let dx = imagePoint.x - start.x
        let dy = imagePoint.y - start.y
        let distance = hypot(dx, dy)

        // Ignore clicks without movement
        guard distance > 0.5 else {
            resetState(on: canvas)
            return
        }

        let minX = min(start.x, imagePoint.x)
        let minY = min(start.y, imagePoint.y)
        let width = abs(dx)
        let height = abs(dy)
        let safeWidth = max(width, 0.1)   // Avoid zero-sized bounds for selection handles
        let safeHeight = max(height, 0.1)

        var startLocal = CGPoint(x: start.x - minX, y: start.y - minY)
        var endLocal = CGPoint(x: imagePoint.x - minX, y: imagePoint.y - minY)

        if width == 0 {
            startLocal.x = safeWidth / 2
            endLocal.x = safeWidth / 2
        }

        if height == 0 {
            startLocal.y = safeHeight / 2
            endLocal.y = safeHeight / 2
        }

        let line = LineAnnotation(
            zIndex: (canvas.annotations.map(\.zIndex).max() ?? 0) + 1,
            transform: AnnotationTransform(
                position: CGPoint(x: minX, y: minY),
                scale: CGSize(width: 1, height: 1),
                rotation: .zero
            ),
            size: CGSize(width: safeWidth, height: safeHeight),
            startPoint: startLocal,
            endPoint: endLocal,
            stroke: strokeColor,
            strokeWidth: strokeWidth,
            arrowStartType: arrowStartType,
            arrowEndType: arrowEndType,
            arrowSize: arrowSize,
            lineStyle: lineStyle,
            lineCap: lineCap
        )

        canvas.addAnnotation(line)
        resetState(on: canvas)
    }

    func previewView(canvas: AnnotationCanvas) -> AnyView {
        guard let start = startPoint, let current = currentPoint else {
            return AnyView(EmptyView())
        }

        let dx = current.x - start.x
        let dy = current.y - start.y
        let distance = hypot(dx, dy)

        guard distance > 0.5 else {
            return AnyView(EmptyView())
        }

        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let width = abs(dx)
        let height = abs(dy)
        let safeWidth = max(width, 0.1)
        let safeHeight = max(height, 0.1)

        var startLocal = CGPoint(x: start.x - minX, y: start.y - minY)
        var endLocal = CGPoint(x: current.x - minX, y: current.y - minY)

        if width == 0 {
            startLocal.x = safeWidth / 2
            endLocal.x = safeWidth / 2
        }

        if height == 0 {
            startLocal.y = safeHeight / 2
            endLocal.y = safeHeight / 2
        }

        // Create a temporary preview line
        let previewLine = LineAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: minX, y: minY),
                scale: CGSize(width: 1, height: 1),
                rotation: .zero
            ),
            size: CGSize(width: safeWidth, height: safeHeight),
            startPoint: startLocal,
            endPoint: endLocal,
            stroke: strokeColor,
            strokeWidth: strokeWidth,
            arrowStartType: arrowStartType,
            arrowEndType: arrowEndType,
            arrowSize: arrowSize,
            lineStyle: lineStyle,
            lineCap: lineCap
        )

        return AnyView(
            LineAnnotationView(annotation: previewLine)
                .opacity(0.7)  // Slightly transparent to indicate preview
        )
    }

    func deactivate() {
        startPoint = nil
        currentPoint = nil
    }

    private func resetState(on canvas: AnnotationCanvas) {
        startPoint = nil
        currentPoint = nil
        canvas.onInteractionEnded.send("drawing_line")
    }
}

// MARK: - Tool Registry

/// Singleton registry for managing available annotation tools
final class ToolRegistry {
    static let shared = ToolRegistry()

    private var tools: [String: AnnotationTool] = [:]

    private init() {
        // Register built-in tools
        register(SelectTool())
        register(ShapeTool())
        register(LineTool())
    }

    /// Register a tool with the registry
    func register(_ tool: AnnotationTool) {
        tools[tool.id] = tool
    }

    /// Retrieve a tool by its ID
    func tool(withID id: String) -> AnnotationTool? {
        tools[id]
    }

    /// Get all registered tools
    func allTools() -> [AnnotationTool] {
        Array(tools.values)
    }
}
