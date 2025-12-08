# Architecture Decision Records (ADR)

This document records key architectural decisions made during QuickEdit development.

**Last Updated:** December 8, 2025

---

## ADR-001: Tool Architecture - Enum vs Protocol-Based

**Status:** ✅ Decided
**Date:** December 8, 2025
**Context:** Phase 1 - UI Foundation

### Decision

Use **enum-based tools** for Phase 1 and Phase 2, with option to refactor to protocol-based tools in Phase 3 if extensibility becomes a requirement.

### Context

Two competing approaches exist for tool architecture:

**Approach A: Protocol-Based Tools** (as documented in `/docs/architecture/tool-system.md`)
```swift
protocol AnnotationTool: AnyObject {
    func onMouseDown(at: CGPoint, on: AnnotationCanvas)
    func settingsPanel() -> some View
    // ...
}
```

**Approach B: Enum-Based Tools** (current implementation in `ContentView.swift`)
```swift
enum AnnotationTool: String, CaseIterable {
    case select, line, shape, text, number, ...
}
```

### Rationale

**Chose Enum-Based for Phase 1-2:**

1. **Simplicity:** Enum approach is simpler for MVP with fixed set of 10 tools
2. **Type Safety:** Enum cases provide compile-time guarantees
3. **SwiftUI Integration:** Easier binding with `@Published var selectedTool: AnnotationTool`
4. **No Dynamic Loading:** MVP doesn't require plugin-style tool loading
5. **Faster Development:** Can iterate faster without protocol overhead

**Protocol-Based Deferred to Phase 3+:**

Will consider protocol-based refactor if:
- Custom tools become a requirement
- Third-party extensions needed
- Tool marketplace planned
- Dynamic tool loading requested

### Consequences

**Positive:**
- ✅ Faster Phase 1/2 development
- ✅ Simpler codebase for MVP
- ✅ Easier to understand for contributors
- ✅ Better Xcode autocomplete and type inference

**Negative:**
- ⚠️ Adding new tools requires code changes (not plugin-based)
- ⚠️ Harder to extend by third parties
- ⚠️ May require refactor if extensibility becomes critical

**Mitigation:**
- Keep tool-specific logic isolated in property structs
- Maintain clear separation between tool enum and tool behavior
- Document protocol-based approach in `/docs/architecture/tool-system.md` for future reference

### Implementation Notes

**Current Structure:**
```swift
// Tool enumeration
enum AnnotationTool: String, CaseIterable {
    case select, freehand, highlight, blur, line, shape, text, number, image, note
}

// Tool-specific properties (one struct per tool)
struct LineProperties { var color: Color; var width: Double; ... }
struct ShapeProperties { var shape: ShapeKind; var fillColor: Color; ... }
// ...

// Centralized view model
class EditorViewModel: ObservableObject {
    @Published var selectedTool: AnnotationTool
    @Published var line = LineProperties()
    @Published var shape = ShapeProperties()
    // ...
}
```

**Benefits of This Structure:**
- Direct property access: `viewModel.line.color`
- No type casting required
- Clear which properties belong to which tool
- Easy to serialize to JSON

**If Protocol-Based Needed Later:**
Can refactor while preserving property structs:
```swift
protocol AnnotationTool {
    associatedtype Properties
    var properties: Properties { get set }
    func settingsPanel() -> some View
}

struct LineTool: AnnotationTool {
    var properties: LineProperties
    func settingsPanel() -> some View { LinePropertiesView(...) }
}
```

---

## ADR-002: Color Representation

**Status:** ✅ Decided
**Date:** December 7, 2025
**Context:** Phase 1 - Data Model

### Decision

Use **RGBA with normalized values (0.0-1.0)** for both UI and JSON storage.

### Context

Need consistent color representation across:
- SwiftUI `Color` for UI
- JSON serialization for file format
- NSColor/CGColor for rendering

### Solution

**CodableColor Wrapper:**
```swift
struct CodableColor: Codable, Hashable {
    var red: Double    // 0.0 to 1.0
    var green: Double  // 0.0 to 1.0
    var blue: Double   // 0.0 to 1.0
    var alpha: Double  // 0.0 to 1.0

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    init(from color: Color) {
        // Convert SwiftUI Color to RGBA via NSColor
        let nsColor = NSColor(color).usingColorSpace(.sRGB)
        // ...
    }
}
```

**JSON Format:**
```json
{
  "strokeColor": {
    "red": 1.0,
    "green": 0.0,
    "blue": 0.0,
    "alpha": 1.0
  }
}
```

### Rationale

**Why RGBA (0-1) instead of hex strings:**
- ✅ Direct mapping to SwiftUI Color components
- ✅ Supports alpha transparency natively
- ✅ No conversion overhead during rendering
- ✅ Easier to interpolate for animations
- ✅ More readable in JSON

