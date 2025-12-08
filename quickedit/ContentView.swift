//
//  ContentView.swift
//  quickedit
//
//  Base editor UI with two-tier toolbar layout aligned to tool specs.
//

import SwiftUI
import Combine

// MARK: - Constants

private enum UIConstants {
    // Sheet sizes
    static let colorSheetHeight: CGFloat = 320
    static let settingsSheetHeight: CGFloat = 260

    // Layout spacing
    static let toolbarHorizontalPadding: CGFloat = 12
    static let toolbarVerticalPadding: CGFloat = 8
    static let toolbarSpacing: CGFloat = 16
    static let toolSpacing: CGFloat = 8
    static let propertiesSpacing: CGFloat = 12

    // Button dimensions
    static let buttonHorizontalPadding: CGFloat = 10
    static let buttonVerticalPadding: CGFloat = 8
    static let buttonCornerRadius: CGFloat = 8
    static let presetButtonHorizontalPadding: CGFloat = 8
    static let presetButtonVerticalPadding: CGFloat = 4
    static let presetButtonCornerRadius: CGFloat = 6

    // Color picker
    static let colorCircleSize: CGFloat = 24
    static let colorCircleAdaptiveMinimum: CGFloat = 38
    static let colorCircleSpacing: CGFloat = 10
    static let presetColorCircleSize: CGFloat = 34

    // Canvas placeholder
    static let canvasIconSize: CGFloat = 48
    static let canvasSpacing: CGFloat = 12

    // Value display
    static let valueDisplayWidth: CGFloat = 44
}

// MARK: - Validation Constants

private enum ValidationConstants {
    // Line validation
    static let strokeWidthRange: ClosedRange<Double> = 0.5...50
    static let arrowSizeRange: ClosedRange<Double> = 5...50

    // Shape validation
    static let shapeStrokeWidthRange: ClosedRange<Double> = 0...50

    // Text validation
    static let fontSizeRange: ClosedRange<Double> = 6...144

    // Number validation
    static let numberSizeRange: ClosedRange<Double> = 15...100
    static let numberCounterRange: ClosedRange<Int> = 1...999

    // Freehand validation
    static let freehandWidthRange: ClosedRange<Double> = 0.5...50

    // Highlight validation
    static let highlightOpacityRange: ClosedRange<Double> = 0.0...1.0

    // Blur validation
    static let blurRadiusRange: ClosedRange<Double> = 1...100

    // Note validation
    static let noteFontSizeRange: ClosedRange<Double> = 8...36

    // Image validation
    static let imageOpacityRange: ClosedRange<Double> = 0.0...1.0
}

// MARK: - Extensions

extension Comparable {
    /// Clamp a value to the specified range
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Color Serialization

/// Codable wrapper for SwiftUI Color, storing RGBA values normalized to 0.0-1.0
struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    /// Convert to SwiftUI Color for UI display
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Create from SwiftUI Color (note: extraction is approximate)
    init(from color: Color) {
        // Note: SwiftUI Color doesn't provide direct RGBA extraction
        // This is a simplified approach - in production, use NSColor/UIColor
        #if canImport(AppKit)
        if let nsColor = NSColor(color).usingColorSpace(.sRGB) {
            self.red = Double(nsColor.redComponent)
            self.green = Double(nsColor.greenComponent)
            self.blue = Double(nsColor.blueComponent)
            self.alpha = Double(nsColor.alphaComponent)
        } else {
            // Fallback to opaque black
            self.red = 0
            self.green = 0
            self.blue = 0
            self.alpha = 1
        }
        #else
        // Fallback for other platforms
        self.red = 0
        self.green = 0
        self.blue = 0
        self.alpha = 1
        #endif
    }

    /// Direct initializer with RGBA components
    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Preset colors
    static let black = CodableColor(red: 0, green: 0, blue: 0, alpha: 1)
    static let white = CodableColor(red: 1, green: 1, blue: 1, alpha: 1)
    static let red = CodableColor(red: 1, green: 0, blue: 0, alpha: 1)
    static let green = CodableColor(red: 0, green: 1, blue: 0, alpha: 1)
    static let blue = CodableColor(red: 0, green: 0, blue: 1, alpha: 1)
    static let yellow = CodableColor(red: 1, green: 1, blue: 0, alpha: 1)
    static let clear = CodableColor(red: 0, green: 0, blue: 0, alpha: 0)
}

