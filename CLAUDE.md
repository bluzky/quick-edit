# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**quickedit** is a simple, extensible image annotation editor for macOS built with SwiftUI and SwiftData (targeting macOS 26.1). Designed for screenshot annotation and image markup workflows, it provides a non-destructive editing system where annotations are stored as structured data separate from the original image.

### Project Goals

Build a lightweight, standard image editor that:
- Is easy to extend with new annotation tools
- Can be integrated into screenshot apps or standalone image annotation workflows
- Uses a non-destructive editing approach (annotations stored separately from image)
- Exports both structured annotation data and final rendered images

### User Flow

1. **Load Image**: User selects or provides an image to annotate
2. **Edit & Annotate**: User applies annotations using various tools (lines, shapes, text, etc.)
3. **Export**: System can:
   - Save structured annotation data (JSON or similar format)
   - Render final composite image with all annotations applied
   - Reload and continue editing from saved annotation data

## Build Commands

### Building and Running
```bash
# Build the project
xcodebuild -project quickedit.xcodeproj -scheme quickedit -configuration Debug build

# Build for release
xcodebuild -project quickedit.xcodeproj -scheme quickedit -configuration Release build

# Clean build folder
xcodebuild -project quickedit.xcodeproj -scheme quickedit clean
```

### Testing
```bash
# Run all tests
xcodebuild test -project quickedit.xcodeproj -scheme quickedit

# Run unit tests only
xcodebuild test -project quickedit.xcodeproj -scheme quickedit -only-testing:quickeditTests

# Run UI tests only
xcodebuild test -project quickedit.xcodeproj -scheme quickedit -only-testing:quickeditUITests

# Run a specific test
xcodebuild test -project quickedit.xcodeproj -scheme quickedit -only-testing:quickeditTests/quickeditTests/example
```

## Built-in Annotation Tools

The editor provides the following core tools out of the box:

### 1. Select Tool
- Select and manipulate existing annotations on canvas
- Resize annotations (drag corners/edges)
- Reposition annotations (drag to move)
- Multi-selection support

### 2. Line Tool
- Draw straight lines or polylines
- Properties: `color`, `width`, `startPoint`, `endPoint`

### 3. Shape Tool
- Draw geometric shapes (rectangle, circle, ellipse, triangle, etc.)
- Properties: `shapeType`, `strokeColor`, `strokeWidth`, `fillColor`, `bounds`
- Supports shape selection from predefined list

### 4. Text Tool
- Add text annotations
- Properties: `text`, `font`, `fontSize`, `color`, `position`

### 5. Number Tool
- Sequential numbered markers (auto-incrementing)
- Each click adds a circle with current number, increments counter for next
- Properties: `number`, `position`, `circleColor`, `textColor`, `size`

### 6. Insert Image Tool
- Embed additional images as annotations
- Properties: `imageData`, `position`, `size`, `opacity`

### 7. Free Draw Tool
- Freehand drawing/sketching
- Properties: `path` (array of points), `color`, `width`, `smoothing`

### 8. Blur Tool
- Blur/pixelate regions (useful for redacting sensitive info)
- Properties: `region` (rect or path), `blurRadius`, `style` (blur/pixelate)

### 9. Highlight Tool
- Highlight regions with semi-transparent color
- Properties: `region` (rect or path), `color`, `opacity`

### 10. Note Tool
- Sticky note-style annotations with arrow pointers
- Properties: `text`, `position`, `noteColor`, `arrowTarget`

### 11. Undo/Redo
- Full undo/redo stack for all annotation operations
- Implemented at annotation layer, not image layer

## Data Structure

### Annotation Document Format

The core data structure uses a JSON-serializable format for portability and extensibility:

