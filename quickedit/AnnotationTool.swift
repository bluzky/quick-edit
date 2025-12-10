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

    /// Render preview overlay during interaction (e.g., shape being drawn)
    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas)
}

// MARK: - Protocol Defaults

/// Default implementations for optional protocol methods
extension AnnotationTool {
    func activate() {}
    func deactivate() {}
    func onCancel(on canvas: AnnotationCanvas) {}
    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {}
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

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        dragStartPoint = point

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
            // If clicking an unselected annotation, select it first
            if !canvas.selectedAnnotationIDs.contains(hit.id) {
                canvas.toggleSelection(for: hit.id)
            }

            // Now prepare to drag (works for both previously selected and newly selected)
            isDraggingAnnotations = true

            // Save original positions of all selected annotations
            originalPositions.removeAll()
            for annotation in canvas.annotations where canvas.selectedAnnotationIDs.contains(annotation.id) {
                originalPositions[annotation.id] = annotation.transform.position
            }
        } else {
            // Clicking empty space - prepare to pan
            canvas.clearSelection()
            isDraggingAnnotations = false
            initialPanOffset = canvas.panOffset
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

    func updateStyle(
        fill: Color,
        stroke: Color,
        strokeWidth: CGFloat,
        cornerRadius: CGFloat,
        shapeKind: ShapeKind
    ) {
        self.fillColor = fill
        self.strokeColor = stroke
        self.strokeWidth = strokeWidth
        self.cornerRadius = cornerRadius
        self.shapeKind = shapeKind
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
            cornerRadius: shapeKind.supportsCornerRadius ? cornerRadius : 0
        )

        canvas.addAnnotation(shape)
        resetState(on: canvas)
    }

    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
        guard let start = startPoint, let end = currentPoint else { return }

        let canvasStart = canvas.imageToCanvas(start)
        let canvasEnd = canvas.imageToCanvas(end)

        let constrained = isShiftPressed()
        let normalized = normalizedRect(start: canvasStart, end: canvasEnd, constrainSquare: constrained)
        let rect = CGRect(origin: normalized.origin, size: normalized.size)

        let path = makeShapePath(
            kind: shapeKind,
            size: rect.size,
            cornerRadius: shapeKind.supportsCornerRadius ? cornerRadius : 0
        ).applying(CGAffineTransform(translationX: rect.origin.x, y: rect.origin.y))

        context.fill(path, with: .color(fillColor))
        context.stroke(path, with: .color(strokeColor), lineWidth: strokeWidth)
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

    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
        guard let start = startPoint, let current = currentPoint else { return }

        let startCanvas = canvas.imageToCanvas(start)
        let endCanvas = canvas.imageToCanvas(current)

        var path = Path()
        path.move(to: startCanvas)
        path.addLine(to: endCanvas)

        let strokeStyle = StrokeStyle(
            lineWidth: strokeWidth,
            lineCap: lineCap.strokeCap,
            lineJoin: .round,
            dash: lineStyle.dashPattern(for: strokeWidth)
        )

        context.stroke(path, with: .color(strokeColor), style: strokeStyle)

        let angle = atan2(endCanvas.y - startCanvas.y, endCanvas.x - startCanvas.x)
        if arrowEndType != .none {
            drawPreviewArrow(
                at: endCanvas,
                angle: angle,
                style: arrowEndType,
                in: &context
            )
        }
        if arrowStartType != .none {
            drawPreviewArrow(
                at: startCanvas,
                angle: angle + .pi,
                style: arrowStartType,
                in: &context
            )
        }
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

    private func drawPreviewArrow(at point: CGPoint, angle: CGFloat, style: ArrowType, in context: inout GraphicsContext) {
        guard arrowSize > 0 else { return }

        var arrowContext = context
        arrowContext.translateBy(x: point.x, y: point.y)
        arrowContext.rotate(by: Angle(radians: Double(angle)))

        let length = arrowSize
        let halfWidth = arrowSize * 0.4

        switch style {
        case .none:
            return  // Should not be called with .none
        case .open:
            var path = Path()
            path.move(to: CGPoint(x: -length, y: -halfWidth))
            path.addLine(to: .zero)
            path.addLine(to: CGPoint(x: -length, y: halfWidth))
            arrowContext.stroke(path, with: .color(strokeColor), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
        case .filled:
            var path = Path()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: -length, y: -halfWidth))
            path.addLine(to: CGPoint(x: -length, y: halfWidth))
            path.closeSubpath()
            arrowContext.fill(path, with: .color(strokeColor))
        case .diamond:
            var path = Path()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: -length / 2, y: -halfWidth))
            path.addLine(to: CGPoint(x: -length, y: 0))
            path.addLine(to: CGPoint(x: -length / 2, y: halfWidth))
            path.closeSubpath()
            arrowContext.fill(path, with: .color(strokeColor))
        case .circle:
            let diameter = arrowSize
            let rect = CGRect(x: -diameter, y: -diameter / 2, width: diameter, height: diameter)
            arrowContext.fill(Path(ellipseIn: rect), with: .color(strokeColor))
        }
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
