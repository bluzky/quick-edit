//
//  LineAnnotationView.swift
//  quickedit
//
//  SwiftUI view for rendering line/arrow annotations
//

import SwiftUI

/// SwiftUI view that renders a LineAnnotation
struct LineAnnotationView: View {
    let annotation: LineAnnotation

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Draw the main line
            LineShape(
                start: CGPoint(
                    x: annotation.startPoint.x + annotation.arrowSize,
                    y: annotation.startPoint.y + annotation.arrowSize
                ),
                end: CGPoint(
                    x: annotation.endPoint.x + annotation.arrowSize,
                    y: annotation.endPoint.y + annotation.arrowSize
                )
            )
            .stroke(
                annotation.stroke,
                style: StrokeStyle(
                    lineWidth: annotation.strokeWidth,
                    lineCap: annotation.lineCap.strokeCap,
                    dash: annotation.lineStyle.dashPattern(for: annotation.strokeWidth)
                )
            )

            // Draw arrows
            if annotation.arrowStartType != .none {
                let angle = atan2(
                    annotation.endPoint.y - annotation.startPoint.y,
                    annotation.endPoint.x - annotation.startPoint.x
                ) + .pi
                ArrowShape(
                    position: CGPoint(
                        x: annotation.startPoint.x + annotation.arrowSize,
                        y: annotation.startPoint.y + annotation.arrowSize
                    ),
                    angle: angle,
                    size: annotation.arrowSize,
                    style: annotation.arrowStartType
                )
                .fill(annotation.stroke)

                if annotation.arrowStartType == .open {
                    ArrowShape(
                        position: CGPoint(
                            x: annotation.startPoint.x + annotation.arrowSize,
                            y: annotation.startPoint.y + annotation.arrowSize
                        ),
                        angle: angle,
                        size: annotation.arrowSize,
                        style: annotation.arrowStartType
                    )
                    .stroke(annotation.stroke, style: StrokeStyle(lineWidth: annotation.strokeWidth, lineCap: .round))
                }
            }

            if annotation.arrowEndType != .none {
                let angle = atan2(
                    annotation.endPoint.y - annotation.startPoint.y,
                    annotation.endPoint.x - annotation.startPoint.x
                )
                ArrowShape(
                    position: CGPoint(
                        x: annotation.endPoint.x + annotation.arrowSize,
                        y: annotation.endPoint.y + annotation.arrowSize
                    ),
                    angle: angle,
                    size: annotation.arrowSize,
                    style: annotation.arrowEndType
                )
                .fill(annotation.stroke)

                if annotation.arrowEndType == .open {
                    ArrowShape(
                        position: CGPoint(
                            x: annotation.endPoint.x + annotation.arrowSize,
                            y: annotation.endPoint.y + annotation.arrowSize
                        ),
                        angle: angle,
                        size: annotation.arrowSize,
                        style: annotation.arrowEndType
                    )
                    .stroke(annotation.stroke, style: StrokeStyle(lineWidth: annotation.strokeWidth, lineCap: .round))
                }
            }
        }
        .frame(
            width: annotation.size.width + annotation.arrowSize * 2,
            height: annotation.size.height + annotation.arrowSize * 2
        )
        .scaleEffect(
            x: annotation.transform.scale.width,
            y: annotation.transform.scale.height,
            anchor: .topLeading
        )
        .rotationEffect(
            annotation.transform.rotation,
            anchor: .center
        )
        .offset(
            x: annotation.transform.position.x - annotation.arrowSize,
            y: annotation.transform.position.y - annotation.arrowSize
        )
        .opacity(annotation.visible ? 1.0 : 0.0)
    }
}

// MARK: - Line Shape

struct LineShape: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

// MARK: - Arrow Shape

