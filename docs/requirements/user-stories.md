# QuickEdit - User Stories

**Document Version:** 1.0
**Last Updated:** December 7, 2025
**Status:** Draft

---

## User Personas

### Persona 1: Sarah - Bug Reporter
**Role:** QA Engineer
**Goal:** Quickly annotate screenshots to report bugs
**Pain Points:**
- Current tools too complex with unnecessary features
- Wants numbered markers to show steps
- Needs to blur sensitive data
- Must share structured data with dev team

### Persona 2: Alex - Developer/Integrator
**Role:** Software Developer
**Goal:** Integrate annotation into screenshot app
**Pain Points:**
- Needs programmatic access to annotation data
- Wants to extend with custom annotation types
- Requires JSON format for easy parsing
- Must be embeddable or callable from other apps

### Persona 3: Jordan - Content Creator
**Role:** Tutorial Creator
**Goal:** Annotate screenshots for blog posts and videos
**Pain Points:**
- Needs arrows, highlights, and text callouts
- Wants professional-looking output
- Must maintain high image quality
- Requires fast workflow

---

## Epic 1: Basic Annotation Workflow

### User Story 1.1: Load Image
**As a** bug reporter
**I want to** quickly load a screenshot
**So that** I can start annotating immediately

**Acceptance Criteria:**
- File > Open or drag-and-drop image
- Supports PNG, JPG formats
- Image appears in canvas ready to annotate
- Canvas auto-zooms to fit window

**Priority:** P0

---

### User Story 1.2: Draw Shapes
**As a** bug reporter
**I want to** draw rectangles and circles around UI elements
**So that** I can highlight problem areas

**Acceptance Criteria:**
- Select Shape tool from toolbar
- Choose rectangle or circle
- Click-drag to create shape
- Adjust stroke color and fill color
- Shape persists on canvas

**Priority:** P0

---

### User Story 1.3: Add Text Labels
**As a** content creator
**I want to** add text annotations
**So that** I can explain what's shown in the screenshot

**Acceptance Criteria:**
- Select Text tool
- Click canvas to place cursor
- Type text
- Change font, size, color
- Text remains editable

**Priority:** P0

---

### User Story 1.4: Move and Resize Annotations
**As a** bug reporter
**I want to** adjust annotation positions after creating them
**So that** I can fix mistakes without starting over

**Acceptance Criteria:**
- Select tool can click to select annotation
- Drag to reposition
- Drag handles to resize
- Visual feedback shows selected item

**Priority:** P0

---

### User Story 1.5: Undo Mistakes
**As a** content creator
**I want to** undo accidental annotations
**So that** I don't have to start over

**Acceptance Criteria:**
- Cmd+Z undoes last action
- Cmd+Shift+Z redoes
- Can undo multiple steps
- Undo works for add, delete, modify

**Priority:** P0

---

## Epic 2: Save and Export

### User Story 2.1: Save Work in Progress
**As a** bug reporter
**I want to** save my annotations and continue later
**So that** I can work on complex bug reports across multiple sessions

**Acceptance Criteria:**
- File > Save creates JSON file
- JSON includes all annotations
- References original image path
- Can reload and continue editing

**Priority:** P0

---

### User Story 2.2: Export Final Image
**As a** content creator
**I want to** export a single image with all annotations
**So that** I can share it in blog posts

**Acceptance Criteria:**
- File > Export creates PNG
- Annotations rendered on image
- Same resolution as original
- High quality output

**Priority:** P0

---

### User Story 2.3: Export Structured Data
**As a** developer integrator
**I want to** export annotations as structured JSON
**So that** my app can programmatically process them

**Acceptance Criteria:**
- JSON format documented
- All annotation types serializable
- JSON includes metadata (created date, author)
- Easy to parse in other languages

**Priority:** P0

---

## Epic 3: Advanced Annotation Tools

### User Story 3.1: Number Steps
**As a** bug reporter
**I want to** add sequential numbered markers
**So that** I can show reproduction steps clearly

**Acceptance Criteria:**
- Select Number tool
- Each click adds next number (1, 2, 3...)
- Numbers are circles with text inside
- Can customize colors and size

**Priority:** P1

---

### User Story 3.2: Free Draw
**As a** content creator
**I want to** draw freehand annotations
**So that** I can circle irregular areas or add custom arrows

**Acceptance Criteria:**
- Select Free Draw tool
- Drag to draw smooth path
- Path follows cursor accurately
- Adjustable color and width

**Priority:** P1

---

### User Story 3.3: Blur Sensitive Data
**As a** bug reporter
**I want to** blur or pixelate sensitive information
**So that** I can share screenshots without exposing private data

**Acceptance Criteria:**
- Select Blur tool
- Drag rectangle over area to blur
- Choose blur or pixelate style
- Blur radius adjustable

**Priority:** P1

---

### User Story 3.4: Highlight Important Areas
**As a** content creator
**I want to** add semi-transparent highlights
**So that** I can emphasize text without obscuring it

**Acceptance Criteria:**
- Select Highlight tool
- Drag to create highlight rectangle
- Choose color (yellow, green, pink presets)
- Adjustable opacity

