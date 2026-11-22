import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// The vault's page: the entry chosen, edited (`PasswordEntryPage`); none chosen, what to do; locked or not set up, the
/// way to it in the Library. The window is left out of capture while it shows an unlocked vault.
struct PasswordsPage: View {
    @Bindable var content: PasswordsContent
    let context: PaneViewContext
    private let model = AppPasswords.model

    var body: some View {
        Group {
            if model.state == .unlocked, let id = content.selected,
                let entry = model.entries.first(where: { $0.id == id })
            {
                PasswordEntryPage(entry: entry, model: model).id(entry.id)
            } else {
                ContentUnavailableView(
                    model.state == .unlocked ? "No Entry Chosen" : "Passwords Are Locked",
                    systemImage: model.state == .unlocked ? "key" : "lock",
                    description: Text(
                        model.state == .unlocked
                            ? "Choose an entry in the Library's Passwords, or make one with +."
                            : "Unlock them in the Library's Passwords."
                    )
                )
            }
        }
        .padding(.top, context.topInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paneBackdrop(context.backdrop)
        .background(CaptureExclusion(excluded: model.state == .unlocked))
    }
}
