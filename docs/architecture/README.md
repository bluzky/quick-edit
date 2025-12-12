# Architecture Documentation

**Last Updated:** December 12, 2025
**Status:** ✅ Complete and Production-Ready

## Quick Start

Choose your documentation:

1. **[Annotation JSON Structure](01-annotation-json.md)** - Data format for annotations
2. **[Canvas API Reference](02-canvas-api.md)** - Complete API documentation
3. **[Tool Protocol Guide](03-tool-protocol.md)** - How to create and integrate tools

---

## What Is This?

QuickEdit uses a **pure SwiftUI canvas system** for annotation-based image editing. The canvas:
- Stores annotations as structured data (separate from images)
- Provides APIs for creating, editing, and transforming annotations
- Supports full undo/redo with command pattern
- Uses protocol-based tools for different annotation types
- Renders everything with pure SwiftUI (no Canvas/GraphicsContext)

---

## Key Features

✅ **Command Pattern** - All operations undoable
✅ **Protocol-Based Tools** - Easy to add new annotation types
✅ **Unidirectional Data Flow** - Predictable state management
✅ **Pure SwiftUI Rendering** - Sharp, crisp rendering at all zoom levels
✅ **Transform System** - Rotate, scale, flip annotations
✅ **Event Publishers** - React to state changes
✅ **Coordinate Conversion** - Canvas ↔ Image space

---

## Architecture Overview

```
User Interface (ContentView)
        ↓
Canvas APIs (30+ methods)
        ↓
Command Pattern (Undo/Redo)
        ↓
Canvas State (@Published)
        ↓
SwiftUI Views (Pure SwiftUI)
        ↓
Sharp Rendering (No Canvas blur)
```

**Core Files:**
- `AnnotationCanvas.swift` - Model and APIs (584 lines)
- `AnnotationCanvasView.swift` - SwiftUI wrapper (17 lines)
- `SwiftUIAnnotationCanvasView.swift` - Main canvas view (176 lines)
- `CanvasCommand.swift` - Command pattern (8 command types, 581 lines)
- `AnnotationTool.swift` - Tool protocol and implementations (565 lines)

**View Layer:**
- `Views/Annotations/` - ShapeAnnotationView, LineAnnotationView, AnnotationView
- `Views/Selection/` - Selection handles and bounding boxes
- `Views/Canvas/` - GridView, ToolPreviewView, ScrollWheelPanContainer

---

## Current Implementation

### Annotation Types
- ✅ **Shape** - Rectangle, ellipse, rounded rect, diamond, triangle
- ✅ **Line** - Straight lines with arrow heads (4 styles)

### Tools
- ✅ **SelectTool** - Select, deselect, pan canvas, drag to move
- ✅ **ShapeTool** - Draw shapes with live SwiftUI preview
- ✅ **LineTool** - Draw lines/arrows with live SwiftUI preview

### Commands (9 types)
- ✅ AddAnnotationCommand
- ✅ DeleteAnnotationsCommand
- ✅ UpdatePropertiesCommand
- ✅ BatchCommand
- ✅ ArrangeCommand (z-index)
- ✅ AlignCommand (7 modes)
- ✅ DistributeCommand (even spacing)
- ✅ RotateCommand (rotate/flip)
- ✅ MoveAnnotationsCommand (drag to move)

### APIs (30+ methods)
- Lifecycle: `addAnnotation()`, `deleteAnnotations()`, `deleteSelected()`
- History: `undo()`, `redo()`, `clearHistory()`
- Transforms: `rotate90()`, `flipHorizontal()`, `alignCenter()`, `moveAnnotations()`, etc.
- Selection: `selectAnnotations()`, `toggleSelection()`, `clearSelection()`
- Pan/Zoom: `pan()`, `setZoom()`, `setPanOffset()`

---

## SwiftUI Architecture

### Rendering Strategy

**Pure SwiftUI Views** - No Canvas/GraphicsContext rasterization:
- Annotations render with `Shape` protocol (Path, stroke, fill)
- Selection handles use geometric SwiftUI views
- Tool previews use the same views as finished annotations
- All rendering scales perfectly at any zoom level

**Transform Layering:**
```
Container (.scaleEffect + .offset)
    ↓
Annotation Views (image space coordinates)
    ↓
Sharp rendering (no blur)
```

### Key Benefits
- **Sharp rendering** - Vector-based SwiftUI Shapes scale perfectly
- **Consistent preview** - Tool preview = final result (same views)
- **Fixed UI elements** - Selection handles stay constant size (1pt / zoomLevel)
- **Simple code** - Single rendering path, no Canvas duplication

---

## Documentation Map

