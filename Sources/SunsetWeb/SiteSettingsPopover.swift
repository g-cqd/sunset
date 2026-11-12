import SwiftUI

/// What one site was allowed (web step g), changed in place; and Stop while the page captures.
struct SiteSettingsPopover: View {
    let content: WebContent
    private var store: SitePermissions { content.permissions }

    var body: some View {
        let host = content.siteHost ?? ""
        VStack(alignment: .leading, spacing: 8) {
            Text(host.isEmpty ? "This page" : host).font(.headline)
            if content.capture != nil {
                Button("Stop Camera, Microphone and Screen") { content.stopCapture() }
            }
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                ForEach(SitePermission.allCases, id: \.self) { permission in
                    GridRow {
                        Label(permission.title, systemImage: permission.symbol)
                        Picker("", selection: binding(permission, host)) {
                            ForEach(PermissionAnswer.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        .labelsHidden()
                        .fixedSize()
                    }
                }
            }
            .disabled(host.isEmpty)
            Text("Some apply when the page is opened again (sound, pop-ups).").font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }

    private func binding(_ permission: SitePermission, _ host: String) -> Binding<PermissionAnswer> {
        Binding(
            get: { store.answer(permission, for: host) },
            set: { answer in
                store.set(
                    answer == store.defaults[permission] ?? permission.defaultAnswer ? nil : answer,
                    permission,
                    for: host
                )
            }
        )
    }
}
