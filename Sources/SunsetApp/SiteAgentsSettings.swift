import SunsetConfig
import SunsetShell
import SunsetWeb
import SwiftUI

/// Settings > Web > Websites: the browser sites are shown, rows of their section: the default for every site, and the
/// sites that have a rule of their own, each changeable or removed (the default applies to it again). A rule is for the
/// site and its subdomains.
struct SiteAgentsSettings: View {
    /// The browser every site with no rule is shown (`web.agent`).
    @Binding var agent: Configuration.Web.Agent
    private let store = SiteAgents.shared

    var body: some View {
        LabeledContent {
            Picker("Other sites", selection: $agent) {
                ForEach(Configuration.Web.Agent.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            .labelsHidden()
            .fixedSize()
        } label: {
            Text("Every site without a rule")
        }
        if store.rules.isEmpty {
            Text("No site has a rule. Give one from a page: the site's panel in the address field, Appears as.")
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
        }
        ForEach(store.rules, id: \.host) { rule in
            SiteRuleRow(host: rule.host) {
                Picker(rule.host, selection: Binding(get: { rule.agent }, set: { store.set($0, for: rule.host) })) {
                    ForEach(BrowserAgent.allCases, id: \.self) { Text($0.title).tag($0) }
                }
            } remove: {
                store.set(nil, for: rule.host)
            }
        }
    }
}
