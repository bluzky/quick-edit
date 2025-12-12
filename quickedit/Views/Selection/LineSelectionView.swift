//
//  LineSelectionView.swift
//  quickedit
//
//  Selection UI for line annotations (connecting line + 2 circular handles)
//

import SwiftUI

/// Selection view for line annotations with endpoint handles
struct LineSelectionView: View {
    let annotation: LineAnnotation
    let zoomLevel: CGFloat

    var body: some View {
        let scaleX = abs(annotation.transform.scale.width == 0 ? 1 : annotation.transform.scale.width)
        let scaleY = abs(annotation.transform.scale.height == 0 ? 1 : annotation.transform.scale.height)

        // Calculate absolute positions in canvas space (zoomed)
        let startAbsolute = CGPoint(
            x: (annotation.transform.position.x + annotation.startPoint.x * scaleX) * zoomLevel,
            y: (annotation.transform.position.y + annotation.startPoint.y * scaleY) * zoomLevel
        )
        let endAbsolute = CGPoint(
            x: (annotation.transform.position.x + annotation.endPoint.x * scaleX) * zoomLevel,
            y: (annotation.transform.position.y + annotation.endPoint.y * scaleY) * zoomLevel
        )

        ZStack(alignment: .topLeading) {
            // Selection line
            Path { path in
                path.move(to: startAbsolute)
                path.addLine(to: endAbsolute)
            }
            .stroke(Color.accentColor, lineWidth: 1)

            // Start point handle
            CircleHandleView(
                position: startAbsolute,
                radius: 4,
                color: .accentColor,
                strokeWidth: 2
            )

            // End point handle
            CircleHandleView(
                position: endAbsolute,
                radius: 4,
                color: .accentColor,
                strokeWidth: 2
            )
        }
    }
}

#Preview {
    ZStack(alignment: .topLeading) {
        // Background line
        LineAnnotationView(
            annotation: LineAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 50),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 200, height: 100),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 200, y: 100),
                stroke: .blue,
                strokeWidth: 2,
                arrowStartType: .none,
                arrowEndType: .filled,
                arrowSize: 12,
                lineStyle: .solid,
                lineCap: .round
            )
        )

        // Selection overlay
        LineSelectionView(
            annotation: LineAnnotation(
                zIndex: 0,
                transform: AnnotationTransform(
                    position: CGPoint(x: 50, y: 50),
                    scale: CGSize(width: 1, height: 1),
                    rotation: .zero
                ),
                size: CGSize(width: 200, height: 100),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 200, y: 100),
                stroke: .blue,
                strokeWidth: 2,
                arrowStartType: .none,
                arrowEndType: .filled,
                arrowSize: 12,
                lineStyle: .solid,
                lineCap: .round
            ),
            zoomLevel: 1.0
        )
    }
    .frame(width: 400, height: 300)
}
