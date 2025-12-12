//
//  GridView.swift
//  quickedit
//
//  SwiftUI view that renders a dot grid background for the annotation canvas.
//

import SwiftUI

/// Renders a dot grid background for the canvas
struct GridView: View {
    let gridSize: CGFloat
    let zoomLevel: CGFloat
    let panOffset: CGPoint
    let showGrid: Bool

    var body: some View {
        if showGrid {
            Canvas { context, size in
                drawGrid(in: &context, size: size)
            }
        }
    }

    private func drawGrid(in context: inout GraphicsContext, size: CGSize) {
        let spacing = gridSize * zoomLevel
        guard spacing >= 4 else { return }

        let startX = fmod(panOffset.x, spacing)
        let startY = fmod(panOffset.y, spacing)

        // Draw dot grid (#c4c4c4)
        let dotColor = Color(red: 0xc4 / 255.0, green: 0xc4 / 255.0, blue: 0xc4 / 255.0)
        let dotRadius: CGFloat = 1.0

        var x = startX
        while x < size.width {
            var y = startY
            while y < size.height {
                let dotRect = CGRect(
                    x: x - dotRadius,
                    y: y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
                context.fill(Path(ellipseIn: dotRect), with: .color(dotColor))
                y += spacing
            }
            x += spacing
        }
    }
}

#Preview {
    GridView(
        gridSize: 20,
        zoomLevel: 1.0,
        panOffset: .zero,
        showGrid: true
    )
    .frame(width: 400, height: 300)
}
