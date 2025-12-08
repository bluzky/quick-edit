# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Note:** Project planning, requirements, and architecture design documents are maintained separately in `/docs/`. This file focuses on technical guidance for working with the codebase.
> - Development methodology: `/docs/xdev/`
> - Project master plan: `/docs/plan/master-plan.md`
> - Requirements: `/docs/requirements/`
> - Architecture: `/docs/architecture/`
> - UI/UX design: `/docs/ui_wireframe/`

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

**Testing Frameworks**:
- Unit tests use Swift Testing framework (`import Testing`, `@Test` macro)
- UI tests use XCTest framework (`import XCTest`, `XCTestCase`)
- Test annotation serialization/deserialization with JSON examples
- Test tool behavior with mock canvas interactions

## Data Model & Architecture

**Complete annotation type specification:** `/docs/architecture/annotation-types.md`

This document defines:
- 10 annotation types (line, shape, text, number, image, freehand, highlight, blur, note, group)
- Base structure common to all annotations (id, type, zIndex, transform, bounds, etc.)
- RGBA color format (normalized 0.0-1.0)
- Coordinate system (top-left origin, points not pixels)
- Complete JSON schema with examples
- Validation rules and extensibility guidelines

**Key architectural decisions:**
- RGBA colors use normalized values (0.0-1.0) for SwiftUI compatibility
- Transform system includes position, rotation, and scale for all annotations
- Groups support arbitrary nesting with hierarchical transforms
- Image annotations support both base64 embedding and file references

## Build Configuration

- Development Team: 965F2J8B9J
- Bundle Identifier: co.onekg.quickedit
- Swift Version: 5.0
- Deployment Target: macOS 26.1
- Sandbox: Enabled (will need user-selected-files entitlement for image loading)
- Hardened Runtime: Enabled
