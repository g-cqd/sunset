import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// The Passwords section's title row, while the vault is unlocked: a new entry from a template, opened on the vault's page
/// to be filled in; and locking it.
struct PasswordsActions: View {
    let model: PasswordsModel
    /// The window, where a new entry opens to be filled in.
    let tabs: TabsModel
    let size: CGSize

    var body: some View {
        if model.state == .unlocked {
            SectionMenuButton(symbol: "plus", label: "New Entry", size: size) {
                ForEach(EntryTemplate.shipped) { template in
                    Button(template.name, systemImage: template.symbol) {
                        guard let made = try? model.add(from: template, title: "") else { return }
                        AppPasswords.show(made.id, in: tabs, editing: true)
                    }
                }
            }
            SidebarIconButton(symbol: "lock", help: "Lock Passwords") { model.lock() }
                .accessibilityLabel("Lock Passwords")
        }
    }
}
