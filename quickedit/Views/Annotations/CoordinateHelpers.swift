//
//  CoordinateHelpers.swift
//  quickedit
//
//  Coordinate conversion utilities for canvas and image space.
//

import Foundation
import CoreGraphics

/// Coordinate conversion helpers for annotation canvas
struct CoordinateHelpers {
    /// Convert a point from image space to canvas space (screen coordinates)
    static func imageToCanvas(_ point: CGPoint, zoom: CGFloat, pan: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x * zoom) + pan.x,
            y: (point.y * zoom) + pan.y
        )
    }

    /// Convert a point from canvas space (screen) to image space (data)
    static func canvasToImage(_ point: CGPoint, zoom: CGFloat, pan: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x - pan.x) / zoom,
            y: (point.y - pan.y) / zoom
        )
    }

    /// Convert a size from image space to canvas space
    static func imageToCanvas(_ size: CGSize, zoom: CGFloat) -> CGSize {
        CGSize(
            width: size.width * zoom,
            height: size.height * zoom
        )
    }

    /// Convert a size from canvas space to image space
    static func canvasToImage(_ size: CGSize, zoom: CGFloat) -> CGSize {
        CGSize(
            width: size.width / zoom,
            height: size.height / zoom
        )
    }

    /// Convert a rect from image space to canvas space
    static func imageToCanvas(_ rect: CGRect, zoom: CGFloat, pan: CGPoint) -> CGRect {
        let origin = imageToCanvas(rect.origin, zoom: zoom, pan: pan)
        let size = imageToCanvas(rect.size, zoom: zoom)
        return CGRect(origin: origin, size: size)
    }

    /// Convert a rect from canvas space to image space
    static func canvasToImage(_ rect: CGRect, zoom: CGFloat, pan: CGPoint) -> CGRect {
        let origin = canvasToImage(rect.origin, zoom: zoom, pan: pan)
        let size = canvasToImage(rect.size, zoom: zoom)
        return CGRect(origin: origin, size: size)
    }
}
