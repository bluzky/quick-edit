//
//  AnnotationCanvasView.swift
//  quickedit
//
//  SwiftUI view that renders the annotation canvas with zoom/pan, hit testing,
//  selection handles, and grid overlay.
//

import SwiftUI
import AppKit

struct AnnotationCanvasView: View {
    @ObservedObject var canvas: AnnotationCanvas

    @State private var initialPanOffset: CGPoint = .zero
    @State private var isDragging = false
    @State private var initialZoom: CGFloat = ZoomConfig.defaultZoom
    @State private var magnifyAnchor: CGPoint?
    @State private var redrawTrigger: Int = 0

    var body: some View {
        GeometryReader { geometry in
            ScrollWheelPanContainer(onScroll: { delta in
                // Trackpad two-finger scroll pans the canvas (natural direction)
                let adjusted = CGPoint(x: delta.x, y: delta.y)
                canvas.pan(by: adjusted)
            }) {
                Canvas { context, size in
                    // Depend on redrawTrigger to force redraw during tool preview
                    let _ = redrawTrigger


                    // Draw background (#f5f5f5 - light gray)
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(Color(red: 0xf5 / 255.0, green: 0xf5 / 255.0, blue: 0xf5 / 255.0))
                    )

                    if canvas.showGrid {
                        drawGrid(in: &context, size: size)
                    }

                    drawAnnotations(in: &context)
                    drawSelectionHandles(in: &context)

                    // Tool preview overlay
                    if let tool = canvas.activeTool {
                        tool.renderPreview(in: &context, canvas: canvas)
                    }
                }
                .gesture(dragGesture)
                .simultaneousGesture(magnificationGesture)
                .onChange(of: geometry.size) { _, newValue in
                    canvas.updateCanvasSize(newValue)
                }
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    initialPanOffset = canvas.panOffset

                    // Forward mouse down to active tool
                    if let tool = canvas.activeTool {
                        tool.onMouseDown(at: value.startLocation, on: canvas)
                    }
                }

                // Forward drag events to tool or pan canvas
                if canvas.activeTool != nil {
                    canvas.activeTool?.onMouseDrag(to: value.location, on: canvas)
                    redrawTrigger += 1  // Force canvas redraw for tool preview
                } else {
                    // No active tool - pan the canvas
                    canvas.setPanOffset(CGPoint(
                        x: initialPanOffset.x + value.translation.width,
                        y: initialPanOffset.y + value.translation.height
                    ))
                }
            }
            .onEnded { value in
                defer {
                    isDragging = false
                    redrawTrigger = 0  // Reset trigger
                }

                // Forward mouse up to active tool
                if let tool = canvas.activeTool {
                    tool.onMouseUp(at: value.location, on: canvas)
                } else {
                    // No active tool - check for tap selection
                    let distance = hypot(value.translation.width, value.translation.height)
                    if distance < 2 {
                        handleTap(at: value.startLocation)
                    }
                }
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if magnifyAnchor == nil {
                    magnifyAnchor = canvas.canvasSize.center
                    initialZoom = canvas.zoomLevel
                }
                let level = initialZoom * value
                canvas.setZoom(level, centerOn: magnifyAnchor)
            }
            .onEnded { _ in
                magnifyAnchor = nil
            }
    }

    private func handleTap(at location: CGPoint) {
        if let tool = canvas.activeTool {
            // Forward tap to tool as mouse down + up
            tool.onMouseDown(at: location, on: canvas)
            tool.onMouseUp(at: location, on: canvas)
        } else {
            // Default behavior - selection
            let canvasPoint = location
            if let hit = canvas.annotation(at: canvasPoint) {
                canvas.toggleSelection(for: hit.id)
                if canvas.snapToGrid {
                    canvas.applyGridSnapping(enabled: true, gridSize: canvas.gridSize)
                }
            } else {
                canvas.clearSelection()
            }
        }
    }

