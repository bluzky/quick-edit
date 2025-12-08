# Complete Annotation Type Reference

This document defines all supported annotation types with their complete property sets.

---

## Base Structure (All Types)

Every annotation follows this structure:

```json
{
  "id": "uuid-string",
  "type": "annotationType",
  "zIndex": 5,
  "transform": {
    "position": {"x": 100.0, "y": 200.0},
    "rotation": 45.0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 200.0,
    "height": 50.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    // Type-specific properties
  },
  "children": []  // Only for groups; can be nested
}
```

### Common Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | string (UUID) | ✓ | - | Unique identifier |
| `type` | string | ✓ | - | Annotation type name |
| `zIndex` | integer | ✓ | - | Layer ordering (higher = on top) |
| `transform` | object | ✓ | - | Position, rotation, scale |
| `bounds` | object | ✓ | - | Width and height |
| `locked` | boolean | - | false | Read-only in UI if true |
| `visible` | boolean | - | true | Hidden if false |
| `properties` | object | ✓ | - | Type-specific configuration |
| `children` | array | - | [] | For groups only; nested annotations |

### Transform Object

```json
{
  "position": {"x": 100.0, "y": 200.0},
  "rotation": 45.0,
  "scale": {"x": 1.0, "y": 1.0}
}
```

| Field | Type | Range | Default | Description |
|-------|------|-------|---------|-------------|
| `position.x` | number | - | 0 | X coordinate of center |
| `position.y` | number | - | 0 | Y coordinate of center |
| `rotation` | number | 0-360 | 0 | Rotation in degrees (clockwise) |
| `scale.x` | number | > 0 | 1.0 | Horizontal scale factor |
| `scale.y` | number | > 0 | 1.0 | Vertical scale factor |

---

## Type 1: Line

Draws a straight line between two points.

```json
{
  "id": "line-001",
  "type": "line",
  "zIndex": 1,
  "transform": {
    "position": {"x": 150.0, "y": 250.0},
    "rotation": 0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 200.0,
    "height": 50.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "startPoint": {"x": 0.0, "y": 0.0},
    "endPoint": {"x": 200.0, "y": 50.0},
    "strokeColor": {
      "red": 1.0,
      "green": 0.0,
      "blue": 0.0,
      "alpha": 1.0
    },
    "strokeWidth": 2.5,
    "lineStyle": "solid",
    "lineCap": "round",
    "lineJoin": "round"
  }
}
```

**Properties:**

| Field | Type | Options | Default | Description |
|-------|------|---------|---------|-------------|
| `startPoint` | {x, y} | - | {0, 0} | Start point relative to bounds |
| `endPoint` | {x, y} | - | - | End point relative to bounds |
| `strokeColor` | RGBA | - | - | Line color |
| `strokeWidth` | number | - | 1.0 | Line thickness in points |
| `lineStyle` | enum | "solid", "dashed", "dotted" | "solid" | Line pattern |
| `lineCap` | enum | "butt", "round", "square" | "butt" | End cap style |
| `lineJoin` | enum | "miter", "round", "bevel" | "miter" | Join style |

---

## Type 2: Shape

Draws a geometric shape (rectangle, circle, polygon, etc.).

```json
{
  "id": "shape-001",
  "type": "shape",
  "zIndex": 2,
  "transform": {
    "position": {"x": 400.0, "y": 300.0},
    "rotation": 15.0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 150.0,
    "height": 100.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "shape": "rectangle",
    "fillColor": {
      "red": 0.2,
      "green": 0.8,
      "blue": 0.5,
      "alpha": 0.7
    },
    "strokeColor": {
      "red": 0.0,
      "green": 0.0,
      "blue": 0.0,
      "alpha": 1.0
    },
    "strokeWidth": 1.5,
    "cornerRadius": 5.0,
    "points": []
  }
}
```

**Properties:**

| Field | Type | Options | Default | Description |
|-------|------|---------|---------|-------------|
| `shape` | enum | "rectangle", "circle", "ellipse", "triangle", "polygon" | - | Shape type |
| `fillColor` | RGBA | - | - | Interior color (can have alpha=0 for no fill) |
| `strokeColor` | RGBA | - | - | Outline color (can have alpha=0 for no stroke) |
| `strokeWidth` | number | - | 1.0 | Outline thickness |
| `cornerRadius` | number | - | 0 | Corner rounding (rectangle only) |
| `points` | array | - | [] | Vertices for polygon (array of {x, y}) |