```json
{
  "version": "1.0",
  "baseImage": {
    "path": "path/to/original/image.png",
    "width": 1920,
    "height": 1080,
    "format": "png"
  },
  "metadata": {
    "created": "2025-12-07T12:00:00Z",
    "modified": "2025-12-07T12:30:00Z",
    "author": "username"
  },
  "annotations": [
    {
      "id": "uuid-1",
      "type": "line",
      "zIndex": 0,
      "properties": {
        "startPoint": {"x": 100, "y": 100},
        "endPoint": {"x": 300, "y": 300},
        "color": "#FF0000",
        "width": 3
      }
    },
    {
      "id": "uuid-2",
      "type": "shape",
      "zIndex": 1,
      "properties": {
        "shapeType": "rectangle",
        "bounds": {"x": 50, "y": 50, "width": 200, "height": 100},
        "strokeColor": "#0000FF",
        "strokeWidth": 2,
        "fillColor": "#0000FF33"
      }
    },
    {
      "id": "uuid-3",
      "type": "text",
      "zIndex": 2,
      "properties": {
        "text": "Hello World",
        "position": {"x": 150, "y": 200},
        "font": "Helvetica",
        "fontSize": 24,
        "color": "#000000"
      }
    },
    {
      "id": "uuid-4",
      "type": "number",
      "zIndex": 3,
      "properties": {
        "number": 1,
        "position": {"x": 400, "y": 400},
        "circleColor": "#FF0000",
        "textColor": "#FFFFFF",
        "size": 30
      }
    },
    {
      "id": "uuid-5",
      "type": "freedraw",
      "zIndex": 4,
      "properties": {
        "path": [
          {"x": 10, "y": 10},
          {"x": 15, "y": 20},
          {"x": 25, "y": 30}
        ],
        "color": "#00FF00",
        "width": 2,
        "smoothing": 0.5
      }
    },
    {
      "id": "uuid-6",
      "type": "blur",
      "zIndex": 5,
      "properties": {
        "region": {"x": 100, "y": 100, "width": 150, "height": 50},
        "blurRadius": 10,
        "style": "pixelate"
      }
    },
    {
      "id": "uuid-7",
      "type": "highlight",
      "zIndex": 6,
      "properties": {
        "region": {"x": 200, "y": 200, "width": 300, "height": 100},
        "color": "#FFFF00",
        "opacity": 0.3
      }
    },
    {
      "id": "uuid-8",
      "type": "note",
      "zIndex": 7,
      "properties": {
        "text": "Important note here",
        "position": {"x": 500, "y": 500},
        "noteColor": "#FFFFCC",
        "arrowTarget": {"x": 450, "y": 450}
      }
    }
  ],
  "state": {
    "numberCounter": 2,
    "selectedAnnotationIds": ["uuid-3"],
    "undoStack": [...],
    "redoStack": [...]
  }
}
```

### SwiftData Models

For persistence, define models that mirror this structure:

- `AnnotationDocument`: Top-level document containing base image + annotations list
- `Annotation`: Protocol or base class with `id`, `type`, `zIndex`, `properties`
- Concrete annotation types: `LineAnnotation`, `ShapeAnnotation`, `TextAnnotation`, etc.
- Each type implements `Codable` for JSON serialization

## Extensibility Architecture

### Adding New Tools

The architecture supports adding custom annotation tools through a plugin-like pattern:

1. **Tool Protocol**: Define a `Tool` protocol that all tools conform to
   ```swift
   protocol Tool {
       var id: String { get }
       var name: String { get }
       var icon: String { get }
       func createAnnotation(at point: CGPoint) -> Annotation?
       func handleDrag(annotation: Annotation, from: CGPoint, to: CGPoint)
       func renderProperties() -> some View  // Tool settings UI
   }
   ```

2. **Annotation Protocol**: All annotations conform to base protocol
   ```swift
   protocol Annotation: Identifiable, Codable {
       var id: UUID { get }
       var type: String { get }
       var zIndex: Int { get }
       func render(in context: GraphicsContext) -> some View
       func bounds() -> CGRect
       func contains(point: CGPoint) -> Bool
   }
   ```

3. **Tool Registry**: Central registry of available tools
   ```swift
   class ToolRegistry {
       static let shared = ToolRegistry()
       private var tools: [String: Tool] = [:]

       func register(tool: Tool)
       func tool(for type: String) -> Tool?
       func allTools() -> [Tool]
   }
   ```

4. **Custom Tool Example**:
   ```swift
   // Developer creates custom arrow tool
   struct ArrowTool: Tool {
       var id = "arrow"
       var name = "Arrow"
       var icon = "arrow.right"

       func createAnnotation(at point: CGPoint) -> Annotation? {
           return ArrowAnnotation(startPoint: point)
       }
       // ... implement other methods
   }

   // Register at app startup
   ToolRegistry.shared.register(tool: ArrowTool())
   ```

### Canvas Architecture

- **Canvas View**: SwiftUI view that handles gesture recognition and tool dispatch
- **Renderer**: Converts annotation data to visual representation (for display and export)
- **Command Pattern**: All editing operations (add, delete, modify) wrapped in commands for undo/redo
- **Observable State**: Use `@Observable` or `ObservableObject` for reactive UI updates

## Architecture

### Data Layer - SwiftData
- **Model Container**: Initialized in `quickeditApp.swift` with a shared instance
- **Schema**: Defined with `Schema([Item.self])`
- **Persistence**: Uses `ModelConfiguration` with persistent storage (not in-memory)
- **Data Models**: Located in `quickedit/` directory, decorated with `@Model` macro
- **Model Context**: Injected via environment (`@Environment(\.modelContext)`) in views

