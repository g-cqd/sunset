import SunsetShell
import SwiftUI

/// What one site was allowed (web step g), changed in place; and Stop while the page captures.
struct SiteSettingsPopover: View {
    @Environment(\.dismiss) private var dismiss
    let content: WebContent
    private var store: SitePermissions { content.permissions }

    var body: some View {
        let host = content.siteHost ?? ""
        VStack(alignment: .leading, spacing: Design.Space.m) {
            Text(host.isEmpty ? "This page" : host).font(Design.Text.title)
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
            Divider()
            HStack {
                Label("Appears as", systemImage: "theatermasks")
                Spacer()
                Picker("Appears as", selection: agentBinding) {
                    Text("Default (\(content.settings.agent.title))").tag(BrowserAgent?.none)
                    ForEach(BrowserAgent.allCases, id: \.self) { Text($0.title).tag(BrowserAgent?.some($0)) }
                }
                .labelsHidden()
                .fixedSize()
            }
            .disabled(host.isEmpty)
            Text("What this site and its subdomains are told Sunset is. The page loads again.")
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
            // Blocking, paused for this site and its subdomains (W-c); off for every site in Settings.
            Toggle(isOn: Binding(get: { content.blocksOnSite }, set: { content.setBlocking($0) })) {
                Label("Block ads and trackers", systemImage: "hand.raised")
            }
            .disabled(host.isEmpty || !ContentBlocker.shared.enabled)
            SiteZoomRow(content: content)
            HStack {
                Button("Hide an Element…") {
                    dismiss()
                    Task { await content.pickElementToHide() }
                }
                Spacer()
                let count = content.hiddenOnSite.count
                if count > 0 {
                    Button(count == 1 ? "Show 1 Hidden" : "Show \(count) Hidden") {
                        Task { await content.showHiddenElements() }
                    }
                }
            }
            .disabled(host.isEmpty)
            let spaces = content.spaceChoices()
            if !spaces.isEmpty, !content.isPrivate {
                HStack {
                    Label("Opens in", systemImage: "square.stack")
                    Spacer()
                    Picker("Opens in", selection: spaceBinding) {
                        Text("Any Space").tag(UUID?.none)
                        ForEach(spaces, id: \.id) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
                .disabled(host.isEmpty)
            }
            Text("Some apply when the page is opened again (sound, pop-ups).").font(Design.Text.detail)
                .foregroundStyle(.secondary)
        }
        .padding(Design.Space.xl)
    }

    /// The Space the site and its subdomains open in, from a link of another Space's page (W-d).
    private var spaceBinding: Binding<UUID?> {
        Binding(
            get: { SiteSpaces.shared.rule(for: content.siteHost) },
            set: { SiteSpaces.shared.set($0, for: content.siteHost) }
        )
    }

    /// The site's own rule (nil: none, the default); changing it loads the page again.
    private var agentBinding: Binding<BrowserAgent?> {
        Binding(get: { content.agents.rule(for: content.siteHost) }, set: { content.appear(as: $0) })
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