struct ArrowShape: Shape {
    let position: CGPoint
    let angle: CGFloat
    let size: CGFloat
    let style: ArrowType

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let length = size
        let halfWidth = size * 0.4
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)

        switch style {
        case .none:
            return path
        case .open:
            // Open arrow - just the two lines
            let x1 = position.x + cosAngle * (-length) - sinAngle * (-halfWidth)
            let y1 = position.y + sinAngle * (-length) + cosAngle * (-halfWidth)
            let x2 = position.x + cosAngle * (-length) - sinAngle * halfWidth
            let y2 = position.y + sinAngle * (-length) + cosAngle * halfWidth

            path.move(to: position)
            path.addLine(to: CGPoint(x: x1, y: y1))
            path.move(to: position)
            path.addLine(to: CGPoint(x: x2, y: y2))
        case .filled:
            // Filled triangle
            let x1 = position.x + cosAngle * (-length) - sinAngle * (-halfWidth)
            let y1 = position.y + sinAngle * (-length) + cosAngle * (-halfWidth)
            let x2 = position.x + cosAngle * (-length) - sinAngle * halfWidth
            let y2 = position.y + sinAngle * (-length) + cosAngle * halfWidth

            path.move(to: position)
            path.addLine(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
            path.closeSubpath()
        case .diamond:
            // Diamond shape
            let halfLength = -length / 2
            let x1 = position.x + cosAngle * halfLength - sinAngle * (-halfWidth)
            let y1 = position.y + sinAngle * halfLength + cosAngle * (-halfWidth)
            let x2 = position.x + cosAngle * (-length)
            let y2 = position.y + sinAngle * (-length)
            let x3 = position.x + cosAngle * halfLength - sinAngle * halfWidth
            let y3 = position.y + sinAngle * halfLength + cosAngle * halfWidth

            path.move(to: position)
            path.addLine(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
            path.addLine(to: CGPoint(x: x3, y: y3))
            path.closeSubpath()
        case .circle:
            // Circle
            let halfSize = -size / 2
            let centerX = position.x + cosAngle * halfSize
            let centerY = position.y + sinAngle * halfSize
            let rectX = centerX - size / 2
            let rectY = centerY - size / 2

            path.addEllipse(in: CGRect(x: rectX, y: rectY, width: size, height: size))
        }

        return path
    }
}

// MARK: - Extensions

extension LineStyle {
    func dashPattern(for lineWidth: CGFloat) -> [CGFloat] {
        switch self {
        case .solid:
            return []
        case .dashed:
            return [lineWidth * 4, lineWidth * 2]
        case .dotted:
            return [lineWidth, lineWidth * 1.5]
        }
    }
}

extension LineCap {
    var strokeCap: CGLineCap {
        switch self {
        case .butt: return .butt
        case .round: return .round
        case .square: return .square
        }
    }
}

// MARK: - Previews

#Preview("Simple Line") {
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
            arrowEndType: .none,
            arrowSize: 12,
            lineStyle: .solid,
            lineCap: .round
        )
    )
    .frame(width: 400, height: 300)
}

#Preview("Arrow") {
    LineAnnotationView(
        annotation: LineAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: 50, y: 100),
                scale: CGSize(width: 1, height: 1),
                rotation: .zero
            ),
            size: CGSize(width: 250, height: 100),
            startPoint: CGPoint(x: 0, y: 50),
            endPoint: CGPoint(x: 250, y: 50),
            stroke: .red,
            strokeWidth: 3,
            arrowStartType: .none,
            arrowEndType: .filled,
            arrowSize: 15,
            lineStyle: .solid,
            lineCap: .round
        )
    )
    .frame(width: 400, height: 300)
}

#Preview("Dashed Double Arrow") {
    LineAnnotationView(
        annotation: LineAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: 75, y: 75),
                scale: CGSize(width: 1, height: 1),
                rotation: .degrees(30)
            ),
            size: CGSize(width: 200, height: 150),
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 200, y: 150),
            stroke: .green,
            strokeWidth: 2,
            arrowStartType: .open,
            arrowEndType: .open,
            arrowSize: 12,
            lineStyle: .dashed,
            lineCap: .round
        )
    )
    .frame(width: 400, height: 300)
}
