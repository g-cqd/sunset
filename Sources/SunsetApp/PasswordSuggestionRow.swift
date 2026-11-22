import SunsetCredentials
import SunsetShell
import SwiftUI

/// One login offered: drawn as a menu's item, highlighted under the pointer (the accent's fill, white text and glyph).
struct PasswordSuggestionRow: View {
    let entry: VaultEntry
    let choose: () -> Void
    @State private var hovered = false

    private var username: String {
        let name = LoginMatch.credentials(of: entry)?.username ?? ""
        return name.isEmpty ? "No username" : name
    }

    var body: some View {
        Button(action: choose) {
            HStack(spacing: Design.Space.s) {
                Image(systemName: "key.fill")
                    .foregroundStyle(hovered ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                    .frame(width: Design.Size.glyphFrame)
                VStack(alignment: .leading, spacing: Design.Space.hair) {
                    Text(username).lineLimit(1)
                    Text(PasswordLook.title(entry))
                        .font(Design.Text.detail)
                        .foregroundStyle(
                            hovered
                                ? AnyShapeStyle(.white.opacity(Design.Fill.inkSecondary)) : AnyShapeStyle(.secondary)
                        )
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(hovered ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .padding(.horizontal, Design.Space.s)
            .padding(.vertical, Design.Space.xs)
            .background(
                Color.accentColor.opacity(hovered ? 1 : 0),
                in: RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityLabel("\(username), \(PasswordLook.title(entry))")
    }

    /// A menu item's highlight corner.
    private static let corner = 5.0
}
