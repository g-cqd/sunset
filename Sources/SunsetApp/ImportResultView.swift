import SunsetImport
import SunsetPane
import SunsetShell
import SwiftUI

/// What an import did (roadmap 0111 G): the bookmarks placed and what was left out; the extensions found, each opened on
/// its store page for the person to install; the containers found, not yet made profiles.
struct ImportResultView: View {
    let outcome: ImportOutcome
    let tabs: TabsModel
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            Text(summary).fixedSize(horizontal: false, vertical: true)
            if !outcome.extensions.isEmpty {
                Text("Extensions").font(Design.Text.title)
                ScrollView {
                    VStack(alignment: .leading, spacing: Design.Space.s) {
                        ForEach(outcome.extensions, id: \.id) { found in row(found) }
                    }
                }
                .bouncesOnlyWhenScrolling()
                .frame(maxHeight: Design.Size.dialogMessage)
            }
            if !outcome.containers.isEmpty { ImportContainers(containers: outcome.containers, tabs: tabs) }
            HStack {
                Spacer()
                Button("Done", action: close).keyboardShortcut(.defaultAction)
            }
        }
    }

    private var summary: String {
        let report = outcome.report
        guard report.links + report.folders > 0 else { return "No bookmarks were found." }
        let links = report.links == 1 ? "1 bookmark" : "\(report.links) bookmarks"
        let placed = "\(links) in the folder \u{201C}\(outcome.folder)\u{201D} of \(outcome.space)\u{2019}s Favorites."
        guard report.leftOut > 0 else { return placed }
        return placed
            + " \(report.leftOut) left out: addresses Sunset does not open (scripts, a browser\u{2019}s own pages), or past what Favorites hold."
    }

    private func row(_ found: BrowserExtension) -> some View {
        HStack {
            Text(found.name).foregroundStyle(found.isEnabled ? .primary : .secondary)
            Spacer()
            if let store = found.store {
                Button("Open Store Page") {
                    tabs.newTab(.page(store))
                    close()
                }
            }
        }
    }
}
