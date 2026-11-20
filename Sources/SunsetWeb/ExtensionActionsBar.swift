import AppKit
import SunsetShell
package import SwiftUI

/// The extensions' buttons in the sidebar's header row, between the sidebar's button and the traffic lights (the owner,
/// ADR-0109, roadmap 0109 D): each the sidebar's button with the extension's icon, its badge on a corner; clicked, the
/// extension's action (its popup under it); its menu: Settings ▸ Extensions.
package struct ExtensionActionsBar: View {
    let host: ExtensionHost
    let page: WebContent?
    let openSettings: () -> Void

    package init(host: ExtensionHost, page: WebContent?, openSettings: @escaping () -> Void) {
        self.host = host
        self.page = page
        self.openSettings = openSettings
    }

    package var body: some View {
        HStack(spacing: Design.Space.xs) {
            ForEach(host.actions(for: page?.extensionTab)) { item in
                SidebarIconButton(
                    help: item.badge.isEmpty ? item.label : "\(item.label) (\(item.badge))",
                    menu: AnyView(Button("Manage Extensions\u{2026}", action: openSettings)),
                    action: { host.perform(item.id, for: page?.extensionTab) },
                    label: { face(item) }
                )
                .disabled(!item.enabled)
                .background { PopupAnchor { host.anchor(item.id, $0) } }
                .accessibilityLabel(item.label)
            }
        }
    }

    private func face(_ item: ExtensionActionItem) -> some View {
        Group {
            if let icon = item.icon {
                Image(nsImage: icon).resizable().interpolation(.high)
                    .frame(width: Design.Size.extensionIcon, height: Design.Size.extensionIcon)
            } else {
                Image(systemName: "puzzlepiece.extension")
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
    }
}