// MARK: - Font Management

enum FontChoice: String, CaseIterable, Codable {
    case system = "System"
    case sfMono = "SF Mono"
    case sfProRounded = "SF Pro Rounded"
    case helveticaNeue = "Helvetica Neue"
    case georgia = "Georgia"
    case menlo = "Menlo"

    var displayName: String {
        rawValue
    }

    /// Get NSFont with specified size, or fallback to system font
    func nsFont(size: CGFloat) -> NSFont {
        switch self {
        case .system:
            return .systemFont(ofSize: size)
        case .sfMono:
            return NSFont(name: "SFMono-Regular", size: size) ?? .systemFont(ofSize: size)
        case .sfProRounded:
            return NSFont(name: "SFRounded-Regular", size: size) ?? .systemFont(ofSize: size)
        case .helveticaNeue:
            return NSFont(name: "HelveticaNeue", size: size) ?? .systemFont(ofSize: size)
        case .georgia:
            return NSFont(name: "Georgia", size: size) ?? .systemFont(ofSize: size)
        case .menlo:
            return NSFont(name: "Menlo-Regular", size: size) ?? .systemFont(ofSize: size)
        }
    }
}

// MARK: - Annotation Tools

enum AnnotationTool: String, CaseIterable {
    case select, freehand, highlight, blur, line, shape, text, number, image, note

    var label: String {
        switch self {
        case .select: return "Select"
        case .freehand: return "Freehand"
        case .highlight: return "Highlight"
        case .blur: return "Blur"
        case .line: return "Line"
        case .shape: return "Shape"
        case .text: return "Text"
        case .number: return "Number"
        case .image: return "Image"
        case .note: return "Note"
        }
    }

    var systemImage: String {
        switch self {
        case .select: return "cursorarrow"
        case .freehand: return "scribble"
        case .highlight: return "highlighter"
        case .blur: return "drop"
        case .line: return "line.diagonal"
        case .shape: return "square.on.circle"
        case .text: return "textformat"
        case .number: return "number.circle"
        case .image: return "photo"
        case .note: return "note.text"
        }
    }
}

enum ToolCategory {
    case selection, marking, drawing, utility, actions
}

struct MainToolbarItem: Identifiable {
    let id = UUID()
    let tool: AnnotationTool?
    let title: String
    let systemName: String
    let category: ToolCategory
    let action: (() -> Void)?
}

struct LineProperties {
    var color: Color = .black
    var width: Double = 2.5 {
        didSet {
            width = width.clamped(to: ValidationConstants.strokeWidthRange)
        }
    }
    var arrowStart: Bool = false
    var arrowEnd: Bool = false
    var arrowStyle: ArrowStyle = .open
    var arrowSize: Double = 10.0 {
        didSet {
            arrowSize = arrowSize.clamped(to: ValidationConstants.arrowSizeRange)
        }
    }
    var lineStyle: LineStyle = .solid
    var lineCap: LineCap = .round
}

struct ShapeProperties {
    var shape: ShapeKind = .rectangle
    var fillColor: Color = Color.white.opacity(0.5)
    var strokeColor: Color = .black
    var strokeWidth: Double = 2.0 {
        didSet {
            strokeWidth = strokeWidth.clamped(to: ValidationConstants.shapeStrokeWidthRange)
        }
    }
}

struct TextProperties {
    var font: FontChoice = .system
    var fontSize: Double = 16 {
        didSet {
            fontSize = fontSize.clamped(to: ValidationConstants.fontSizeRange)
        }
    }
    var isBold: Bool = false
    var isItalic: Bool = false
    var textColor: Color = .black
    var alignment: TextAlignmentChoice = .left
    var backgroundColor: Color = .clear
}

