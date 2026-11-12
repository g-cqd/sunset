import AppKit
import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetPrivate
import SunsetRender
import SunsetShell
import SunsetShellBridge
import SunsetTerminal
import SunsetWeb
import SwiftUI

/// The content of a terminal window: the tabs of the window (one, unless the built-in bar is on), the sidebar and the tab bar when the configuration shows
/// them, and the settings that reach every terminal.
struct TerminalScene: View {
    let launch: LaunchOptions
    @State var tabs = TabsModel(favorites: AppFavorites.shared)
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
            size: tabs.fontZoom.size(base: launch.fontSize ?? file.size),
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
    private var colors: DefaultColors {
        DefaultColors(configuration.colors, cursorShape: configuration.cursorShape, blinks: configuration.cursorBlinks)
    }

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
        .modifier(WindowDialogs(tabs: tabs, layout: configuration.layout))
        .animation(configuration.layout.smooth, value: tabs.bar != nil)
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
        .navigationTitle(tabs.selectedContent?.title ?? "Sunset")
        .focusedSceneValue(\.terminalModel, tabs.selectedTerminal)
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
        .onChange(of: configuration.renderer) { _, _ in forEachModel(configure) }
        .onChange(of: configuration.terminalPadding) { _, _ in forEachModel(configure) }
        .onChange(of: configuration.backgroundAlpha) { _, _ in forEachModel(configure) }
        .onChange(of: colors) { _, _ in forEachModel(configure) }
        .onChange(of: blinkSchedule) { _, _ in forEachModel(configure) }
        .onChange(of: configuration.tabs.confirmClose, initial: true) { _, confirm in tabs.confirmClose = confirm }
        .onDisappear {
            if let window { TabRegistry.shared.unregister(window) }
            tabs.stopAll()
        }
    }

    // MARK: Parts

    /// The sidebar beside the terminal, on the side `sidebar.side` says: the margin is on the window's edge. Any empty area in it drags the window.
    private var dockedSidebar: some View {
        TabSidebar(tabs: tabs, settings: ShellSettings(configuration), togglePin: AppConfiguration.togglePin)
            .padding(.top, configuration.sidebar.padding)
            .padding(sidebarSide.edge, configuration.sidebar.padding)
            .frame(width: configuration.sidebar.width, alignment: sidebarSide.alignment)
            .frame(maxHeight: .infinity)
            .background { windowDragSurface }
            .transition(.move(edge: sidebarSide.moveEdge).combined(with: .opacity))
    }

    /// The panes of what is shown; with nothing shown, the pane area's hint while the window stays for its Favorites, and nothing while it goes.
    @ViewBuilder private var terminal: some View {
        if tabs.selectedContent != nil || !tabs.favorites.isEmpty {
            PaneArea(
                tabs: tabs,
                optionAsMeta: configuration.keyboard.optionAsMeta,
                translucent: !look.isOpaque,
                topInset: topInset,
                layout: configuration.layout,
                docked: configuration.sidebarDocked,
                margin: configuration.sidebar.padding,
                windowRadius: windowRadius,
                windowCorners: areaWindowCorners,
                sidebarOnRight: configuration.sidebar.side == .right
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
        BuiltInTabBar(tabs: tabs, settings: ShellSettings(configuration).tabs.bar)
            .padding(.leading, noDecorations && barAtTop ? 72 : 0)
            .background { windowDragSurface }
    }

    /// A transparent strip of a fixed height that drags the window (`WindowDragGesture`).
    @ViewBuilder private func dragHandle(height: Double) -> some View {
        if noDecorations, height > 0 {
            windowDragSurface.frame(height: height)
        }
    }

    /// A transparent surface that drags the window from any non-interactive area above it.
    private var windowDragSurface: some View {
        Color.clear.contentShape(.rect).gesture(WindowDragGesture())
    }

    // MARK: Models

    private func start() {
        AppActions.shared.openTerminalWindow = { openWindow(id: "terminal") }
        tabs.onEmpty = { dismiss() }
        tabs.makeContent = { makeContent($0) }
        tabs.onChange = { SessionStore.shared.scheduleSave() }
        if tabs.workspace.isEmpty {
            // A terminal that was running in another window is waiting for this one, else the saved tabs of an earlier run, else a new one starts.
            if !AppActions.shared.handoff.isEmpty {
                let content = AppActions.shared.handoff.removeFirst()
                if let page = content as? WebContent { WebOpening.wire(page, in: tabs) }
                tabs.adopt(content)
            } else if let saved = SessionStore.shared.take() {
                tabs.restore(saved)
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

    /// A terminal for nil or a terminal's descriptor (in its directory, when that is still there); else what `PaneContentKinds` makes of it.
    private func makeContent(_ descriptor: PaneDescriptor?) -> any PaneContent {
        if let descriptor, descriptor.kind != PaneDescriptor.terminalKind {
            let content = PaneContentKinds.make(descriptor) { SessionStore.shared.scheduleSave() }
            if let page = content as? WebContent { WebOpening.wire(page, in: tabs) }
            return content
        }
        let model = TerminalModel()
        model.startDirectory = descriptor?.directory.flatMap { PaneContentKinds.isDirectory($0) ? $0 : nil }
        model.topInsetPoints = topInset
        configure(model)
        let integrated = configuration.terminal.shellIntegration
        model.start(
            command: launch.command,
            environment: Self.shellEnvironment(for: launch.command, integrated: integrated),
            font: font,
            scrollback: launch.scrollback ?? configuration.scrollbackLines
        )
        return model
    }

    private func configure(_ model: TerminalModel) {
        model.wire(to: tabs)
        model.blinkSchedule = blinkSchedule
        model.defaultColors = colors
        model.paddingPoints = configuration.terminalPadding
        model.backgroundAlpha = configuration.backgroundAlpha
        model.scroll = configuration.scroll
        model.rendererChoice = configuration.renderer
        model.applyLayout()
    }

    private func forEachModel(_ body: (TerminalModel) -> Void) {
        for model in tabs.allTerminals { body(model) }
    }
}
