//
//  MultiSelectionView.swift
//  quickedit
//
//  Selection UI for multiple selected annotations (bounding box outline only)
//

import SwiftUI

/// Selection view for multiple annotations showing combined bounding box
struct MultiSelectionView: View {
    let boundingBox: CGRect
    let zoomLevel: CGFloat

    var body: some View {
        let zoomedBounds = CGRect(
            x: boundingBox.origin.x * zoomLevel,
            y: boundingBox.origin.y * zoomLevel,
            width: boundingBox.width * zoomLevel,
            height: boundingBox.height * zoomLevel
        )

        Rectangle()
            .stroke(Color.accentColor, lineWidth: 1)
            .frame(width: zoomedBounds.width, height: zoomedBounds.height)
            .position(
                x: zoomedBounds.origin.x + zoomedBounds.width / 2,
                y: zoomedBounds.origin.y + zoomedBounds.height / 2
            )
    }
}

#Preview {
    ZStack(alignment: .topLeading) {
        // Multiple annotations
        ShapeAnnotationView(
            annotation: ShapeAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 50),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 100, height: 80),
                fill: .blue.opacity(0.2),
                stroke: .blue,
                strokeWidth: 2,
                shapeKind: .rectangle,
                cornerRadius: 0
            )
        )

        ShapeAnnotationView(
            annotation: ShapeAnnotation(
                zIndex: 1,
                transform: AnnotationTransform(
                    position: CGPoint(x: 120, y: 100),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 120, height: 100),
                fill: .green.opacity(0.2),
                stroke: .green,
                strokeWidth: 2,
                shapeKind: .ellipse,
                cornerRadius: 0
            )
        )

        // Multi-selection bounding box
        MultiSelectionView(
            boundingBox: CGRect(x: 50, y: 50, width: 190, height: 150),
            zoomLevel: 1.0
        )
    }
    .frame(width: 400, height: 300)
}
