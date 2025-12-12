//
//  CircleHandleView.swift
//  quickedit
//
//  SwiftUI view for circular handles (used for line endpoints)
//

import SwiftUI

/// Circular handle for line annotation endpoints
struct CircleHandleView: View {
    let position: CGPoint
    let radius: CGFloat
    let color: Color
    let strokeWidth: CGFloat

    init(position: CGPoint, radius: CGFloat = 4, color: Color = .accentColor, strokeWidth: CGFloat = 2) {
        self.position = position
        self.radius = radius
        self.color = color
        self.strokeWidth = strokeWidth
    }

    var body: some View {
        Circle()
            .fill(.white)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: strokeWidth)
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(position)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)

        // Line with circular handles at endpoints
        Path { path in
            path.move(to: CGPoint(x: 50, y: 100))
            path.addLine(to: CGPoint(x: 250, y: 150))
        }
        .stroke(Color.blue, lineWidth: 2)

        CircleHandleView(position: CGPoint(x: 50, y: 100))
        CircleHandleView(position: CGPoint(x: 250, y: 150))
    }
    .frame(width: 300, height: 250)
}