struct NumberProperties {
    var current: Int = 1 {
        didSet {
            current = current.clamped(to: ValidationConstants.numberCounterRange)
        }
    }
    var circleColor: Color = Color(red: 0.12, green: 0.56, blue: 1.0)
    var numberColor: Color = .white
    var size: Double = 30 {
        didSet {
            size = size.clamped(to: ValidationConstants.numberSizeRange)
        }
    }
    var shapeStyle: NumberShapeStyle = .circle
}

struct FreehandProperties {
    var color: Color = .black
    var width: Double = 3.0 {
        didSet {
            width = width.clamped(to: ValidationConstants.freehandWidthRange)
        }
    }
}

struct HighlightProperties {
    var color: Color = Color.yellow.opacity(0.4)
    var opacity: Double = 0.4 {
        didSet {
            opacity = opacity.clamped(to: ValidationConstants.highlightOpacityRange)
        }
    }
}

struct BlurProperties {
    var radius: Double = 10.0 {
        didSet {
            radius = radius.clamped(to: ValidationConstants.blurRadiusRange)
        }
    }
}

struct NoteProperties {
    var noteColor: Color = Color.yellow.opacity(0.9)
    var textColor: Color = .black
    var font: FontChoice = .system
    var fontSize: Double = 12 {
        didSet {
            fontSize = fontSize.clamped(to: ValidationConstants.noteFontSizeRange)
        }
    }
    var isBold: Bool = false
    var isItalic: Bool = false
    var alignment: TextAlignmentChoice = .left
    var arrowOn: Bool = true
}

struct ImageProperties {
    var opacity: Double = 1.0 {
        didSet {
            opacity = opacity.clamped(to: ValidationConstants.imageOpacityRange)
        }
    }
    var isLocked: Bool = false
    var flipH: Bool = false
    var flipV: Bool = false
}

enum ArrowStyle: String, CaseIterable {
    case open = "Open", filled = "Filled", diamond = "Diamond", circle = "Circle"
}

enum LineStyle: String, CaseIterable {
    case solid = "Solid", dashed = "Dashed", dotted = "Dotted"
}

enum LineCap: String, CaseIterable {
    case butt = "Butt", round = "Round", square = "Square"
}

enum ShapeKind: String, CaseIterable {
    case rectangle = "Rectangle", circle = "Circle", ellipse = "Ellipse", triangle = "Triangle"
}

enum TextAlignmentChoice: String, CaseIterable {
    case left = "Left", center = "Center", right = "Right", justify = "Justify"
}

enum NumberShapeStyle: String, CaseIterable {
    case circle = "Circle", square = "Square", rounded = "Rounded"
}

final class EditorViewModel: ObservableObject {
    @Published var selectedTool: AnnotationTool = .select {
        didSet {
            // Update selectedColor to reflect the current tool's primary color
            syncColorFromTool()
        }
    }
    @Published var snapToGrid: Bool = false
    @Published var alignmentGuides: Bool = true
    @Published var rulers: Bool = false
    @Published var selectedColor: Color = Color.accentColor

    @Published var line = LineProperties()
    @Published var shape = ShapeProperties()
    @Published var text = TextProperties()
    @Published var number = NumberProperties()
    @Published var freehand = FreehandProperties()
    @Published var highlight = HighlightProperties()
    @Published var blur = BlurProperties()
    @Published var note = NoteProperties()
    @Published var image = ImageProperties()

    func resetNumberCounter() {
        number.current = 1
    }

    func incrementNumber() {
        number.current += 1
    }

    func decrementNumber() {
        number.current = max(1, number.current - 1)
    }

    /// Sync selectedColor from the current tool's primary color
    private func syncColorFromTool() {
        switch selectedTool {
        case .freehand:
            selectedColor = freehand.color
        case .highlight:
            selectedColor = highlight.color
        case .line:
            selectedColor = line.color
        case .shape:
            selectedColor = shape.fillColor
        case .text:
            selectedColor = text.textColor
        case .number:
            selectedColor = number.circleColor
        case .note:
            selectedColor = note.noteColor
        case .blur, .select, .image:
            // These tools don't have a primary color
            break
        }
    }

