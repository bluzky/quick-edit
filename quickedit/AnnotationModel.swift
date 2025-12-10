//
//  AnnotationModel.swift
//  quickedit
//
//  Annotation protocol, concrete annotations, control points, and geometry helpers.
//

import SwiftUI
import AppKit

// MARK: - Shapes

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

// MARK: - Transforms

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

// MARK: - Control Points

enum ControlPointRole: Hashable {
    case corner(ResizeHandle)
    case edge(ResizeHandle)
    case lineStart
    case lineEnd
    case center
}

struct AnnotationControlPoint: Hashable {
    let id: ControlPointRole
    var position: CGPoint   // Image-space position
}

// MARK: - Annotation Protocol

protocol Annotation: AnyObject, Identifiable {
    var id: UUID { get }
    var zIndex: Int { get set }
    var visible: Bool { get set }
    var locked: Bool { get set }
    var transform: AnnotationTransform { get set }
    var size: CGSize { get set }           // Stored in image space
    var bounds: CGRect { get }

    func contains(point: CGPoint) -> Bool  // Point is in image space
    func controlPoints() -> [AnnotationControlPoint]
    func moveControlPoint(_ id: ControlPointRole, to position: CGPoint)

    /// Draw custom selection handles for this annotation type.
    /// Each annotation type can render its own selection UI.
    func drawSelectionHandles(in context: inout GraphicsContext, canvas: AnnotationCanvas)
}

extension Annotation {
    func move(by delta: CGPoint) {
        transform.position.x += delta.x
        transform.position.y += delta.y
    }
}

// MARK: - Shape Annotation

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

    func controlPoints() -> [AnnotationControlPoint] {
        let rect = bounds
        let midX = rect.midX
        let midY = rect.midY
        return [
            AnnotationControlPoint(id: .corner(.topLeft), position: CGPoint(x: rect.minX, y: rect.minY)),
            AnnotationControlPoint(id: .edge(.top), position: CGPoint(x: midX, y: rect.minY)),
            AnnotationControlPoint(id: .corner(.topRight), position: CGPoint(x: rect.maxX, y: rect.minY)),
            AnnotationControlPoint(id: .edge(.left), position: CGPoint(x: rect.minX, y: midY)),
            AnnotationControlPoint(id: .edge(.right), position: CGPoint(x: rect.maxX, y: midY)),
            AnnotationControlPoint(id: .corner(.bottomLeft), position: CGPoint(x: rect.minX, y: rect.maxY)),
            AnnotationControlPoint(id: .edge(.bottom), position: CGPoint(x: midX, y: rect.maxY)),
            AnnotationControlPoint(id: .corner(.bottomRight), position: CGPoint(x: rect.maxX, y: rect.maxY))
        ]
    }

    func moveControlPoint(_ id: ControlPointRole, to position: CGPoint) {
        var minX = bounds.minX
        var maxX = bounds.maxX
        var minY = bounds.minY
        var maxY = bounds.maxY

        switch id {
        case .corner(.topLeft):
            minX = position.x
            minY = position.y
        case .corner(.topRight):
            maxX = position.x
            minY = position.y
        case .corner(.bottomLeft):
            minX = position.x
            maxY = position.y
        case .corner(.bottomRight):
            maxX = position.x
            maxY = position.y
        case .edge(.top):
            minY = position.y
        case .edge(.bottom):
            maxY = position.y
        case .edge(.left):
            minX = position.x
        case .edge(.right):
            maxX = position.x
        default:
            break
        }

        if minX > maxX { swap(&minX, &maxX) }
        if minY > maxY { swap(&minY, &maxY) }

        let width = max(maxX - minX, 0.1)
        let height = max(maxY - minY, 0.1)

        let scaleX = abs(transform.scale.width == 0 ? 1 : transform.scale.width)
        let scaleY = abs(transform.scale.height == 0 ? 1 : transform.scale.height)

        transform.position = CGPoint(x: minX, y: minY)
        size = CGSize(width: width / scaleX, height: height / scaleY)
    }

    func drawSelectionHandles(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
        // Convert to canvas space
        let origin = canvas.imageToCanvas(bounds.origin)
        let size = CGSize(width: bounds.width * canvas.zoomLevel, height: bounds.height * canvas.zoomLevel)
        let rect = CGRect(origin: origin, size: size)

        // Draw selection outline
        let outline = Path(rect)
        context.stroke(outline, with: .color(Color.accentColor), lineWidth: 1)

        // Draw 8 resize handles at constant on-screen size
        let handleRects = ResizeHandleLayout.handleRects(for: CGRect(origin: .zero, size: rect.size), zoomLevel: canvas.zoomLevel)
        for (_, handle) in handleRects {
            var handleRect = handle
            handleRect.origin.x += rect.origin.x
            handleRect.origin.y += rect.origin.y
            context.fill(Path(handleRect), with: .color(.white))
            context.stroke(Path(handleRect), with: .color(.accentColor), lineWidth: 1)
        }
    }
}

// MARK: - Line Annotation

