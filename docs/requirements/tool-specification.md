# Tool Specification

**Document Version:** 1.0
**Last Updated:** December 7, 2025
**Status:** Complete - Reflects User Preferences

---

## Overview

This document provides complete specifications for all 11 annotation tools in QuickEdit, including:

1. **Tool Purpose** - What the tool does
2. **Interaction Behavior** - How users interact with the tool
3. **Tool Behavior** - Expected behaviors and special features
4. **Customizable Attributes** - User-configurable properties with defaults
5. **Default Attributes** - Default values for each tool

Each specification follows the user preferences gathered and includes mandatory (P0), optional (P1), and advanced (P2) features.

---

## Global Behaviors

- **Snap to Grid (P0):** Toggle in toolbar; default off; 8px grid; applies to move/resize/creation. Persists per document.
- **Alignment Guides (P0):** Toggle in toolbar; default on; show center/edge guides while moving/resizing/creating. Persists per document.
- **Rulers (P1):** Toggle in toolbar; default off; per document.
- **Layering (P0):** New objects insert on top. Commands: Bring to Front/Back and Step Forward/Backward. Lock/Unlock and Hide/Show per object. Layer list (P1).
- **Selection/Handles (P0):** All annotations (except pure undo/redo) show bounding box with 8 resize handles on select; Shift keeps aspect; rotate handle at top-center (except Line/Number).
- **Keyboard (P0):** Esc cancels active creation; Delete/Backspace deletes selection; Cmd/Ctrl+C/V copy/paste; Cmd/Ctrl+D duplicate; Cmd/Ctrl+G group; Shift+G ungroup; Cmd/Ctrl+Z undo; Cmd/Ctrl+Shift+Z redo.
- **Creation & Cancel (P0):** Click-drag to create regions (Shape, Highlight, Blur, Image); click to place base then drag/resize if needed (Text cursor, Number, Note arrow target). Esc cancels while drawing. Undo removes last created object.
- **Undo/Redo (P0):** Global history, 100-step limit, per-action granularity (create, move, resize, text edit, style change). Cmd/Ctrl+Z, Cmd/Ctrl+Shift+Z.

---

## Tool 1: Select Tool

### Purpose
Select, move, resize, and manipulate existing annotations

### Interaction Behavior
- **Selection:** Click annotation to select, click empty space to deselect
- **Selection Handles:** 8 handles appear on selected annotation
  - Corner handles: Resize diagonally (free resize)
  - Edge handles: Resize in one dimension
  - Center handle: Move annotation
  - **Shift + Corner Drag:** Maintain aspect ratio
- **Multi-selection:** Shift-click to select multiple
- **Keyboard:** Arrow keys nudge 1px, Shift+arrows nudge 10px

### Tool Behavior
- **Visual Feedback:** Selected annotation shows bounding box with handles
- **Snap to Grid:** When enabled (global setting), aligns to invisible grid
- **Guides:** Show alignment helpers when moving/resizing (if enabled in global settings)
- **Rulers:** Display canvas measurement rulers (if enabled in global settings)
- **Undo Support:** All moves/resizes are undoable
- **Layer Commands:** Context menu offers Bring to Front/Back, Step Forward/Backward, Lock/Unlock, Hide/Show

### Customizable Attributes
None - Pure selection tool without configurable attributes

---

## Tool 2: Line Tool

### Purpose
Draw straight lines between two points

### Interaction Behavior
- **Creation:** Click to set start point, drag to set end point, release to finish
- **Live Preview:** Line preview follows cursor while dragging
- **End Points:** Small circles indicate start/end while drawing
- **Arrow Placement:** Toggle arrowheads at start/end during creation
- **Cancel:** Esc cancels while dragging; undo removes last segment or last line

### Tool Behavior
- **Straight Only:** Always creates perfectly straight lines
- **Auto-Snap:** 45° angle snapping (no Shift key needed - user preference for "only straight lines")
- **Multiple Segments:** Can create connected lines (P2)
- **Selection:** Bounding box without rotate handle; Shift-resize keeps length scaling proportional

### Customizable Attributes

#### Mandatory (P0)
- **Stroke Color**
  - Type: Color picker
  - Default: Black
  - Transparency: Supported
  - Description: Color of the line

- **Line Width**
  - Type: Slider
  - Range: 0.5 - 20.0 points
  - Default: 2.0 points
  - Presets: Thin (1.0), Medium (2.5), Thick (5.0)

- **Arrow Heads**
  - Type: Toggle switch (for each end)
  - Default: Off
  - Options: Start, End
  - Size: Slider (5 - 30 points)

- **Arrow Style**
  - Type: Segmented control
  - Options:
    - Open (V shape)
    - Filled triangle
    - Diamond
    - Circle
  - Default: Open

#### Optional (P1)
- **Line Style**
  - Type: Segmented control
  - Options: Solid, Dashed, Dotted
  - Default: Solid
  - Dashed pattern: Customizable dash length

- **Line Cap**
  - Type: Segmented control
  - Options: Butt, Round, Square
  - Default: Round