private func drawAnnotations(in context: inout GraphicsContext) {
        let sorted = canvas.annotations.sorted { $0.zIndex < $1.zIndex }
        for annotation in sorted where annotation.visible {
            if let lineAnnotation = annotation as? LineAnnotation {
                drawLine(lineAnnotation, in: &context)
            } else if let shapeAnnotation = annotation as? ShapeAnnotation {
                drawShape(shapeAnnotation, in: &context)
            }
        }
    }

    private func drawLine(_ annotation: LineAnnotation, in context: inout GraphicsContext) {
        // Avoid rendering zero-length lines
        guard annotation.size.width > 0 || annotation.size.height > 0 else { return }

        let basePosition = canvas.imageToCanvas(annotation.transform.position)
        let signedWidth = annotation.size.width * annotation.transform.scale.width * canvas.zoomLevel
        let signedHeight = annotation.size.height * annotation.transform.scale.height * canvas.zoomLevel

        let centerX = basePosition.x + (signedWidth / 2)
        let centerY = basePosition.y + (signedHeight / 2)

        let scaleXSign: CGFloat = annotation.transform.scale.width >= 0 ? 1 : -1
        let scaleYSign: CGFloat = annotation.transform.scale.height >= 0 ? 1 : -1

        let scaledSize = CGSize(width: abs(signedWidth), height: abs(signedHeight))

        var contextCopy = context
        contextCopy.translateBy(x: centerX, y: centerY)
        contextCopy.rotate(by: annotation.transform.rotation)
        contextCopy.scaleBy(x: scaleXSign, y: scaleYSign)
        contextCopy.translateBy(x: -scaledSize.width / 2, y: -scaledSize.height / 2)

        // Scale local coordinates into the drawing space
        let widthScale = annotation.size.width == 0 ? 1 : scaledSize.width / annotation.size.width
        let heightScale = annotation.size.height == 0 ? 1 : scaledSize.height / annotation.size.height

        let start = CGPoint(
            x: annotation.startPoint.x * widthScale,
            y: annotation.startPoint.y * heightScale
        )
        let end = CGPoint(
            x: annotation.endPoint.x * widthScale,
            y: annotation.endPoint.y * heightScale
        )

        var path = Path()
        path.move(to: start)
        path.addLine(to: end)

        let strokeStyle = StrokeStyle(
            lineWidth: annotation.strokeWidth,
            lineCap: annotation.lineCap.strokeCap,
            lineJoin: .round,
            dash: annotation.lineStyle.dashPattern(for: annotation.strokeWidth)
        )
        contextCopy.stroke(path, with: .color(annotation.stroke), style: strokeStyle)

        let angle = atan2(end.y - start.y, end.x - start.x)
        if annotation.arrowEndType != .none {
            drawArrow(
                at: end,
                angle: angle,
                size: annotation.arrowSize,
                color: annotation.stroke,
                style: annotation.arrowEndType,
                lineWidth: annotation.strokeWidth,
                in: &contextCopy
            )
        }
        if annotation.arrowStartType != .none {
            drawArrow(
                at: start,
                angle: angle + .pi,
                size: annotation.arrowSize,
                color: annotation.stroke,
                style: annotation.arrowStartType,
                lineWidth: annotation.strokeWidth,
                in: &contextCopy
            )
        }
    }

    private func drawShape(_ annotation: ShapeAnnotation, in context: inout GraphicsContext) {
        let transform = annotation.transform
        let basePosition = canvas.imageToCanvas(transform.position)
        let scaledSize = CGSize(
            width: annotation.size.width * transform.scale.width * canvas.zoomLevel,
            height: annotation.size.height * transform.scale.height * canvas.zoomLevel
        )

        let centerX = basePosition.x + (scaledSize.width / 2)
        let centerY = basePosition.y + (scaledSize.height / 2)

        var contextCopy = context
        contextCopy.translateBy(x: centerX, y: centerY)
        contextCopy.rotate(by: transform.rotation)
        contextCopy.translateBy(x: -scaledSize.width / 2, y: -scaledSize.height / 2)

        let path = makeShapePath(
            kind: annotation.shapeKind,
            size: CGSize(width: abs(scaledSize.width), height: abs(scaledSize.height)),
            cornerRadius: annotation.cornerRadius
        )

        contextCopy.fill(path, with: .color(annotation.fill))
        contextCopy.stroke(path, with: .color(annotation.stroke), lineWidth: annotation.strokeWidth)
    }

    private func drawSelectionHandles(in context: inout GraphicsContext) {
        guard !canvas.selectedAnnotationIDs.isEmpty else { return }

        if canvas.selectedAnnotationIDs.count == 1,
           let id = canvas.selectedAnnotationIDs.first,
           let annotation = canvas.annotation(withID: id) {
            // Single selection: draw type-specific handles
            annotation.drawSelectionHandles(in: &context, canvas: canvas)
            return
        }

        // Multi-selection: draw outline only
        guard let selectedBounds = canvas.selectionBoundingBox(for: canvas.selectedAnnotationIDs) else { return }
        let origin = canvas.imageToCanvas(selectedBounds.origin)
        let size = CGSize(width: selectedBounds.width * canvas.zoomLevel, height: selectedBounds.height * canvas.zoomLevel)
        let rect = CGRect(origin: origin, size: size)
        let outline = Path(rect)
        context.stroke(outline, with: .color(Color.accentColor), lineWidth: 1)
    }

    private func drawGrid(in context: inout GraphicsContext, size: CGSize) {
        let spacing = canvas.gridSize * canvas.zoomLevel
        guard spacing >= 4 else { return }

        let startX = fmod(canvas.panOffset.x, spacing)
        let startY = fmod(canvas.panOffset.y, spacing)

        // Draw dot grid (#c4c4c4)
        let dotColor = Color(red: 0xc4 / 255.0, green: 0xc4 / 255.0, blue: 0xc4 / 255.0)
        let dotRadius: CGFloat = 1.0

        var x = startX
        while x < size.width {
            var y = startY
            while y < size.height {
                let dotRect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
                context.fill(Path(ellipseIn: dotRect), with: .color(dotColor))
                y += spacing
            }
            x += spacing
        }
    }
}

