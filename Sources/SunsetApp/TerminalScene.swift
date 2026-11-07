import SunsetConfig
import SunsetRender
import SwiftUI

/// The content of a terminal window: the model, the AppKit view, the title and the settings that reach the model.
struct TerminalScene: View {
    let launch: LaunchOptions
    @State private var model = TerminalModel()
    @Environment(\.dismiss) private var dismiss
    private let config = AppConfiguration.shared

    /// The launch options win, then the configuration (the file, or the defaults).
    private var font: FontSettings {
        let file = config.configuration.font
        return FontSettings(
            name: launch.fontName ?? file.family ?? "Menlo",
            size: launch.fontSize ?? file.size,
            ligatures: launch.ligatures ?? file.ligatures,
            featureList: file.features
        )
    }

    private var noDecorations: Bool { config.configuration.window.decorations == .none }

    /// The strip at the top that drags a window with no title bar, in points: the terminal starts below it.
    private var topInset: Double { noDecorations ? config.configuration.window.dragStrip : 0 }

    private func applyScroll() {
        model.scrollTrackpad = config.configuration.scroll.trackpad
        model.scrollWheel = config.configuration.scroll.wheel
    }

    private var look: WindowLook { WindowLook(config.configuration) }

    private func applyLayout() {
        model.apply(padding: config.configuration.terminalPadding)
        model.apply(backgroundAlpha: config.configuration.backgroundAlpha)
    }

    private var colors: DefaultColors { DefaultColors(config.configuration.colors) }

    private var blinkSchedule: BlinkSchedule {
        BlinkSchedule(stopAfter: config.configuration.cursorBlinkTimeout.map { Duration.seconds($0) })
    }

    var body: some View {
        TerminalRepresentable(
            model: model,
            optionAsMeta: config.configuration.keyboard.optionAsMeta,
            translucent: !look.isOpaque
        )
        .background(look.isOpaque ? Color.black : Color.clear)
        .ignoresSafeArea(edges: noDecorations ? .top : [])
        .background(WindowChrome(settings: config.configuration.window, look: look))
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
            model.topInsetPoints = topInset
            model.paddingPoints = config.configuration.terminalPadding
            model.backgroundAlpha = config.configuration.backgroundAlpha
            applyScroll()
            model.start(
                command: launch.command,
                environment: environment,
                font: font,
                scrollback: launch.scrollback ?? config.configuration.scrollbackLines
            )
        }
        .onChange(of: font) { _, newFont in model.apply(font: newFont) }
        .onChange(of: config.configuration.scroll) { _, _ in applyScroll() }
        .onChange(of: config.configuration.terminalPadding) { _, _ in applyLayout() }
        .onChange(of: config.configuration.backgroundAlpha) { _, _ in applyLayout() }
        .onChange(of: topInset) { _, inset in model.apply(topInset: inset) }
        .onChange(of: colors) { _, newColors in model.apply(colors: newColors) }
        .onChange(of: blinkSchedule) { _, schedule in model.blinkSchedule = schedule }
        .onDisappear { model.stop() }
    }
}
