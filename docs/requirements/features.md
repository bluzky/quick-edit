# QuickEdit - Feature Requirements

**Document Version:** 1.0
**Last Updated:** December 7, 2025
**Status:** Draft - Awaiting Approval

---

## Overview

This document defines all features and functional requirements for QuickEdit, a lightweight image annotation editor for macOS.

---

## Core Concept

**User Flow:**
1. User loads an image
2. User annotates image using various tools
3. User exports:
   - Final rendered image (PNG/JPG)
   - Structured annotation data (JSON)
   - OR continues editing by reloading annotation data

**Key Principle:** Non-destructive editing - annotations stored separately from original image.

---

## Feature Categories

### P0: Must-Have (MVP - Week 6)
Features required for minimum viable product.

### P1: Should-Have (Final - Week 8)
Features for complete product, added after MVP.

### P2: Nice-to-Have (Post-MVP)
Features for future releases.

---

## P0: Must-Have Features (MVP)

### F001: Image Loading
**Priority:** P0
**Description:** User can load an image file to annotate

**Requirements:**
- Support PNG, JPG, JPEG formats
- File picker dialog for selecting image
- Display image on canvas at appropriate size
- Handle large images (up to 4K resolution)

**Acceptance Criteria:**
- [ ] User clicks "Open Image" button
- [ ] File picker shows only supported formats
- [ ] Selected image displays in canvas
- [ ] Canvas zooms to fit image in window

---

### F002: Select Tool
**Priority:** P0
**Description:** Select, move, and resize existing annotations

**Requirements:**
- Click annotation to select it
- Drag annotation to reposition
- Resize handles on corners/edges
- Visual feedback (selection highlight)
- Deselect by clicking empty space

**Acceptance Criteria:**
- [ ] Clicking annotation shows selection box
- [ ] Dragging moves annotation
- [ ] Corner handles resize proportionally
- [ ] Edge handles resize in one dimension
- [ ] Selection highlight is clearly visible

---

### F003: Line Tool
**Priority:** P0
**Description:** Draw straight lines on image

**Requirements:**
- Click-drag to create line
- Adjustable color (RGB color picker)
- Adjustable width (1-20px)
- Line properties persist when deselected
- Can edit line endpoints after creation

**Properties:**
- `startPoint`: CGPoint
- `endPoint`: CGPoint
- `color`: Hex string (e.g., "#FF0000")
- `width`: Float (1-20)

**Acceptance Criteria:**
- [ ] User selects Line tool from toolbar
- [ ] Click-drag creates line from start to end point
- [ ] Properties panel shows color/width controls
- [ ] Changing color updates line immediately
- [ ] Select tool can reposition line endpoints

---

### F004: Shape Tool (Rectangle)
**Priority:** P0
**Description:** Draw rectangles on image

**Requirements:**
- Click-drag to create rectangle
- Adjustable stroke color and width
- Adjustable fill color (including transparent)
- Properties panel for customization

**Properties:**
- `bounds`: CGRect (x, y, width, height)
- `strokeColor`: Hex string
- `strokeWidth`: Float (0-20)
- `fillColor`: Hex string with alpha (e.g., "#FF000033")

**Acceptance Criteria:**
- [ ] User selects Shape tool, chooses Rectangle
- [ ] Click-drag creates rectangle
- [ ] Stroke and fill colors adjustable
- [ ] Transparent fill supported
- [ ] Can resize/reposition with Select tool

---

### F005: Shape Tool (Circle/Ellipse)
**Priority:** P0
**Description:** Draw circles and ellipses on image

**Requirements:**
- Same as rectangle, but circular shape
- Shift-drag for perfect circle
- Normal drag for ellipse

**Acceptance Criteria:**
- [ ] User selects Shape tool, chooses Circle
- [ ] Click-drag creates ellipse
- [ ] Shift-drag creates perfect circle
- [ ] Same property controls as rectangle

---

### F006: Text Tool
**Priority:** P0
**Description:** Add text annotations to image

**Requirements:**
- Click to place text insertion point
- Type to add text
- Adjustable font family
- Adjustable font size (8-72pt)
- Adjustable color
- Text editable after creation

**Properties:**
- `text`: String
- `position`: CGPoint
- `font`: String (font name)
- `fontSize`: Float (8-72)
- `color`: Hex string

**Acceptance Criteria:**
- [ ] User clicks Text tool, then clicks canvas
- [ ] Text cursor appears, user can type
- [ ] Properties panel shows font/size/color
- [ ] Double-clicking text with Select tool enables editing
- [ ] Text renders anti-aliased and clear

---

