//
//  ShapeSelectionView.swift
//  quickedit
//
//  Selection UI for shape annotations (outline + 8 resize handles)
//

import SwiftUI

/// Selection view for shape annotations with 8 resize handles
struct ShapeSelectionView: View {
    let annotation: ShapeAnnotation
    let zoomLevel: CGFloat

    var body: some View {
        let bounds = annotation.bounds
        let zoomedBounds = CGRect(
            x: bounds.origin.x * zoomLevel,
            y: bounds.origin.y * zoomLevel,
            width: bounds.width * zoomLevel,
            height: bounds.height * zoomLevel
        )
        let handleSize = ResizeHandleLayout.handleSize

        ZStack(alignment: .topLeading) {
            // Selection outline
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 1)
                .frame(width: zoomedBounds.width, height: zoomedBounds.height)
                .position(
                    x: zoomedBounds.origin.x + zoomedBounds.width / 2,
                    y: zoomedBounds.origin.y + zoomedBounds.height / 2
                )

            // 8 resize handles
            let handleRects = ResizeHandleLayout.handleRects(for: CGRect(origin: .zero, size: zoomedBounds.size), zoomLevel: 1.0)

            ForEach(Array(handleRects.keys), id: \.self) { handle in
                if let rect = handleRects[handle] {
                    ResizeHandleView(
                        position: CGPoint(
                            x: zoomedBounds.origin.x + rect.midX,
                            y: zoomedBounds.origin.y + rect.midY
                        ),
                        size: handleSize,
                        color: .accentColor,
                        strokeWidth: 1
                    )
                }
            }
        }
    }
}

#Preview {
    ZStack(alignment: .topLeading) {
        // Background shape
        ShapeAnnotationView(
            annotation: ShapeAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 50),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 200, height: 150),
                fill: .blue.opacity(0.2),
                stroke: .blue,
                strokeWidth: 2,
                shapeKind: .rounded,
                cornerRadius: 10
            )
        )

        // Selection overlay
        ShapeSelectionView(
            annotation: ShapeAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 50),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 200, height: 150),
                fill: .blue.opacity(0.2),
                stroke: .blue,
                strokeWidth: 2,
                shapeKind: .rounded,
                cornerRadius: 10
            ),
            zoomLevel: 1.0
        )
    }
    .frame(width: 400, height: 300)
}