**Shape-Specific Notes:**

- **rectangle**: Uses `cornerRadius` for rounded corners
- **circle**: `bounds.width` should equal `bounds.height`
- **ellipse**: Different width/height for oval shape
- **triangle**: Predefined 3-point shape
- **polygon**: Custom vertices defined in `points` array

---

## Type 3: Text

Renders text with configurable font, size, and color.

```json
{
  "id": "text-001",
  "type": "text",
  "zIndex": 3,
  "transform": {
    "position": {"x": 200.0, "y": 150.0},
    "rotation": 0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 250.0,
    "height": 40.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "text": "Important Note",
    "fontSize": 16.0,
    "fontName": "System",
    "fontWeight": "regular",
    "fontStyle": "normal",
    "textColor": {
      "red": 0.0,
      "green": 0.0,
      "blue": 0.0,
      "alpha": 1.0
    },
    "textAlignment": "left",
    "lineSpacing": 1.2,
    "backgroundColor": {
      "red": 1.0,
      "green": 1.0,
      "blue": 1.0,
      "alpha": 0.0
    }
  }
}
```

**Properties:**

| Field | Type | Options | Default | Description |
|-------|------|---------|---------|-------------|
| `text` | string | - | "" | Text content |
| `fontSize` | number | - | 12.0 | Font size in points |
| `fontName` | string | - | "System" | Font family name |
| `fontWeight` | enum | "thin", "light", "regular", "medium", "semibold", "bold", "heavy" | "regular" | Font weight |
| `fontStyle` | enum | "normal", "italic" | "normal" | Font style |
| `textColor` | RGBA | - | - | Text color |
| `textAlignment` | enum | "left", "center", "right", "justify" | "left" | Horizontal alignment |
| `lineSpacing` | number | - | 1.0 | Line spacing multiplier |
| `backgroundColor` | RGBA | - | {1,1,1,0} | Background fill color |

---

## Type 4: Number

Draws a circle with a number inside (for sequential annotations).

```json
{
  "id": "number-001",
  "type": "number",
  "zIndex": 4,
  "transform": {
    "position": {"x": 500.0, "y": 400.0},
    "rotation": 0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 40.0,
    "height": 40.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "number": 5,
    "circleColor": {
      "red": 1.0,
      "green": 0.0,
      "blue": 0.0,
      "alpha": 1.0
    },
    "textColor": {
      "red": 1.0,
      "green": 1.0,
      "blue": 1.0,
      "alpha": 1.0
    },
    "fontSize": 18.0,
    "diameter": 40.0
  }
}
```

**Properties:**

| Field | Type | Range | Default | Description |
|-------|------|-------|---------|-------------|
| `number` | integer | 1-99 | - | Number to display |
| `circleColor` | RGBA | - | - | Circle background color |
| `textColor` | RGBA | - | - | Number text color |
| `fontSize` | number | - | 14.0 | Size of number text |
| `diameter` | number | - | - | Circle diameter in points |

---

## Type 5: Image

Embeds an image annotation (inserted from file or clipboard).

```json
{
  "id": "image-001",
  "type": "image",
  "zIndex": 0,
  "transform": {
    "position": {"x": 600.0, "y": 200.0},
    "rotation": 0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 200.0,
    "height": 150.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "imageSource": {
      "type": "base64",
      "data": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    },
    "opacity": 1.0,
    "blurRadius": 0,
    "cornerRadius": 0
  }
}
```

**Image Source (variant 1: Base64):**

```json
"imageSource": {
  "type": "base64",
  "data": "iVBORw0KGgoAAAANS..."
}
```

**Image Source (variant 2: Filename):**

```json
"imageSource": {
  "type": "filename",
  "path": "assets/inserted-image.png"
}
```

**Properties:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `imageSource` | object | - | Image data or reference |
| `imageSource.type` | enum | - | "base64" or "filename" |
| `imageSource.data` | string | - | Base64-encoded image data (for base64 type) |
| `imageSource.path` | string | - | Relative file path (for filename type) |
| `opacity` | number | 1.0 | Opacity (0.0-1.0) |
| `blurRadius` | number | 0 | Gaussian blur radius in points |
| `cornerRadius` | number | 0 | Corner rounding radius |

