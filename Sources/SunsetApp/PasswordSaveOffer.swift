import SunsetShell
import SwiftUI

/// The offer to save a password just sent, short as macOS's own: what for, then Save (or Update), Never for This Site and
/// Not Now. Clicked away, it is Not Now.
struct PasswordSaveOffer: View {
    enum Answer { case save, never, notNow }

    let site: String
    let username: String
    let isUpdate: Bool
    let answer: (Answer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            HStack(alignment: .top, spacing: Design.Space.s) {
                Image(systemName: "key.fill").font(Design.Text.title).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: Design.Space.hair) {
                    Text(isUpdate ? "Update the password for \(site)?" : "Save a password for \(site)?").font(.headline)
                    if !username.isEmpty {
                        Text(username).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }
            HStack(spacing: Design.Space.s) {
                Button("Never for This Site") { answer(.never) }
                Spacer(minLength: Design.Space.m)
                Button("Not Now") { answer(.notNow) }
                Button(isUpdate ? "Update" : "Save") { answer(.save) }.keyboardShortcut(.defaultAction)
            }
            .controlSize(.small)
        }
        .padding(Design.Space.m)
        .frame(width: Self.width)
    }

    private static let width = 320.0
}
