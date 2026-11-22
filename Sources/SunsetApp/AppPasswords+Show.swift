import SunsetCredentials
import SunsetPane
import SunsetShell

extension AppPasswords {
    /// The vault's page in the window: its tab (the one that is there, else a new one), on `entry`.
    static func content(in tabs: TabsModel) -> PasswordsContent? {
        tabs.single(kind: PasswordsContent.kind) as? PasswordsContent
    }

    /// The page on `entry`; `editing`: ready to be filled in (a new one).
    static func show(_ entry: VaultEntry.ID, in tabs: TabsModel, editing: Bool = false) {
        let shown = tabs.showSingle(.passwords) as? PasswordsContent
        shown?.editsOnOpen = editing
        shown?.selected = entry
    }
}
