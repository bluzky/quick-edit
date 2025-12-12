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
        let handleSize = ResizeHandleLayout.handleSize / zoomLevel

        ZStack(alignment: .topLeading) {
            // Selection outline
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 1 / zoomLevel)
                .frame(width: bounds.width, height: bounds.height)
                .position(
                    x: bounds.origin.x + bounds.width / 2,
                    y: bounds.origin.y + bounds.height / 2
                )

            // 8 resize handles
            let handleRects = ResizeHandleLayout.handleRects(for: CGRect(origin: .zero, size: bounds.size), zoomLevel: zoomLevel)

            ForEach(Array(handleRects.keys), id: \.self) { handle in
                if let rect = handleRects[handle] {
                    ResizeHandleView(
                        position: CGPoint(
                            x: bounds.origin.x + rect.midX,
                            y: bounds.origin.y + rect.midY
                        ),
                        size: handleSize,
                        color: .accentColor,
                        strokeWidth: 1 / zoomLevel
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