**Priority:** P1

---

### User Story 3.5: Add Callout Notes
**As a** bug reporter
**I want to** add sticky note annotations with arrows
**So that** I can add detailed comments pointing to specific elements

**Acceptance Criteria:**
- Select Note tool
- Click to place note
- Arrow points to target
- Multi-line text supported
- Adjustable colors

**Priority:** P1

---

### User Story 3.6: Insert Additional Images
**As a** content creator
**I want to** insert small images as annotations
**So that** I can add logos or comparison images

**Acceptance Criteria:**
- Select Insert Image tool
- Choose image file
- Image appears as annotation
- Can resize and reposition

**Priority:** P1

---

## Epic 4: Productivity Features

### User Story 4.1: Keyboard Shortcuts
**As a** power user
**I want to** use keyboard shortcuts for common actions
**So that** I can work faster without reaching for the mouse

**Acceptance Criteria:**
- Cmd+Z/Shift+Z for undo/redo
- V, L, R, T, N for tools
- Delete to remove selected
- Arrow keys to nudge
- All shortcuts documented

**Priority:** P1

---

### User Story 4.2: Quick Delete
**As a** bug reporter
**I want to** right-click to delete annotations
**So that** I can quickly remove mistakes

**Acceptance Criteria:**
- Right-click annotation shows menu
- Delete option removes it
- Also shows Duplicate, Bring to Front options

**Priority:** P1

---

### User Story 4.3: Duplicate Annotations
**As a** content creator
**I want to** duplicate similar annotations
**So that** I can maintain consistent styling

**Acceptance Criteria:**
- Cmd+D duplicates selected annotation
- Duplicate placed slightly offset
- All properties copied
- Can immediately drag to position

**Priority:** P1

---

## Epic 5: Developer Extensibility

### User Story 5.1: Custom Annotation Types
**As a** developer integrator
**I want to** create custom annotation types
**So that** I can add domain-specific annotations

**Acceptance Criteria:**
- Annotation protocol documented
- Example custom annotation provided
- Custom types serialize to JSON
- Custom rendering supported

**Priority:** P1

---

### User Story 5.2: Custom Tools
**As a** developer integrator
**I want to** implement custom tools
**So that** I can extend the editor's capabilities

**Acceptance Criteria:**
- Tool protocol documented
- ToolRegistry allows registration
- Example custom tool provided
- Custom tool appears in toolbar

**Priority:** P1

---

### User Story 5.3: Programmatic API
**As a** developer integrator
**I want to** call QuickEdit functionality from my app
**So that** I can integrate annotation into my workflow

**Acceptance Criteria:**
- Can load image programmatically
- Can add annotations via API
- Can export without showing UI
- API documented with examples

**Priority:** P2 (Post-MVP)

---

## Edge Cases & Error Scenarios

### Edge Case 1: Invalid Image Format
**Scenario:** User tries to open unsupported file (PDF, GIF, etc.)
**Expected:** Error message "Unsupported format. Please use PNG or JPG."

### Edge Case 2: Missing Base Image
**Scenario:** User loads JSON but base image path is invalid
**Expected:** Warning "Base image not found. Continue with annotations only?"

### Edge Case 3: Corrupted JSON
**Scenario:** User loads malformed JSON file
**Expected:** Error message "Invalid annotation file. Cannot load."

### Edge Case 4: Very Large Image
**Scenario:** User loads 8K (7680x4320) image
**Expected:** App loads with warning "Large image may impact performance." Canvas zooms to fit.

### Edge Case 5: Too Many Annotations
**Scenario:** Document has 500+ annotations
**Expected:** Performance warning or pagination/lazy loading

### Edge Case 6: Unsaved Changes
**Scenario:** User tries to quit with unsaved annotations
**Expected:** Dialog "Save changes before quitting? [Save] [Don't Save] [Cancel]"

---

## Success Metrics

### Metric 1: Time to First Annotation
**Target:** < 30 seconds from app launch for new user

### Metric 2: Annotation Creation Speed
**Target:** < 5 seconds per annotation for experienced user

### Metric 3: Tool Switch Speed
**Target:** < 1 second to change tools

### Metric 4: Export Time
**Target:** < 2 seconds for 1080p image

### Metric 5: Error Rate
**Target:** < 1% crash rate during normal usage

---

## Out of Scope (Explicitly Not Included)

1. **Video Annotation:** Only static images supported
2. **Real-time Collaboration:** Single-user only
3. **Cloud Storage:** Local files only
4. **Version History:** No built-in versioning beyond undo
5. **OCR/Text Recognition:** No automatic text detection
6. **AI Features:** No AI-powered blur/highlight suggestions
7. **Mobile App:** macOS desktop only (no iOS/iPadOS)
8. **Web Version:** Native macOS app only

---

**Review Notes:**
- User stories align with personas
- P0 stories cover MVP requirements
- P1 stories complete full product
- Edge cases considered
- Success metrics defined

**Status:** Ready for review
**Next Step:** Architecture design
