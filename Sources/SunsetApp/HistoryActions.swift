import SunsetShell
import SunsetShellModel
import SunsetWebModel
import SwiftUI

/// The history's title row: with several profiles, how the pages are listed by profile; and Clear History….
struct HistoryActions: View {
    let tabs: TabsModel
    @AppStorage("history.profiles") private var profiles = HistoryProfiles.all.rawValue

    var body: some View {
        if AppSpaces.all.profiles.profiles.count > 1 {
            SidebarIconMenu(symbol: "person.2", help: "History by profile") {
                Picker("Profiles", selection: $profiles) {
                    ForEach(HistoryProfiles.allCases, id: \.self) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        Button("Clear\u{2026}") { AppActions.shared.clearHistory() }
            .buttonStyle(.quiet)
            .font(Design.Text.detail)
            .disabled(AppHistory.shared?.count ?? 0 == 0)
            .accessibilityLabel("Clear History")
    }
}
