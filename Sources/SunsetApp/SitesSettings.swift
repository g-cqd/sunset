import SunsetConfig
import SunsetPane
import SunsetRuntime
import SunsetShell
import SunsetWeb
import SwiftUI

/// Settings › Web › Each site, in its own sections: the defaults every site gets; the sites and patterns with settings of
/// their own, each folding open on what differs, each line reset by itself, the site forgotten at once; and a rule added
/// for a host, its subdomains (`*.host`) or an address prefix, the most specific winning. Everything a site's panel can
/// set is listed here.
struct SitesSettings: View {
    @Environment(\.runtime) var runtime

    var heading: String?
    let config: any SettingsStore
    @State private var open: Set<String> = []
    @State private var pattern = ""
    @State private var adding = AddedRule.agent(.chrome)

    var body: some View {
        let stores = SiteSummary.Stores.app
        let rows = SiteSummary.rows(stores, profile: config.profileID) { id in AppSpaces.all.space(id)?.space.name }
        Group {
            Section {
                defaults
            } header: {
                VStack(alignment: .leading, spacing: Design.Space.m) {
                    if let heading { Text(heading).font(Design.Text.heading).foregroundStyle(.primary) }
                    Text("Every site")
                }
            } footer: {
                Text("What sites may do, and how each answer is asked, are under Websites.")
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
            }
            Section("Sites with settings of their own") {
                if rows.isEmpty {
                    Text(
                        "None yet. Give a site settings of its own from its panel in the address field, or add a rule below."
                    )
                    .foregroundStyle(.secondary)
                }
                ForEach(rows, id: \.host) { row in site(row, stores: stores) }
            }
            Section {
                addRule
            } header: {
                Text("Add a rule")
            } footer: {
                Text(
                    RichText.attributed(
                        "For a site and its subdomains (`example.org`), its subdomains only (`*.example.org`), or the "
                            + "pages under an address (`https://example.org/docs/`). Where several match, the most "
                            + "specific wins."
                    )
                )
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Defaults

    @ViewBuilder private var defaults: some View {
        LabeledContent {
            Toggle("Block ads and trackers", isOn: config.binding(\.web.blocking)).settingSwitch().labelsHidden()
        } label: {
            SettingsLabel("Block ads and trackers")
        }
        LabeledContent {
            Picker("Browser shown", selection: config.binding(\.web.agent)) {
                ForEach(Configuration.Web.Agent.allCases, id: \.self) { agent in
                    Text(BrowserAgent(rawValue: agent.rawValue)?.title ?? agent.rawValue).tag(agent)
                }
            }
            .labelsHidden()
            .fixedSize()
        } label: {
            SettingsLabel("Browser shown")
        }
        LabeledContent {
            Picker("Website data", selection: config.binding(\.web.keep.siteData)) {
                Text("Kept").tag(Configuration.Web.Keep.SiteData.keep)
                Text("Kept if chosen").tag(Configuration.Web.Keep.SiteData.keepChosen)
                Text("Cleared on quit").tag(Configuration.Web.Keep.SiteData.clearOnQuit)
            }
            .labelsHidden()
            .fixedSize()
        } label: {
            SettingsLabel("Website data")
        }
        LabeledContent {
            Text("100 %").foregroundStyle(.secondary)
        } label: {
            SettingsLabel("Zoom")
        }
    }

    // MARK: A site

    private func site(_ row: SiteSummary.Row, stores: SiteSummary.Stores) -> some View {
        DisclosureGroup(isExpanded: binding(row.host)) {
            FoldContent {
                ForEach(Array(zip(row.kinds, row.parts).enumerated()), id: \.offset) { _, pair in
                    LabeledContent {
                        Button("Reset") {
                            SiteSummary.reset(pair.0, of: row.host, in: stores, profile: config.profileID)
                            changed()
                        }
                    } label: {
                        Text(Self.title(pair.0))
                        Text(pair.1)
                    }
                }
                LabeledContent {
                    Button("Forget Site", role: .destructive) {
                        SiteSummary.forget(row.host, in: stores, profile: config.profileID)
                        changed()
                    }
                } label: {
                    EmptyView()
                }
            }
        } label: {
            HStack(spacing: Design.Space.s) {
                Text(row.host).code()
                // Folded, what it has; open, each line says it.
                if !open.contains(row.host) {
                    Text(row.parts.joined(separator: " · ")).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        }
    }

    static func title(_ kind: SiteSummary.Kind) -> String {
        switch kind {
            case .permissions: "What it may do"
            case .agent: "Browser shown"
            case .blocking: "Blocking"
            case .zoom: "Zoom"
            case .hidden: "Hidden elements"
            case .space: "Opens in"
            case .kept: "Its data"
        }
    }

    // MARK: Adding

    /// What a rule added sets: the kinds kept by pattern (`SiteRules`).
    enum AddedRule: Hashable {
        case agent(BrowserAgent)
        case kept
    }

    @ViewBuilder private var addRule: some View {
        LabeledContent {
            TextField("Site or address", text: $pattern, prompt: Text("example.org, *.example.org or an address"))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .code()
                .frame(maxWidth: Design.Size.settingsField)
        } label: {
            SettingsLabel("For")
        }
        LabeledContent {
            Picker("Setting", selection: $adding) {
                ForEach(BrowserAgent.allCases, id: \.self) { agent in
                    Text("Shown as \(agent.title)").tag(AddedRule.agent(agent))
                }
                Text("Its data kept when Sunset quits").tag(AddedRule.kept)
            }
            .labelsHidden()
            .fixedSize()
        } label: {
            SettingsLabel("Setting")
        }
        LabeledContent {
            Button("Add Rule") { add() }
                .disabled(SitePattern(pattern) == nil)
        } label: {
            if !pattern.isEmpty, SitePattern(pattern) == nil {
                Text("Not a site or an address Sunset reads.").foregroundStyle(.orange)
            } else {
                EmptyView()
            }
        }
    }

    private func add() {
        guard let rule = SitePattern(pattern) else { return }
        switch adding {
            case .agent(let agent): SiteAgents.shared.set(agent, for: rule, profile: config.profileID)
            case .kept: KeptSites.shared.set(true, for: rule, profile: config.profileID)
        }
        open.insert(rule.key)
        pattern = ""
        changed()
    }

    private func binding(_ host: String) -> Binding<Bool> {
        Binding(get: { open.contains(host) }, set: { if $0 { open.insert(host) } else { open.remove(host) } })
    }

    /// The hidden elements' rules changed: the pages' blocker is compiled again.
    private func changed() {
        runtime.task { await ContentBlocker.shared.compileHidden() }
    }
}
