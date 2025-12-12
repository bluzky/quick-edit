//
//  ShapeAnnotationView.swift
//  quickedit
//
//  SwiftUI view for rendering shape annotations (rectangle, ellipse, etc.)
//

import SwiftUI

/// SwiftUI view that renders a ShapeAnnotation
struct ShapeAnnotationView: View {
    let annotation: ShapeAnnotation

    var body: some View {
        let path = makeShapePath(
            kind: annotation.shapeKind,
            size: annotation.size,
            cornerRadius: annotation.cornerRadius
        )

        path
            .fill(annotation.fill)
            .overlay(
                path
                    .stroke(annotation.stroke, lineWidth: annotation.strokeWidth)
            )
            .frame(width: annotation.size.width, height: annotation.size.height)
            .annotationTransform(annotation.transform, size: annotation.size)
            .opacity(annotation.visible ? 1.0 : 0.0)
    }
}

#Preview("Rectangle") {
    ShapeAnnotationView(
        annotation: ShapeAnnotation(
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
            shapeKind: .rectangle,
            cornerRadius: 0
        )
    )
    .frame(width: 400, height: 300)
}

#Preview("Ellipse") {
    ShapeAnnotationView(
        annotation: ShapeAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: 100, y: 100),
                scale: CGSize(width: 1, height: 1),
                rotation: .degrees(45)
            ),
            size: CGSize(width: 150, height: 150),
            fill: .red.opacity(0.3),
            stroke: .red,
            strokeWidth: 3,
            shapeKind: .ellipse,
            cornerRadius: 0
        )
    )
    .frame(width: 400, height: 300)
}

#Preview("Rounded Rectangle") {
    ShapeAnnotationView(
        annotation: ShapeAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: 50, y: 50),
                scale: CGSize(width: 1, height: 1),
                rotation: .zero
            ),
            size: CGSize(width: 200, height: 100),
            fill: .green.opacity(0.3),
            stroke: .green,
            strokeWidth: 2,
            shapeKind: .rounded,
            cornerRadius: 20
        )
    )
    .frame(width: 400, height: 300)
}
