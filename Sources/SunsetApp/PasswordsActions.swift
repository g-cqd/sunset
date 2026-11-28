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
    @State private var showingHealth = false

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
                Button("Password Health\u{2026}", systemImage: "checkmark.shield") {
                    showingHealth = true
                }
                Divider()
                Button("Back Up Vault (.svault)…", systemImage: "externaldrive.badge.plus") {
                    PasswordsBackup.backup(from: model)
                }
                Button("Restore from Backup (.svault)…", systemImage: "arrow.counterclockwise") {
                    PasswordsBackup.restore(into: model)
                }
                Divider()
                Button("Import Logins…", systemImage: "square.and.arrow.down") {
                    PasswordsImport.run(into: model)
                }
                Button("Export Logins to CSV…", systemImage: "square.and.arrow.up") {
                    PasswordsImport.export(from: model)
                }
                Button("Export as KeePass Database…", systemImage: "square.and.arrow.up.on.square") {
                    PasswordsKeePassExport.run(from: model)
                }
            }
            .sheet(isPresented: $showingHealth) {
                VaultHealthSheet(model: model) { id in
                    AppPasswords.show(id, in: tabs, editing: true)
                }
            }
            SidebarIconButton(symbol: "lock", help: "Lock Passwords") { model.lock() }
                .accessibilityLabel("Lock Passwords")
        }
    }
}
