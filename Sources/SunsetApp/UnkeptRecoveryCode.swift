import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// A new vault's recovery code, with Copy and the button that says it was kept: in the setup window, and at the head of the
/// Passwords section until then (t333: the window was seen closing by itself, and the code, shown once, was lost).
struct UnkeptRecoveryCode: View {
    let code: RecoveryCode
    /// The button's title: "Done" in the setup window, "I Kept It" in the section.
    let done: String
    let leading: Double
    let kept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            Text("Your Recovery Code").font(Design.Text.title)
            Text(
                "It opens the vault if you forget the password and Touch ID cannot. Write it down or keep it somewhere safe: it is not shown again once kept."
            )
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            Text(code.text).font(Design.Text.body.monospaced()).textSelection(.enabled)
            HStack {
                FeedbackButton("Copy") { Clipboard.copy(code.text, concealed: true, what: "Recovery code copied") }
                Button("Print Emergency Sheet…") { PasswordsBackup.printEmergencySheet(code: code) }
                Spacer()
                // Return confirms it in the setup window only: in the sidebar, a Return meant for elsewhere must not.
                if leading == 0 {
                    Button(done, action: kept).keyboardShortcut(.defaultAction)
                } else {
                    Button(done, action: kept)
                }
            }
        }
        .padding(.leading, leading)
    }
}
