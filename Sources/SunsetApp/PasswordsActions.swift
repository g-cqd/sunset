import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// The Passwords section's title row, while the vault is unlocked: a new entry from a template, opened on the vault's page
/// to be filled in; logins imported from a CSV file; and locking it.
struct PasswordsActions: View {
    let model: PasswordsModel
    /// The window, where a new entry opens to be filled in.
    let tabs: TabsModel

    var body: some View {
        if model.state == .unlocked {
            SidebarIconMenu(symbol: "plus", help: "New Entry") {
                ForEach(EntryTemplate.shipped) { template in
                    Button(template.name, systemImage: template.symbol) {
                        guard let made = try? model.add(from: template, title: "") else { return }
                        AppPasswords.show(made.id, in: tabs, editing: true)
                    }
                }
            }
            SidebarIconMenu(symbol: "ellipsis", help: "More") {
                Button("Import Logins…", systemImage: "square.and.arrow.down") {
                    PasswordsImport.run(into: model)
                }
                Button("Export Logins to CSV…", systemImage: "square.and.arrow.up") {
                    PasswordsImport.export(from: model)
                }
            }
            SidebarIconButton(symbol: "lock", help: "Lock Passwords") { model.lock() }
                .accessibilityLabel("Lock Passwords")
        }
    }
}
