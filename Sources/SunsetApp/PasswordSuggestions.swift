import SunsetCredentials
import SunsetShell
import SwiftUI

/// The logins a sign-in field is offered, as macOS lists its own: a key, the username, the entry's title; the row under
/// the pointer highlighted as a menu's item (the accent, white text). Nothing is filled until one is clicked.
struct PasswordSuggestions: View {
    let logins: [VaultEntry]
    let choose: (VaultEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(logins.prefix(Self.most)) { entry in
                PasswordSuggestionRow(entry: entry) { choose(entry) }
            }
        }
        .padding(Self.inset)
        .frame(width: Self.width)
    }

    /// At most this many, as AutoFill keeps its list short.
    private static let most = 5
    private static let width = 260.0
    /// From the popover's edge to the rows' highlight, as a menu's.
    private static let inset = 5.0
}
