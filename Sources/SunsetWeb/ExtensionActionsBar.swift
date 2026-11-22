import AppKit
import SunsetShell
import SunsetWebModel
package import SwiftUI
import WebKit

/// The extensions' buttons in the sidebar's header row, between the sidebar's button and the traffic lights: each the sidebar's button with the extension's icon, its badge on a corner; clicked, the
/// extension's action (its popup under it); its menu: Settings ▸ Extensions.
package struct ExtensionActionsBar: View {
    let host: ExtensionHost
    let page: WebContent?
    /// The width the header leaves for the buttons (the rest behind the puzzle piece).
    let width: Double
    let openSettings: () -> Void
    @Environment(\.sidebarButtonMetrics) private var metrics
    @State private var puzzle: NSView?

    package init(host: ExtensionHost, page: WebContent?, width: Double, openSettings: @escaping () -> Void) {
        self.host = host
        self.page = page
        self.width = width
        self.openSettings = openSettings
    }

    package var body: some View {
        let items = host.actions(for: page?.extensionTab)
        let room = ExtensionRoom.places(width: width, button: metrics.size.width, spacing: Design.Space.xs)
        let shown = ExtensionRoom.shown(count: items.count, room: room)
        HStack(spacing: Design.Space.xs) {
            ForEach(Array(items.prefix(shown).enumerated()), id: \.element.id) { index, item in
                button(item, first: index == 0, last: index == items.count - 1)
            }
            if shown < items.count { more(items) }
        }
        // The page shown is the window's active tab: extensions told when it changes (`tabs.onActivated`).
        .onChange(of: page.map(ObjectIdentifier.init), initial: true) {
            if let tab = page?.extensionTab { host.controller.didActivateTab(tab, previousActiveTab: nil) }
        }
    }

    private func button(_ item: ExtensionActionItem, first: Bool, last: Bool) -> some View {
        SidebarIconButton(
            help: page == nil
                ? "\(item.label): for web pages" : item.badge.isEmpty ? item.label : "\(item.label) (\(item.badge))",
            menu: AnyView(menu(item, first: first, last: last)),
            action: { host.perform(item.id, for: page?.extensionTab) },
            label: { face(item, look: .of(available: available(item))) }
        )
        .disabled(!available(item))
        .background { PopupAnchor { host.anchor(item.id, $0) } }
        .accessibilityLabel(item.label)
    }

    /// Its order, and Settings ("allow reordering the extensions").
    @ViewBuilder private func menu(_ item: ExtensionActionItem, first: Bool, last: Bool) -> some View {
        Button("Move Left") { host.move(item.id, by: -1) }.disabled(first)
        Button("Move Right") { host.move(item.id, by: 1) }.disabled(last)
        Divider()
        Button("Manage Extensions\u{2026}", action: openSettings)
    }

    /// The puzzle piece: every extension, in their order; one chosen opens its popup under the puzzle piece.
    private func more(_ items: [ExtensionActionItem]) -> some View {
        SidebarIconButton(
            help: "Extensions",
            menu: AnyView(Button("Manage Extensions\u{2026}", action: openSettings)),
            action: { showList(items) },
            label: { Image(systemName: "puzzlepiece.extension") }
        )
        .background { PopupAnchor { puzzle = $0 } }
        .accessibilityLabel("Extensions")
    }

    private func showList(_ items: [ExtensionActionItem]) {
        guard let puzzle else { return }
        let menu = NSMenu()
        // Each entry's own state: automatic enabling would turn every entry with an action on.
        menu.autoenablesItems = false
        for item in items {
            let entry = ClosureMenuItem(title: item.badge.isEmpty ? item.label : "\(item.label)  (\(item.badge))") {
                host.perform(item.id, for: page?.extensionTab, under: puzzle)
            }
            entry.image = item.icon ?? NSImage(systemSymbolName: "puzzlepiece.extension", accessibilityDescription: nil)
            entry.image?.size = CGSize(width: Design.Size.extensionIcon, height: Design.Size.extensionIcon)
            entry.isEnabled = ExtensionRoom.isAvailable(enabled: item.enabled, inWebTab: page != nil)
            menu.addItem(entry)
        }
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: "Manage Extensions\u{2026}", run: openSettings))
        menu.popUp(positioning: nil, at: CGPoint(x: 0, y: puzzle.bounds.maxY + Design.Space.xs), in: puzzle)
    }

    private func available(_ item: ExtensionActionItem) -> Bool {
        ExtensionRoom.isAvailable(enabled: item.enabled, inWebTab: page != nil)
    }

    private func face(_ item: ExtensionActionItem, look: ExtensionFaceLook) -> some View {
        Group {
            if let icon = item.icon {
                Image(nsImage: icon).resizable().interpolation(.high)
                    .frame(width: Design.Size.extensionIcon, height: Design.Size.extensionIcon)
            } else {
                // No icon of its own: its initial, so that it is not taken for the puzzle piece (which lists them all).
                Text(item.label.prefix(1).uppercased())
                    .font(Design.Text.secondary.weight(.semibold))
                    .frame(width: Design.Size.extensionIcon, height: Design.Size.extensionIcon)
                    .background(RoundedRectangle(cornerRadius: Design.Space.xs).fill(.quaternary))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !item.badge.isEmpty {
                Text(item.badge)
                    .font(Design.Text.badge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Design.Space.hair)
                    .background(Capsule().fill(Color.red))
                    .offset(x: Design.Space.s, y: Design.Space.xs)
            }
        }
        // Unavailable here: grey, faded, blending with the chrome under it.
        .saturation(look.saturation)
        .opacity(look.opacity)
        .blendMode(look.blends ? .luminosity : .normal)
        .animation(.smooth(duration: Design.Motion.foldDuration), value: look)
    }
}