    func applySelectedColor(_ color: Color) {
        selectedColor = color
        switch selectedTool {
        case .freehand:
            freehand.color = color
        case .highlight:
            highlight.color = color
        case .line:
            line.color = color
        case .shape:
            shape.fillColor = color
        case .text:
            text.textColor = color
        case .number:
            number.circleColor = color
        case .image:
            // no-op for now
            break
        case .note:
            note.noteColor = color
        case .blur, .select:
            break
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = EditorViewModel()
    @State private var showingColorSheet = false
    @State private var showingSettingsSheet = false

    var body: some View {
        VStack(spacing: 0) {
            canvasArea
            PropertiesToolbar(viewModel: viewModel)
            MainToolbar(
                viewModel: viewModel,
                onColor: { showingColorSheet = true },
                onUndo: {},
                onRedo: {},
                onSettings: { showingSettingsSheet = true }
            )
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingColorSheet) {
            ColorUtilitySheet(
                selectedColor: $viewModel.selectedColor,
                applyColor: viewModel.applySelectedColor
            )
            .presentationDetents([.height(UIConstants.colorSheetHeight)])
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheet(
                snapToGrid: $viewModel.snapToGrid,
                alignmentGuides: $viewModel.alignmentGuides,
                rulers: $viewModel.rulers
            )
            .presentationDetents([.height(UIConstants.settingsSheetHeight)])
        }
    }

    private var canvasArea: some View {
        ZStack {
            Color(nsColor: .controlBackgroundColor)
            VStack(spacing: UIConstants.canvasSpacing) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: UIConstants.canvasIconSize))
                    .foregroundColor(.secondary)
                Text("Canvas Area")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Select a tool below to configure properties")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Properties Toolbar

struct PropertiesToolbar: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: UIConstants.propertiesSpacing) {
                ToolIndicator(tool: viewModel.selectedTool)
                Divider()
                propertiesContent
                Spacer(minLength: 0)
            }
            .padding(.horizontal, UIConstants.toolbarHorizontalPadding)
            .padding(.vertical, UIConstants.toolbarVerticalPadding)
            .background(Color(nsColor: .separatorColor).opacity(0.1))
            Divider()
        }
    }

    @ViewBuilder
    private var propertiesContent: some View {
        switch viewModel.selectedTool {
        case .select:
            Text("Select objects to view details")
                .foregroundColor(.secondary)
        case .line:
            LinePropertiesView(line: $viewModel.line)
        case .shape:
            ShapePropertiesView(shape: $viewModel.shape)
        case .text:
            TextPropertiesView(text: $viewModel.text)
        case .number:
            NumberPropertiesView(number: $viewModel.number, reset: viewModel.resetNumberCounter, increment: viewModel.incrementNumber, decrement: viewModel.decrementNumber)
        case .freehand:
            FreehandPropertiesView(freehand: $viewModel.freehand)
        case .highlight:
            HighlightPropertiesView(highlight: $viewModel.highlight)
        case .blur:
            BlurPropertiesView(blur: $viewModel.blur)
        case .image:
            ImagePropertiesView(image: $viewModel.image)
        case .note:
            NotePropertiesView(note: $viewModel.note)
        }
    }
}

struct ToolIndicator: View {
    let tool: AnnotationTool

    var body: some View {
        HStack(spacing: UIConstants.toolSpacing) {
            Image(systemName: tool.systemImage)
            Text(tool.label)
                .fontWeight(.semibold)
        }
        .padding(UIConstants.toolbarVerticalPadding)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(UIConstants.buttonCornerRadius)
    }
}

struct LinePropertiesView: View {
    @Binding var line: LineProperties

