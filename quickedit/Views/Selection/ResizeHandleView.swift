//
//  ResizeHandleView.swift
//  quickedit
//
//  SwiftUI view for square resize handles
//

import SwiftUI

/// Square resize handle for shape annotations
struct ResizeHandleView: View {
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let strokeWidth: CGFloat

    init(position: CGPoint, size: CGFloat = 8, color: Color = .accentColor, strokeWidth: CGFloat = 1) {
        self.position = position
        self.size = size
        self.color = color
        self.strokeWidth = strokeWidth
    }

    var body: some View {
        Rectangle()
            .fill(.white)
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: strokeWidth)
            )
            .frame(width: size, height: size)
            .position(position)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)

        // Show handles at different positions
        ResizeHandleView(position: CGPoint(x: 50, y: 50))
        ResizeHandleView(position: CGPoint(x: 200, y: 50))
        ResizeHandleView(position: CGPoint(x: 200, y: 150))
        ResizeHandleView(position: CGPoint(x: 50, y: 150))
        ResizeHandleView(position: CGPoint(x: 125, y: 50))
        ResizeHandleView(position: CGPoint(x: 125, y: 150))
        ResizeHandleView(position: CGPoint(x: 50, y: 100))
        ResizeHandleView(position: CGPoint(x: 200, y: 100))
    }
    .frame(width: 300, height: 250)
}
