import AppKit
import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetPrivate
import SunsetShell
import SunsetShellBridge
import SunsetWeb
import SwiftUI

/// A pop-up window (task t132, the owner, 2026-11-20): "the slight margin window, corner radii on all corners and just a
/// little space above the content to have the traffic lights (on the side the sidebar is) and the other side a button with
/// 'Open in ‹current Space›' with a selector for the Space to move the popup to as a standard tab there. It should not exist
/// as a standard tab until then, and it should not show the sidebar at all."
struct PopupScene: View {
    let id: UUID
    @State private var window: NSWindow?
    let config = AppConfiguration.shared
    @Environment(\.surfaceStyle) private var surface

    private var popup: PopupWindowStore.Popup? {
        PopupWindowStore.shared.popup(id)
    }
    private var configuration: Configuration {
        config.shown
    }
    /// The traffic lights' side: the sidebar's, as in the window of tabs.
    private var lightsSide: Configuration.Side {
        configuration.window.lightsSide.resolved(sidebar: configuration.sidebar.side)
    }
    private var layout: PopupWindowLayout {
        PopupWindowLayout(configuration, windowRadius: windowRadius)
    }
    /// The window's look, as a window of tabs has it, tinted by the colour of the Space its opener was in.
    private var look: WindowLook {
        let base = WindowLook(configuration, light: config.isLight)
        guard let space = popup?.openerSpace.flatMap({ AppSpaces.all.space($0) }) else { return base }
        return base.tinted(by: space.space.tint)
    }
    private var windowRadius: Double {
        window.flatMap { WindowCornerRadius.of($0) } ?? ConcentricRadius.standardWindow
    }

    var body: some View {
        VStack(spacing: 0) {
            strip
            card
        }
        .padding([.horizontal, .bottom], layout.margin)
        // Behind everything the window's material, as a window of tabs: its colour only where the look is opaque.
        .background(look.isOpaque ? Color(nsColor: .windowBackgroundColor) : .clear)
        .ignoresSafeArea(edges: .top)
        .environment(\.surfaceStyle, SurfaceStyle(configuration))
        .background(
            WindowChrome(
                settings: popupWindowSettings,
                look: look,
                presentation: .windows,
                lights: LightsPlacement(
                    x: layout.lightsX,
                    y: layout.lightsMiddle,
                    visible: true,
                    side: lightsSide,
                    centred: true
                ),
                attached: { attach($0) },
                obscuredTop: { _ in }
            )
        )
        .onDisappear { PopupWindowStore.shared.closed(id) }
    }

    /// The window's settings with no title bar: the strip is drawn by the scene.
    private var popupWindowSettings: Configuration.Window {
        var settings = configuration.window
        settings.decorations = .none
        return settings
    }

    /// The lights on one side, Open in ‹Space› on the other; the rest drags the window.
    private var strip: some View {
        HStack(spacing: 0) {
            if lightsSide == .right { openIn }
            Spacer(minLength: Design.TabCapsules.lightsClearance)
                .frame(height: layout.strip)
            if lightsSide == .left { openIn }
        }
        // The capsule as far from its side edge as from the window's top (the strip is inside the side margin already).
        .padding(.horizontal, PopupWindowLayout.capsuleGap - layout.margin)
        .frame(height: layout.strip)
        .background { Color.clear.contentShape(.rect).gesture(WindowDragGesture()) }
    }

    @ViewBuilder private var openIn: some View {
        if let popup {
            PopupOpenInButton(
                current: popup.openerSpace.flatMap { AppSpaces.all.space($0) },
                spaces: AppSpaces.all.spaces,
                height: PopupWindowLayout.capsuleHeight
            ) { space in
                PopupWindowStore.shared.move(id, to: space)
            }
        }
    }

    @ViewBuilder private var card: some View {
        let shape = RoundedRectangle(
            cornerRadius: layout.cardRadius,
            style: .continuous
        )
        if let page = popup?.page {
            page.makeView(PaneViewContext(focused: true, translucent: false, optionAsMeta: false))
                .clipShape(shape)
                .overlay { shape.hairline(surface.layout) }
                .navigationTitle(page.pageTitle.isEmpty ? (page.url?.host() ?? "") : page.pageTitle)
        } else {
            Color.clear
        }
    }

    private func attach(_ window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        PopupWindowStore.shared.attach(id, window: window)
    }
}
