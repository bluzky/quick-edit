//
//  AnnotationView.swift
//  quickedit
//
//  Router view that renders the appropriate annotation view based on type.
//

import SwiftUI

/// Router view that renders any annotation type
struct AnnotationView: View {
    let annotation: any Annotation
    var zoomLevel: CGFloat = 1.0

    var body: some View {
        Group {
            if let shape = annotation as? ShapeAnnotation {
                ShapeAnnotationView(annotation: shape, zoomLevel: zoomLevel)
            } else if let line = annotation as? LineAnnotation {
                LineAnnotationView(annotation: line)
            } else {
                // Fallback for unknown annotation types
                EmptyView()
            }
        }
    }
}

#Preview("Shape") {
    AnnotationView(
        annotation: ShapeAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: 100, y: 100),
                scale: CGSize(width: 1, height: 1),
                rotation: .degrees(15)
            ),
            size: CGSize(width: 150, height: 150),
            fill: .blue.opacity(0.3),
            stroke: .blue,
            strokeWidth: 2,
            shapeKind: .ellipse,
            cornerRadius: 0
        )
    )
    .frame(width: 400, height: 300)
}

#Preview("Line") {
    AnnotationView(
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
    .frame(width: 400, height: 300)
}

#Preview("Multiple Annotations") {
    ZStack(alignment: .topLeading) {
        AnnotationView(
            annotation: ShapeAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 50),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 200, height: 150),
                fill: .green.opacity(0.2),
                stroke: .green,
                strokeWidth: 2,
                shapeKind: .rounded,
                cornerRadius: 15
            )
        )
        AnnotationView(
            annotation: LineAnnotation(
                zIndex: 1,
                transform: AnnotationTransform(
                    position: CGPoint(x: 100, y: 80),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 180, height: 80),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 180, y: 80),
                stroke: .orange,
                strokeWidth: 3,
                arrowStartType: .none,
                arrowEndType: .filled,
                arrowSize: 12,
                lineStyle: .dashed,
                lineCap: .round
            )
        )
    }
    .frame(width: 400, height: 300)
}
