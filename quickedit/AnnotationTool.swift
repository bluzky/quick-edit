//
//  AnnotationTool.swift
//  quickedit
//
//  Protocol-based tool system for creating and manipulating annotations via mouse events.
//  All tools implement this protocol and register with ToolRegistry.
//

import SwiftUI
import Combine

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

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        dragStartPoint = point

        // Hit test to find annotation at point (point is in canvas space)
        if let hit = canvas.annotation(at: point) {
            // If clicking an already selected annotation, prepare to drag
            if canvas.selectedAnnotationIDs.contains(hit.id) {
                isDraggingAnnotations = true
            } else {
                // Select the annotation
                canvas.toggleSelection(for: hit.id)
                isDraggingAnnotations = false
            }
        } else {
            // Clicking empty space - prepare to pan
            canvas.clearSelection()
            isDraggingAnnotations = false
            initialPanOffset = canvas.panOffset
        }
    }

    func onMouseDrag(to point: CGPoint, on canvas: AnnotationCanvas) {
        guard let startPoint = dragStartPoint else { return }

        if isDraggingAnnotations {
            // TODO: Move selected annotations
            // This would require a MoveAnnotationsCommand
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
        // Apply grid snapping if enabled and we were dragging annotations
        if isDraggingAnnotations && canvas.snapToGrid {
            canvas.applyGridSnapping(enabled: true, gridSize: canvas.gridSize)
        }

        // Clean up state
        dragStartPoint = nil
        isDraggingAnnotations = false
        initialPanOffset = nil
    }

    func deactivate() {
        // Clean up state when tool is deactivated
        dragStartPoint = nil
        isDraggingAnnotations = false
        initialPanOffset = nil
    }
}

// MARK: - Rectangle Tool

/// Tool for drawing rectangle annotations
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
        // Update current point for preview
        let imagePoint = canvas.canvasToImage(point)
        currentPoint = imagePoint
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        guard let start = startPoint else { return }
        let imagePoint = canvas.canvasToImage(point)

        // Calculate normalized rectangle (top-left origin, positive width/height)
        let minX = min(start.x, imagePoint.x)
        let minY = min(start.y, imagePoint.y)
        let width = abs(imagePoint.x - start.x)
        let height = abs(imagePoint.y - start.y)

        // Create rectangle annotation
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

        // Add annotation via command pattern for undo support
        canvas.addAnnotation(rect)

        // Clear state
        startPoint = nil
        currentPoint = nil
        canvas.onInteractionEnded.send("drawing_rectangle")
    }

    func renderPreview(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
        guard let start = startPoint, let end = currentPoint else { return }

        // Convert image space coordinates to canvas space for rendering
        let canvasStart = canvas.imageToCanvas(start)
        let canvasEnd = canvas.imageToCanvas(end)

        // Create rectangle with normalized coordinates
        let rect = CGRect(
            x: min(canvasStart.x, canvasEnd.x),
            y: min(canvasStart.y, canvasEnd.y),
            width: abs(canvasEnd.x - canvasStart.x),
            height: abs(canvasEnd.y - canvasStart.y)
        )

        // Draw preview
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

// MARK: - Tool Registry

/// Singleton registry for managing available annotation tools
final class ToolRegistry {
    static let shared = ToolRegistry()

    private var tools: [String: AnnotationTool] = [:]

    private init() {
        // Register built-in tools
        register(SelectTool())
        register(RectangleTool())
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
