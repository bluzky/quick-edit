# Annotation JSON Structure

**Last Updated:** December 12, 2025

## Overview

Annotations are stored as structured data separate from images, enabling non-destructive editing. Each annotation type follows a consistent base structure with type-specific properties.

---

## Base Annotation Structure

All annotations share these common properties:

```json
{
  "id": "uuid-string",
  "type": "rectangle|line|text|...",
  "zIndex": 0,
  "visible": true,
  "locked": false,
  "transform": {
    "position": { "x": 0.0, "y": 0.0 },
    "scale": { "width": 1.0, "height": 1.0 },
    "rotation": 0.0
  },
  "size": { "width": 100.0, "height": 100.0 }
}
```

### Common Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | UUID string | Unique identifier |
| `type` | String | Annotation type identifier |
| `zIndex` | Integer | Layer order (higher = front) |
| `visible` | Boolean | Visibility state |
| `locked` | Boolean | Prevents editing if true |
| `transform` | Object | Position, scale, rotation |
| `size` | Object | Width and height in image space (axis-aligned bounds) |

### Transform Object

```json
{
  "position": { "x": 0.0, "y": 0.0 },    // Top-left corner in image space
  "scale": { "width": 1.0, "height": 1.0 }, // Scale factors (can be negative for flip)
  "rotation": 0.0                         // Rotation in degrees
}
```

**Coordinate System:**
- Origin (0,0) is top-left of image
- Units are in image pixels (not screen pixels)
- Position is pre-transform (anchor point)

---

## Shape Annotation (rectangle, rounded, ellipse, diamond, triangle)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "type": "shape",
  "zIndex": 1,
  "visible": true,
  "locked": false,
  "transform": {
    "position": { "x": 100.0, "y": 150.0 },
    "scale": { "width": 1.0, "height": 1.0 },
    "rotation": 0.0
  },
  "size": { "width": 200.0, "height": 150.0 },
  "fill": { "r": 0.0, "g": 0.5, "b": 1.0, "a": 0.3 },
  "stroke": { "r": 0.0, "g": 0.5, "b": 1.0, "a": 1.0 },
  "strokeWidth": 2.0,
  "shapeKind": "rectangle",
  "cornerRadius": 0.0
}
```

**Type-specific properties:**
- `fill` - Fill color (RGBA, 0.0-1.0 normalized)
- `stroke` - Stroke color (RGBA, 0.0-1.0 normalized)
- `strokeWidth` - Stroke thickness in image units
- `shapeKind` - `rectangle|rounded|ellipse|diamond|triangle`
- `cornerRadius` - Corner radius for rectangle/rounded

---

## Line Annotation

```json
{
  "type": "line",
  "startPoint": { "x": 0.0, "y": 0.0 },
  "endPoint": { "x": 100.0, "y": 100.0 },
  "stroke": { "r": 0.0, "g": 0.0, "b": 0.0, "a": 1.0 },
  "strokeWidth": 2.0,
  "arrowStartType": "none",
  "arrowEndType": "open",
  "arrowSize": 10.0,
  "lineStyle": "solid",
  "lineCap": "round"
}
```

**Type-specific properties:**
- `startPoint`, `endPoint` - Points relative to `transform.position` within the `size` bounds
- `stroke`, `strokeWidth` - Line appearance
- `arrowStartType`, `arrowEndType` - `none|open|filled|diamond|circle`
- `arrowSize` - Arrowhead length/width
- `lineStyle` - `solid|dashed|dotted`
- `lineCap` - `butt|round|square`

**Selection behavior:** shows two endpoint handles (no bounding box handles).

### Text Annotation

```json
{
  "type": "text",
  "text": "Sample text",
  "fontName": "Helvetica",
  "fontSize": 16.0,
  "textColor": { "r": 0.0, "g": 0.0, "b": 0.0, "a": 1.0 },
  "alignment": "left",
  "backgroundColor": null
}
```

### Freehand Annotation

```json
{
  "type": "freehand",
  "points": [
    { "x": 10.0, "y": 20.0 },
    { "x": 15.0, "y": 25.0 }
  ],
  "stroke": { "r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0 },
  "strokeWidth": 3.0,
  "smoothing": 0.5
}
```

---

## Color Format

All colors use normalized RGBA values (0.0 to 1.0):

```json
{
  "r": 0.0,    // Red component (0.0 = none, 1.0 = full)
  "g": 0.5,    // Green component
  "b": 1.0,    // Blue component
  "a": 0.3     // Alpha (transparency: 0.0 = transparent, 1.0 = opaque)
}
```

**Conversion:**
- From RGB 0-255: `normalized = value / 255.0`
- To RGB 0-255: `value = normalized * 255.0`

---

## File Format

Annotations can be exported as a JSON array:

```json
{
  "version": "1.0",
  "imageSize": { "width": 1920.0, "height": 1080.0 },
  "annotations": [
    { /* annotation 1 */ },
    { /* annotation 2 */ }
  ]
}
```

**Usage:**
- Save: Export annotations to `.json` file
- Load: Parse JSON and recreate annotation objects
- Edit: Reload saved annotations and continue editing

---

## Implementation Notes

**Current Swift Types:**

```swift
struct AnnotationTransform {
    var position: CGPoint
    var scale: CGSize      // width/height can be negative (flip)
    var rotation: Angle    // SwiftUI Angle type
}

protocol Annotation: AnyObject, Identifiable {
    var id: UUID { get }
    var zIndex: Int { get set }
    var visible: Bool { get set }
    var locked: Bool { get set }
    var transform: AnnotationTransform { get set }
    var size: CGSize { get set }

    func contains(point: CGPoint) -> Bool
}
```

**See Also:**
- Canvas API: `02-canvas-api.md`
- Tool Protocol: `03-tool-protocol.md`