---

## Type 6: Freehand

Stores free-form drawing as a series of strokes.

```json
{
  "id": "freehand-001",
  "type": "freehand",
  "zIndex": 2,
  "transform": {
    "position": {"x": 0.0, "y": 0.0},
    "rotation": 0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 800.0,
    "height": 600.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "strokes": [
      {
        "points": [
          {"x": 100.0, "y": 150.0},
          {"x": 101.0, "y": 152.0},
          {"x": 103.0, "y": 155.0},
          {"x": 105.0, "y": 160.0}
        ],
        "strokeColor": {
          "red": 0.0,
          "green": 0.0,
          "blue": 0.0,
          "alpha": 1.0
        },
        "strokeWidth": 3.0
      }
    ],
    "smoothing": 0.5
  }
}
```

**Properties:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `strokes` | array | [] | Array of stroke objects |
| `strokes[].points` | array | - | Array of {x, y} points (in order) |
| `strokes[].strokeColor` | RGBA | - | Color of this stroke |
| `strokes[].strokeWidth` | number | 2.0 | Width of this stroke |
| `smoothing` | number | 0.0 | Smoothing factor (0.0-1.0, Catmull-Rom spline) |

---

## Type 7: Highlight

Semi-transparent colored overlay for highlighting regions.

```json
{
  "id": "highlight-001",
  "type": "highlight",
  "zIndex": 1,
  "transform": {
    "position": {"x": 150.0, "y": 300.0},
    "rotation": 0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 200.0,
    "height": 30.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "highlightColor": {
      "red": 1.0,
      "green": 1.0,
      "blue": 0.0,
      "alpha": 0.4
    },
    "cornerRadius": 3.0
  }
}
```

**Properties:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `highlightColor` | RGBA | - | Highlight color (typically with alpha < 1.0) |
| `cornerRadius` | number | 0 | Optional corner rounding |

---

## Type 8: Blur

Blurs the content beneath it.

```json
{
  "id": "blur-001",
  "type": "blur",
  "zIndex": 10,
  "transform": {
    "position": {"x": 400.0, "y": 150.0},
    "rotation": 0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 150.0,
    "height": 50.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "blurRadius": 10.0,
    "blurStyle": "gaussian"
  }
}
```

**Properties:**

| Field | Type | Options | Default | Description |
|-------|------|---------|---------|-------------|
| `blurRadius` | number | - | 5.0 | Blur strength in points |
| `blurStyle` | enum | "gaussian", "motion", "zoom" | "gaussian" | Type of blur |

---

## Type 9: Note

Sticky note with text.

```json
{
  "id": "note-001",
  "type": "note",
  "zIndex": 6,
  "transform": {
    "position": {"x": 700.0, "y": 200.0},
    "rotation": 0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 120.0,
    "height": 120.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "backgroundColor": {
      "red": 1.0,
      "green": 0.95,
      "blue": 0.2,
      "alpha": 0.9
    },
    "text": "Follow up",
    "fontSize": 12.0,
    "textColor": {
      "red": 0.0,
      "green": 0.0,
      "blue": 0.0,
      "alpha": 1.0
    },
    "shadowOpacity": 0.3
  }
}
```

**Properties:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `backgroundColor` | RGBA | - | Sticky note color |
| `text` | string | "" | Note content |
| `fontSize` | number | 12.0 | Text size |
| `textColor` | RGBA | - | Text color |
| `shadowOpacity` | number | 0.0 | Drop shadow intensity (0.0-1.0) |

---

## Type 10: Group

Container for nested annotations with hierarchical support.