    var body: some View {
        HStack(spacing: UIConstants.propertiesSpacing) {
            ColorPicker("Color", selection: $line.color, supportsOpacity: true)
                .labelsHidden()
            SliderWithLabel(label: "Width", value: $line.width, range: 0.5...20, step: 0.5)
            SliderWithLabel(label: "Arrow Size", value: $line.arrowSize, range: 5...30, step: 1)
            Toggle("Start", isOn: $line.arrowStart).toggleStyle(.button).padding(.horizontal, UIConstants.presetButtonVerticalPadding)
            Toggle("End", isOn: $line.arrowEnd).toggleStyle(.button).padding(.horizontal, UIConstants.presetButtonVerticalPadding)
            Picker("Arrow Style", selection: $line.arrowStyle) {
                ForEach(ArrowStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            Picker("Line Style", selection: $line.lineStyle) {
                ForEach(LineStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            Picker("Cap", selection: $line.lineCap) {
                ForEach(LineCap.allCases, id: \.self) { cap in
                    Text(cap.rawValue).tag(cap)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

struct ShapePropertiesView: View {
    @Binding var shape: ShapeProperties

    var body: some View {
        HStack(spacing: UIConstants.propertiesSpacing) {
            Picker("Shape", selection: $shape.shape) {
                ForEach(ShapeKind.allCases, id: \.self) { shape in
                    Text(shape.rawValue).tag(shape)
                }
            }
            .pickerStyle(.segmented)
            ColorPicker("Fill", selection: $shape.fillColor, supportsOpacity: true)
                .labelsHidden()
            ColorPicker("Stroke", selection: $shape.strokeColor, supportsOpacity: true)
                .labelsHidden()
            SliderWithLabel(label: "Stroke", value: $shape.strokeWidth, range: 0...20, step: 0.5)
        }
    }
}

struct TextPropertiesView: View {
    @Binding var text: TextProperties

    var body: some View {
        HStack(spacing: UIConstants.propertiesSpacing) {
            Menu {
                ForEach(FontChoice.allCases, id: \.self) { font in
                    Button(font.displayName) {
                        text.font = font
                    }
                }
            } label: {
                Label(text.font.displayName, systemImage: "textformat")
            }
            SliderWithLabel(label: "Size", value: $text.fontSize, range: 8...72, step: 1)
            Toggle("B", isOn: $text.isBold).toggleStyle(.button)
            Toggle("I", isOn: $text.isItalic).toggleStyle(.button)
            ColorPicker("Text", selection: $text.textColor, supportsOpacity: true)
                .labelsHidden()
            Picker("Align", selection: $text.alignment) {
                ForEach(TextAlignmentChoice.allCases, id: \.self) { align in
                    Text(align.rawValue.prefix(1)).tag(align)
                }
            }
            .pickerStyle(.segmented)
            ColorPicker("Background", selection: $text.backgroundColor, supportsOpacity: true)
                .labelsHidden()
        }
    }
}

struct NumberPropertiesView: View {
    @Binding var number: NumberProperties
    let reset: () -> Void
    let increment: () -> Void
    let decrement: () -> Void

    var body: some View {
        HStack(spacing: UIConstants.propertiesSpacing) {
            Text("Current: \(number.current)")
            HStack(spacing: UIConstants.presetButtonVerticalPadding) {
                Button(action: decrement) { Image(systemName: "chevron.left") }
                Button(action: increment) { Image(systemName: "chevron.right") }
            }
            ColorPicker("Circle", selection: $number.circleColor, supportsOpacity: true)
                .labelsHidden()
            ColorPicker("Number", selection: $number.numberColor, supportsOpacity: true)
                .labelsHidden()
            SliderWithLabel(label: "Size", value: $number.size, range: 20...60, step: 1)
            Picker("Shape", selection: $number.shapeStyle) {
                ForEach(NumberShapeStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            Button("Reset Counter", action: reset)
        }
    }
}

struct FreehandPropertiesView: View {
    @Binding var freehand: FreehandProperties

    private let presets: [(String, Double)] = [("Fine", 1), ("Medium", 3), ("Thick", 5), ("Extra", 10)]

    var body: some View {
        HStack(spacing: UIConstants.propertiesSpacing) {
            ColorPicker("Color", selection: $freehand.color, supportsOpacity: true)
                .labelsHidden()
            SliderWithLabel(label: "Width", value: $freehand.width, range: 1...20, step: 0.5)
            HStack(spacing: UIConstants.presetButtonVerticalPadding) {
                ForEach(presets, id: \.0) { preset in
                    Button(preset.0) {
                        freehand.width = preset.1
                    }
                    .padding(.horizontal, UIConstants.presetButtonHorizontalPadding)
                    .padding(.vertical, UIConstants.presetButtonVerticalPadding)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(UIConstants.presetButtonCornerRadius)
                }
            }
        }
    }
}

struct HighlightPropertiesView: View {
    @Binding var highlight: HighlightProperties
    private let presetColors: [Color] = [
        Color.yellow.opacity(0.4),
        Color.green.opacity(0.4),
        Color.pink.opacity(0.4),
        Color.blue.opacity(0.4),
        Color.orange.opacity(0.4)
    ]

    var body: some View {
        HStack(spacing: UIConstants.propertiesSpacing) {
            HStack(spacing: UIConstants.presetButtonCornerRadius) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: UIConstants.colorCircleSize, height: UIConstants.colorCircleSize)
                        .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                        .onTapGesture {
                            highlight.color = color
                        }
                }
            }
            ColorPicker("Custom", selection: $highlight.color, supportsOpacity: true)
                .labelsHidden()
            SliderWithLabel(label: "Opacity", value: $highlight.opacity, range: 0.1...0.9, step: 0.05)
        }
    }
}

struct BlurPropertiesView: View {
    @Binding var blur: BlurProperties

    var body: some View {
        HStack(spacing: UIConstants.propertiesSpacing) {
            SliderWithLabel(label: "Pixelate Radius", value: $blur.radius, range: 1...50, step: 1)
        }
    }
}

struct NotePropertiesView: View {
    @Binding var note: NoteProperties

    var body: some View {
        HStack(spacing: UIConstants.propertiesSpacing) {
            ColorPicker("Note", selection: $note.noteColor, supportsOpacity: true)
                .labelsHidden()
            ColorPicker("Text", selection: $note.textColor, supportsOpacity: true)
                .labelsHidden()
            Menu {
                ForEach(FontChoice.allCases, id: \.self) { font in
                    Button(font.displayName) {
                        note.font = font
                    }
                }
            } label: {
                Label(note.font.displayName, systemImage: "textformat")
            }
            SliderWithLabel(label: "Size", value: $note.fontSize, range: 10...24, step: 1)
            Toggle("B", isOn: $note.isBold).toggleStyle(.button)
            Toggle("I", isOn: $note.isItalic).toggleStyle(.button)
            Picker("Align", selection: $note.alignment) {
                ForEach(TextAlignmentChoice.allCases, id: \.self) { align in
                    Text(align.rawValue.prefix(1)).tag(align)
                }
            }
            .pickerStyle(.segmented)
            Toggle("Arrow", isOn: $note.arrowOn)
        }
    }
}

struct ImagePropertiesView: View {
    @Binding var image: ImageProperties

    var body: some View {
        HStack(spacing: UIConstants.propertiesSpacing) {
            SliderWithLabel(label: "Opacity", value: $image.opacity, range: 0.1...1.0, step: 0.05)
            Toggle("Lock", isOn: $image.isLocked)
            Toggle("Flip H", isOn: $image.flipH)
            Toggle("Flip V", isOn: $image.flipV)
        }
    }
}

struct SliderWithLabel: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1.0

    var body: some View {
        HStack(spacing: UIConstants.toolSpacing) {
            Text(label)
            Slider(value: $value, in: range, step: step)
            Text(String(format: "%.1f", value))
                .foregroundColor(.secondary)
                .frame(width: UIConstants.valueDisplayWidth, alignment: .leading)
        }
    }
}

// MARK: - Utility Sheets

struct ColorUtilitySheet: View {
    @Binding var selectedColor: Color
    let applyColor: (Color) -> Void

    private let presetColors: [Color] = [
        Color.black,
        Color.white,
        Color.red,
        Color.green,
        Color.blue,
        Color.yellow,
        Color.orange,
        Color.pink,
        Color.purple
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color Picker")
                .font(.headline)
            Text("Preset colors")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: UIConstants.colorCircleAdaptiveMinimum), spacing: UIConstants.colorCircleSpacing)], spacing: UIConstants.colorCircleSpacing) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: UIConstants.presetColorCircleSize, height: UIConstants.presetColorCircleSize)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(color == selectedColor ? 0.8 : 0.3), lineWidth: color == selectedColor ? 2 : 1)
                        )
                        .onTapGesture {
                            selectedColor = color
                            applyColor(color)
                        }
                }
            }

            ColorPicker("Custom", selection: $selectedColor, supportsOpacity: true)
                .onChange(of: selectedColor) { _, newValue in
                    applyColor(newValue)
                }

            Spacer()
        }
        .padding()
    }
}

