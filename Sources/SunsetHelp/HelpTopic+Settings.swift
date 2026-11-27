extension HelpTopic {
    /// The topic that explains the setting `id` of the file, where one does: its "?" opens it.
    /// - Parameter id: A setting's key ("tabs.keepAwakeDisplay").
    /// - Returns: Its topic, or nil.
    public static func explaining(setting id: String) -> HelpTopic? {
        switch id {
            case "tabs.keepAwakeDisplay": .keepAwake
            case "sidebar.library": .library
            case "web.address": .sidebarField
            case "web.permissions": .sitePermissions
            case "web.approveRiskyDownloads", "web.askWhereToSave": .downloads
            case "profiles.list": .profiles
            case "web.privateWindowShares": .privateBrowsing
            case "spaces.favorites", "spaces.pinned": .spaces
            case "features": .features
            case "control.enabled", "control.typing", "control.tool": .controlFromOutside
            case "web.agent", "web.agentScripts": .browserIdentity
            case "web.blocking": .blocking
            case "passwords.lockAfter", "passwords.backupFolder": .passwords
            default: nil
        }
    }
}
