import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetPrivate
import SunsetRender
import SwiftUI

/// The content of a terminal window: the tabs of the window (one, unless the built-in bar is on), the sidebar and the tab bar when the configuration shows
/// them, and the settings that reach every terminal.
struct TerminalScene: View {
    let launch: LaunchOptions
    @State var tabs = TabsModel()
    @State var window: NSWindow?
    /// How much of the window's top the title bar and the system tab bar cover.
    @State private var obscured = 0.0
    /// Whether the floating sidebar (and with it the traffic lights) is out.
    @State var floatingShown = false
    /// The sidebar was just unpinned: the panel starts out (the pointer is where the column was) and goes when the pointer is not on it.
    @State var opensAtOnce = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    let config = AppConfiguration.shared

    var configuration: Configuration { config.configuration }
    var presentation: TabPresentation { configuration.presentation }
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
    private var look: WindowLook { WindowLook(configuration) }
    private var colors: DefaultColors { DefaultColors(configuration.colors) }

    private var blinkSchedule: BlinkSchedule {
        BlinkSchedule(stopAfter: configuration.cursorBlinkTimeout.map { Duration.seconds($0) })
    }

    var body: some View {
        VStack(spacing: 0) {
            if barAtTop { tabBar }
            HStack(spacing: 0) {
                if configuration.sidebarDocked, sidebarSide == .left { dockedSidebar }
                terminal
                if configuration.sidebarDocked, sidebarSide == .right { dockedSidebar }
            }
            .overlay(alignment: sidebarSide.alignment) { resizeHandle }
            .overlay(alignment: .top) { if floatsSidebar { dragHandle(height: configuration.window.dragStrip) } }
            .overlay(alignment: sidebarSide.alignment) { floatingSidebar }
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
        .preferredColorScheme(configuration.appearance.scheme.colorScheme)
        .navigationTitle(tabs.selectedModel?.title ?? "Sunset")
        .focusedSceneValue(\.terminalModel, tabs.selectedModel)
        .task { start() }
        .animation(configuration.layout.smooth, value: configuration.sidebar.autoHide)
        .animation(configuration.layout.smooth, value: configuration.sidebar.padding)
        .onChange(of: configuration.sidebarDocked) { _, docked in
            forEachModel { $0.holdResize(for: .milliseconds(350)) }
            floatingShown = !docked
            opensAtOnce = !docked
        }
        .onChange(of: font) { _, newFont in forEachModel { $0.apply(font: newFont) } }
        .onChange(of: configuration.scroll) { _, _ in forEachModel(configure) }
        .onChange(of: configuration.terminalPadding) { _, _ in forEachModel(configure) }
        .onChange(of: configuration.backgroundAlpha) { _, _ in forEachModel(configure) }
        .onChange(of: colors) { _, _ in forEachModel(configure) }
        .onChange(of: blinkSchedule) { _, _ in forEachModel(configure) }
        .onDisappear {
            if let window { TabRegistry.shared.unregister(window) }
            tabs.stopAll()
        }
    }

    // MARK: Parts

    /// The sidebar beside the terminal, on the side `sidebar.side` says: the margin is on the window's edge.
    private var dockedSidebar: some View {
        TabSidebar(tabs: tabs, settings: configuration)
            .padding(.top, configuration.sidebar.padding)
            .padding(sidebarSide.edge, configuration.sidebar.padding)
            .frame(width: configuration.sidebar.width, alignment: sidebarSide.alignment)
            .frame(maxHeight: .infinity)
            .background(alignment: .top) { dragHandle(height: configuration.window.dragStrip) }
            .transition(.move(edge: sidebarSide.moveEdge).combined(with: .opacity))
    }

    @ViewBuilder private var terminal: some View {
        if tabs.selectedModel != nil {
            PaneArea(
                tabs: tabs,
                optionAsMeta: configuration.keyboard.optionAsMeta,
                translucent: !look.isOpaque,
                topInset: topInset,
                layout: configuration.layout,
                docked: configuration.sidebarDocked,
                margin: configuration.sidebar.padding,
                windowRadius: windowRadius,
                windowCorners: areaWindowCorners
            )
        } else {
            Color.clear
        }
    }

    /// The corners of the pane area that are corners of the window: a docked sidebar covers the corners on its side, the built-in bar those at its edge.
    private var areaWindowCorners: CornerSet {
        var corners = CornerSet.all
        if configuration.sidebarDocked {
            corners.subtract(sidebarSide == .left ? [.topLeading, .bottomLeading] : [.topTrailing, .bottomTrailing])
        }
        if presentation.showsBuiltInBar {
            corners.subtract(
                configuration.tabs.bar.position == .top
                    ? [.topLeading, .topTrailing] : [.bottomLeading, .bottomTrailing]
            )
        }
        return corners
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
        tabs.onChange = { SessionStore.shared.scheduleSave() }
        if tabs.workspace.isEmpty {
            // A terminal that was running in another window is waiting for this one, else the saved tabs of an earlier run, else a new one starts.
            if !AppActions.shared.handoff.isEmpty {
                tabs.adopt(AppActions.shared.handoff.removeFirst())
            } else if let saved = SessionStore.shared.take() {
                tabs.restore(saved) {
                    var isDirectory: ObjCBool = false
                    return FileManager.default.fileExists(atPath: $0, isDirectory: &isDirectory)
                        && isDirectory.boolValue
                }
                // The other windows of the session open one after the other, each taking the next saved window.
                if SessionStore.shared.hasPending { AppActions.shared.openTerminalWindow() }
            } else {
                tabs.newTab()
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
        model.topInsetPoints = topInset
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
