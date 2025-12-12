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

    func body(content: Content) -> some View {
        content
            // First: Apply the frame size
            .frame(width: size.width, height: size.height)
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
            // Fourth: Offset to the annotation's location (relative positioning)
            .offset(x: transform.position.x, y: transform.position.y)
    }
}

extension View {
    /// Apply annotation transform to this view
    func annotationTransform(_ transform: AnnotationTransform, size: CGSize) -> some View {
        self.modifier(AnnotationTransformModifier(transform: transform, size: size))
    }
}