final class LineAnnotation: Annotation {
    let id: UUID = UUID()
    var zIndex: Int
    var visible: Bool = true
    var locked: Bool = false
    var transform: AnnotationTransform
    var size: CGSize

    // Line-specific properties
    var startPoint: CGPoint    // Relative to transform.position
    var endPoint: CGPoint      // Relative to transform.position
    var stroke: Color
    var strokeWidth: CGFloat
    var arrowStartType: ArrowType
    var arrowEndType: ArrowType
    var arrowSize: CGFloat
    var lineStyle: LineStyle
    var lineCap: LineCap

    init(
        zIndex: Int,
        transform: AnnotationTransform,
        size: CGSize,
        startPoint: CGPoint,
        endPoint: CGPoint,
        stroke: Color,
        strokeWidth: CGFloat,
        arrowStartType: ArrowType,
        arrowEndType: ArrowType,
        arrowSize: CGFloat,
        lineStyle: LineStyle,
        lineCap: LineCap
    ) {
        self.zIndex = zIndex
        self.transform = transform
        self.size = size
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.arrowStartType = arrowStartType
        self.arrowEndType = arrowEndType
        self.arrowSize = arrowSize
        self.lineStyle = lineStyle
        self.lineCap = lineCap
    }

    func contains(point: CGPoint) -> Bool {
        // Convert to local space: translate, unscale (including flips), then unrotate
        var local = CGPoint(
            x: point.x - transform.position.x,
            y: point.y - transform.position.y
        )

        guard transform.scale.width != 0, transform.scale.height != 0 else {
            return false
        }

        local.x /= transform.scale.width
        local.y /= transform.scale.height

        // Unrotate around the line's bounding box center
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

        // Distance from point to segment; include generous tolerance for easier hit testing
        let distance = distanceFromPoint(local, toLineSegmentFrom: startPoint, to: endPoint)
        let tolerance = max(strokeWidth / 2, 4)
        return distance <= tolerance
    }

    var bounds: CGRect {
        let scaledSize = CGSize(
            width: size.width * abs(transform.scale.width),
            height: size.height * abs(transform.scale.height)
        )
        return CGRect(origin: transform.position, size: scaledSize)
    }

    func controlPoints() -> [AnnotationControlPoint] {
        let scaleX = abs(transform.scale.width == 0 ? 1 : transform.scale.width)
        let scaleY = abs(transform.scale.height == 0 ? 1 : transform.scale.height)
        let start = CGPoint(
            x: transform.position.x + startPoint.x * scaleX,
            y: transform.position.y + startPoint.y * scaleY
        )
        let end = CGPoint(
            x: transform.position.x + endPoint.x * scaleX,
            y: transform.position.y + endPoint.y * scaleY
        )
        return [
            AnnotationControlPoint(id: .lineStart, position: start),
            AnnotationControlPoint(id: .lineEnd, position: end)
        ]
    }

    func moveControlPoint(_ id: ControlPointRole, to position: CGPoint) {
        let scaleX = abs(transform.scale.width == 0 ? 1 : transform.scale.width)
        let scaleY = abs(transform.scale.height == 0 ? 1 : transform.scale.height)

        var start = CGPoint(
            x: transform.position.x + startPoint.x * scaleX,
            y: transform.position.y + startPoint.y * scaleY
        )
        var end = CGPoint(
            x: transform.position.x + endPoint.x * scaleX,
            y: transform.position.y + endPoint.y * scaleY
        )

        switch id {
        case .lineStart:
            start = position
        case .lineEnd:
            end = position
        default:
            break
        }

        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let width = max(abs(end.x - start.x), 0.1)
        let height = max(abs(end.y - start.y), 0.1)

        transform.position = CGPoint(x: minX, y: minY)
        size = CGSize(width: width / scaleX, height: height / scaleY)

        startPoint = CGPoint(x: start.x - minX, y: start.y - minY)
        endPoint = CGPoint(x: end.x - minX, y: end.y - minY)
    }

    func drawSelectionHandles(in context: inout GraphicsContext, canvas: AnnotationCanvas) {
        // Get the line's control points in image space
        let scaleX = abs(transform.scale.width == 0 ? 1 : transform.scale.width)
        let scaleY = abs(transform.scale.height == 0 ? 1 : transform.scale.height)

        let startAbsolute = CGPoint(
            x: transform.position.x + startPoint.x * scaleX,
            y: transform.position.y + startPoint.y * scaleY
        )
        let endAbsolute = CGPoint(
            x: transform.position.x + endPoint.x * scaleX,
            y: transform.position.y + endPoint.y * scaleY
        )

        // Convert to canvas space
        let startCanvas = canvas.imageToCanvas(startAbsolute)
        let endCanvas = canvas.imageToCanvas(endAbsolute)

        // Draw selection line
        var linePath = Path()
        linePath.move(to: startCanvas)
        linePath.addLine(to: endCanvas)
        context.stroke(linePath, with: .color(Color.accentColor), lineWidth: 1)

        // Draw circular endpoint handles at constant on-screen size
        let handleRadius: CGFloat = 4.0  // 8pt diameter

        // Start point handle
        let startRect = CGRect(
            x: startCanvas.x - handleRadius,
            y: startCanvas.y - handleRadius,
            width: handleRadius * 2,
            height: handleRadius * 2
        )
        context.fill(Path(ellipseIn: startRect), with: .color(.white))
        context.stroke(Path(ellipseIn: startRect), with: .color(.accentColor), lineWidth: 2)

        // End point handle
        let endRect = CGRect(
            x: endCanvas.x - handleRadius,
            y: endCanvas.y - handleRadius,
            width: handleRadius * 2,
            height: handleRadius * 2
        )
        context.fill(Path(ellipseIn: endRect), with: .color(.white))
        context.stroke(Path(ellipseIn: endRect), with: .color(.accentColor), lineWidth: 2)
    }
}

