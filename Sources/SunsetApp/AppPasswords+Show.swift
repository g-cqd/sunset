import SunsetCredentials
import SunsetPane
import SunsetShell

extension AppPasswords {
    /// The vault's page in the window: its tab (the one that is there, else a new one), on `entry`.
    static func content(in tabs: TabsModel) -> PasswordsContent? {
        tabs.single(kind: PasswordsContent.kind) as? PasswordsContent
    }

    static func show(_ entry: VaultEntry.ID, in tabs: TabsModel) {
        let shown = tabs.showSingle(.passwords) as? PasswordsContent
        shown?.selected = entry
    }
}
