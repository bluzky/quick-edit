//
//  CanvasCommand.swift
//  quickedit
//
//  Command pattern implementation for undo/redo functionality.
//  All canvas mutations should be wrapped in commands.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Command Protocol

/// Protocol for all canvas commands that support undo/redo
protocol CanvasCommand: AnyObject {
    /// Human-readable action name for UI (e.g., "Add Rectangle", "Delete 3 Annotations")
    var actionName: String { get }

    /// Execute the command on the canvas
    func execute(on canvas: AnnotationCanvas)

    /// Undo the command on the canvas
    func undo(on canvas: AnnotationCanvas)
}

// MARK: - Command History Manager

/// Manages undo/redo stacks and command execution
final class CommandHistory {
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []
    private let maxHistorySize: Int = 100

    // MARK: - State

    /// Whether undo is available
    var canUndo: Bool {
        !undoStack.isEmpty
    }

    /// Whether redo is available
    var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// Name of the action that will be undone (for UI)
    var undoActionName: String? {
        undoStack.last?.actionName
    }

    /// Name of the action that will be redone (for UI)
    var redoActionName: String? {
        redoStack.last?.actionName
    }

    // MARK: - Command Execution

    /// Execute a command and add it to the undo stack
    func execute(_ command: CanvasCommand, on canvas: AnnotationCanvas) {
        command.execute(on: canvas)
        undoStack.append(command)
        redoStack.removeAll()

        // Limit history size to prevent unbounded memory growth
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
    }

    /// Undo the last command
    func undo(on canvas: AnnotationCanvas) {
        guard let command = undoStack.popLast() else { return }
        command.undo(on: canvas)
        redoStack.append(command)
    }

    /// Redo the last undone command
    func redo(on canvas: AnnotationCanvas) {
        guard let command = redoStack.popLast() else { return }
        command.execute(on: canvas)
        undoStack.append(command)
    }

    /// Clear all undo/redo history
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}

// MARK: - Add Annotation Command

/// Command to add an annotation to the canvas
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

// MARK: - Delete Annotations Command

/// Command to delete one or more annotations from the canvas
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
        // Save annotations before deleting (for undo)
        savedAnnotations = canvas.annotations.filter { annotationIDs.contains($0.id) }

        // Remove from canvas
        canvas.annotations.removeAll { annotationIDs.contains($0.id) }
        canvas.onAnnotationDeleted.send(annotationIDs)

        // Clear selection of deleted items
        canvas.selectedAnnotationIDs.subtract(annotationIDs)
    }

    func undo(on canvas: AnnotationCanvas) {
        // Restore annotations
        canvas.annotations.append(contentsOf: savedAnnotations)

        // Re-sort by z-index to maintain proper layer order
        canvas.annotations.sort { $0.zIndex < $1.zIndex }

        // Emit add events for restored annotations
        for annotation in savedAnnotations {
            canvas.onAnnotationAdded.send(annotation)
        }
    }
}

// MARK: - Update Properties Command

/// Command to update properties of an annotation
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

        // Capture old properties before modification
        oldProperties = captureProperties(from: annotation)

        // Apply new properties
        applyProperties(newProperties, to: &canvas.annotations[index])
        canvas.onAnnotationModified.send(annotationID)
    }

    func undo(on canvas: AnnotationCanvas) {
        guard let index = canvas.annotations.firstIndex(where: { $0.id == annotationID }) else { return }

        // Restore old properties
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
        if let shape = annotation as? ShapeAnnotation {
            props["fill"] = shape.fill
            props["stroke"] = shape.stroke
            props["strokeWidth"] = shape.strokeWidth
            props["shapeKind"] = shape.shapeKind
            props["cornerRadius"] = shape.cornerRadius
        }
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
        if let shape = annotation as? ShapeAnnotation {
            if let fill = properties["fill"] as? Color {
                shape.fill = fill
            }
            if let stroke = properties["stroke"] as? Color {
                shape.stroke = stroke
            }
            if let strokeWidth = properties["strokeWidth"] as? CGFloat {
                shape.strokeWidth = strokeWidth
            }
            if let shapeKind = properties["shapeKind"] as? ShapeKind {
                shape.shapeKind = shapeKind
            }
            if let cornerRadius = properties["cornerRadius"] as? CGFloat {
                shape.cornerRadius = cornerRadius
            }
        }
    }
}

// MARK: - Batch Command

/// Command that executes multiple commands as a single undoable operation
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
        // Undo in reverse order
        for command in commands.reversed() {
            command.undo(on: canvas)
        }
    }
}

// MARK: - Arrange Command (Z-Index)

/// Command to change z-index (layer order) of annotations
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
        // Save old z-indices
        for annotation in canvas.annotations where annotationIDs.contains(annotation.id) {
            oldZIndices[annotation.id] = annotation.zIndex
        }

        let maxZ = canvas.annotations.map(\.zIndex).max() ?? 0
        let minZ = canvas.annotations.map(\.zIndex).min() ?? 0

        // Apply z-index changes
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
        // Restore old z-indices
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            if let oldZ = oldZIndices[canvas.annotations[i].id] {
                canvas.annotations[i].zIndex = oldZ
                canvas.onAnnotationModified.send(canvas.annotations[i].id)
            }
        }
    }
}

