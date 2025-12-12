//
//  SwiftUIAnnotationCanvasView.swift
//  quickedit
//
//  Pure SwiftUI implementation of annotation canvas (no Canvas/GraphicsContext)
//

import SwiftUI

/// Pure SwiftUI annotation canvas view
struct SwiftUIAnnotationCanvasView: View {
    @ObservedObject var canvas: AnnotationCanvas

    @State private var initialPanOffset: CGPoint = .zero
    @State private var isDragging = false
    @State private var initialZoom: CGFloat = ZoomConfig.defaultZoom
    @State private var magnifyAnchor: CGPoint?
    @State private var redrawTrigger: Int = 0
    @State private var annotationUpdateTrigger: Int = 0

    var body: some View {
        GeometryReader { geometry in
            ScrollWheelPanContainer(onScroll: { delta in
                // Trackpad two-finger scroll pans the canvas (natural direction)
                let adjusted = CGPoint(x: delta.x, y: delta.y)
                canvas.pan(by: adjusted)
            }) {
                ZStack(alignment: .topLeading) {
                // Background color
                Color(red: 0xf5 / 255.0, green: 0xf5 / 255.0, blue: 0xf5 / 255.0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Grid overlay
                if canvas.showGrid {
                    GridView(
                        gridSize: canvas.gridSize,
                        zoomLevel: canvas.zoomLevel,
                        panOffset: canvas.panOffset,
                        showGrid: canvas.showGrid
                    )
                }

                // Annotations layer (apply canvas transform to entire layer)
                ZStack(alignment: .topLeading) {
                    ForEach(canvas.annotations.sorted(by: { $0.zIndex < $1.zIndex }), id: \.id) { annotation in
                        AnnotationView(annotation: annotation)
                    }
                    .id(annotationUpdateTrigger) // Force recreation when annotations change
                }
                .scaleEffect(canvas.zoomLevel, anchor: .topLeading)
                .offset(x: canvas.panOffset.x, y: canvas.panOffset.y)

                // Selection layer (apply canvas transform to entire layer)
                if !canvas.selectedAnnotationIDs.isEmpty {
                    ZStack(alignment: .topLeading) {
                        if canvas.selectedAnnotationIDs.count == 1,
                           let id = canvas.selectedAnnotationIDs.first,
                           let annotation = canvas.annotation(withID: id) {
                            // Single selection
                            SingleSelectionView(annotation: annotation, zoomLevel: canvas.zoomLevel)
                        } else if let boundingBox = canvas.selectionBoundingBox(for: canvas.selectedAnnotationIDs) {
                            // Multi-selection
                            MultiSelectionView(boundingBox: boundingBox, zoomLevel: canvas.zoomLevel)
                        }
                    }
                    .id(annotationUpdateTrigger) // Force recreation when annotations change
                    .scaleEffect(canvas.zoomLevel, anchor: .topLeading)
                    .offset(x: canvas.panOffset.x, y: canvas.panOffset.y)
                }

                // Tool preview layer
                if let tool = canvas.activeTool {
                    ToolPreviewView(tool: tool, canvas: canvas, redrawTrigger: redrawTrigger)
                }
            }
            .gesture(dragGesture)
            .simultaneousGesture(magnificationGesture)
            .onChange(of: geometry.size) { _, newValue in
                canvas.updateCanvasSize(newValue)
            }
            .onReceive(canvas.onAnnotationModified) { _ in
                annotationUpdateTrigger += 1
            }
            .onReceive(canvas.onAnnotationAdded) { _ in
                annotationUpdateTrigger += 1
            }
            .onReceive(canvas.onAnnotationDeleted) { _ in
                annotationUpdateTrigger += 1
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
                    redrawTrigger += 1  // Force redraw for tool preview
                    annotationUpdateTrigger += 1  // Force annotation view updates during drag
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
            .onChanged { scale in
                if magnifyAnchor == nil {
                    // Center zoom on canvas center
                    magnifyAnchor = CGPoint(
                        x: canvas.canvasSize.width / 2,
                        y: canvas.canvasSize.height / 2
                    )
                    initialZoom = canvas.zoomLevel
                }
                let newZoom = initialZoom * scale
                canvas.setZoom(newZoom, centerOn: magnifyAnchor)
            }
            .onEnded { _ in
                magnifyAnchor = nil
            }
    }

    private func handleTap(at location: CGPoint) {
        let imagePoint = canvas.canvasToImage(location)

        // Find topmost annotation at tap location
        let tappedAnnotation = canvas.annotations
            .sorted(by: { $0.zIndex > $1.zIndex })
            .first { annotation in
                !annotation.locked && annotation.visible && annotation.contains(point: imagePoint)
            }

        if let annotation = tappedAnnotation {
            // Toggle selection
            canvas.toggleSelection(for: annotation.id)
        } else {
            // Clicked empty space - clear selection
            canvas.clearSelection()
        }
    }
}

#Preview {
    SwiftUIAnnotationCanvasView(
        canvas: {
            let canvas = AnnotationCanvas()

            // Add sample shapes
            let shape1 = ShapeAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 100, y: 100),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 200, height: 150),
                fill: .blue.opacity(0.3),
                stroke: .blue,
                strokeWidth: 2,
                shapeKind: .rounded,
                cornerRadius: 15
            )

            let shape2 = ShapeAnnotation(
                zIndex: 1,
                transform: AnnotationTransform(
                    position: CGPoint(x: 250, y: 200),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .degrees(15)
                ),
                size: CGSize(width: 150, height: 150),
                fill: .red.opacity(0.3),
                stroke: .red,
                strokeWidth: 2,
                shapeKind: .ellipse,
                cornerRadius: 0
            )

            let line = LineAnnotation(
                zIndex: 2,
                transform: AnnotationTransform(
                    position: CGPoint(x: 150, y: 300),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 200, height: 80),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 200, y: 80),
                stroke: .green,
                strokeWidth: 3,
                arrowStartType: .none,
                arrowEndType: .filled,
                arrowSize: 12,
                lineStyle: .solid,
                lineCap: .round
            )

            canvas.addAnnotation(shape1)
            canvas.addAnnotation(shape2)
            canvas.addAnnotation(line)
            canvas.selectAnnotations([shape1.id])

            return canvas
        }()
    )
    .frame(width: 800, height: 600)
}