### View Layer - SwiftUI
- **App Entry**: `quickeditApp.swift` - Sets up WindowGroup and injects ModelContainer
- **Main View**: `ContentView.swift` - Master-detail NavigationSplitView pattern
- **Data Queries**: Use `@Query` property wrapper to reactively fetch from SwiftData
- **Previews**: Use `.modelContainer(for: Item.self, inMemory: true)` for isolated preview data

### Project Structure

Current structure (to be evolved):
```
quickedit/                      # Main application target
  ├── quickeditApp.swift       # App entry point, ModelContainer setup
  ├── ContentView.swift        # Main UI (to become editor shell)
  ├── Item.swift               # SwiftData model (to become AnnotationDocument)
  └── Assets.xcassets/         # App icons and assets

quickeditTests/                # Unit tests (Swift Testing framework)
quickeditUITests/              # UI tests (XCTest framework)
```

Recommended structure for image editor:
```
quickedit/
  ├── App/
  │   └── quickeditApp.swift          # App entry point
  ├── Models/
  │   ├── AnnotationDocument.swift    # Main document model
  │   ├── Annotation.swift            # Annotation protocol/base
  │   ├── LineAnnotation.swift        # Line annotation implementation
  │   ├── ShapeAnnotation.swift       # Shape annotation implementation
  │   ├── TextAnnotation.swift        # Text annotation implementation
  │   └── ... (other annotation types)
  ├── Tools/
  │   ├── Tool.swift                  # Tool protocol
  │   ├── ToolRegistry.swift          # Tool registration system
  │   ├── SelectTool.swift
  │   ├── LineTool.swift
  │   ├── ShapeTool.swift
  │   └── ... (other tools)
  ├── Views/
  │   ├── EditorView.swift            # Main editor interface
  │   ├── CanvasView.swift            # Interactive canvas
  │   ├── ToolbarView.swift           # Tool selection toolbar
  │   ├── PropertiesPanel.swift       # Tool properties panel
  │   └── AnnotationRenderer.swift    # Annotation rendering
  ├── Services/
  │   ├── ImageLoader.swift           # Image loading service
  │   ├── AnnotationSerializer.swift  # JSON serialization
  │   ├── ImageExporter.swift         # Export to image file
  │   └── UndoManager.swift           # Custom undo/redo logic
  └── Assets.xcassets/
```

### Key Patterns

**SwiftData Integration**:
- ModelContainer is created once in the App struct and injected via `.modelContainer()` modifier
- Views access context through `@Environment(\.modelContext)`
- Use `@Query` for reactive data fetching (automatically updates UI on changes)
- Data operations (insert, delete) are wrapped in `withAnimation` for smooth transitions
- Store `AnnotationDocument` objects with embedded image references and annotation arrays

**Canvas Drawing & Interaction**:
- Use SwiftUI `Canvas` view for rendering annotations efficiently
- Handle gestures with `.gesture()` modifiers (DragGesture, TapGesture, MagnificationGesture)
- Coordinate space conversions between canvas and annotation coordinate systems
- Use `GeometryReader` to track canvas size and scroll position
- Layer annotations using `zIndex` for proper rendering order

**Command Pattern for Undo/Redo**:
- All edits are commands: `AddAnnotationCommand`, `DeleteAnnotationCommand`, `ModifyAnnotationCommand`
- Commands implement `execute()` and `undo()` methods
- Maintain separate undo and redo stacks
- Example:
  ```swift
  protocol Command {
      func execute(on document: AnnotationDocument)
      func undo(on document: AnnotationDocument)
  }
  ```

**Rendering Pipeline**:
- **Display Rendering**: Canvas view renders annotations in real-time using SwiftUI Canvas API
- **Export Rendering**: ImageRenderer creates final composite image
  ```swift
  let renderer = ImageRenderer(content: AnnotatedImageView(document: doc))
  let image = renderer.nsImage  // macOS NSImage
  ```

**Navigation**:
- Main window shows editor canvas with toolbar and properties panel
- Optional document browser for managing multiple annotation projects
- Consider using `NavigationSplitView` for document list + editor

**Testing Frameworks**:
- Unit tests use Swift Testing framework (`import Testing`, `@Test` macro)
- UI tests use XCTest framework (`import XCTest`, `XCTestCase`)
- Test annotation serialization/deserialization with JSON examples
- Test tool behavior with mock canvas interactions

## Development Notes

### Adding New Annotation Types

1. Create new annotation struct/class conforming to `Annotation` protocol
2. Implement required properties: `id`, `type`, `zIndex`
3. Define type-specific properties in a `properties` dict or struct
4. Implement `Codable` for JSON serialization
5. Implement rendering logic in `render()` method
6. Add corresponding tool to create/edit this annotation type
7. Register tool in `ToolRegistry` during app initialization

### Adding New Tools