// MARK: - Resize Handles

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

    static func hitRects(for bounds: CGRect, zoomLevel: CGFloat) -> [ResizeHandle: CGRect] {
        let w = bounds.width
        let h = bounds.height
        let hs = handleHitSize / zoomLevel

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

// MARK: - Geometry Helpers

func distanceFromPoint(_ point: CGPoint, toLineSegmentFrom a: CGPoint, to b: CGPoint) -> CGFloat {
    // Handle zero-length line gracefully
    guard a != b else { return hypot(point.x - a.x, point.y - a.y) }

    let dx = b.x - a.x
    let dy = b.y - a.y
    let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / (dx * dx + dy * dy)))
    let projection = CGPoint(x: a.x + t * dx, y: a.y + t * dy)
    return hypot(point.x - projection.x, point.y - projection.y)
}

// MARK: - Snapshotting

struct AnnotationSnapshot {
    struct Base {
        var transform: AnnotationTransform
        var size: CGSize
        var visible: Bool
        var locked: Bool
        var zIndex: Int
    }

    struct ShapeState {
        var fill: Color
        var stroke: Color
        var strokeWidth: CGFloat
        var shapeKind: ShapeKind
        var cornerRadius: CGFloat
    }

    struct LineState {
        var startPoint: CGPoint
        var endPoint: CGPoint
        var stroke: Color
        var strokeWidth: CGFloat
        var arrowStartType: ArrowType
        var arrowEndType: ArrowType
        var arrowSize: CGFloat
        var lineStyle: LineStyle
        var lineCap: LineCap
    }

    var base: Base
    var shape: ShapeState?
    var line: LineState?

    static func capture(_ annotation: any Annotation) -> AnnotationSnapshot {
        var shapeState: ShapeState?
        var lineState: LineState?

        if let shape = annotation as? ShapeAnnotation {
            shapeState = ShapeState(
                fill: shape.fill,
                stroke: shape.stroke,
                strokeWidth: shape.strokeWidth,
                shapeKind: shape.shapeKind,
                cornerRadius: shape.cornerRadius
            )
        }

        if let line = annotation as? LineAnnotation {
            lineState = LineState(
                startPoint: line.startPoint,
                endPoint: line.endPoint,
                stroke: line.stroke,
                strokeWidth: line.strokeWidth,
                arrowStartType: line.arrowStartType,
                arrowEndType: line.arrowEndType,
                arrowSize: line.arrowSize,
                lineStyle: line.lineStyle,
                lineCap: line.lineCap
            )
        }

        return AnnotationSnapshot(
            base: Base(
                transform: annotation.transform,
                size: annotation.size,
                visible: annotation.visible,
                locked: annotation.locked,
                zIndex: annotation.zIndex
            ),
            shape: shapeState,
            line: lineState
        )
    }

    func apply(to annotation: inout any Annotation) {
        annotation.transform = base.transform
        annotation.size = base.size
        annotation.visible = base.visible
        annotation.locked = base.locked
        annotation.zIndex = base.zIndex

        if let shapeState = shape, let shapeAnnotation = annotation as? ShapeAnnotation {
            shapeAnnotation.fill = shapeState.fill
            shapeAnnotation.stroke = shapeState.stroke
            shapeAnnotation.strokeWidth = shapeState.strokeWidth
            shapeAnnotation.shapeKind = shapeState.shapeKind
            shapeAnnotation.cornerRadius = shapeState.cornerRadius
        }

        if let lineState = line, let lineAnnotation = annotation as? LineAnnotation {
            lineAnnotation.startPoint = lineState.startPoint
            lineAnnotation.endPoint = lineState.endPoint
            lineAnnotation.stroke = lineState.stroke
            lineAnnotation.strokeWidth = lineState.strokeWidth
            lineAnnotation.arrowStartType = lineState.arrowStartType
            lineAnnotation.arrowEndType = lineState.arrowEndType
            lineAnnotation.arrowSize = lineState.arrowSize
            lineAnnotation.lineStyle = lineState.lineStyle
            lineAnnotation.lineCap = lineState.lineCap
        }
    }
}