private extension CGSize {
    var center: CGPoint { CGPoint(x: width / 2, y: height / 2) }
}

// MARK: - Line Helpers

extension LineStyle {
    func dashPattern(for lineWidth: CGFloat) -> [CGFloat] {
        switch self {
        case .solid:
            return []
        case .dashed:
            return [lineWidth * 4, lineWidth * 2]
        case .dotted:
            return [lineWidth, lineWidth * 1.5]
        }
    }
}

extension LineCap {
    var strokeCap: CGLineCap {
        switch self {
        case .butt: return .butt
        case .round: return .round
        case .square: return .square
        }
    }
}

private func drawArrow(
    at point: CGPoint,
    angle: CGFloat,
    size: CGFloat,
    color: Color,
    style: ArrowType,
    lineWidth: CGFloat,
    in context: inout GraphicsContext
) {
    guard size > 0 else { return }

    var arrowContext = context
    arrowContext.translateBy(x: point.x, y: point.y)
    arrowContext.rotate(by: Angle(radians: Double(angle)))

    let length = size
    let halfWidth = size * 0.4

    switch style {
    case .none:
        return  // Safety: shouldn't be called with .none
    case .open:
        var path = Path()
        path.move(to: CGPoint(x: -length, y: -halfWidth))
        path.addLine(to: .zero)
        path.addLine(to: CGPoint(x: -length, y: halfWidth))
        arrowContext.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    case .filled:
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: -length, y: -halfWidth))
        path.addLine(to: CGPoint(x: -length, y: halfWidth))
        path.closeSubpath()
        arrowContext.fill(path, with: .color(color))
    case .diamond:
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: -length / 2, y: -halfWidth))
        path.addLine(to: CGPoint(x: -length, y: 0))
        path.addLine(to: CGPoint(x: -length / 2, y: halfWidth))
        path.closeSubpath()
        arrowContext.fill(path, with: .color(color))
    case .circle:
        let diameter = size
        let rect = CGRect(x: -diameter, y: -diameter / 2, width: diameter, height: diameter)
        arrowContext.fill(Path(ellipseIn: rect), with: .color(color))
    }
}

// MARK: - Scroll Wheel Support

/// Hosts SwiftUI content and intercepts scroll wheel events to drive panning
private struct ScrollWheelPanContainer<Content: View>: NSViewRepresentable {
    let onScroll: (CGPoint) -> Void
    let content: Content

    init(onScroll: @escaping (CGPoint) -> Void, @ViewBuilder content: () -> Content) {
        self.onScroll = onScroll
        self.content = content()
    }

    func makeNSView(context: Context) -> ScrollWheelPanHostingView<Content> {
        let host = ScrollWheelPanHostingView(rootView: content)
        host.onScroll = onScroll
        return host
    }

    func updateNSView(_ nsView: ScrollWheelPanHostingView<Content>, context: Context) {
        nsView.onScroll = onScroll
        nsView.rootView = content
    }
}

private final class ScrollWheelPanHostingView<Content: View>: NSHostingView<Content> {
    var onScroll: ((CGPoint) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func scrollWheel(with event: NSEvent) {
        guard event.phase != .ended else { return }
        onScroll?(CGPoint(x: event.scrollingDeltaX, y: event.scrollingDeltaY))
        // Avoid super to keep the event from trying to scroll enclosing views
    }
}
