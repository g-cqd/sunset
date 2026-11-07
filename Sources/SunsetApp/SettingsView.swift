import SunsetConfig
import SwiftUI

/// The Settings window: every option of the configuration file, in sections that follow the file's. Edits go to the file (saved a moment after the last
/// change) and the open windows follow at once; a hand edit of the file shows up here too.
struct SettingsView: View {
    let config = AppConfiguration.shared

    var body: some View {
        Form {
            fontSection
            colorsSection
            windowSection
            scrollSection
            terminalSection
            keyboardSection
            fileSection
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 640)
    }

    // MARK: Sections

    private var fontSection: some View {
        Section("Font") {
            TextField(
                "Family",
                text: config.textBinding(\.font.family),
                prompt: Text("Menlo, SF Mono, JetBrains Mono…")
            )
            NumberRow(
                name: "Size",
                value: config.binding(\.font.size),
                range: 4 ... 200,
                step: 0.5,
                unit: "pt",
                fractionDigits: 1
            )
            Toggle("Ligatures", isOn: config.binding(\.font.ligatures))
            TextField("Features", text: config.binding(\.font.features), prompt: Text("zero, ss01, cv02=3"))
        }
    }

    private var colorsSection: some View {
        Section("Colors") {
            colorRow("Foreground", \.colors.foreground, fallback: [229, 229, 229])
            colorRow("Background", \.colors.background, fallback: [0, 0, 0])
            colorRow("Cursor", \.colors.cursor, fallback: [229, 229, 229])
        }
    }

    private func colorRow(_ name: String, _ keyPath: WritableKeyPath<Configuration, [UInt8]?>, fallback: [UInt8])
        -> some View
    {
        LabeledContent(name) {
            HStack {
                Toggle("Custom", isOn: config.switchBinding(keyPath, whenOn: fallback)).labelsHidden()
                ColorPicker(name, selection: config.colorBinding(keyPath, fallback: fallback), supportsOpacity: false)
                    .labelsHidden()
                    .disabled(config.configuration[keyPath: keyPath] == nil)
            }
        }
    }

    private var windowSection: some View {
        Section("Window") {
            Picker("Title bar", selection: config.binding(\.window.decorations)) {
                Text("None (content under the title bar)").tag(Configuration.Window.Decorations.none)
                Text("System").tag(Configuration.Window.Decorations.native)
            }
            number("Drag strip", \.window.dragStrip, range: 0 ... 64, step: 1, unit: "pt")
            number("Traffic lights, from the left", \.window.trafficLightsX, range: 0 ... 400, step: 1, unit: "pt")
            number("Traffic lights, from the top", \.window.trafficLightsY, range: 0 ... 400, step: 1, unit: "pt")
        }
    }

    private var scrollSection: some View {
        Section("Scrolling") {
            number("Trackpad (lines per line of travel)", \.scroll.trackpad, range: 0.05 ... 20, step: 0.05, unit: "×")
            number("Wheel (lines per notch)", \.scroll.wheel, range: 0.05 ... 50, step: 0.05, unit: "×")
            NumberRow(
                name: "History",
                value: Binding(
                    get: { Double(config.configuration.scrollbackLines) },
                    set: { value in config.update { $0.scrollbackLines = Int(value) } }
                ),
                range: 0 ... 10_000_000,
                step: 1000,
                unit: "lines",
                fractionDigits: 0
            )
            Text("The history length applies to windows opened after the change.").font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var terminalSection: some View {
        Section("Terminal") {
            Toggle("Cursor blinks for ever", isOn: foreverBinding)
            if config.configuration.cursorBlinkTimeout != nil {
                number("Stop blinking after", \.cursorBlinkTimeoutSeconds, range: 1 ... 3600, step: 1, unit: "s")
            }
            Picker("Renderer", selection: config.binding(\.renderer)) {
                ForEach(Configuration.Renderer.allCases, id: \.self) { Text($0.rawValue) }
            }
            Text("Only the CPU renderer exists yet; the choice is saved for when the GPU one does.").font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var keyboardSection: some View {
        Section("Keyboard") {
            Toggle("Option sends Escape (Meta)", isOn: config.binding(\.keyboard.optionAsMeta))
        }
    }

    private var fileSection: some View {
        Section("Configuration file") {
            Text(config.path).font(.callout).textSelection(.enabled)
            HStack {
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: config.path)])
                }
                .disabled(!config.hasFile)
                Button("Open in editor") { NSWorkspace.shared.open(URL(fileURLWithPath: config.path)) }
                    .disabled(!config.hasFile)
            }
            if let error = config.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
            }
            ForEach(Array(config.issues.enumerated()), id: \.offset) { _, issue in
                Label("\(issue.path): \(issue.message)", systemImage: "exclamationmark.circle").foregroundStyle(.orange)
            }
            Text(
                "Saving here rewrites the file with every option; comments in a hand-written file are not kept (the previous file is saved as config.json.bak)."
            )
            .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Helpers

    private var foreverBinding: Binding<Bool> {
        Binding(
            get: { config.configuration.cursorBlinkTimeout == nil },
            set: { forever in config.update { $0.cursorBlinkTimeout = forever ? nil : 15 } }
        )
    }

    private func number(
        _ name: String,
        _ keyPath: WritableKeyPath<Configuration, Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String
    ) -> some View {
        NumberRow(name: name, value: config.binding(keyPath), range: range, step: step, unit: unit)
    }
}
