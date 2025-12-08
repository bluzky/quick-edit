# Architecture Documentation

This directory contains all technical architecture and design documents for QuickEdit.

**Last Updated:** December 7, 2025

---

## Documents

### Core Architecture

#### [annotation-types.md](./annotation-types.md)
**Complete annotation type specification**

Defines all 10 annotation types with full JSON schema:
- Line, Shape, Text, Number, Image
- Freehand, Highlight, Blur, Note, Group
- Base structure, transform system, RGBA colors
- Validation rules and extensibility guidelines

**Status:** ✅ Complete

---

#### [tool-system.md](./tool-system.md)
**Tool architecture and implementation guide**

Complete tool system with SwiftUI implementation:
- `AnnotationTool` protocol design
- `ToolManager` for tool registration
- `AnnotationCanvas` with undo/redo
- Example implementations (Select, Line, Shape, Text)
- Custom tool creation guide

**Status:** ✅ Complete (Fixed from draft)

**Key Features:**
- Proper `@Observable` state management
- Direct property binding (no casting)
- Performance optimizations (60 FPS throttling)
- Keyboard shortcuts integration
- Validation and error handling

---

### Design Reviews

#### [tool-system-review.md](./tool-system-review.md)
**Review of original tool system draft**

Documents critical issues found and fixes applied:
- ❌ Broken SwiftUI state management → ✅ Fixed with `@Observable`
- ❌ Type erasure problems → ✅ Removed protocol, use concrete types
- ❌ Missing type definitions → ✅ Added AnnotationCanvas, Transform, etc.
- ❌ Color serialization issues → ✅ Added CodableColor wrapper

---

## Architecture Decisions

### Color Format
- **UI:** SwiftUI `Color` for editing
- **Storage:** RGBA (0.0-1.0 normalized) in JSON
- **Conversion:** `CodableColor` wrapper for Codable conformance

### State Management
- **Tools:** `@Observable` classes (Swift 5.9+)
- **Canvas:** `@Observable` for annotations array
- **Bindings:** Direct `$property` syntax

### Coordinate System
- **Origin:** Top-left (0, 0)
- **Units:** Points (not pixels)
- **Transforms:** Position, rotation, scale for all annotations

### Undo/Redo
- **Pattern:** Command pattern
- **Implementation:** Canvas manages undo/redo stacks
- **Scope:** All annotation operations (add, delete, modify)

### Extensibility
- **Tools:** Register via `ToolManager.register()`
- **Annotations:** Protocol-based, support custom types
- **Groups:** Arbitrary nesting supported

---

## Implementation Phases

### Phase 1: Preparation (Week 1) - Current
- ✅ Annotation types specification
- ✅ Tool system architecture
- ⏳ Canvas architecture (pending)
- ⏳ UI wireframes (pending)

### Phase 2: Frontend (Week 2-3)
- Implement AnnotationCanvas
- Build tool implementations
- Create UI with mock data

### Phase 3: Backend & MVP (Week 4-6)
- Real annotation rendering
- JSON serialization
- File I/O and export

### Phase 4: Polish (Week 7-8)
- Advanced tools
- Performance optimization
- Developer documentation

---

## Key Types Reference

### Annotation Protocol
```swift
protocol Annotation: Identifiable, Codable {
    var id: UUID { get }
    var type: String { get }
    var zIndex: Int { get set }
    var transform: Transform { get set }
    var bounds: CGSize { get set }
    var locked: Bool { get set }
    var visible: Bool { get set }
}
```

### Transform
```swift
struct Transform: Codable {
    var position: CGPoint
    var rotation: CGFloat  // 0-360 degrees
    var scale: CGPoint     // (x, y) scale factors
}
```

### Tool Protocol
```swift
protocol AnnotationTool: AnyObject {
    var id: String { get }
    var name: String { get }
    var icon: String { get }

    func onMouseDown(at: CGPoint, on: AnnotationCanvas)
    func onMouseDrag(to: CGPoint, on: AnnotationCanvas)
    func onMouseUp(at: CGPoint, on: AnnotationCanvas)

    @ViewBuilder
    func settingsPanel() -> some View

    func renderPreview(in: inout GraphicsContext, canvasSize: CGSize)
}
```

---

## Testing Strategy

### Unit Tests
- Annotation serialization/deserialization
- Tool validation logic
- Coordinate transformations
- Color conversions

### Integration Tests
- Tool creates annotations correctly
- Undo/redo works for all operations
- Canvas hit testing
- Selection and manipulation

### UI Tests
- Tool switching
- Annotation creation workflow
- Properties panel updates
- Keyboard shortcuts

---

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Canvas FPS | 60 | Preview rendering throttled |
| Max Annotations | 500+ | With lazy rendering |
| JSON Save | < 500ms | Typical document |
| PNG Export | < 2s | 1920x1080 image |
| Tool Switch | < 100ms | Instant feedback |

---

## Dependencies

### SwiftUI Features
- `@Observable` macro (macOS 14+)
- `Canvas` view for rendering
- `GraphicsContext` for drawing
- `Binding` for two-way data flow

### Frameworks
- SwiftUI (UI layer)
- SwiftData (persistence)
- Combine (reactive updates)
- CoreGraphics (rendering)

---

## Next Steps

1. **Create canvas-architecture.md**
   - Define AnnotationCanvas responsibilities
   - Hit testing algorithm
   - Rendering pipeline
   - Coordinate space conversions

2. **Create ui-architecture.md**
   - Main window layout
   - Toolbar design
   - Properties panel
   - Canvas view integration

3. **Create export-system.md**
   - Image export pipeline
   - JSON serialization details
   - File format specifications
   - Batch export support

---

## Questions & Decisions

### Open Questions
- [ ] Maximum z-index value? (Propose: Int.max)
- [ ] Annotation limit per document? (Propose: 1000)
- [ ] Cached rendering strategy? (Investigate in Phase 2)

### Decided
- ✅ Use RGBA (0.0-1.0) for colors
- ✅ Use @Observable for state management
- ✅ Support arbitrary group nesting
- ✅ Coordinate precision: CGFloat (Double on 64-bit)

---

**Status:** Architecture design in progress
**Completion:** 40% (2 of 5 core documents complete)
**Next Document:** canvas-architecture.md
