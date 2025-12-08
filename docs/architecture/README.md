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
**Tool architecture and implementation guide (Protocol-Based Reference)**

Complete tool system with SwiftUI implementation:
- `AnnotationTool` protocol design
- `ToolManager` for tool registration
- `AnnotationCanvas` with undo/redo
- Example implementations (Select, Line, Shape, Text)
- Custom tool creation guide

**Status:** ✅ Complete (Reference Design)
**Note:** Current implementation uses enum-based tools for MVP simplicity. See ADR-001 in architecture-decisions.md

**Key Features:**
- Proper `@Observable` state management
- Direct property binding (no casting)
- Performance optimizations (60 FPS throttling)
- Keyboard shortcuts integration
- Validation and error handling

---

#### [canvas-architecture.md](./canvas-architecture.md)
**Canvas rendering and interaction system**

Complete canvas architecture:
- Coordinate systems (image space vs canvas space)
- Rendering pipeline with z-index layering
- Hit testing algorithms for all annotation types
- Resize handle detection
- Alignment guides and grid snapping
- Zoom/pan implementation
- Command pattern for undo/redo
- Performance optimization strategies

**Status:** ✅ Complete

---

#### [canvas-api-design.md](./canvas-api-design.md)
**Canvas-Centric Architecture - API Design**

**⭐ CRITICAL DESIGN DOCUMENT** for Phase 2+

Complete separation between canvas and UI:
- **Public APIs:** Tool management, selection, properties, arrangement, history
- **Event System:** Observable properties and Combine publishers
- **Tool Integration:** How tools communicate with canvas
- **UI Examples:** Toolbar, properties panel, inspector, menus
- **Extension Points:** Custom tools, event handlers, third-party integration
- **Migration Path:** From Phase 1 tight coupling to Phase 2+ decoupling

**Key Principle:** Canvas owns state. UI calls APIs and subscribes to events.

**Status:** ✅ Complete

---

#### [architecture-decisions.md](./architecture-decisions.md)
**Architecture Decision Records (ADRs)**

Documents key architectural decisions:
- **ADR-001:** Tool Architecture (Enum vs Protocol) - Chose enum for MVP
- **ADR-002:** Color Representation (RGBA 0-1) - CodableColor wrapper
- **ADR-003:** Font Representation - FontChoice enum with fallback
- **ADR-004:** Input Validation - Automatic clamping with didSet
- **ADR-005:** Canvas-Centric Architecture - Separation of UI and logic ⭐ **CRITICAL**

**Status:** ✅ Complete

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

### Canvas-Centric Architecture ⭐ **MOST IMPORTANT**
- **Canvas as Single Source of Truth:** All state lives in `AnnotationCanvas`
- **UI as Thin Layer:** Components call canvas APIs and subscribe to events
- **Clear Separation:** UI never directly modifies canvas state
- **Event System:** Observable properties + Combine publishers for updates
- **See:** ADR-005 in architecture-decisions.md and canvas-api-design.md

### Color Format
- **UI:** SwiftUI `Color` for editing
- **Storage:** RGBA (0.0-1.0 normalized) in JSON
- **Conversion:** `CodableColor` wrapper for Codable conformance

### State Management
- **Phase 1 (Current):** `EditorViewModel` with `@Observable`
- **Phase 2+ (Target):** `AnnotationCanvas` with public APIs
- **Migration:** Gradual transition from direct access to API calls

### Tool Architecture
- **Phase 1-2:** Enum-based tools for MVP simplicity
- **Phase 3+:** Optional protocol-based for extensibility
- **Integration:** Tools use canvas APIs, never direct mutation

### Coordinate System
- **Origin:** Top-left (0, 0)
- **Units:** Points (not pixels)
- **Transforms:** Position, rotation, scale for all annotations

### Undo/Redo
- **Pattern:** Command pattern
- **Implementation:** Canvas intercepts all mutations, wraps in commands
- **Scope:** All annotation operations (add, delete, modify, arrange)

### Extensibility
- **Tools:** Register via `ToolManager.register()` or canvas API
- **UI Components:** Build custom toolbars/panels using canvas APIs
- **Events:** Subscribe to canvas events for custom behavior
- **Plugins:** Third-party extensions via public API surface

---

## Implementation Phases

### Phase 1: Preparation (Week 1) - ✅ COMPLETE
- ✅ Annotation types specification
- ✅ Tool system architecture
- ✅ Canvas architecture
- ✅ UI implementation (with mock canvas)
- ✅ Architecture decision records

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

## Next Steps (Phase 2)

1. **Implement AnnotationCanvas class**
   - Follow canvas-architecture.md specification
   - Basic annotation array management
   - Z-index sorting for rendering
   - Selection state tracking

2. **Implement rendering pipeline**
   - SwiftUI Canvas integration
   - Annotation rendering by type
   - Selection handles display
   - Grid and guides overlay

3. **Add mouse interaction**
   - Tool event handling (onMouseDown/Drag/Up)
   - Hit testing implementation
   - Resize handle detection
   - Drag to move/resize annotations

4. **Create export-system.md** (if time permits in Phase 2)
   - Image export pipeline
   - JSON serialization details
   - File format specifications

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

**Status:** Phase 1 Architecture Complete ✅
**Completion:** 100% (All Phase 1 documents complete)
**Next Phase:** Phase 2 - Frontend Implementation
**Last Updated:** December 8, 2025
