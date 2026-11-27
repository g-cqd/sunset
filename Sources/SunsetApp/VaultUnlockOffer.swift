import SunsetAppCore
import SunsetShell
import SwiftUI

/// Shown under a sign-in, email or one-time code field while the vault is locked (`passwords.offerUnlock`):
/// starts as a single menu row ("Unlock Passwords…"); clicking it unlocks with Touch ID when available, or expands a
/// compact master-password field inside the panel, then calls `unlocked()` so matching entries appear immediately.
struct VaultUnlockOffer: View {
    let model: PasswordsModel
    /// Called when the inline password field needs the panel to accept keyboard focus.
    let requestKeyFocus: () -> Void
    let unlocked: () -> Void
    @State private var askingPassword = false
    @State private var password = ""
    @State private var refused = false
    @FocusState private var typing: Bool

    var body: some View {
        Group {
            if askingPassword {
                passwordForm
            } else {
                FillMenuRow(
                    title: "Unlock Passwords\u{2026}",
                    detail: model.hasTouchID ? "Use Touch ID or Master Password" : "Enter Master Password",
                    symbol: model.hasTouchID ? "touchid" : "lock.fill"
                ) {
                    if model.hasTouchID, model.unlockWithTouchID() {
                        unlocked()
                    } else {
                        askingPassword = true
                        requestKeyFocus()
                        typing = true
                    }
                }
            }
        }
        .padding(FillMenuRow.inset)
        .frame(width: Self.width)
    }

    private var passwordForm: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            HStack(spacing: Design.Space.s) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: Design.Size.glyphFrame)
                Text("Unlock Passwords").font(.subheadline.weight(.medium))
            }
            SecureField("Master Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .focused($typing)
                .onSubmit(submit)
            if refused {
                Text(refusedMessage)
                    .font(Design.Text.detail)
                    .foregroundStyle(.orange)
            }
            HStack(spacing: Design.Space.s) {
                if model.hasTouchID {
                    Button("Touch ID") {
                        if model.unlockWithTouchID() { unlocked() }
                    }
                }
                Spacer(minLength: 0)
                Button("Unlock", action: submit)
                    .keyboardShortcut(.defaultAction)
                    .disabled(password.isEmpty)
            }
            .controlSize(.small)
        }
        .padding(.horizontal, Design.Space.xs)
        .padding(.vertical, Design.Space.xs)
        .onAppear {
            requestKeyFocus()
            typing = true
        }
    }

    private var refusedMessage: String {
        if let wait = model.retryIn {
            return "Wrong password. Try again in \(Int(wait.components.seconds) + 1) s."
        }
        return "That does not unlock this vault."
    }

    private func submit() {
        if model.unlock(password: password) {
            password = ""
            refused = false
            unlocked()
        } else {
            password = ""
            refused = true
        }
    }

    private static let width = 264.0
}
