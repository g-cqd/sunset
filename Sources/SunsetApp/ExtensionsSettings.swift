import SunsetPane
import SunsetShell
import SunsetWeb
import SunsetWebModel
import SwiftUI

/// Settings ▸ Web ▸ Extensions (roadmap 0109 C, ADR-0109): each profile's extensions, a section each: on or off, in private
/// windows or not, removed after a question; Install… beside the profile's name.
struct ExtensionsSettings: View {
    private let spaces = AppSpaces.all
    @State private var removing: (host: ExtensionHost, entry: ExtensionStore.Installed)?

    var body: some View {
        ForEach(spaces.profiles.profiles, id: \.profile.id) { profile in
            if let host = ExtensionHosts.shared.host(for: profile.profile.isFirst ? nil : profile.profile.id) {
                Section {
                    if host.installed.isEmpty {
                        Text("No extension").foregroundStyle(.secondary)
                    }
                    ForEach(Array(host.installed.enumerated()), id: \.element.id) { index, entry in
                        row(entry, in: host)
                            // The buttons' order (the owner, 2026-11-20).
                            .contextMenu {
                                Button("Move Up") { host.moveEntry(entry.id, by: -1) }.disabled(index == 0)
                                Button("Move Down") { host.moveEntry(entry.id, by: 1) }
                                    .disabled(index == host.installed.count - 1)
                            }
                    }
                } header: {
                    HStack {
                        Text(spaces.profiles.profiles.count > 1 ? profile.profile.name : "Extensions")
                        Spacer()
                        Button("Install\u{2026}") { AppActions.shared.installExtension(into: host) }
                    }
                }
            }
        }
        .confirmationDialog(
            "Remove \u{201C}\(removing?.entry.name ?? "")\u{201D}?",
            isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })
        ) {
            Button("Remove", role: .destructive) {
                if let removing { removing.host.remove(removing.entry.id) }
                removing = nil
            }
        } message: {
            Text("Its data in this profile is erased.")
        }
    }

    private func row(_ entry: ExtensionStore.Installed, in host: ExtensionHost) -> some View {
        LabeledContent {
            HStack(spacing: Design.Space.m) {
                Toggle(
                    "In private windows",
                    isOn: Binding(get: { entry.inPrivate }, set: { host.set(entry.id, inPrivate: $0) })
                )
                .choiceBox()
                .disabled(!entry.enabled)
                Toggle("On", isOn: Binding(get: { entry.enabled }, set: { host.set(entry.id, enabled: $0) }))
                    .labelsHidden()
                    .settingSwitch()
                Button("Remove\u{2026}") { removing = (host, entry) }
            }
        } label: {
            VStack(alignment: .leading, spacing: Design.Space.xs) {
                Text(entry.name)
                Text(
                    ExtensionWording.lines(
                        permissions: entry.granted.filter { !$0.contains("/") },
                        sites: entry.granted.filter { $0.contains("/") || $0 == "<all_urls>" }
                    )
                    .joined(separator: " · ")
                )
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
        }
    }
}
