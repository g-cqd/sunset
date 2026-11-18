import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// Settings > Web > Each site (roadmap 0022 W-d): every site that has something of its own (what it may do, the browser it
/// is shown, blocking paused, a zoom, its Space), in words, each forgotten at once; the defaults then apply to it.
struct SitesSettings: View {
    var body: some View {
        let stores = SiteSummary.Stores.app
        let rows = SiteSummary.rows(stores) { id in AppSpaces.all.space(id)?.space.name }
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            if rows.isEmpty {
                Text("No site has settings of its own. Give some from a site's panel in the address field.")
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
            }
            ForEach(rows, id: \.host) { row in
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(row.host)
                        Text(row.parts.joined(separator: " · ")).font(Design.Text.detail).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Forget") {
                        SiteSummary.forget(row.host, in: stores)
                        ContentBlocker.shared.reapplyAll()
                    }
                }
            }
        }
    }
}
