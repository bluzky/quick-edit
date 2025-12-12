//
//  SingleSelectionView.swift
//  quickedit
//
//  Router view for rendering selection UI based on annotation type
//

import SwiftUI

/// Router view that renders the appropriate selection UI for a single annotation
struct SingleSelectionView: View {
    let annotation: any Annotation
    let zoomLevel: CGFloat

    var body: some View {
        Group {
            if let shape = annotation as? ShapeAnnotation {
                ShapeSelectionView(annotation: shape, zoomLevel: zoomLevel)
            } else if let line = annotation as? LineAnnotation {
                LineSelectionView(annotation: line, zoomLevel: zoomLevel)
            } else {
                // Fallback for unknown annotation types
                EmptyView()
            }
        }
    }
}

#Preview("Shape Selection") {
    ZStack(alignment: .topLeading) {
        ShapeAnnotationView(
            annotation: ShapeAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 50),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .degrees(15)
                ),
                size: CGSize(width: 200, height: 150),
                fill: .blue.opacity(0.2),
                stroke: .blue,
                strokeWidth: 2,
                shapeKind: .ellipse,
                cornerRadius: 0
            )
        )

        SingleSelectionView(
            annotation: ShapeAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 50),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .degrees(15)
                ),
                size: CGSize(width: 200, height: 150),
                fill: .blue.opacity(0.2),
                stroke: .blue,
                strokeWidth: 2,
                shapeKind: .ellipse,
                cornerRadius: 0
            ),
            zoomLevel: 1.0
        )
    }
    .frame(width: 400, height: 300)
}

#Preview("Line Selection") {
    ZStack(alignment: .topLeading) {
        LineAnnotationView(
            annotation: LineAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 100),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 250, height: 100),
                startPoint: CGPoint(x: 0, y: 50),
                endPoint: CGPoint(x: 250, y: 50),
                stroke: .red,
                strokeWidth: 3,
                arrowStartType: .none,
                arrowEndType: .filled,
                arrowSize: 15,
                lineStyle: .solid,
                lineCap: .round
            )
        )

        SingleSelectionView(
            annotation: LineAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 100),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 250, height: 100),
                startPoint: CGPoint(x: 0, y: 50),
                endPoint: CGPoint(x: 250, y: 50),
                stroke: .red,
                strokeWidth: 3,
                arrowStartType: .none,
                arrowEndType: .filled,
                arrowSize: 15,
                lineStyle: .solid,
                lineCap: .round
            ),
            zoomLevel: 1.0
        )
    }
    .frame(width: 400, height: 300)
}
