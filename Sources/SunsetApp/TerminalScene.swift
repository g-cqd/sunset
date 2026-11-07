import SunsetConfig
import SunsetHost
import SunsetRender
import SwiftUI

/// The content of a terminal window: the tabs of the window (one, unless the built-in bar is on), the sidebar and the tab bar when the configuration shows
/// them, and the settings that reach every terminal.
struct TerminalScene: View {
    let launch: LaunchOptions
    @State private var tabs = TabsModel()
    @State private var window: NSWindow?
    /// How much of the window's top the title bar and the system tab bar cover.
    @State private var obscured = 0.0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    private let config = AppConfiguration.shared

    private var configuration: Configuration { config.configuration }
    private var presentation: TabPresentation { configuration.presentation }
    private var noDecorations: Bool { configuration.window.decorations == .none }
    private var barAtTop: Bool { presentation.showsBuiltInBar && configuration.tabs.bar.position == .top }

    /// The launch options win, then the configuration (the file, or the defaults).
    private var font: FontSettings {
        let file = configuration.font
        return FontSettings(
            name: launch.fontName ?? file.family ?? "Menlo",
            size: launch.fontSize ?? file.size,
            ligatures: launch.ligatures ?? file.ligatures,
            featureList: file.features
        )
    }

    /// The strip at the top that drags a window with no title bar, in points: the terminal starts below it (the built-in bar at the top is the strip then).
    private var topInset: Double {
        guard noDecorations, !barAtTop else { return 0 }
        // With no title bar the content goes under it; the system's tab bar (when there are tabs) is below the strip and covers more.
        return max(configuration.window.dragStrip, presentation.showsNativeTabBar ? obscured : 0)
    }
    private var look: WindowLook { WindowLook(configuration) }
    private var colors: DefaultColors { DefaultColors(configuration.colors) }

    private var blinkSchedule: BlinkSchedule {
        BlinkSchedule(stopAfter: configuration.cursorBlinkTimeout.map { Duration.seconds($0) })
    }

    var body: some View {
        VStack(spacing: 0) {
            if barAtTop { tabBar }
            HStack(spacing: 0) {
                if presentation.showsSidebar {
                    TabSidebar(tabs: tabs, settings: configuration)
                        .frame(width: configuration.sidebar.width)
                        .frame(maxHeight: .infinity)
                        .padding(.top, noDecorations ? max(configuration.window.dragStrip, 36) : 0)
                        .background(alignment: .top) { dragHandle(height: configuration.window.dragStrip) }
                }
                terminal
            }
            if presentation.showsBuiltInBar, configuration.tabs.bar.position == .bottom { tabBar }
        }
        .background(look.isOpaque ? Color.black : Color.clear)
        .ignoresSafeArea(edges: noDecorations ? .top : [])
        .background(
            WindowChrome(
                settings: configuration.window,
                look: look,
                presentation: presentation,
                attached: { attach($0) },
                obscuredTop: { obscured = $0 }
            )
        )
        .navigationTitle(tabs.selectedModel?.title ?? "Sunset")
        .focusedSceneValue(\.terminalModel, tabs.selectedModel)
        .task { start() }
        .onChange(of: font) { _, newFont in forEachModel { $0.apply(font: newFont) } }
        .onChange(of: configuration.scroll) { _, _ in forEachModel(configure) }
        .onChange(of: configuration.terminalPadding) { _, _ in forEachModel(configure) }
        .onChange(of: configuration.backgroundAlpha) { _, _ in forEachModel(configure) }
        .onChange(of: topInset) { _, _ in forEachModel(configure) }
        .onChange(of: colors) { _, _ in forEachModel(configure) }
        .onChange(of: blinkSchedule) { _, _ in forEachModel(configure) }
        .onDisappear {
            if let window { TabRegistry.shared.unregister(window) }
            tabs.stopAll()
        }
    }

    // MARK: Parts

    @ViewBuilder private var terminal: some View {
        if let model = tabs.selectedModel {
            TerminalRepresentable(
                model: model,
                optionAsMeta: configuration.keyboard.optionAsMeta,
                translucent: !look.isOpaque
            )
            .id(tabs.list.selectedID)
        } else {
            Color.clear
        }
    }

    private var tabBar: some View {
        BuiltInTabBar(tabs: tabs, settings: configuration.tabs.bar)
            .padding(.leading, noDecorations && barAtTop ? 72 : 0)
            .background(alignment: .top) { dragHandle(height: 40) }
    }

    /// A transparent area that drags the window (SwiftUI's `WindowDragGesture`): the title bar's job when there is none.
    @ViewBuilder private func dragHandle(height: Double) -> some View {
        if noDecorations, height > 0 {
            Color.clear.frame(height: height).contentShape(.rect).gesture(WindowDragGesture())
        }
    }

    // MARK: Models

    private func start() {
        AppActions.shared.openTerminalWindow = { openWindow(id: "terminal") }
        tabs.onEmpty = { dismiss() }
        tabs.makeModel = { makeModel() }
        if tabs.list.isEmpty {
            // A terminal that was running in another window is waiting for this one, else a new one starts.
            if AppActions.shared.handoff.isEmpty {
                tabs.newTab()
            } else {
                tabs.adopt(AppActions.shared.handoff.removeFirst())
            }
        }
    }

    private func attach(_ window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        TabRegistry.shared.register(window, tabs: tabs)
        AppActions.shared.joinPendingTab(window)
    }

    private func makeModel() -> TerminalModel {
        let model = TerminalModel()
        configure(model)
        var environment = ProcessInfo.processInfo.environment
        environment["TERM_PROGRAM"] = "sunset"
        environment["COLORTERM"] = "truecolor"
        environment["TERM"] = "xterm-256color"
        model.start(
            command: launch.command,
            environment: environment,
            font: font,
            scrollback: launch.scrollback ?? configuration.scrollbackLines
        )
        return model
    }

    private func configure(_ model: TerminalModel) {
        model.blinkSchedule = blinkSchedule
        model.defaultColors = colors
        model.topInsetPoints = topInset
        model.paddingPoints = configuration.terminalPadding
        model.backgroundAlpha = configuration.backgroundAlpha
        model.scrollTrackpad = configuration.scroll.trackpad
        model.scrollWheel = configuration.scroll.wheel
        model.applyLayout()
    }

    private func forEachModel(_ body: (TerminalModel) -> Void) {
        for model in tabs.allModels { body(model) }
    }
}
