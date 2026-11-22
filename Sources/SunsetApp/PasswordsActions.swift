import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// The Passwords section's title row, while the vault is unlocked: a new entry from a template, and locking it.
struct PasswordsActions: View {
    let model: PasswordsModel
    let size: CGSize

    var body: some View {
        if model.state == .unlocked {
            SectionMenuButton(symbol: "plus", label: "New Entry", size: size) {
                ForEach(EntryTemplate.shipped) { template in
                    Button(template.name, systemImage: template.symbol) {
                        _ = try? model.add(from: template, title: "New \(template.name)")
                    }
                }
            }
            SidebarIconButton(symbol: "lock", help: "Lock Passwords") { model.lock() }
                .accessibilityLabel("Lock Passwords")
        }
    }
}