```json
{
  "id": "group-001",
  "type": "group",
  "zIndex": 5,
  "transform": {
    "position": {"x": 500.0, "y": 500.0},
    "rotation": 0,
    "scale": {"x": 1.0, "y": 1.0}
  },
  "bounds": {
    "width": 400.0,
    "height": 300.0
  },
  "locked": false,
  "visible": true,
  "properties": {
    "name": "Review Section",
    "description": "All review-related annotations"
  },
  "children": [
    {
      "id": "line-002",
      "type": "line",
      "zIndex": 6,
      "transform": {
        "position": {"x": 50.0, "y": 50.0},
        "rotation": 0,
        "scale": {"x": 1.0, "y": 1.0}
      },
      "bounds": {"width": 150.0, "height": 0},
      "locked": false,
      "visible": true,
      "properties": {
        "startPoint": {"x": 0.0, "y": 0.0},
        "endPoint": {"x": 150.0, "y": 0.0},
        "strokeColor": {"red": 1.0, "green": 0.0, "blue": 0.0, "alpha": 1.0},
        "strokeWidth": 2.0,
        "lineStyle": "solid",
        "lineCap": "round",
        "lineJoin": "round"
      }
    },
    {
      "id": "text-002",
      "type": "text",
      "zIndex": 7,
      "transform": {
        "position": {"x": 50.0, "y": 100.0},
        "rotation": 0,
        "scale": {"x": 1.0, "y": 1.0}
      },
      "bounds": {"width": 200.0, "height": 30.0},
      "locked": false,
      "visible": true,
      "properties": {
        "text": "Needs revision",
        "fontSize": 14.0,
        "fontName": "System",
        "fontWeight": "bold",
        "fontStyle": "normal",
        "textColor": {"red": 1.0, "green": 0.0, "blue": 0.0, "alpha": 1.0},
        "textAlignment": "left",
        "lineSpacing": 1.0,
        "backgroundColor": {"red": 1.0, "green": 1.0, "blue": 1.0, "alpha": 0.0}
      }
    }
  ]
}
```

**Properties:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | "" | Group label |
| `description` | string | "" | Optional description |

**Children:**

- Groups contain a `children` array with nested annotations
- Children can be any annotation type, including groups (arbitrary nesting)
- When a group is transformed, all children are transformed relative to it
- Child `zIndex` is relative to group's `zIndex` for rendering order

---

## RGBA Color Format

All colors use RGBA with normalized values (0.0-1.0):

```json
{
  "red": 1.0,
  "green": 0.5,
  "blue": 0.0,
  "alpha": 0.8
}
```

| Component | Range | Description |
|-----------|-------|-------------|
| `red` | 0.0-1.0 | Red channel |
| `green` | 0.0-1.0 | Green channel |
| `blue` | 0.0-1.0 | Blue channel |
| `alpha` | 0.0-1.0 | Opacity (0=transparent, 1=opaque) |

**Common Colors:**

| Name | RGBA |
|------|------|
| Black | {0, 0, 0, 1} |
| White | {1, 1, 1, 1} |
| Red | {1, 0, 0, 1} |
| Green | {0, 1, 0, 1} |
| Blue | {0, 0, 1, 1} |
| Yellow | {1, 1, 0, 1} |
| Transparent | {0, 0, 0, 0} |

---

## Coordinate System

- **Origin**: Top-left corner (0, 0)
- **X-axis**: Increases rightward
- **Y-axis**: Increases downward
- **Rotation**: Clockwise from 0-360 degrees, centered on `transform.position`
- **Bounds**: Dimensions are in points (not pixels)

---

## Complete Example: Full Annotation Document

