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
            if let rectAnnotation = annotation as? RectangleAnnotation {
                drawRectangle(rectAnnotation, in: &context)
            }
        }
    }

    private func drawRectangle(_ annotation: RectangleAnnotation, in context: inout GraphicsContext) {
        // Apply transforms (scale, rotation, flip)
        let transform = annotation.transform
        let basePosition = canvas.imageToCanvas(transform.position)
        let scaledSize = CGSize(
            width: annotation.size.width * transform.scale.width * canvas.zoomLevel,
            height: annotation.size.height * transform.scale.height * canvas.zoomLevel
        )

        // Calculate center point for rotation
        let centerX = basePosition.x + (scaledSize.width / 2)
        let centerY = basePosition.y + (scaledSize.height / 2)

        var contextCopy = context

        // Apply transformations: translate to center, rotate, scale, translate back
        contextCopy.translateBy(x: centerX, y: centerY)
        contextCopy.rotate(by: transform.rotation)
        contextCopy.translateBy(x: -scaledSize.width / 2, y: -scaledSize.height / 2)

        // Draw rectangle at origin (already translated)
        let rect = CGRect(origin: .zero, size: CGSize(width: abs(scaledSize.width), height: abs(scaledSize.height)))
        let path = Path(rect)
        contextCopy.fill(path, with: .color(annotation.fill))
        contextCopy.stroke(path, with: .color(annotation.stroke), lineWidth: 1.5)
    }

    private func drawSelectionHandles(in context: inout GraphicsContext) {
        guard let selectedBounds = canvas.selectionBoundingBox(for: canvas.selectedAnnotationIDs) else { return }

        // Convert to canvas space
        let origin = canvas.imageToCanvas(selectedBounds.origin)
        let size = CGSize(width: selectedBounds.width * canvas.zoomLevel, height: selectedBounds.height * canvas.zoomLevel)
        let rect = CGRect(origin: origin, size: size)

        // Draw selection outline
        let outline = Path(rect)
        context.stroke(outline, with: .color(Color.accentColor), lineWidth: 1)

        // Draw handles at constant on-screen size
        let handleRects = ResizeHandleLayout.handleRects(for: CGRect(origin: .zero, size: rect.size), zoomLevel: canvas.zoomLevel)
        for (_, handle) in handleRects {
            var handleRect = handle
            handleRect.origin.x += rect.origin.x
            handleRect.origin.y += rect.origin.y
            context.fill(Path(handleRect), with: .color(.white))
            context.stroke(Path(handleRect), with: .color(.accentColor))
        }
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
