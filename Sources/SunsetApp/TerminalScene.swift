import SwiftUI

/// The content of a terminal window: the model, the AppKit view, the title and the settings that reach the model.
struct TerminalScene: View {
    let launch: LaunchOptions
    @State private var model = TerminalModel()
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.fontName) private var fontName = "Menlo"
    @AppStorage(SettingsKeys.fontSize) private var fontSize = 14.0
    @AppStorage(SettingsKeys.ligatures) private var ligatures = false
    @AppStorage(SettingsKeys.features) private var features = ""
    @AppStorage(SettingsKeys.optionAsMeta) private var optionAsMeta = false

    private var font: FontSettings {
        FontSettings(
            name: launch.fontName ?? fontName,
            size: launch.fontSize ?? fontSize,
            ligatures: launch.ligatures ?? ligatures,
            featureList: features
        )
    }

    var body: some View {
        TerminalRepresentable(model: model, optionAsMeta: optionAsMeta)
            .background(Color.black)
            .navigationTitle(model.title)
            .focusedSceneValue(\.terminalModel, model)
            .task {
                var environment = ProcessInfo.processInfo.environment
                environment["TERM_PROGRAM"] = "sunset"
                environment["COLORTERM"] = "truecolor"
                environment["TERM"] = "xterm-256color"
                model.onExit = { dismiss() }
                model.start(command: launch.command, environment: environment, font: font)
            }
            .onChange(of: font) { _, newFont in model.apply(font: newFont) }
            .onDisappear { model.stop() }
    }
}
