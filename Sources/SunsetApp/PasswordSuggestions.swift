import SunsetCredentials
import SunsetShell
import SwiftUI

/// The logins a sign-in field is offered, as macOS lists its own: a key, the username, the entry's title; the row under
/// the pointer highlighted as a menu's item (the accent, white text). Nothing is filled until one is clicked.
struct PasswordSuggestions: View {
    let logins: [VaultEntry]
    /// True when the page origin uses unencrypted `http://` (non-loopback) so the person sees a clear warning before
    /// filling credentials (roadmap 0094 / t103).
    var isInsecureOrigin = false
    let choose: (VaultEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isInsecureOrigin {
                Label("Not Secure (HTTP) — password sent unencrypted", systemImage: "exclamationmark.triangle.fill")
                    .font(Design.Text.detail)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, Design.Space.s)
                    .padding(.vertical, Design.Space.xs)
                Divider()
                    .padding(.bottom, Design.Space.hair)
            }
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
