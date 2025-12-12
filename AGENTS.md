# AGENTS.md

This file provides guidance for agentic coding agents working in this repository.

## Build/Lint/Test Commands

### Building
```bash
# Build debug
xcodebuild -project quickedit.xcodeproj -scheme quickedit -configuration Debug build

# Build release
xcodebuild -project quickedit.xcodeproj -scheme quickedit -configuration Release build

# Clean
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

# Run specific test
xcodebuild test -project quickedit.xcodeproj -scheme quickedit -only-testing:quickeditTests/testName
```

### Linting/Type Checking
No dedicated linter configured. Use Xcode's built-in Swift compiler for type checking.

## Code Style Guidelines

### File Structure
- Use `// MARK: - Section Name` comments to organize code sections
- Group imports: SwiftUI first, then AppKit, then other frameworks
- Separate constants into private enums (e.g., `UIConstants`, `ValidationConstants`)

### Naming Conventions
- Use camelCase for variables, functions, and methods
- Use PascalCase for types, protocols, and enums
- Use descriptive names: `transform` not `t`, `strokeWidth` not `sw`
- Enum cases: lowercase with underscores if needed (e.g., `topLeft`, `line_diagonal`)

### Code Organization
- Define constants in private enums at the top of files
- Use extensions for utility functions and protocol conformances
- Group related functionality with MARK comments
- Use `private` for implementation details, `internal` for module interfaces

### Types and Safety
- Use `final` classes when inheritance is not needed
- Prefer structs for data models and value types
- Use protocols for abstraction (e.g., `Annotation` protocol)
- Implement input validation with property observers (`didSet`) that clamp values
- Use guard statements for early returns and error handling

### UI and Constants
- No magic numbers: define all dimensions, spacing, and limits as constants
- Use normalized color values (0.0-1.0) for RGBA components
- Group UI constants by feature (toolbar, canvas, color picker, etc.)
- Use `Color(nsColor: .systemColor)` for system colors

### Error Handling
- Use guard statements for precondition checks
- Return optionals for operations that may fail
- Use `fatalError` only for truly unrecoverable errors
- Validate inputs automatically rather than throwing errors

### Reactive Programming
- Use Combine for reactive state management
- Use `@Published` for observable properties
- Use `sink` with proper cancellable storage
- Update UI on main thread with `receive(on: RunLoop.main)`

### Comments and Documentation
- No inline comments unless complex logic requires explanation
- Use descriptive function/variable names instead of comments
- Document protocols and public APIs with doc comments
- Use TODO comments for incomplete implementations

### Imports and Dependencies
- Import only what's needed
- Use `@testable import` for test targets
- Prefer SwiftUI over AppKit when possible
- Use system frameworks appropriately (AppKit for macOS-specific features)

### Testing
- Use Swift Testing framework with `@Test` macro
- Test annotation serialization/deserialization with JSON examples
- Test tool behavior with mock canvas interactions
- Focus on unit tests for model logic and UI tests for interactions</content>
<parameter name="filePath">/Users/flex/workspace/my_rec/quickedit/AGENTS.md