### F007: Undo/Redo
**Priority:** P0
**Description:** Undo and redo annotation operations

**Requirements:**
- Undo last action (Cmd+Z)
- Redo undone action (Cmd+Shift+Z)
- Unlimited undo stack (or reasonable limit like 50)
- Undo applies to: add, delete, modify, move, resize

**Acceptance Criteria:**
- [ ] After adding annotation, Cmd+Z removes it
- [ ] After undo, Cmd+Shift+Z restores it
- [ ] Undo stack persists during session
- [ ] Stack clears when new document loaded

---

### F008: Save Annotations to JSON
**Priority:** P0
**Description:** Save annotation data to JSON file

**Requirements:**
- File > Save menu option
- Exports JSON with all annotations
- Includes base image reference (path)
- JSON is human-readable and well-formatted

**Acceptance Criteria:**
- [ ] User clicks "Save" button
- [ ] File picker lets user choose location
- [ ] JSON file created with all annotation data
- [ ] JSON matches documented schema

---

### F009: Load Annotations from JSON
**Priority:** P0
**Description:** Reload previously saved annotation session

**Requirements:**
- File > Open menu option
- Parses JSON and recreates all annotations
- Loads base image if available
- Error handling for invalid JSON

**Acceptance Criteria:**
- [ ] User clicks "Open" button
- [ ] Selects saved JSON file
- [ ] All annotations appear on canvas
- [ ] Base image loads correctly
- [ ] Invalid JSON shows error message

---

### F010: Export Annotated Image
**Priority:** P0
**Description:** Export final image with annotations rendered

**Requirements:**
- File > Export menu option
- Renders base image + all annotations to single PNG
- Same resolution as original image
- High quality rendering

**Acceptance Criteria:**
- [ ] User clicks "Export" button
- [ ] File picker lets user save PNG
- [ ] Exported image includes all visible annotations
- [ ] Image quality matches canvas display
- [ ] Export completes in < 2 seconds for 1080p image

---

## P1: Should-Have Features (Final Release)

### F011: Number Tool
**Priority:** P1
**Description:** Sequential numbered markers with auto-increment

**Requirements:**
- Click to place numbered circle
- Number auto-increments (1, 2, 3, ...)
- Adjustable circle size and colors
- Reset counter option

**Properties:**
- `number`: Int
- `position`: CGPoint
- `circleColor`: Hex string
- `textColor`: Hex string
- `size`: Float (20-60)

**Acceptance Criteria:**
- [ ] First click creates "1", second creates "2", etc.
- [ ] Properties panel shows current number
- [ ] Can manually set number for specific marker
- [ ] Counter persists across session

---

### F012: Free Draw Tool
**Priority:** P1
**Description:** Freehand drawing with path smoothing

**Requirements:**
- Click-drag to draw freehand path
- Path smoothing for natural curves
- Adjustable color and width
- Pressure sensitivity optional

**Properties:**
- `path`: Array of CGPoint
- `color`: Hex string
- `width`: Float (1-20)
- `smoothing`: Float (0-1)

**Acceptance Criteria:**
- [ ] Drag creates smooth curved path
- [ ] Path follows mouse/trackpad accurately
- [ ] No jagged edges on curves
- [ ] Can draw complex shapes

---

### F013: Blur Tool
**Priority:** P1
**Description:** Blur or pixelate regions (for redaction)

**Requirements:**
- Drag to define rectangular region
- Two styles: Gaussian blur, Pixelate
- Adjustable blur radius
- Non-destructive (can remove/edit later)

**Properties:**
- `region`: CGRect
- `blurRadius`: Float (5-50)
- `style`: Enum (blur, pixelate)

**Acceptance Criteria:**
- [ ] Drag creates blur region
- [ ] Blur style selector in properties panel
- [ ] Blur radius adjustable
- [ ] Underlying image not permanently modified

---

### F014: Highlight Tool
**Priority:** P1
**Description:** Semi-transparent highlight over regions

**Requirements:**
- Drag to create rectangular highlight
- Adjustable color and opacity
- Common colors (yellow, green, pink) as presets

**Properties:**
- `region`: CGRect
- `color`: Hex string
- `opacity`: Float (0.2-0.8)

**Acceptance Criteria:**
- [ ] Drag creates semi-transparent overlay
- [ ] Opacity adjustable
- [ ] Preset colors available
- [ ] Doesn't obscure underlying content completely

---

### F015: Note Tool
**Priority:** P1
**Description:** Sticky note annotations with arrow pointers

**Requirements:**
- Click to place note
- Arrow points to target location
- Multi-line text support
- Adjustable note color (like Post-it)

