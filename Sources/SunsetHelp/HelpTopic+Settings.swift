extension HelpTopic {
    /// The topic that explains the setting `id` of the file, where one does (roadmap 0041 C): its "?" opens it.
    /// - Parameter id: A setting's key ("tabs.keepAwakeDisplay").
    /// - Returns: Its topic, or nil.
    public static func explaining(setting id: String) -> HelpTopic? {
        settings[id]
    }

    static let settings: [String: HelpTopic] = [
        "tabs.keepAwakeDisplay": .keepAwake,
        "tabs.keepRunningForFavorites": .favorites,
        "sidebar.library": .library,
        "sidebar.documentSort": .library,
        "web.address": .sidebarField,
        "web.permissions": .sitePermissions,
        "web.approveRiskyDownloads": .downloads,
        "web.askWhereToSave": .downloads,
        "profiles.list": .profiles,
        "web.privateWindowShares": .privateBrowsing,
        "web.httpFallback": .plainHTTP,
        "spaces.favorites": .spaces,
        "spaces.pinned": .spaces,
        "features": .features,
        "web.agent": .browserIdentity,
        "web.agentScripts": .browserIdentity
    ]
}
