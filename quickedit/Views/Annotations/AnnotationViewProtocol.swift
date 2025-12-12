//
//  AnnotationViewProtocol.swift
//  quickedit
//
//  Protocol for SwiftUI views that render annotations.
//

import SwiftUI

/// Protocol for views that render specific annotation types
protocol AnnotationViewProtocol: View {
    /// The annotation type this view renders
    associatedtype AnnotationType: Annotation

    /// The annotation to render
    var annotation: AnnotationType { get }

    /// Initialize with an annotation
    init(annotation: AnnotationType)
}
