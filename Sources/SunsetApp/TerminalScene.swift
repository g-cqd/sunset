import SunsetConfig
import SunsetHost
import SunsetPrivate
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
    /// Whether the floating sidebar (and with it the traffic lights) is out.
    @State private var floatingShown = false
    /// The sidebar was just unpinned: the panel starts out (the pointer is where the column was) and goes when the pointer is not on it.
    @State private var opensAtOnce = false
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
        guard noDecorations, !barAtTop, !configuration.sidebarDocked else { return 0 }
        // With no title bar the content goes under it; the system's tab bar (when there are tabs) is below the strip and covers more.
        return max(configuration.window.dragStrip, presentation.showsNativeTabBar ? obscured : 0)
    }
    /// Behind everything: the window's colour (a window material shows through when it is not opaque). It shows around the terminal card while the
    /// sidebar is shown; otherwise the terminal covers it edge to edge.
    private var rootColor: Color {
        guard look.isOpaque else { return .clear }
        return configuration.sidebarDocked ? Color(nsColor: .windowBackgroundColor) : .black
    }
    /// The window's corner radius, from AppKit (16 pt on macOS 27.0.1).
    private var windowRadius: Double {
        window.flatMap { WindowCornerRadius.of($0) } ?? ConcentricRadius.standardWindow
    }
    private var floatsSidebar: Bool { presentation.showsSidebar && configuration.sidebar.autoHide }

    /// With the sidebar the traffic lights are part of it, in the slot at its top (`SidebarHeader`), away from the window's edge: docked they are always
    /// there; floating they come and go with the panel, which is inset by the margin.
    private var lights: LightsPlacement? {
        guard presentation.showsSidebar else { return nil }
        let margin = configuration.sidebar.padding
        let origin = SidebarHeader.lightsOrigin(margin: margin, floating: !configuration.sidebarDocked)
        return LightsPlacement(
            x: origin,
            y: origin,
            visible: configuration.sidebarDocked || floatingShown
        )
    }

    @ViewBuilder private var floatingSidebar: some View {
        if floatsSidebar {
            FloatingSidebar(
                tabs: tabs,
                settings: configuration,
                windowRadius: windowRadius,
                shown: $floatingShown,
                opensAtOnce: $opensAtOnce
            )
            .transition(.opacity)
        }
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
                if configuration.sidebarDocked {
                    TabSidebar(tabs: tabs, settings: configuration)
                        .padding(.top, configuration.sidebar.padding)
                        .padding(.leading, configuration.sidebar.padding)
                        .frame(width: configuration.sidebar.width, alignment: .leading)
                        .frame(maxHeight: .infinity)
                        .background { SidebarBackdrop(look: SidebarLook(configuration)) }
                        .background(alignment: .top) { dragHandle(height: configuration.window.dragStrip) }
                        .overlay(alignment: .trailing) { SidebarResizeHandle(width: configuration.sidebar.width) }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                terminal
            }
            .overlay(alignment: .top) { if floatsSidebar { dragHandle(height: configuration.window.dragStrip) } }
            .overlay(alignment: .leading) { floatingSidebar }
            if presentation.showsBuiltInBar, configuration.tabs.bar.position == .bottom { tabBar }
        }
        .background(rootColor)
        .ignoresSafeArea(edges: noDecorations ? .top : [])
        .background(
            WindowChrome(
                settings: configuration.window,
                look: look,
                presentation: presentation,
                lights: lights,
                attached: { attach($0) },
                obscuredTop: { obscured = $0 }
            )
        )
        .navigationTitle(tabs.selectedModel?.title ?? "Sunset")
        .focusedSceneValue(\.terminalModel, tabs.selectedModel)
        .task { start() }
        .animation(SidebarRow.smooth, value: configuration.sidebar.autoHide)
        .animation(SidebarRow.smooth, value: configuration.sidebar.padding)
        .onChange(of: configuration.sidebarDocked) { _, docked in
            forEachModel { $0.holdResize(for: .milliseconds(350)) }
            floatingShown = !docked
            opensAtOnce = !docked
        }
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
            .modifier(
                TerminalCard(
                    isCard: configuration.sidebarDocked,
                    margin: configuration.sidebar.padding,
                    cornerRadius: ConcentricRadius.inner(outer: windowRadius, inset: configuration.sidebar.padding)
                )
            )
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
        model.scrollInertia = configuration.scroll.inertia
        model.applyLayout()
    }

    private func forEachModel(_ body: (TerminalModel) -> Void) {
        for model in tabs.allModels { body(model) }
    }
}
