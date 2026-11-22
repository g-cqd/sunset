import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// The vault's page: the entry chosen (else the first), on a page laid out as Settings' (`PasswordEntryPage`); locked,
/// it is unlocked right here; none yet, what to do. The window is left out of capture while it shows an unlocked vault.
struct PasswordsPage: View {
    @Bindable var content: PasswordsContent
    let context: PaneViewContext
    private let model = AppPasswords.model
    @State private var password = ""
    @State private var refused = false

    private var shown: VaultEntry? {
        model.entries.first { $0.id == content.selected } ?? model.entries.first
    }

    var body: some View {
        Group {
            switch model.state {
                case .unlocked:
                    if let entry = shown {
                        PasswordEntryPage(entry: entry, model: model, editing: content.editsOnOpen)
                            .id(entry.id)
                            .onAppear { content.editsOnOpen = false }
                    } else {
                        ContentUnavailableView(
                            "No Entries Yet",
                            systemImage: "key",
                            description: Text("Make one with + in the Library's Passwords.")
                        )
                    }
                case .locked: locked
                case .none:
                    ContentUnavailableView(
                        "Passwords Are Not Set Up",
                        systemImage: "key",
                        description: Text("Set them up in the Library's Passwords.")
                    )
            }
        }
        .padding(.top, context.topInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paneBackdrop(context.backdrop)
        .background(CaptureExclusion(excluded: model.state == .unlocked))
    }

    private var locked: some View {
        ContentUnavailableView {
            Label("Passwords Are Locked", systemImage: "lock")
        } description: {
            Text(refused ? "That does not unlock this vault." : "Unlock them to see and edit your entries.")
        } actions: {
            VStack(spacing: Design.Space.s) {
                SecureField("Master Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: Self.field)
                    .onSubmit(unlock)
                HStack(spacing: Design.Space.s) {
                    if model.hasTouchID {
                        Button("Use Touch ID") { refused = !model.unlockWithTouchID() }
                    }
                    Button("Unlock", action: unlock).keyboardShortcut(.defaultAction).disabled(password.isEmpty)
                }
            }
        }
    }

    private static let field = 240.0

    private func unlock() {
        refused = !model.unlock(password: password)
        password = ""
    }
}