- **Corner Indicators**
  - Type: Toggle switch
  - Default: On
  - Description: Show small circles at start/end points

#### Advanced (P2)
- **Custom Dash Pattern**
  - Type: Array of numbers
  - Description: Define custom dash patterns
  - Example: [10, 5, 2, 5] for dash-dot-dot

- **Measurement Display**
  - Type: Toggle switch
  - Default: Off
  - Shows: Length in pixels, inches, or cm

- **Angle Display**
  - Type: Toggle switch
  - Default: Off
  - Description: Show angle of line

---

## Tool 3: Shape Tool

### Purpose
Draw geometric shapes (rectangle, circle, ellipse, triangle, polygon)

### Interaction Behavior
- **Creation:** Click and drag from corner to opposite corner (corner-based drawing)
- **Shape Selection:** Visual grid of available shapes with previews
- **Recent Shapes:** Shows last 5 shapes used for quick access
- **Live Preview:** Shape preview while dragging
- **Cancel:** Esc cancels during drag; undo removes last created shape

### Tool Behavior
- **Corner-Based:** Click point becomes top-left corner
- **Aspect Ratio:** press shift while dragging to lock aspect ratio
- **Shape Memory:** Remembers last used shape for next tool activation
- **Selection:** Bounding box with rotate handle; Shift-resize keeps aspect ratio

### Customizable Attributes

#### Mandatory (P0)
- **Shape Type**
  - Type: Visual grid selector
  - Options: Rectangle, Circle, Ellipse, Triangle
  - Default: Rectangle
  - Recent shapes: Remember last 5 used

- **Fill Color**
  - Type: Color picker
  - Default: White with 50% opacity
  - Transparency: Supported
  - Option: No fill

- **Stroke Color**
  - Type: Color picker
  - Default: Black
  - Option: No stroke

- **Stroke Width**
  - Type: Slider
  - Range: 0 - 20 points
  - Default: 2.0 points


---

## Tool 4: Text Tool

### Purpose
Add and edit text annotations with formatting

### Interaction Behavior
- **Creation:** Click to place text cursor, type text inline
- **Editing:** Double-click existing text to edit with rich editor
- **In-Place Editor:** Rich text editor appears with formatting toolbar
- **Text Input:** Support for multi-line text with auto-resize
- **Cancel:** Esc cancels placement if text not committed; undo removes last created text box

### Tool Behavior
- **Rich Editing:** Full formatting toolbar appears when editing
- **Auto-Save:** Text automatically saved as user types
- **Validation:** Cannot create empty text (allows placeholder only)
- **Auto-Position:** Text field size adjusts based on content
- **Box Resize:** Drag handles to resize text box; text wraps by default; overflow auto-expands height
- **Rotation:** Rotate handle available; Shift locks to 15° increments

### Customizable Attributes on tool bar

#### Mandatory (P0)
- **Font Family**
  - Type: Dropdown
  - Default: System Font
  - Options: All system fonts

- **Font Size**
  - Type: Slider
  - Range: 8 - 72 points
  - Default: 16 points

- **Bold toggle**
- **Italic toggle**

- **Text Color**
  - Type: Color picker
  - Default: Black

- **Alignment**
  - Type: Segmented control
  - Options: Left, Center, Right, Justify
  - Default: Left

- **Background Color**
  - Type: Color picker
  - Default: Transparent
  - Description: Text background highlight


---

## Tool 5: Number Tool

### Purpose
Create numbered markers with auto-increment

### Interaction Behavior
- **Placement:** Click to place marker at cursor; Shift+drag after placement repositions before commit
- **Cancel:** Esc cancels placement; undo removes last marker

### Tool Behavior
- **Auto-Increment:** Counter increases per marker per document; undo decrements count
- **Collision Warning:** Warn if overlapping another number; still allows placement
- **Selection:** Bounding box resize scales circle and font proportionally; no rotate handle

### Customizable Attributes