**Why not hex (#RRGGBB):**
- ❌ Loses precision for alpha channel (#RRGGBBAA is less common)
- ❌ Requires string parsing
- ❌ Harder to manipulate programmatically

### Consequences

- All color properties in annotation JSON use RGBA object format
- UI uses SwiftUI `Color` with automatic conversion
- Export uses CGColor/NSColor with direct component access

---

## ADR-003: Font Representation

**Status:** ✅ Decided
**Date:** December 8, 2025
**Context:** Phase 1 - Code Quality

### Decision

Use **FontChoice enum** instead of string-based font names.

### Context

Original implementation used strings:
```swift
var fontName: String = "System"  // Fragile!
```

Problems:
- Typos cause runtime errors
- No compile-time validation
- Font might not exist on system

### Solution

```swift
enum FontChoice: String, CaseIterable, Codable {
    case system = "System"
    case sfMono = "SF Mono"
    case georgia = "Georgia"
    // ...

    func nsFont(size: CGFloat) -> NSFont {
        switch self {
        case .system: return .systemFont(ofSize: size)
        case .sfMono: return NSFont(name: "SFMono-Regular", size: size) ?? .systemFont(ofSize: size)
        // ... with fallback for each case
        }
    }
}
```

### Rationale

- ✅ Compile-time safety
- ✅ Autocomplete in Xcode
- ✅ Fallback to system font if unavailable
- ✅ Codable for JSON serialization
- ✅ Easy to add new fonts

### Consequences

- Font selection UI automatically updates when new fonts added
- JSON stores enum raw value (e.g., `"font": "SF Mono"`)
- Font loading never fails (always has fallback)

---

## ADR-004: Input Validation Strategy

**Status:** ✅ Decided
**Date:** December 8, 2025
**Context:** Phase 1 - Code Quality

### Decision

Use **automatic clamping** via `didSet` observers on property structs.

### Context

Need to prevent invalid values (e.g., negative stroke width, font size > 1000).

### Solution

**Validation Constants:**
```swift
private enum ValidationConstants {
    static let strokeWidthRange: ClosedRange<Double> = 0.5...50
    static let fontSizeRange: ClosedRange<Double> = 6...144
    // ...
}
```

**Property Validation:**
```swift
struct LineProperties {
    var width: Double = 2.5 {
        didSet {
            width = width.clamped(to: ValidationConstants.strokeWidthRange)
        }
    }
}
```

**Helper Extension:**
```swift
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
```

### Rationale

**Why automatic clamping:**
- ✅ No need to check before every assignment
- ✅ Invalid values corrected silently
- ✅ Prevents crashes from extreme values
- ✅ Works with both UI sliders and direct property access

**Why didSet instead of willSet:**
- Value already assigned, just clamping after the fact
- Simpler to read and understand

**Why not validation functions:**
- Property access is cleaner: `line.width = 100` (auto-clamped to 50)
- No need to remember to call `validate()` every time

### Consequences

- All numeric properties self-validate
- UI sliders define ranges, but validation is redundant safety layer
- JSON deserialization automatically clamps loaded values
- No runtime errors from out-of-range values

---

## ADR-005: Canvas-Centric Architecture - Separation of UI and Logic

**Status:** ✅ Decided
**Date:** December 8, 2025
**Context:** Phase 1 → Phase 2 Transition

### Decision

Adopt a **canvas-centric architecture** where the `AnnotationCanvas` is the single source of truth and provides APIs for all operations. UI components (toolbars, panels, menus) are independent consumers that call canvas APIs and subscribe to canvas events.

### Context

**Problem:**
Current Phase 1 implementation has tight coupling between UI (ContentView) and logic (EditorViewModel):
- Toolbar directly modifies tool state
- Properties panel directly accesses tool properties
- No clear boundary between presentation and business logic
- Difficult to create custom toolbars or alternative UIs

**Requirements:**
1. Developers should be able to build custom toolbars (floating, context-sensitive, etc.)
2. Canvas should provide tool integration and handle tool behavior
3. UI should be independent and communicate only through canvas APIs
4. Event system for UI to react to canvas changes
5. Support for operations on selected items (arrangement, property editing)

### Solution

**Canvas as Event Source (NOT Listener):**

```
User Action → UI Calls Canvas API → Canvas Updates State → Canvas Emits Event → UI Listens & Reacts
```

**Critical:** Canvas NEVER listens to UI events. Event flow is unidirectional:
- **UI → Canvas:** Commands (API calls like `setActiveTool()`, `selectAnnotations()`)
- **Canvas → UI:** Events (notifications like `$activeTool`, `onAnnotationAdded`)
- No reverse flow. No circular dependencies.

**Key Components:**

1. **Canvas Public API Surface:**
   - Tool Management: `setActiveTool(_:)`, `activeTool`
   - Selection: `selectAnnotations(_:)`, `selectedAnnotationIDs`
   - Properties: `updateProperty(_:value:for:)`
   - Arrangement: `arrange(_:)`, `groupSelected()`
   - History: `undo()`, `redo()`, `canUndo`, `canRedo`
   - State: `zoomLevel`, `panOffset`, `showGrid`, etc.

2. **Event System (Observable/Combine):**
   - `@Observable` for simple state (`activeTool`, `selectedAnnotationIDs`)
   - `PassthroughSubject` for complex events (annotation lifecycle, interactions)
   - Delegate pattern as alternative for custom integrations

3. **Tool Integration:**
   - Tools receive canvas callbacks: `onMouseDown/Drag/Up(at:on:)`
   - Tools mutate state via canvas APIs only (never direct)
   - Canvas handles command wrapping for undo/redo

### Rationale

**Why Canvas-Centric:**
- ✅ Single source of truth for annotation state
- ✅ Enforces consistent behavior across all UIs
- ✅ Enables undo/redo by intercepting all mutations
- ✅ Testable without UI dependencies
- ✅ Clear API contract for third-party extensions

**Why Event System:**
- ✅ Loose coupling between canvas and UI
- ✅ Multiple UIs can observe same canvas
- ✅ UI automatically updates on canvas changes
- ✅ Supports SwiftUI reactive patterns

**Why APIs Instead of Direct Access:**
- ✅ Encapsulation - canvas can validate/transform inputs
- ✅ Command pattern - every mutation = undoable command
- ✅ Versioning - can evolve APIs without breaking UIs
- ✅ Documentation - clear contract for developers

### Consequences

**Positive:**
- ✅ **Extensibility:** Custom toolbars, panels, and UIs without modifying canvas
- ✅ **Testability:** Canvas logic testable without UI, UI testable with mock canvas
- ✅ **Maintainability:** Clear boundaries, changes isolated to components
- ✅ **Flexibility:** Floating toolbars, inspector views, keyboard shortcuts all share APIs
- ✅ **Third-Party Support:** Plugins can register custom tools and subscribe to events

**Negative:**
- ⚠️ **More boilerplate:** APIs require more code than direct property access
- ⚠️ **Learning curve:** Developers must learn canvas API surface
- ⚠️ **Initial complexity:** Event subscription patterns require understanding

**Migration Impact:**
```swift
// Before (Phase 1 - Direct Access)
viewModel.line.color = newColor
viewModel.selectedTool = .line

// After (Phase 2+ - Canvas APIs)
canvas.updateProperty(\.strokeColor, value: newColor, for: selectedIDs)
canvas.setActiveTool(LineTool())

// Before (Phase 1 - Direct Observation)
@Published var selectedTool: AnnotationTool

// After (Phase 2+ - Canvas Events)
canvas.$activeTool.sink { tool in
    // React to change
}
```

### Implementation Plan

**Phase 2 - Foundation:**
1. Create `AnnotationCanvas` class with core APIs
2. Implement basic event system
3. Migrate one toolbar to use canvas APIs
4. Test with existing UI

**Phase 3 - Full API:**
1. Implement all selection/property/arrangement APIs
2. Add comprehensive event coverage
3. Migrate all UI components to canvas APIs
4. Remove direct state access from UI

**Phase 4 - Extension System:**
1. Tool registration system
2. Plugin architecture
3. Third-party toolbar example
4. Documentation for developers

### Documentation

**Primary:** `/docs/architecture/canvas-api-design.md`

Covers:
- Complete API reference (tool, selection, property, arrangement, history, state)
- Event system design (delegates, publishers)
- Tool integration protocol
- UI component integration examples
- Extension points for third-party developers
- Migration guide from Phase 1 to Phase 2+

---

## Future Decisions Pending

### Pending: Persistence Strategy

**Question:** Use SwiftData, FileManager JSON, or hybrid?

**Options:**
1. **SwiftData:** Store `AnnotationDocument` model with Core Data backend
2. **FileManager:** Direct JSON read/write with `Codable`
3. **Hybrid:** SwiftData for app state, JSON for export/import

**Decision:** Deferred to Phase 3
**Blocker:** Need to see file size and performance characteristics first

### Pending: Multi-Page Support

**Question:** Single image per document or support multiple pages?

**Decision:** Deferred to Phase 4 (P2 feature)
**Reasoning:** MVP focuses on single-image annotation

### Pending: Cloud Sync

**Question:** iCloud, CloudKit, or custom backend?

**Decision:** Deferred to post-MVP (P2 feature)
**Reasoning:** Local-first approach for MVP

---

## Decision Process

When making architecture decisions:

1. **Document the question** - What are we trying to solve?
2. **List options** - What are the alternatives?
3. **Analyze tradeoffs** - What are pros/cons of each?
4. **Make decision** - Pick one and document why
5. **Track consequences** - Note what changed as a result
6. **Review periodically** - Revisit if requirements change

**Review Schedule:**
- After each phase completion
- When new major feature requested
- If performance issues arise
- If extensibility becomes requirement

---

**Status:** Living Document
**Maintained by:** Project Lead
**Review Frequency:** Per-phase and on-demand
