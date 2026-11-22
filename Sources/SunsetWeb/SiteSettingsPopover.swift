import SunsetRuntime
import SunsetShell
import SwiftUI

/// What one site was allowed, changed in place; and Stop while the page captures.
struct SiteSettingsPopover: View {
    @Environment(\.runtime) var runtime

    @Environment(\.dismiss) private var dismiss
    @Environment(\.barTint) private var tint
    @Environment(\.colorScheme) private var outer
    let content: WebContent
    private var store: SitePermissions {
        content.permissions
    }

    @State private var showsPermissions = false
    @State private var showsMore = false

    /// The plainest first: blocking, zoom, what Sunset appears as, where the site opens; what the site may use, and hiding
    /// what is on its pages, a level down.
    var body: some View {
        let host = content.siteHost ?? ""
        VStack(alignment: .leading, spacing: Design.Space.m) {
            Text(host.isEmpty ? "This page" : host).font(Design.Text.title).fontDesign(host.isEmpty ? nil : .monospaced)
                .foregroundStyle(.primary)
            // What the page uses now, apart from the site's settings: live, for this tab only.
            if SitePageNow.shows(content) {
                SitePageNow(content: content)
                Divider()
            }
            // Blocking, paused for this site and its subdomains; off for every site in Settings.
            Toggle(isOn: Binding(get: { content.blocksOnSite }, set: { content.setBlocking($0) })) {
                Label("Block ads and trackers", systemImage: "hand.raised")
            }
            .settingSwitch()
            .disabled(host.isEmpty || !ContentBlocker.shared.enabled)
            if !content.isPrivate, KeptSites.shared.applies(content.settings.profile) {
                // The sites chosen keep their data when Sunset quits; the others' is cleared.
                Toggle(
                    isOn: Binding(
                        get: { KeptSites.shared.keeps(host, profile: content.settings.profile) },
                        set: { KeptSites.shared.set($0, for: host, profile: content.settings.profile) }
                    )
                ) {
                    Label("Keep its data when Sunset quits", systemImage: "archivebox")
                }
                .settingSwitch()
                .disabled(host.isEmpty)
            }
            SiteZoomRow(content: content)
            appearsAs.disabled(host.isEmpty)
            opensIn.disabled(host.isEmpty)
            Divider()
            Fold(permissionsTitle(host), isExpanded: $showsPermissions) {
                permissions(host)
            }
            .disabled(host.isEmpty)
            Fold("More", isExpanded: $showsMore) {
                VStack(alignment: .leading, spacing: Design.Space.s) {
                    hiding
                    Text(
                        "Appears as: what this site and its subdomains are told Sunset is; the page loads again. Sound and pop-ups apply when it is opened again."
                    )
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .disabled(host.isEmpty)
        }
        // One font and one box for every row's symbol, so the titles start at one place.
        .font(Design.Text.body)
        .labelStyle(.row)
        .frame(width: 320, alignment: .leading)
        .padding(Design.Space.xl)
        // Read on any page: the popover's glass took the page's white under it while its text was the window's (light on
        // a dark window), which could not be read (seen 2026-11-18). The chrome's glass kept, its tint stronger under the
        // text, and the controls in the tint's scheme.
        .environment(\.colorScheme, tint.resolved(in: outer))
        .background(BarTint.fill(for: tint.resolved(in: outer)).opacity(Design.Fill.popoverShade))
    }

    /// "Permissions", with how many this site was given an answer of its own.
    private func permissionsTitle(_ host: String) -> String {
        let own = SitePermission.allCases.filter {
            store.answer($0, for: host) != store.defaults[$0] ?? $0.defaultAnswer
        }
        return own.isEmpty ? "Permissions" : "Permissions (\(own.count) set)"
    }

    private func permissions(_ host: String) -> some View {
        // As wide as the popover, each answer at its trailing edge, as the rows above.
        VStack(alignment: .leading, spacing: Design.Space.s) {
            ForEach(SitePermission.allCases, id: \.self) { permission in
                HStack {
                    Label(permission.title, systemImage: permission.symbol)
                    Spacer(minLength: Design.Space.m)
                    Picker(permission.title, selection: binding(permission, host)) {
                        ForEach(PermissionAnswer.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
            }
        }
    }

    private var appearsAs: some View {
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
    }

    @ViewBuilder private var opensIn: some View {
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
        }
    }

    private var hiding: some View {
        HStack {
            Button("Hide an Element…") {
                dismiss()
                runtime.task { await content.pickElementToHide() }
            }
            Spacer()
            let count = content.hiddenOnSite.count
            if count > 0 {
                Button(count == 1 ? "Show 1 Hidden" : "Show \(count) Hidden") {
                    runtime.task { await content.showHiddenElements() }
                }
            }
        }
    }

    /// The Space the site and its subdomains open in, from a link of another Space's page.
    private var spaceBinding: Binding<UUID?> {
        Binding(
            get: { SiteSpaces.shared.rule(for: content.siteHost, profile: content.settings.profile) },
            set: { SiteSpaces.shared.set($0, for: content.siteHost, profile: content.settings.profile) }
        )
    }

    /// The site's own rule (nil: none, the default); changing it loads the page again.
    private var agentBinding: Binding<BrowserAgent?> {
        Binding(
            get: { content.agents.rule(for: content.siteHost, profile: content.settings.profile) },
            set: { content.appear(as: $0) }
        )
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