struct SettingsSheet: View {
    @Binding var snapToGrid: Bool
    @Binding var alignmentGuides: Bool
    @Binding var rulers: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
            Toggle("Snap to Grid (8px)", isOn: $snapToGrid)
            Toggle("Alignment Guides", isOn: $alignmentGuides)
            Toggle("Show Rulers", isOn: $rulers)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Main Toolbar

struct MainToolbar: View {
    @ObservedObject var viewModel: EditorViewModel
    let onColor: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onSettings: () -> Void

    private var items: [MainToolbarItem] {
        [
            MainToolbarItem(tool: .select, title: "Select", systemName: "cursorarrow", category: .selection, action: nil),
            MainToolbarItem(tool: .freehand, title: "Freehand", systemName: "scribble", category: .marking, action: nil),
            MainToolbarItem(tool: .highlight, title: "Highlight", systemName: "highlighter", category: .marking, action: nil),
            MainToolbarItem(tool: .blur, title: "Blur", systemName: "drop", category: .marking, action: nil),
            MainToolbarItem(tool: .line, title: "Line", systemName: "line.diagonal", category: .drawing, action: nil),
            MainToolbarItem(tool: .shape, title: "Shape", systemName: "square.on.circle", category: .drawing, action: nil),
            MainToolbarItem(tool: .text, title: "Text", systemName: "textformat", category: .drawing, action: nil),
            MainToolbarItem(tool: .number, title: "Number", systemName: "number.circle", category: .drawing, action: nil),
            MainToolbarItem(tool: .image, title: "Image", systemName: "photo", category: .utility, action: nil),
            MainToolbarItem(tool: .note, title: "Note", systemName: "note.text", category: .utility, action: nil),
            MainToolbarItem(tool: nil, title: "Color", systemName: "paintpalette", category: .utility, action: onColor),
            MainToolbarItem(tool: nil, title: "Undo", systemName: "arrow.uturn.backward", category: .actions, action: onUndo),
            MainToolbarItem(tool: nil, title: "Redo", systemName: "arrow.uturn.forward", category: .actions, action: onRedo),
            MainToolbarItem(tool: nil, title: "Settings", systemName: "gearshape", category: .actions, action: onSettings)
        ]
    }