1. Create new tool struct conforming to `Tool` protocol
2. Define tool metadata: `id`, `name`, `icon` (SF Symbol)
3. Implement `createAnnotation(at:)` for initial placement
4. Implement `handleDrag(annotation:from:to:)` for interactive editing
5. Implement `renderProperties()` for tool settings UI
6. Register tool: `ToolRegistry.shared.register(tool: YourTool())`

### Working with SwiftData

- Store `AnnotationDocument` objects in SwiftData for persistence
- Always perform inserts/deletes through `modelContext`
- Wrap mutations in `withAnimation` for UI consistency
- Use `@Query` for automatic UI updates when documents change
- Preview environments should use `inMemory: true` to avoid polluting production data

### Image Handling

- Load images using `NSImage` (macOS) or `UIImage` (iOS if porting)
- Store image references (file paths/URLs), not raw image data in JSON
- For embedded images in annotations, consider base64 encoding or separate assets folder
- Use `ImageRenderer` to export final composite images
- Consider image size limits and memory management for large screenshots

### Coordinate Systems

- Base image has its own coordinate system (0,0 at top-left, width x height)
- Canvas may have zoom/pan transformations applied
- Always store annotation coordinates in image space, not canvas space
- Convert between spaces using `CGAffineTransform` or custom conversion functions

### Performance Considerations

- Use `Canvas` API for efficient annotation rendering (GPU-accelerated)
- Avoid re-rendering all annotations on every change (use SwiftUI diffing)
- For complex paths (free draw), consider path simplification algorithms
- Lazy-load annotation rendering for documents with many annotations
- Use `@MainActor` for UI-bound operations

## Implementation Requirements & Considerations

### Phase 1: Core Foundation
- [ ] Define `Annotation` protocol and base models
- [ ] Implement `AnnotationDocument` SwiftData model
- [ ] Create JSON serialization/deserialization system
- [ ] Build basic canvas view with image display
- [ ] Implement coordinate system management

### Phase 2: Basic Tools
- [ ] Select tool (selection, move, resize)
- [ ] Line tool
- [ ] Shape tool (rectangle, circle)
- [ ] Text tool
- [ ] Tool registry and switching system

### Phase 3: Advanced Tools
- [ ] Number tool with auto-increment
- [ ] Free draw tool with path smoothing
- [ ] Blur/pixelate tool
- [ ] Highlight tool
- [ ] Note/callout tool
- [ ] Insert image tool

### Phase 4: Editor Features
- [ ] Undo/redo system with command pattern
- [ ] Properties panel for tool settings
- [ ] Toolbar UI with tool icons
- [ ] Keyboard shortcuts
- [ ] Context menus for annotations

### Phase 5: Export & Integration
- [ ] Export to PNG/JPG with annotations rendered
- [ ] Save/load annotation JSON files
- [ ] Import images (file picker, drag & drop)
- [ ] Copy/paste annotations
- [ ] Export structured data API for external use

### Design Decisions to Make

1. **Color Representation**: Use hex strings (#RRGGBB) or SwiftUI Color (requires custom Codable)?
2. **Font Storage**: Store font name strings or full font descriptors?
3. **Image References**: Store absolute paths, relative paths, or embed images?
4. **Undo Stack Limit**: Unlimited or capped (e.g., last 50 actions)?
5. **Multi-page Support**: Single image per document or support for multiple pages?
6. **Export Format**: PNG, PDF, SVG, or multiple formats?
7. **Coordinate Precision**: Float or Double for positions?
8. **Layer Management**: Allow manual z-index reordering or auto-assign based on creation order?

### Extension Points for Developers

Developers can extend the editor by:
1. **Custom Tools**: Implement `Tool` protocol and register
2. **Custom Annotations**: Implement `Annotation` protocol with unique rendering
3. **Custom Exporters**: Add new export formats beyond PNG
4. **Custom Filters**: Add image filters/effects as annotation types
5. **Plugins**: Load tools dynamically from external packages/bundles

### Keyboard Shortcuts (Recommended)

- `Cmd+Z`: Undo
- `Cmd+Shift+Z`: Redo
- `V`: Select tool
- `L`: Line tool
- `R`: Rectangle tool
- `T`: Text tool
- `N`: Number tool
- `Delete/Backspace`: Delete selected annotation
- `Cmd+D`: Duplicate selected annotation
- `Cmd+S`: Save document
- `Cmd+E`: Export image
- `Arrow keys`: Nudge selected annotation

## Build Configuration

- Development Team: 965F2J8B9J
- Bundle Identifier: co.onekg.quickedit
- Swift Version: 5.0
- Deployment Target: macOS 26.1
- Sandbox: Enabled (will need user-selected-files entitlement for image loading)
- Hardened Runtime: Enabled