// MARK: - Alignment Command

/// Command to align annotations relative to each other
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
        // Restore old positions
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            if let oldPos = oldPositions[canvas.annotations[i].id] {
                canvas.annotations[i].transform.position = oldPos
                canvas.onAnnotationModified.send(canvas.annotations[i].id)
            }
        }
    }
}

// MARK: - Distribute Command

/// Command to evenly distribute annotations (requires 3+ items)
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
        // Restore old positions
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            if let oldPos = oldPositions[canvas.annotations[i].id] {
                canvas.annotations[i].transform.position = oldPos
                canvas.onAnnotationModified.send(canvas.annotations[i].id)
            }
        }
    }
}

// MARK: - Rotate Command

/// Command to rotate or flip annotations
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
        // Restore old transforms
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            if let oldTransform = oldTransforms[canvas.annotations[i].id] {
                canvas.annotations[i].transform = oldTransform
                canvas.onAnnotationModified.send(canvas.annotations[i].id)
            }
        }
    }
}

// MARK: - Move Command

/// Command to move annotations by a delta offset
final class MoveAnnotationsCommand: CanvasCommand {
    let annotationIDs: Set<UUID>
    let delta: CGPoint
    private var originalPositions: [UUID: CGPoint] = [:]

    var actionName: String {
        annotationIDs.count == 1 ? "Move Annotation" : "Move \(annotationIDs.count) Annotations"
    }

    init(annotationIDs: Set<UUID>, delta: CGPoint) {
        self.annotationIDs = annotationIDs
        self.delta = delta
    }

    func execute(on canvas: AnnotationCanvas) {
        // Save original positions before moving
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            originalPositions[canvas.annotations[i].id] = canvas.annotations[i].transform.position

            // Apply delta to position
            canvas.annotations[i].transform.position.x += delta.x
            canvas.annotations[i].transform.position.y += delta.y

            canvas.onAnnotationModified.send(canvas.annotations[i].id)
        }
    }

    func undo(on canvas: AnnotationCanvas) {
        // Restore original positions
        for i in canvas.annotations.indices where annotationIDs.contains(canvas.annotations[i].id) {
            if let originalPos = originalPositions[canvas.annotations[i].id] {
                canvas.annotations[i].transform.position = originalPos
                canvas.onAnnotationModified.send(canvas.annotations[i].id)
            }
        }
    }
}

// MARK: - Move Control Point Command

/// Command to move a single control point (endpoint or resize handle)
final class MoveControlPointCommand: CanvasCommand {
    let annotationID: UUID
    let controlPointID: ControlPointRole
    let newPosition: CGPoint   // Image-space position
    private var snapshot: AnnotationSnapshot?

    var actionName: String { "Adjust Handle" }

    init(annotationID: UUID, controlPointID: ControlPointRole, newPosition: CGPoint) {
        self.annotationID = annotationID
        self.controlPointID = controlPointID
        self.newPosition = newPosition
    }

    func execute(on canvas: AnnotationCanvas) {
        guard let index = canvas.annotationIndex(for: annotationID) else { return }
        if snapshot == nil {
            snapshot = AnnotationSnapshot.capture(canvas.annotations[index])
        }
        canvas.annotations[index].moveControlPoint(controlPointID, to: newPosition)
        canvas.onAnnotationModified.send(annotationID)
    }

    func undo(on canvas: AnnotationCanvas) {
        guard let snapshot, let index = canvas.annotationIndex(for: annotationID) else { return }
        snapshot.apply(to: &canvas.annotations[index])
        canvas.onAnnotationModified.send(annotationID)
    }
}

// MARK: - Update Shape Text Command

/// Command to update the text content of a shape annotation
final class UpdateShapeTextCommand: CanvasCommand {
    let annotationID: UUID
    let newText: String
    private var oldText: String?

    var actionName: String { "Edit Text" }

    init(annotationID: UUID, newText: String) {
        self.annotationID = annotationID
        self.newText = newText
    }

    func execute(on canvas: AnnotationCanvas) {
        guard let index = canvas.annotationIndex(for: annotationID),
              let shapeAnnotation = canvas.annotations[index] as? ShapeAnnotation else {
            return
        }

        // Save old text for undo
        if oldText == nil {
            oldText = shapeAnnotation.text
        }

        // Update the text
        shapeAnnotation.text = newText
        canvas.onAnnotationModified.send(annotationID)
    }

    func undo(on canvas: AnnotationCanvas) {
        guard let oldText,
              let index = canvas.annotationIndex(for: annotationID),
              let shapeAnnotation = canvas.annotations[index] as? ShapeAnnotation else {
            return
        }

        shapeAnnotation.text = oldText
        canvas.onAnnotationModified.send(annotationID)
    }
}
