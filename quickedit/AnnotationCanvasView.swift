//
//  AnnotationCanvasView.swift
//  quickedit
//
//  SwiftUI view that renders the annotation canvas with zoom/pan, hit testing,
//  selection handles, and grid overlay.
//

import SwiftUI

struct AnnotationCanvasView: View {
    @ObservedObject var canvas: AnnotationCanvas

    var body: some View {
        SwiftUIAnnotationCanvasView(canvas: canvas)
    }
}
