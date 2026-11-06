import SunsetConfig
import SunsetRender
import SwiftUI

/// The content of a terminal window: the model, the AppKit view, the title and the settings that reach the model.
struct TerminalScene: View {
    let launch: LaunchOptions
    @State private var model = TerminalModel()
    @Environment(\.dismiss) private var dismiss
    private let config = AppConfiguration.shared
    @AppStorage(SettingsKeys.fontName) private var fontName = "Menlo"
    @AppStorage(SettingsKeys.fontSize) private var fontSize = 14.0
    @AppStorage(SettingsKeys.ligatures) private var ligatures = false
    @AppStorage(SettingsKeys.features) private var features = ""
    @AppStorage(SettingsKeys.optionAsMeta) private var optionAsMeta = false

    /// The launch options win, then the configuration file (when there is one), then the app's own settings.
    private var font: FontSettings {
        let file = config.hasFile ? config.configuration.font : nil
        return FontSettings(
            name: launch.fontName ?? file?.family ?? fontName,
            size: launch.fontSize ?? file?.size ?? fontSize,
            ligatures: launch.ligatures ?? file?.ligatures ?? ligatures,
            featureList: features
        )
    }

    private var colors: DefaultColors { DefaultColors(config.configuration.colors) }

    private var blinkSchedule: BlinkSchedule {
        BlinkSchedule(stopAfter: config.configuration.cursorBlinkTimeout.map { Duration.seconds($0) })
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
                model.blinkSchedule = blinkSchedule
                model.defaultColors = colors
                model.start(
                    command: launch.command,
                    environment: environment,
                    font: font,
                    scrollback: launch.scrollback ?? config.configuration.scrollbackLines
                )
            }
            .onChange(of: font) { _, newFont in model.apply(font: newFont) }
            .onChange(of: colors) { _, newColors in model.apply(colors: newColors) }
            .onChange(of: blinkSchedule) { _, schedule in model.blinkSchedule = schedule }
            .onDisappear { model.stop() }
    }
}
