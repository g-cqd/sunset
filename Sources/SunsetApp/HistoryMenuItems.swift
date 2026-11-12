import SunsetWeb
import SwiftUI

/// The History menu's list (web step e): the last ten pages, then Show All History and Clear History…
struct HistoryMenuItems: View {
    let page: WebContent?
    private var changes = HistoryChanges.shared

    init(page: WebContent?) { self.page = page }

    var body: some View {
        let _ = changes.generation
        let recent = AppHistory.shared?.recent(limit: 10) ?? []
        if !recent.isEmpty {
            Divider()
            ForEach(recent) { entry in
                Button(entry.title.isEmpty ? AddressChoice.shortAddress(entry.url) : entry.title) {
                    AppActions.shared.openFromHistory(entry.url, newTab: false)
                }
            }
        }
        Divider()
        Button("Show All History") { AppActions.shared.toggleHistoryPanel(show: true) }.keyboardShortcut("y")
        Button("Clear History\u{2026}") { AppActions.shared.clearHistory() }
    }
}
