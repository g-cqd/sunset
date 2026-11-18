import SunsetConfig
import SunsetShell
import SunsetWeb
import SwiftUI

/// Settings > Web > Websites: the browser sites are shown (roadmap 0022, W-a): the default for every site, and the sites
/// that have a rule of their own, each changeable or removed (the default applies to it again). A rule is for the site
/// and its subdomains.
struct SiteAgentsSettings: View {
    /// The browser every site with no rule is shown (`web.agent`).
    @Binding var agent: Configuration.Web.Agent
    private let store = SiteAgents.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            Picker("Browser shown to other sites", selection: $agent) {
                ForEach(Configuration.Web.Agent.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            .fixedSize()
            if store.rules.isEmpty {
                Text("No site has a rule. Give one from a page: the site's panel in the address field, Appears as.")
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
            }
            ForEach(store.rules, id: \.host) { rule in
                HStack {
                    Text(rule.host).foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: Binding(get: { rule.agent }, set: { store.set($0, for: rule.host) })) {
                        ForEach(BrowserAgent.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    Button {
                        store.set(nil, for: rule.host)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Remove: the default applies again")
                }
                .padding(.leading, Design.Optical.siteRowsIndent)
            }
        }
    }
}
