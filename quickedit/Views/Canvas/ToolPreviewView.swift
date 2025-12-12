//
//  ToolPreviewView.swift
//  quickedit
//
//  View for rendering tool preview overlays using pure SwiftUI
//

import SwiftUI

/// Renders tool preview overlay using SwiftUI
struct ToolPreviewView: View {
    let tool: any AnnotationTool
    let canvas: AnnotationCanvas
    let redrawTrigger: Int

    var body: some View {
        // Depend on redrawTrigger to force redraw during tool interaction
        let _ = redrawTrigger

        ZStack(alignment: .topLeading) {
            tool.previewView(canvas: canvas)
        }
        .scaleEffect(canvas.zoomLevel, anchor: .topLeading)
        .offset(x: canvas.panOffset.x, y: canvas.panOffset.y)
    }
}