    var body: some View {
        HStack(spacing: UIConstants.toolbarSpacing) {
            toolbarGroup(title: "Selection", category: .selection)
            toolbarGroup(title: "Marking", category: .marking)
            toolbarGroup(title: "Drawing", category: .drawing)
            toolbarGroup(title: "Utility", category: .utility)
            toolbarGroup(title: "Actions", category: .actions)
        }
        .padding(.horizontal, UIConstants.toolbarHorizontalPadding)
        .padding(.vertical, UIConstants.toolbarVerticalPadding)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder
    private func toolbarGroup(title: String, category: ToolCategory) -> some View {
        HStack(spacing: UIConstants.toolSpacing) {
            ForEach(items.filter { $0.category == category }) { item in
                ToolbarButton(item: item, selectedTool: $viewModel.selectedTool)
            }
        }
    }
}

struct ToolbarButton: View {
    let item: MainToolbarItem
    @Binding var selectedTool: AnnotationTool

    var isSelected: Bool {
        guard let tool = item.tool else { return false }
        return tool == selectedTool
    }

    var body: some View {
        Button {
            if let tool = item.tool {
                selectedTool = tool
            } else {
                item.action?()
            }
        } label: {
            HStack(spacing: UIConstants.presetButtonCornerRadius) {
                Image(systemName: item.systemName)
                Text(item.title)
            }
            .padding(.horizontal, UIConstants.buttonHorizontalPadding)
            .padding(.vertical, UIConstants.buttonVerticalPadding)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(nsColor: .separatorColor).opacity(0.1))
            .foregroundColor(isSelected ? Color.accentColor : .primary)
            .cornerRadius(8)
        }
    }
}

#Preview {
    ContentView()
}
