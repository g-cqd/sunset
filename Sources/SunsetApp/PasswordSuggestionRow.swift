import SunsetCredentials
import SwiftUI

/// One login offered: its username and its entry's title, as a menu's item (`FillMenuRow`).
struct PasswordSuggestionRow: View {
    let entry: VaultEntry
    let choose: () -> Void

    var body: some View {
        let name = LoginMatch.credentials(of: entry)?.username ?? ""
        FillMenuRow(title: name.isEmpty ? "No username" : name, detail: PasswordLook.title(entry), choose: choose)
    }
}
