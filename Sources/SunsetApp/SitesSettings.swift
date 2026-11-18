import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// Settings > Web > Each site (roadmap 0022 W-d), rows of their section (note n13): every site that has something of its own
/// (what it may do, the browser it is shown, blocking paused, a zoom, its Space), in words, each forgotten at once; the
/// defaults then apply to it.
struct SitesSettings: View {
    var body: some View {
        let stores = SiteSummary.Stores.app
        let rows = SiteSummary.rows(stores) { id in AppSpaces.all.space(id)?.space.name }
        if rows.isEmpty {
            Text("None yet. Give a site settings of its own from its panel in the address field.")
                .foregroundStyle(.secondary)
        }
        ForEach(rows, id: \.host) { row in
            LabeledContent {
                Button("Forget") {
                    SiteSummary.forget(row.host, in: stores)
                    Task { await ContentBlocker.shared.compileHidden() }
                }
            } label: {
                Text(row.host)
                Text(row.parts.joined(separator: " · "))
            }
        }
    }
}
