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
    private var originalPositions: [UUID: CGPoint] = [:]  // Track original positions for live preview

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        dragStartPoint = point

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

        // Clean up state
        dragStartPoint = nil
        isDraggingAnnotations = false
        initialPanOffset = nil
        originalPositions.removeAll()
    }

    func deactivate() {
        // Clean up state when tool is deactivated
        dragStartPoint = nil
        isDraggingAnnotations = false
        initialPanOffset = nil
        originalPositions.removeAll()
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