#### Mandatory (P0)
- **Circle Color**
  - Type: Color picker
  - Default: Blue (#1E90FF)
  - Presets: Red, Green, Blue, Yellow, Black

- **Number Color**
  - Type: Color picker
  - Default: White
  - Description: Text color inside circle

- **Size (circle and font fix ratio)**
  - Type: Slider
  - Range: 20 - 60 points
  - Default: 30 points
  - Presets: Small (25), Medium (35), Large (45)


- **Reset Counter**
  - Type: Button
  - Description: Reset to 1

- **Shape Style**
  - Type: Segmented control
  - Options: Circle, Square, Rounded Square
  - Default: Circle


---

## Tool 6: Freehand Tool

### Purpose
Draw freeform paths

### Interaction Behavior
- **Creation:** Click-drag to draw; stroke follows cursor with live preview
- **Cancel:** Esc cancels current stroke; undo removes last stroke

### Tool Behavior
- **Selection:** Bounding box with rotate handle; Shift-resize scales uniformly

### Customizable Attributes

#### Mandatory (P0)
- **Stroke Color**
  - Type: Color picker
  - Default: Black
  - Transparency: Supported

- **Line Width**
  - Type: Slider
  - Range: 1 - 20 points
  - Default: 3 points
  - Presets: Fine (1), Medium (3), Thick (5), Extra (10)

---

## Tool 7: Blur Tool

### Purpose
Blur regions of the image

### Interaction Behavior
- **Creation:** Click-drag to paint blur area freehand
- **Cancel:** Esc cancels while drawing; undo removes last blur paint pass

### Tool Behavior
- **Selection:** Bounding box with rotate handle; Shift-resize scales uniformly
- **Motion Blur Angle:** Angle slider appears when Motion style is selected

### Customizable Attributes

#### Mandatory (P0)
- **Blur Radius**
  - Type: Slider
 - Range: 1 - 50 points
 - Default: 10 points
 - Live preview: Yes

- **Blur Style**
  - Type: Segmented control
  - Options: Gaussian, Pixelate, Motion
  - Default: Gaussian
---

## Tool 8: Highlight Tool

### Purpose
Add semi-transparent colored overlays

### Interaction Behavior
- **Creation:** Click-drag to paint highlight freehand
- **Cancel:** Esc cancels while drawing; undo removes last highlight paint pass

### Tool Behavior
- **Selection:** Bounding box with rotate handle; Shift-resize scales uniformly

### Customizable Attributes

#### Mandatory (P0)
- **Highlight Color**
  - Type: Color picker with presets
  - Presets: Yellow, Green, Pink, Blue, Orange
  - Default: Yellow
  - Default alpha: 40%

- **Opacity**
  - Type: Slider
  - Range: 10% - 90%
  - Default: 40%

---

## Tool 9: Note Tool

### Purpose
Create sticky note-style annotations with arrows

### Interaction Behavior
- **Placement:** Click target to anchor arrow tip; drag to position note body before release
- **Edit:** Double-click to edit text inline
- **Cancel:** Esc cancels placement; undo removes last note

### Tool Behavior
- **Arrow:** Origin snaps to closest note edge; head updates as note moves; arrow can be toggled on/off
- **Selection:** Bounding box with rotate handle; Shift-resize keeps aspect; text wraps by default
- **Contrast:** Auto-adjust text color for readability on selected note color

### Customizable Attributes

#### Mandatory (P0)
- **Note Color**
  - Type: Color preset selector
  - Presets: Yellow, Pink, Blue, Green, White
  - Default: Yellow
  - Default alpha: 90%

- **Text Color**
  - Type: Color picker
  - Default: Black
  - Auto-adjust: Based on note background

- **Font Size**
  - Type: Slider
  - Range: 10 - 24 points
  - Default: 12 points

- **Font Family**
  - Type: Dropdown
  - Default: System Font
  - Options: All system fonts

- **Bold toggle**
- **Italic toggle**

- **Alignment**
  - Type: Segmented control
  - Options: Left, Center, Right, Justify
  - Default: Left

- **Arrow Target**
  - Auto-detected from first click
  - Note positioned automatically beside target
 
- **Arrow Toggle**
  - Type: Toggle switch
  - Default: On

---

## Tool 10: Image Tool

### Purpose
Insert images as annotations

### Interaction Behavior
- **Placement:** Click-drag to set bounds; image scales to fit while maintaining aspect ratio
- **Cancel:** Esc cancels placement; undo removes last image

### Tool Behavior
- **Selection:** Bounding box with rotate handle; Shift-resize locks aspect ratio
- **Transforms:** Flip horizontal/vertical buttons; lock toggle prevents edits/moves

### Customizable Attributes

#### Mandatory (P0)
- **Opacity**
  - Type: Slider
  - Range: 10% - 100%
  - Default: 100%

- **Lock**
  - Type: Toggle switch
  - Default: Off

#### Optional (P1)
- **Flip Horizontal / Flip Vertical**
  - Type: Buttons

---

## Tool 11: Undo/Redo System

### Purpose
Provide editing safety by reverting or reapplying recent actions across all tools

### Tool Behavior
- **Scope:** All actions are undoable/redoable: create, delete, move, resize, rotate, text edits, style changes, grouping, layer changes
- **History Depth:** 100 steps; discards oldest when limit reached
- **Granularity:** Per-action granularity; continuous drags commit on mouse up
- **Commands:** Cmd/Ctrl+Z undo; Cmd/Ctrl+Shift+Z redo
- **State Persistence:** History is in-session only; clearing document resets history; not persisted between sessions

---

---

## Attribute Categories Summary

### Visual Properties (All Tools)
- Colors with transparency
- Line widths, sizes, dimensions
- Opacity and blend modes
- Corner radius, edge styles

### Text Properties
- Font family, size, weight, style
- Alignment and spacing
- Colors and backgrounds

### Behavior Properties
- Tool-specific behaviors
- Interaction modes
- Auto-detection features

### Performance Properties
- Quality vs speed trade-offs
- Optimization options
- Cache settings

---

**Document Status:** ✅ Complete
**Reflects:** All user preferences gathered
**Next:** Use in UI design and implementation
