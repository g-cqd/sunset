import SunsetAppCore
import SunsetCredentials
import SunsetMetrics
import SunsetShell
import SwiftUI

/// The Library's Passwords section (roadmap 0091 E, ADR-0116): set up the vault, unlock it, or its entries. While it is
/// unlocked and shown, the window is left out of screen capture and sharing.
struct PasswordsSection: View {
    let layout: LayoutMetrics
    let query: String
    @State private var password = ""
    @State private var refused = false
    @State private var opened: VaultEntry.ID?
    private let model = AppPasswords.model

    var body: some View {
        Group {
            switch model.state {
                case .none: invitation
                case .locked: unlock
                case .unlocked: list
            }
        }
        .padding(.horizontal, layout.tabPaddingLeading)
        .background(CaptureExclusion(excluded: model.state == .unlocked))
    }

    private var invitation: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            Text("Keep passwords, cards and notes in a vault of your own, sealed on this Mac.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Set Up Passwords\u{2026}") { PasswordsSetupWindow.present(model: model) }
        }
        .padding(.top, Design.Space.m)
    }

    private var unlock: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            if model.hasTouchID {
                Button("Unlock with Touch ID") { refused = !model.unlockWithTouchID() }
            }
            SecureField("Master Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    refused = !model.unlock(password: password)
                    password = ""
                }
            if refused {
                Text("That does not unlock this vault.").font(Design.Text.detail).foregroundStyle(.red)
            }
        }
        .padding(.top, Design.Space.m)
    }

    @ViewBuilder private var list: some View {
        let found = model.entries.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
        if found.isEmpty {
            Text(model.entries.isEmpty ? "No entries yet: + makes one" : "No entry matches")
                .foregroundStyle(.secondary)
                .padding(.top, Design.Space.m)
        }
        ForEach(found) { entry in
            PasswordEntryRow(entry: entry, isOpen: opened == entry.id, model: model) {
                opened = opened == entry.id ? nil : entry.id
            }
        }
    }
}