```json
{
  "version": "1.0",
  "metadata": {
    "createdAt": "2025-01-15T10:30:00Z",
    "modifiedAt": "2025-01-15T10:45:00Z",
    "canvasSize": {
      "width": 1920,
      "height": 1080
    },
    "imageFilename": "screenshot.png"
  },
  "annotations": [
    {
      "id": "group-main",
      "type": "group",
      "zIndex": 1,
      "transform": {
        "position": {"x": 100.0, "y": 100.0},
        "rotation": 0,
        "scale": {"x": 1.0, "y": 1.0}
      },
      "bounds": {"width": 600.0, "height": 400.0},
      "locked": false,
      "visible": true,
      "properties": {
        "name": "Review Section",
        "description": "All review annotations"
      },
      "children": [
        {
          "id": "line-red",
          "type": "line",
          "zIndex": 2,
          "transform": {
            "position": {"x": 200.0, "y": 150.0},
            "rotation": 0,
            "scale": {"x": 1.0, "y": 1.0}
          },
          "bounds": {"width": 150.0, "height": 0},
          "locked": false,
          "visible": true,
          "properties": {
            "startPoint": {"x": 0.0, "y": 0.0},
            "endPoint": {"x": 150.0, "y": 0.0},
            "strokeColor": {"red": 1.0, "green": 0.0, "blue": 0.0, "alpha": 1.0},
            "strokeWidth": 2.0,
            "lineStyle": "solid",
            "lineCap": "round",
            "lineJoin": "round"
          }
        },
        {
          "id": "text-urgent",
          "type": "text",
          "zIndex": 3,
          "transform": {
            "position": {"x": 200.0, "y": 180.0},
            "rotation": 0,
            "scale": {"x": 1.0, "y": 1.0}
          },
          "bounds": {"width": 200.0, "height": 30.0},
          "locked": false,
          "visible": true,
          "properties": {
            "text": "Needs revision",
            "fontSize": 14.0,
            "fontName": "System",
            "fontWeight": "bold",
            "fontStyle": "normal",
            "textColor": {"red": 1.0, "green": 0.0, "blue": 0.0, "alpha": 1.0},
            "textAlignment": "left",
            "lineSpacing": 1.0,
            "backgroundColor": {"red": 1.0, "green": 1.0, "blue": 1.0, "alpha": 0.0}
          }
        },
        {
          "id": "number-1",
          "type": "number",
          "zIndex": 4,
          "transform": {
            "position": {"x": 400.0, "y": 150.0},
            "rotation": 0,
            "scale": {"x": 1.0, "y": 1.0}
          },
          "bounds": {"width": 50.0, "height": 50.0},
          "locked": false,
          "visible": true,
          "properties": {
            "number": 1,
            "circleColor": {"red": 0.2, "green": 0.6, "blue": 1.0, "alpha": 1.0},
            "textColor": {"red": 1.0, "green": 1.0, "blue": 1.0, "alpha": 1.0},
            "fontSize": 20.0,
            "diameter": 50.0
          }
        }
      ]
    },
    {
      "id": "highlight-important",
      "type": "highlight",
      "zIndex": 0,
      "transform": {
        "position": {"x": 300.0, "y": 250.0},
        "rotation": 0,
        "scale": {"x": 1.0, "y": 1.0}
      },
      "bounds": {"width": 250.0, "height": 40.0},
      "locked": false,
      "visible": true,
      "properties": {
        "highlightColor": {"red": 1.0, "green": 1.0, "blue": 0.0, "alpha": 0.3},
        "cornerRadius": 2.0
      }
    },
    {
      "id": "note-followup",
      "type": "note",
      "zIndex": 5,
      "transform": {
        "position": {"x": 700.0, "y": 200.0},
        "rotation": 0,
        "scale": {"x": 1.0, "y": 1.0}
      },
      "bounds": {"width": 120.0, "height": 120.0},
      "locked": false,
      "visible": true,
      "properties": {
        "backgroundColor": {"red": 1.0, "green": 0.95, "blue": 0.2, "alpha": 0.9},
        "text": "Follow up on this",
        "fontSize": 12.0,
        "textColor": {"red": 0.0, "green": 0.0, "blue": 0.0, "alpha": 1.0},
        "shadowOpacity": 0.3
      }
    }
  ]
}
```

---

## Validation Rules

1. **Unique IDs**: All `id` values must be unique across entire document
2. **Valid Types**: Type must be one of the defined types
3. **Positive Bounds**: `width` and `height` must be > 0
4. **Valid Transform**: Rotation must be 0-360, scale must be > 0
5. **Color Range**: RGBA values must be 0.0-1.0
6. **No Circular Groups**: Groups cannot contain themselves directly or indirectly
7. **Child Ordering**: Child annotations' `zIndex` is relative within group

---

## Extensibility

Custom annotation types can be added by:

1. Defining a new `type` string
2. Adding custom properties in the `properties` object
3. Documenting the schema for your custom type
4. Handling serialization/deserialization in your parser

Example custom type:

```json
{
  "id": "custom-001",
  "type": "customAnnotationType",
  "zIndex": 7,
  "transform": {...},
  "bounds": {...},
  "locked": false,
  "visible": true,
  "properties": {
    "customField1": "value",
    "customField2": 42,
    "customColor": {"red": 0.5, "green": 0.5, "blue": 0.5, "alpha": 1.0}
  }
}
```

---

## Migration & Versioning

The schema version is stored in `metadata.version`. Future changes should:

1. Increment the minor version for new types/fields (e.g., 1.0 → 1.1)
2. Increment the major version for breaking changes (e.g., 1.0 → 2.0)
3. Parsers should handle multiple versions gracefully
4. Deprecated fields should remain documented for backward compatibility
