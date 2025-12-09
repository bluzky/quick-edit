//
//  AnnotationCanvas.swift
//  quickedit
//
//  Core canvas model and utilities for rendering, hit testing, zoom/pan,
//  grid snapping, and selection management.
//

import SwiftUI
import Combine
import AppKit

enum ShapeKind: String, CaseIterable {
    case rectangle = "Rectangle"
    case rounded = "Rounded"
    case ellipse = "Ellipse"
    case diamond = "Diamond"
    case triangle = "Triangle"

    var supportsCornerRadius: Bool {
        self == .rectangle || self == .rounded
    }
}

func makeShapePath(kind: ShapeKind, size: CGSize, cornerRadius: CGFloat) -> Path {
    let width = max(size.width, 0)
    let height = max(size.height, 0)

    switch kind {
    case .rectangle:
        return Path(CGRect(origin: .zero, size: CGSize(width: width, height: height)))
    case .rounded:
        let radius = min(min(width, height) / 2, cornerRadius)
        return Path(roundedRect: CGRect(origin: .zero, size: CGSize(width: width, height: height)), cornerSize: CGSize(width: radius, height: radius))
    case .ellipse:
        return Path(ellipseIn: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
    case .diamond:
        let path = Path { p in
            p.move(to: CGPoint(x: width / 2, y: 0))
            p.addLine(to: CGPoint(x: width, y: height / 2))
            p.addLine(to: CGPoint(x: width / 2, y: height))
            p.addLine(to: CGPoint(x: 0, y: height / 2))
            p.closeSubpath()
        }
        return path
    case .triangle:
        let path = Path { p in
            p.move(to: CGPoint(x: width / 2, y: 0))
            p.addLine(to: CGPoint(x: width, y: height))
            p.addLine(to: CGPoint(x: 0, y: height))
            p.closeSubpath()
        }
        return path
    }
}

struct AnnotationTransform {
    var position: CGPoint
    var scale: CGSize
    var rotation: Angle

    static let identity = AnnotationTransform(
        position: .zero,
        scale: CGSize(width: 1, height: 1),
        rotation: .zero
    )
}

protocol Annotation: AnyObject, Identifiable {
    var id: UUID { get }
    var zIndex: Int { get set }
    var visible: Bool { get set }
    var locked: Bool { get set }
    var transform: AnnotationTransform { get set }
    var size: CGSize { get set }           // Stored in image space

    func contains(point: CGPoint) -> Bool  // Point is in image space
}

final class ShapeAnnotation: Annotation {
    let id: UUID = UUID()
    var zIndex: Int
    var visible: Bool = true
    var locked: Bool = false
    var transform: AnnotationTransform
    var size: CGSize
    var fill: Color
    var stroke: Color
    var strokeWidth: CGFloat
    var shapeKind: ShapeKind
    var cornerRadius: CGFloat

    init(
        zIndex: Int,
        transform: AnnotationTransform,
        size: CGSize,
        fill: Color,
        stroke: Color,
        strokeWidth: CGFloat,
        shapeKind: ShapeKind,
        cornerRadius: CGFloat
    ) {
        self.zIndex = zIndex
        self.transform = transform
        self.size = size
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.shapeKind = shapeKind
        self.cornerRadius = cornerRadius
    }

    func contains(point: CGPoint) -> Bool {
        // Convert to local space: translate, unscale (including flips), then unrotate
        var local = CGPoint(
            x: point.x - transform.position.x,
            y: point.y - transform.position.y
        )

        // Guard against zero scale to avoid division by zero
        guard transform.scale.width != 0, transform.scale.height != 0 else {
            return false
        }

        local.x /= transform.scale.width
        local.y /= transform.scale.height

        // Unrotate around the shape center
        if transform.rotation != .zero {
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let translated = CGPoint(x: local.x - center.x, y: local.y - center.y)
            let angle = -transform.rotation.radians
            let rotated = CGPoint(
                x: translated.x * cos(angle) - translated.y * sin(angle),
                y: translated.x * sin(angle) + translated.y * cos(angle)
            )
            local = CGPoint(x: rotated.x + center.x, y: rotated.y + center.y)
        }

        // Hit test against filled path plus stroke
        let basePath = makeShapePath(kind: shapeKind, size: size, cornerRadius: cornerRadius)
        var hitPath = basePath
        if strokeWidth > 0 {
            hitPath.addPath(basePath.strokedPath(.init(lineWidth: strokeWidth)))
        }
        return hitPath.contains(local)
    }

    var bounds: CGRect {
        let scaledSize = CGSize(
            width: size.width * abs(transform.scale.width),
            height: size.height * abs(transform.scale.height)
        )
        return CGRect(origin: transform.position, size: scaledSize)
    }
}

enum ResizeHandle: CaseIterable {
    case topLeft, top, topRight
    case left, right
    case bottomLeft, bottom, bottomRight
}

struct ResizeHandleLayout {
    static let handleSize: CGFloat = 8       // On-screen size at 100%
    static let handleHitSize: CGFloat = 12   // On-screen hit target at 100%

    // Keep handles a consistent on-screen size by scaling by inverse zoom
    static func handleRects(for bounds: CGRect, zoomLevel: CGFloat) -> [ResizeHandle: CGRect] {
        let w = bounds.width
        let h = bounds.height
        let hs = handleSize / zoomLevel

        return [
            .topLeft: CGRect(x: -hs / 2, y: -hs / 2, width: hs, height: hs),
            .top: CGRect(x: w / 2 - hs / 2, y: -hs / 2, width: hs, height: hs),
            .topRight: CGRect(x: w - hs / 2, y: -hs / 2, width: hs, height: hs),
            .left: CGRect(x: -hs / 2, y: h / 2 - hs / 2, width: hs, height: hs),
            .right: CGRect(x: w - hs / 2, y: h / 2 - hs / 2, width: hs, height: hs),
            .bottomLeft: CGRect(x: -hs / 2, y: h - hs / 2, width: hs, height: hs),
            .bottom: CGRect(x: w / 2 - hs / 2, y: h - hs / 2, width: hs, height: hs),
            .bottomRight: CGRect(x: w - hs / 2, y: h - hs / 2, width: hs, height: hs)
        ]
    }
}

struct ZoomConfig {
    static let minZoom: CGFloat = 0.1   // 10%
    static let maxZoom: CGFloat = 5.0   // 500%
    static let defaultZoom: CGFloat = 1.0
    static let fitToWindowMargin: CGFloat = 20

    static let presetLevels: [CGFloat] = [
        0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 4.0, 5.0
    ]
}

final class AnnotationCanvas: ObservableObject {
    // MARK: - Image
    @Published var baseImage: NSImage?
    @Published var imageSize: CGSize = .zero

    // MARK: - Annotations
    @Published internal var annotations: [any Annotation] = []  // Internal for command pattern access
    @Published var selectedAnnotationIDs: Set<UUID> = []

    // MARK: - View State
    @Published var zoomLevel: CGFloat = ZoomConfig.defaultZoom  // 0.1 to 5.0
    @Published var panOffset: CGPoint = .zero
    @Published var showGrid: Bool = true
    @Published var gridSize: CGFloat = 16
    @Published var snapToGrid: Bool = false
    @Published var showAlignmentGuides: Bool = true
    @Published var showRulers: Bool = false
    @Published private(set) var activeTool: (any AnnotationTool)? = nil

    // MARK: - Event Publishers
    let onAnnotationAdded = PassthroughSubject<any Annotation, Never>()
    let onAnnotationModified = PassthroughSubject<UUID, Never>()
    let onAnnotationDeleted = PassthroughSubject<Set<UUID>, Never>()
    let onInteractionBegan = PassthroughSubject<String, Never>()
    let onInteractionEnded = PassthroughSubject<String, Never>()

    // MARK: - Canvas Metrics
    @Published var canvasSize: CGSize = .zero

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

    init() {
        seedDemoAnnotations()
    }

    // MARK: - Coordinate Conversion

    func imageToCanvas(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x * zoomLevel) + panOffset.x,
            y: (point.y * zoomLevel) + panOffset.y
        )
    }

    func canvasToImage(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x - panOffset.x) / zoomLevel,
            y: (point.y - panOffset.y) / zoomLevel
        )
    }

    func canvasRect(for annotation: any Annotation) -> CGRect {
        let origin = imageToCanvas(annotation.transform.position)
        // Apply scale transform
        let size = CGSize(
            width: annotation.size.width * abs(annotation.transform.scale.width) * zoomLevel,
            height: annotation.size.height * abs(annotation.transform.scale.height) * zoomLevel
        )
        return CGRect(origin: origin, size: size)
    }

    // MARK: - Tool Management

    func setActiveTool(_ tool: (any AnnotationTool)?) {
        // Defer to avoid "Publishing changes from within view updates" warning
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.activeTool?.deactivate()
            self.activeTool = tool
            tool?.activate()
            self.clearSelection()
        }
    }

    func isToolActive(_ toolID: String) -> Bool {
        activeTool?.id == toolID
    }

    // MARK: - Selection Management

    func selectAnnotations(_ ids: Set<UUID>) {
        selectedAnnotationIDs = ids
    }

    func clearSelection() {
        selectedAnnotationIDs.removeAll()
    }

    func toggleSelection(for id: UUID) {
        if selectedAnnotationIDs.contains(id) {
            selectedAnnotationIDs.remove(id)
        } else {
            selectedAnnotationIDs = [id]
        }
    }

    func getSelectedAnnotations() -> [any Annotation] {
        annotations.filter { selectedAnnotationIDs.contains($0.id) }
    }

    func selectionBoundingBox(for ids: Set<UUID>) -> CGRect? {
        let selected = annotations.compactMap { annotation -> CGRect? in
            guard ids.contains(annotation.id) else { return nil }

            // Account for scale when calculating bounding box
            let scaledSize = CGSize(
                width: annotation.size.width * abs(annotation.transform.scale.width),
                height: annotation.size.height * abs(annotation.transform.scale.height)
            )

            // Note: This still doesn't account for rotation (which requires rotating the corners)
            // For now, we use the axis-aligned bounding box of the scaled shape
            return CGRect(origin: annotation.transform.position, size: scaledSize)
        }

        guard let first = selected.first else { return nil }
        return selected.dropFirst().reduce(first) { partialResult, rect in
            partialResult.union(rect)
        }
    }

    // MARK: - Annotation Lifecycle API

    /// Add an annotation to the canvas (wraps in command for undo/redo)
    func addAnnotation(_ annotation: any Annotation) {
        let command = AddAnnotationCommand(annotation: annotation)
        execute(command)
    }

    /// Delete annotations by ID (wraps in command for undo/redo)
    func deleteAnnotations(_ ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        let command = DeleteAnnotationsCommand(annotationIDs: ids)
        execute(command)
    }

    /// Delete currently selected annotations
    func deleteSelected() {
        guard !selectedAnnotationIDs.isEmpty else { return }
        deleteAnnotations(selectedAnnotationIDs)
    }

    /// Update properties for one or more annotations (wraps in command for undo/redo)
    func updateProperties(for annotationIDs: Set<UUID>, updates: [String: Any]) {
        guard !annotationIDs.isEmpty else { return }

        var commands: [CanvasCommand] = []
        for id in annotationIDs {
            commands.append(UpdatePropertiesCommand(annotationID: id, updates: updates))
        }

        let batch = BatchCommand(actionName: "Update Properties", commands: commands)
        execute(batch)
    }

    // MARK: - Property Update Convenience Methods

    /// Update transform for annotations (convenience method)
    func updateTransform(for ids: Set<UUID>, transform: AnnotationTransform) {
        updateProperties(for: ids, updates: ["transform": transform])
    }

    /// Update visibility for annotations (convenience method)
    func updateVisibility(for ids: Set<UUID>, visible: Bool) {
        updateProperties(for: ids, updates: ["visible": visible])
    }

    /// Update locked state for annotations (convenience method)
    func updateLocked(for ids: Set<UUID>, locked: Bool) {
        updateProperties(for: ids, updates: ["locked": locked])
    }

    // MARK: - Pan API

    /// Pan the canvas by a delta amount
    func pan(by delta: CGPoint) {
        panOffset.x += delta.x
        panOffset.y += delta.y
    }

    /// Set the pan offset directly
    func setPanOffset(_ offset: CGPoint) {
        panOffset = offset
    }

    // MARK: - Arrangement API (Z-Index)

    /// Change z-index of annotations (defaults to selected if not specified)
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

    /// Align annotations (defaults to selected if not specified)
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

    /// Distribute annotations evenly (defaults to selected if not specified, requires 3+ items)
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

    /// Rotate or flip annotations (defaults to selected if not specified)
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

    // MARK: - Move API

    /// Move annotations by a delta offset
    /// - Parameters:
    ///   - ids: Set of annotation IDs to move
    ///   - delta: Movement offset in image space
    func moveAnnotations(_ ids: Set<UUID>, by delta: CGPoint) {
        guard !ids.isEmpty else { return }
        let command = MoveAnnotationsCommand(annotationIDs: ids, delta: delta)
        execute(command)
    }

    // MARK: - History API

    /// Undo the last command
    func undo() {
        commandHistory.undo(on: self)
        updateHistoryState()
    }

    /// Redo the last undone command
    func redo() {
        commandHistory.redo(on: self)
        updateHistoryState()
    }

    /// Clear all undo/redo history
    func clearHistory() {
        commandHistory.clear()
        updateHistoryState()
    }

    // MARK: - Hit Testing

    func annotation(at canvasPoint: CGPoint) -> (any Annotation)? {
        let imagePoint = canvasToImage(canvasPoint)
        for annotation in annotations.sorted(by: { $0.zIndex > $1.zIndex }) where annotation.visible && !annotation.locked {
            if annotation.contains(point: imagePoint) {
                return annotation
            }
        }
        return nil
    }

    // MARK: - Grid Snapping

    func snapToGrid(_ point: CGPoint, gridSize: CGFloat) -> CGPoint {
        CGPoint(
            x: round(point.x / gridSize) * gridSize,
            y: round(point.y / gridSize) * gridSize
        )
    }

    /// Apply grid snapping to selected annotations
    /// This creates a MoveAnnotationsCommand for undo/redo support
    func applyGridSnapping(enabled: Bool, gridSize: CGFloat) {
        guard enabled else { return }
        guard !selectedAnnotationIDs.isEmpty else { return }

        // Snap selection bounding box (works for single + multi-select)
        guard let selectionBounds = selectionBoundingBox(for: selectedAnnotationIDs) else { return }
        let snappedOrigin = snapToGrid(selectionBounds.origin, gridSize: gridSize)
        let delta = CGPoint(
            x: snappedOrigin.x - selectionBounds.origin.x,
            y: snappedOrigin.y - selectionBounds.origin.y
        )

        // Only snap if there's a meaningful delta
        guard abs(delta.x) > 0.1 || abs(delta.y) > 0.1 else { return }

        // Use moveAnnotations to apply snap (goes through command pattern for undo/redo)
        moveAnnotations(selectedAnnotationIDs, by: delta)
    }

    // MARK: - Zoom / Pan

    func setZoom(_ level: CGFloat, centerOn point: CGPoint?) {
        let clamped = level.clamped(to: ZoomConfig.minZoom...ZoomConfig.maxZoom)

        if let point = point {
            // Keep the given point stable while zooming
            let imagePoint = canvasToImage(point)
            zoomLevel = clamped
            let newCanvasPoint = imageToCanvas(imagePoint)
            panOffset.x += point.x - newCanvasPoint.x
            panOffset.y += point.y - newCanvasPoint.y
        } else {
            zoomLevel = clamped
        }
    }

    func zoomToFit() {
        guard imageSize != .zero && canvasSize != .zero else { return }

        let availableSize = CGSize(
            width: canvasSize.width - ZoomConfig.fitToWindowMargin * 2,
            height: canvasSize.height - ZoomConfig.fitToWindowMargin * 2
        )

        let scaleX = availableSize.width / imageSize.width
        let scaleY = availableSize.height / imageSize.height

        zoomLevel = min(scaleX, scaleY).clamped(to: ZoomConfig.minZoom...ZoomConfig.maxZoom)
        centerImage()
    }

    func centerImage() {
        guard imageSize != .zero else { return }

        let scaledSize = CGSize(
            width: imageSize.width * zoomLevel,
            height: imageSize.height * zoomLevel
        )

        panOffset = CGPoint(
            x: (canvasSize.width - scaledSize.width) / 2,
            y: (canvasSize.height - scaledSize.height) / 2
        )
    }

    // MARK: - Canvas Size

    func updateCanvasSize(_ size: CGSize) {
        guard canvasSize != size else { return }
        canvasSize = size
        if imageSize != .zero {
            zoomToFit()
        }
    }

    // MARK: - Demo Data

    private func seedDemoAnnotations() {
        let first = ShapeAnnotation(
            zIndex: 1,
            transform: AnnotationTransform(position: CGPoint(x: 120, y: 90), scale: CGSize(width: 1, height: 1), rotation: .zero),
            size: CGSize(width: 240, height: 160),
            fill: Color.blue.opacity(0.18),
            stroke: Color.blue.opacity(0.6),
            strokeWidth: 1.5,
            shapeKind: .rectangle,
            cornerRadius: 0
        )

        let second = ShapeAnnotation(
            zIndex: 2,
            transform: AnnotationTransform(position: CGPoint(x: 260, y: 220), scale: CGSize(width: 1, height: 1), rotation: .zero),
            size: CGSize(width: 180, height: 120),
            fill: Color.green.opacity(0.18),
            stroke: Color.green.opacity(0.6),
            strokeWidth: 1.5,
            shapeKind: .ellipse,
            cornerRadius: 0
        )

        let third = ShapeAnnotation(
            zIndex: 3,
            transform: AnnotationTransform(position: CGPoint(x: 420, y: 140), scale: CGSize(width: 1, height: 1), rotation: .zero),
            size: CGSize(width: 140, height: 120),
            fill: Color.orange.opacity(0.18),
            stroke: Color.orange.opacity(0.6),
            strokeWidth: 1.5,
            shapeKind: .diamond,
            cornerRadius: 0
        )

        // Direct initialization - don't create undo commands for demo data
        annotations = [first, second, third]
        imageSize = CGSize(width: 800, height: 600)
    }
}