| Document | Purpose | Audience |
|----------|---------|----------|
| [01-annotation-json.md](01-annotation-json.md) | JSON structure, color format | Backend, Import/Export |
| [02-canvas-api.md](02-canvas-api.md) | API reference, usage examples | UI developers |
| [03-tool-protocol.md](03-tool-protocol.md) | Creating tools, integration | Tool developers |

---

## Common Tasks

### Add a New Annotation Type

1. Read: [01-annotation-json.md](01-annotation-json.md) - JSON structure
2. Implement `Annotation` protocol
3. Create SwiftUI view (e.g., `TextAnnotationView: View`)
4. Add to `AnnotationView` router
5. Create tool (see [03-tool-protocol.md](03-tool-protocol.md))

### Create a New Tool

1. Read: [03-tool-protocol.md](03-tool-protocol.md) - Complete guide
2. Implement `AnnotationTool` protocol
3. Implement `previewView()` to return SwiftUI preview
4. Register in `ToolRegistry`
5. Map to UI in `ContentView.swift`

### Use Canvas APIs

1. Read: [02-canvas-api.md](02-canvas-api.md) - API reference
2. Call methods on `AnnotationCanvas` instance
3. Never mutate state directly
4. All operations are automatically undoable

---

## Code Examples

### Draw Shape
```swift
let shape = ShapeAnnotation(
    zIndex: canvas.annotations.count,
    transform: AnnotationTransform(
        position: CGPoint(x: 100, y: 100),
        scale: CGSize(width: 1, height: 1),
        rotation: .zero
    ),
    size: CGSize(width: 200, height: 150),
    fill: .blue.opacity(0.3),
    stroke: .blue,
    strokeWidth: 2,
    shapeKind: .rounded,
    cornerRadius: 15
)
canvas.addAnnotation(shape)  // Undoable!
```

### Rotate Selected
```swift
canvas.rotate90()      // Rotate 90° clockwise
canvas.undo()         // Undo rotation
canvas.flipHorizontal() // Mirror horizontally
```

### Create Tool with SwiftUI Preview
```swift
final class MyTool: AnnotationTool {
    let id = "my-tool"
    let name = "My Tool"
    let iconName = "star.fill"

    func onMouseDown(at point: CGPoint, on canvas: AnnotationCanvas) {
        // Start drawing
    }

    func onMouseUp(at point: CGPoint, on canvas: AnnotationCanvas) {
        // Create annotation
        canvas.addAnnotation(annotation)
    }

    func previewView(canvas: AnnotationCanvas) -> AnyView {
        // Return SwiftUI view for live preview
        return AnyView(
            MyAnnotationView(annotation: previewAnnotation)
                .opacity(0.7)
        )
    }
}
```

---

## Build Status

✅ **0 errors, 0 warnings**

**Core Files:**
- CanvasCommand.swift: 581 lines (9 command types)
- AnnotationTool.swift: 565 lines (3 tools with SwiftUI previews)
- AnnotationCanvas.swift: 584 lines (30+ APIs)
- SwiftUIAnnotationCanvasView.swift: 176 lines
- AnnotationCanvasView.swift: 17 lines (simple wrapper)

**View Layer:**
- ShapeAnnotationView.swift: 70 lines
- LineAnnotationView.swift: 260 lines (pure SwiftUI Shapes)
- Selection views: 6 files, ~300 lines total

**Total:** ~2,500 lines of canvas + view code

---

## Testing

**Manual Testing:**
- ✅ Shape drawing with live SwiftUI preview
- ✅ Line/arrow drawing with live SwiftUI preview
- ✅ Selection with handles (fixed size at all zoom levels)
- ✅ Drag to move annotations (live preview)
- ✅ Undo/redo for all operations
- ✅ Canvas panning and zooming (sharp at all levels)
- ✅ Grid snapping
- ✅ Transform rendering (rotate/flip/scale)

**Test Coverage:**
- Command pattern (execute/undo/redo)
- Coordinate conversion
- Hit testing
- Tool integration
- SwiftUI rendering

---

## Future Roadmap

**Next Annotation Types:**
- Text annotations (rich text)
- Freehand drawing (pen tool)
- Highlight (translucent markers)
- Blur (privacy masking)
- Image annotations (stickers)

**Next Features:**
- JSON serialization (save/load)
- Multi-selection box (drag rectangle to select)
- Grouping (nested transforms)
- Layers panel
- Text editing

**All infrastructure ready!** Just implement protocols and integrate.

---

## Related Documentation

- **Project Overview:** `/CLAUDE.md`
- **Implementation Plan:** `/docs/implementation-plan.md`
- **Requirements:** `/docs/requirements/`
- **Master Plan:** `/docs/plan/master-plan.md`

---

## Questions?

**For tool development:** See [03-tool-protocol.md](03-tool-protocol.md)
**For API usage:** See [02-canvas-api.md](02-canvas-api.md)
**For data format:** See [01-annotation-json.md](01-annotation-json.md)
