import SunsetConfig
import SunsetShell
import SwiftUI

/// The Settings window: a sidebar of panes with a search field, in the manner of System Settings. Every option of the configuration file has a control; the
/// search finds options by name and by related words and shows them (with their controls) whatever pane they are in. Edits go to the file (saved a moment
/// after the last change) and the open windows follow at once; a hand edit of the file shows up here too.
struct SettingsView: View {
    let config = AppConfiguration.shared
    @State private var selection: SettingsPane? = .font
    @State private var query = ""
    @FocusState private var searching: Bool

    private var results: [SettingsEntry] { SettingsSearch.matches(query, in: SettingsPane.allEntries) }
    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationSplitView {
            List(SettingsPane.allCases, selection: $selection) { pane in
                Label(pane.title, systemImage: pane.symbol).tag(pane)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
        } detail: {
            detail
        }
        .searchable(text: $query, placement: .sidebar, prompt: "Search")
        .searchFocused($searching)
        // The window opens with the search field ready to type in, as System Settings does (not in the first text field of a pane).
        .onAppear { searching = true }
        .frame(minWidth: 700, minHeight: 480)
        .frame(width: 760, height: 560)
    }

    @ViewBuilder private var detail: some View {
        if isSearching {
            searchResults
        } else if let pane = selection {
            Form { rows(of: pane.entries) }
                .formStyle(.grouped)
                .navigationTitle(pane.title)
        }
    }

    private var searchResults: some View {
        Form {
            if results.isEmpty {
                ContentUnavailableView.search(text: query)
            }
            ForEach(SettingsSearch.panes(of: results), id: \.self) { paneID in
                Section(SettingsPane(rawValue: paneID)?.title ?? paneID) {
                    rows(of: results.filter { $0.pane == paneID })
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Search")
    }

    private func rows(of entries: [SettingsEntry]) -> some View {
        ForEach(entries, id: \.id) { entry in control(for: entry.id) }
    }

    // MARK: Controls

    @ViewBuilder private func control(for id: String) -> some View {
        switch id {
            case "font.family":
                TextField(
                    "Family",
                    text: config.textBinding(\.font.family),
                    prompt: Text("Menlo, SF Mono, JetBrains Mono…")
                )
            case "font.size":
                NumberRow(
                    name: "Size",
                    value: config.binding(\.font.size),
                    range: 4 ... 200,
                    step: 0.5,
                    unit: "pt",
                    fractionDigits: 1
                )
            case "font.ligatures": Toggle("Ligatures", isOn: config.binding(\.font.ligatures))
            case "font.features":
                TextField("Features", text: config.binding(\.font.features), prompt: Text("zero, ss01, cv02=3"))
            case "colors.foreground": colorRow("Foreground", \.colors.foreground, fallback: [229, 229, 229])
            case "colors.background": colorRow("Background", \.colors.background, fallback: [0, 0, 0])
            case "colors.cursor": colorRow("Cursor", \.colors.cursor, fallback: [229, 229, 229])
            case "colors.ansi": AnsiPaletteRow(config: config)
            case "scroll.trackpad":
                number(
                    "Trackpad (lines per line of travel)",
                    \.scroll.trackpad,
                    range: 0.05 ... 20,
                    step: 0.05,
                    unit: "×"
                )
            case "scroll.wheel":
                number("Wheel (lines per notch)", \.scroll.wheel, range: 0.05 ... 50, step: 0.05, unit: "×")
            case "scroll.inertia":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    number("Wheel inertia", \.scroll.inertia, range: 0 ... 2, step: 0.05, unit: "s")
                    Text("How long a wheel notch glides (0: none). A trackpad uses the system's own momentum.")
                        .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "scroll.history": history
            case "terminal.blinkForever": Toggle("Cursor blinks for ever", isOn: foreverBinding)
            case "terminal.blinkTimeout":
                number("Stop blinking after", \.cursorBlinkTimeoutSeconds, range: 1 ... 3600, step: 1, unit: "s")
                    .disabled(config.configuration.cursorBlinkTimeout == nil)
            case "terminal.renderer": renderer
            case let web where web.hasPrefix("web."): webControl(for: id)
            case "keyboard.meta": Toggle("Option sends Escape (Meta)", isOn: config.binding(\.keyboard.optionAsMeta))
            case "file.location": fileInfo
            default: windowControls(for: id)
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
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
            Text("The history length applies to windows opened after the change.").font(Design.Text.detail)
                .foregroundStyle(.secondary)
        }
    }

    private var renderer: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            Picker("Renderer", selection: config.binding(\.renderer)) {
                ForEach(Configuration.Renderer.allCases, id: \.self) { Text($0.rawValue) }
            }
            Text(
                "GPU draws with Metal, CPU on the processor; auto picks the GPU when the machine has one. Both draw the same pixels."
            )
            .font(Design.Text.detail)
            .foregroundStyle(.secondary)
        }
    }

    private var fileInfo: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            Text(config.path).font(Design.Text.secondary).textSelection(.enabled)
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
            .font(Design.Text.detail).foregroundStyle(.secondary)
        }
    }

    func colorRow(_ name: String, _ keyPath: WritableKeyPath<Configuration, [UInt8]?>, fallback: [UInt8])
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

    // MARK: Helpers

    private var foreverBinding: Binding<Bool> {
        Binding(
            get: { config.configuration.cursorBlinkTimeout == nil },
            set: { forever in config.update { $0.cursorBlinkTimeout = forever ? nil : 15 } }
        )
    }

    func number(
        _ name: String,
        _ keyPath: WritableKeyPath<Configuration, Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String
    ) -> some View {
        NumberRow(name: name, value: config.binding(keyPath), range: range, step: step, unit: unit)
    }
}