**Properties:**
- `text`: String
- `position`: CGPoint (note location)
- `arrowTarget`: CGPoint (what it points to)
- `noteColor`: Hex string

**Acceptance Criteria:**
- [ ] Click creates note with arrow
- [ ] Arrow endpoint adjustable
- [ ] Multi-line text supported
- [ ] Note visually distinct from canvas

---

### F016: Insert Image Tool
**Priority:** P1
**Description:** Embed additional images as annotations

**Requirements:**
- Select image file to insert
- Image appears as draggable annotation
- Resize while maintaining aspect ratio
- Adjustable opacity

**Properties:**
- `imageData`: Base64 string or file path
- `position`: CGPoint
- `size`: CGSize
- `opacity`: Float (0.1-1.0)

**Acceptance Criteria:**
- [ ] User selects Insert Image tool
- [ ] File picker lets user choose image
- [ ] Image appears on canvas
- [ ] Can resize/reposition like other annotations

---

### F017: Keyboard Shortcuts
**Priority:** P1
**Description:** Keyboard shortcuts for common actions

**Requirements:**
- Cmd+Z: Undo
- Cmd+Shift+Z: Redo
- V: Select tool
- L: Line tool
- R: Rectangle tool
- T: Text tool
- N: Number tool
- Delete/Backspace: Delete selected annotation
- Cmd+D: Duplicate selected annotation
- Arrow keys: Nudge selected annotation 1px

**Acceptance Criteria:**
- [ ] All shortcuts listed above functional
- [ ] Shortcuts shown in menus
- [ ] No conflicts with system shortcuts

---

### F018: Context Menus
**Priority:** P1
**Description:** Right-click menus for annotations

**Requirements:**
- Right-click annotation shows menu
- Options: Delete, Duplicate, Bring to Front, Send to Back
- Copy/Paste support

**Acceptance Criteria:**
- [ ] Right-click shows context menu
- [ ] All menu actions functional
- [ ] Menu doesn't appear when right-clicking empty canvas

---

### F019: Export Multiple Formats
**Priority:** P1
**Description:** Export to JPG in addition to PNG

**Requirements:**
- Export dialog shows format options
- PNG (lossless)
- JPG (quality slider 50-100)

**Acceptance Criteria:**
- [ ] User can choose export format
- [ ] PNG exports lossless
- [ ] JPG quality adjustable
- [ ] File extension matches format

---

## P2: Nice-to-Have Features (Post-MVP)

### F020: Multi-Page Documents
Support annotating multiple images in one document

### F021: Arrow Tool
Dedicated arrow annotation (currently can fake with line tool)

### F022: Crop Tool
Crop base image before annotating

### F023: Layer Management
Manual z-index reordering, layer panel

### F024: Templates
Save/load annotation templates (e.g., "Screenshot Bug Report Template")

### F025: Export to PDF
Vector-based PDF export with selectable text

### F026: Cloud Sync
Save annotations to iCloud or cloud storage

### F027: Collaboration
Multi-user real-time annotation

### F028: iOS/iPadOS Version
Mobile companion app

---

## Non-Functional Requirements

### NFR001: Performance
- Canvas renders at 60 FPS with up to 50 annotations
- Export completes in < 2s for 1080p images
- JSON save/load completes in < 500ms

### NFR002: Usability
- New users can create first annotation within 30 seconds
- Tool switching takes < 1 second
- Properties panel updates immediately (< 100ms)

### NFR003: Reliability
- App doesn't crash during normal operation
- Unsaved work warned before quit
- Invalid JSON files don't crash app

### NFR004: Compatibility
- Works on macOS 26.1+
- Supports standard image formats (PNG, JPG)
- JSON format is forward-compatible (older app can ignore unknown annotation types)

### NFR005: Accessibility
- Keyboard navigation supported
- High contrast mode compatible
- VoiceOver labels for all tools

### NFR006: Extensibility
- Developers can add custom annotation types
- Tool protocol well-documented
- Example custom tool provided

---

## Open Questions

1. **Image Size Limits:** Maximum supported image resolution? (Propose: 8K max)
2. **Annotation Limits:** Maximum annotations per document? (Propose: 500)
3. **File Associations:** Should .quickedit file extension be registered?
4. **Default Export Location:** Same directory as base image, or last-used location?
5. **Tool Persistence:** Should last-selected tool be remembered across sessions?

---

**Approval:**
- [ ] Requirements reviewed
- [ ] Priorities agreed upon
- [ ] Open questions resolved

**Approved by:** _____________
**Date:** _____________
