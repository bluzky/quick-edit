//
//  AnnotationTransformModifier.swift
//  quickedit
//
//  ViewModifier that applies annotation transforms (position, rotation, scale) to SwiftUI views.
//

import SwiftUI

/// Applies annotation transform to any SwiftUI view
struct AnnotationTransformModifier: ViewModifier {
    let transform: AnnotationTransform
    let size: CGSize
    let zoomLevel: CGFloat

    func body(content: Content) -> some View {
        content
            // Note: Size is already zoomed in the annotation view, so we don't apply it here
            // Second: Apply scale (including negative for flip)
            .scaleEffect(
                x: transform.scale.width,
                y: transform.scale.height,
                anchor: .topLeading
            )
            // Third: Apply rotation around center
            .rotationEffect(
                transform.rotation,
                anchor: .center
            )
            // Fourth: Offset to the annotation's location (scaled by zoom)
            .offset(x: transform.position.x * zoomLevel, y: transform.position.y * zoomLevel)
    }
}

extension View {
    /// Apply annotation transform to this view
    func annotationTransform(_ transform: AnnotationTransform, size: CGSize, zoomLevel: CGFloat = 1.0) -> some View {
        self.modifier(AnnotationTransformModifier(transform: transform, size: size, zoomLevel: zoomLevel))
    }
}
