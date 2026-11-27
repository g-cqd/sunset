import SunsetCredentials
import SunsetShell
import SwiftUI

/// The logins a sign-in field is offered: a key, the username, the entry's title; the row under the pointer highlighted
/// with concentric corner geometry (`FillMenuRow`). Nothing is filled until one is clicked.
struct PasswordSuggestions: View {
    let logins: [VaultEntry]
    /// True when the page origin uses unencrypted `http://` (non-loopback) so the person sees a clear warning before
    /// filling credentials (roadmap 0094 / t103).
    var isInsecureOrigin = false
    let choose: (VaultEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.hair) {
            if isInsecureOrigin {
                Label("Not Secure (HTTP) — password sent unencrypted", systemImage: "exclamationmark.triangle.fill")
                    .font(Design.Text.detail)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, Design.Space.s)
                    .padding(.vertical, Design.Space.xs)
                Divider()
                    .opacity(Design.Fill.fainterDivider)
                    .padding(.bottom, Design.Space.hair)
            }
            ForEach(logins.prefix(Self.most)) { entry in
                PasswordSuggestionRow(entry: entry) { choose(entry) }
            }
        }
        .padding(FillMenuRow.inset)
        .frame(width: Self.width)
    }

    /// At most this many, as AutoFill keeps its list short.
    private static let most = 5
    private static let width = 264.0
}
