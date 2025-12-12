//
//  ShapeAnnotationView.swift
//  quickedit
//
//  SwiftUI view for rendering shape annotations (rectangle, ellipse, etc.)
//

import SwiftUI

/// SwiftUI view that renders a ShapeAnnotation
struct ShapeAnnotationView: View {
    let annotation: ShapeAnnotation
    var zoomLevel: CGFloat = 1.0

    var body: some View {
        let zoomedSize = CGSize(
            width: annotation.size.width * zoomLevel,
            height: annotation.size.height * zoomLevel
        )

        let path = makeShapePath(
            kind: annotation.shapeKind,
            size: zoomedSize,
            cornerRadius: annotation.cornerRadius * zoomLevel
        )

        ZStack {
            path
                .fill(annotation.fill)
                .overlay(
                    path
                        .stroke(annotation.stroke, lineWidth: annotation.strokeWidth * zoomLevel)
                )

            if !annotation.text.isEmpty {
                textView(zoomedSize: zoomedSize)
            }
        }
        .frame(width: zoomedSize.width, height: zoomedSize.height)
        .annotationTransform(annotation.transform, size: annotation.size, zoomLevel: zoomLevel)
        .opacity(annotation.visible ? 1.0 : 0.0)
    }

    private func textView(zoomedSize: CGSize) -> some View {
        Text(annotation.text)
            .font(makeFont())
            .foregroundColor(annotation.textColor)
            .multilineTextAlignment(horizontalTextAlignment)
            .lineLimit(nil)
            .frame(
                width: max(zoomedSize.width - 16, 0),
                height: max(zoomedSize.height - 16, 0),
                alignment: textFrameAlignment
            )
            .padding(8)
    }

    private func makeFont() -> Font {
        let size = annotation.fontSize * zoomLevel
        switch annotation.fontFamily {
        case "System":
            return .system(size: size)
        case "SF Mono":
            return .system(size: size, design: .monospaced)
        case "SF Pro Rounded":
            return .system(size: size, design: .rounded)
        default:
            return Font.custom(annotation.fontFamily, size: size)
        }
    }

    private var horizontalTextAlignment: TextAlignment {
        switch annotation.horizontalAlignment {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    private var textFrameAlignment: Alignment {
        let horizontal: SwiftUI.HorizontalAlignment = {
            switch annotation.horizontalAlignment {
            case .left: return .leading
            case .center: return .center
            case .right: return .trailing
            }
        }()

        let vertical: SwiftUI.VerticalAlignment = {
            switch annotation.verticalAlignment {
            case .top: return .top
            case .middle: return .center
            case .bottom: return .bottom
            }
        }()

        return Alignment(horizontal: horizontal, vertical: vertical)
    }
}

#Preview("Rectangle") {
    ShapeAnnotationView(
        annotation: ShapeAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: 100, y: 100),
                scale: CGSize(width: 1, height: 1),
                rotation: .zero
            ),
            size: CGSize(width: 200, height: 150),
            fill: .blue.opacity(0.3),
            stroke: .blue,
            strokeWidth: 2,
            shapeKind: .rectangle,
            cornerRadius: 0
        )
    )
    .frame(width: 400, height: 300)
}

#Preview("Ellipse") {
    ShapeAnnotationView(
        annotation: ShapeAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: 100, y: 100),
                scale: CGSize(width: 1, height: 1),
                rotation: .degrees(45)
            ),
            size: CGSize(width: 150, height: 150),
            fill: .red.opacity(0.3),
            stroke: .red,
            strokeWidth: 3,
            shapeKind: .ellipse,
            cornerRadius: 0
        )
    )
    .frame(width: 400, height: 300)
}

#Preview("Rounded Rectangle") {
    ShapeAnnotationView(
        annotation: ShapeAnnotation(
            zIndex: 0,
            transform: AnnotationTransform(
                position: CGPoint(x: 50, y: 50),
                scale: CGSize(width: 1, height: 1),
                rotation: .zero
            ),
            size: CGSize(width: 200, height: 100),
            fill: .green.opacity(0.3),
            stroke: .green,
            strokeWidth: 2,
            shapeKind: .rounded,
            cornerRadius: 20
        )
    )
    .frame(width: 400, height: 300)
}
