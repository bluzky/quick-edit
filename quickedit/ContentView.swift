//
//  ContentView.swift
//  quickedit
//
//  Base editor UI with two-tier toolbar layout aligned to tool specs.
//

import SwiftUI
import Combine

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
    var width: Double = 2.5
    var arrowStart: Bool = false
    var arrowEnd: Bool = false
    var arrowStyle: ArrowStyle = .open
    var arrowSize: Double = 10.0
    var lineStyle: LineStyle = .solid
    var lineCap: LineCap = .round
}

struct ShapeProperties {
    var shape: ShapeKind = .rectangle
    var fillColor: Color = Color.white.opacity(0.5)
    var strokeColor: Color = .black
    var strokeWidth: Double = 2.0
}

struct TextProperties {
    var fontName: String = "System"
    var fontSize: Double = 16
    var isBold: Bool = false
    var isItalic: Bool = false
    var textColor: Color = .black
    var alignment: TextAlignmentChoice = .left
    var backgroundColor: Color = .clear
}

struct NumberProperties {
    var current: Int = 1
    var circleColor: Color = Color(red: 0.12, green: 0.56, blue: 1.0)
    var numberColor: Color = .white
    var size: Double = 30
    var shapeStyle: NumberShapeStyle = .circle
}

struct FreehandProperties {
    var color: Color = .black
    var width: Double = 3.0
}

struct HighlightProperties {
    var color: Color = Color.yellow.opacity(0.4)
    var opacity: Double = 0.4
}

struct BlurProperties {
    var radius: Double = 10.0
}

struct NoteProperties {
    var noteColor: Color = Color.yellow.opacity(0.9)
    var textColor: Color = .black
    var fontName: String = "System"
    var fontSize: Double = 12
    var isBold: Bool = false
    var isItalic: Bool = false
    var alignment: TextAlignmentChoice = .left
    var arrowOn: Bool = true
}

struct ImageProperties {
    var opacity: Double = 1.0
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
    @Published var selectedTool: AnnotationTool = .select
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
            .presentationDetents([.height(320)])
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheet(
                snapToGrid: $viewModel.snapToGrid,
                alignmentGuides: $viewModel.alignmentGuides,
                rulers: $viewModel.rulers
            )
            .presentationDetents([.height(260)])
        }
    }

    private var canvasArea: some View {
        ZStack {
            Color(nsColor: .controlBackgroundColor)
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 48))
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
            HStack(spacing: 12) {
                ToolIndicator(tool: viewModel.selectedTool)
                Divider()
                propertiesContent
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
        HStack(spacing: 8) {
            Image(systemName: tool.systemImage)
            Text(tool.label)
                .fontWeight(.semibold)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct LinePropertiesView: View {
    @Binding var line: LineProperties

    var body: some View {
        HStack(spacing: 12) {
            ColorPicker("Color", selection: $line.color, supportsOpacity: true)
                .labelsHidden()
            SliderWithLabel(label: "Width", value: $line.width, range: 0.5...20, step: 0.5)
            SliderWithLabel(label: "Arrow Size", value: $line.arrowSize, range: 5...30, step: 1)
            Toggle("Start", isOn: $line.arrowStart).toggleStyle(.button).padding(.horizontal, 4)
            Toggle("End", isOn: $line.arrowEnd).toggleStyle(.button).padding(.horizontal, 4)
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
        HStack(spacing: 12) {
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
        HStack(spacing: 12) {
            Menu {
                Button("System") { text.fontName = "System" }
                Button("SF Mono") { text.fontName = "SF Mono" }
                Button("Georgia") { text.fontName = "Georgia" }
            } label: {
                Label(text.fontName, systemImage: "textformat")
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
        HStack(spacing: 12) {
            Text("Current: \(number.current)")
            HStack(spacing: 4) {
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
        HStack(spacing: 12) {
            ColorPicker("Color", selection: $freehand.color, supportsOpacity: true)
                .labelsHidden()
            SliderWithLabel(label: "Width", value: $freehand.width, range: 1...20, step: 0.5)
            HStack(spacing: 4) {
                ForEach(presets, id: \.0) { preset in
                    Button(preset.0) {
                        freehand.width = preset.1
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
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
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
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
        HStack(spacing: 12) {
            SliderWithLabel(label: "Pixelate Radius", value: $blur.radius, range: 1...50, step: 1)
        }
    }
}

struct NotePropertiesView: View {
    @Binding var note: NoteProperties

    var body: some View {
        HStack(spacing: 12) {
            ColorPicker("Note", selection: $note.noteColor, supportsOpacity: true)
                .labelsHidden()
            ColorPicker("Text", selection: $note.textColor, supportsOpacity: true)
                .labelsHidden()
            Menu {
                Button("System") { note.fontName = "System" }
                Button("SF Mono") { note.fontName = "SF Mono" }
                Button("Georgia") { note.fontName = "Georgia" }
            } label: {
                Label(note.fontName, systemImage: "textformat")
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
        HStack(spacing: 12) {
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
        HStack(spacing: 8) {
            Text(label)
            Slider(value: $value, in: range, step: step)
            Text(String(format: "%.1f", value))
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .leading)
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

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 38), spacing: 10)], spacing: 10) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 34, height: 34)
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
        HStack(spacing: 16) {
            toolbarGroup(title: "Selection", category: .selection)
            toolbarGroup(title: "Marking", category: .marking)
            toolbarGroup(title: "Drawing", category: .drawing)
            toolbarGroup(title: "Utility", category: .utility)
            toolbarGroup(title: "Actions", category: .actions)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder
    private func toolbarGroup(title: String, category: ToolCategory) -> some View {
        HStack(spacing: 8) {
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
            HStack(spacing: 6) {
                Image(systemName: item.systemName)
                Text(item.title)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(nsColor: .separatorColor).opacity(0.1))
            .foregroundColor(isSelected ? Color.accentColor : .primary)
            .cornerRadius(8)
        }
    }
}

#Preview {
    ContentView()
}
