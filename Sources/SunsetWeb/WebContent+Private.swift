/// A private page (web step h): its store in memory, its answers its own.
extension WebContent {
    package var isPrivate: Bool { settings.privacy != nil }

    /// Where this page's site answers are: the kept ones, or for a private page its own, in memory, starting from the defaults.
    package var permissions: SitePermissions {
        // A profile with its own defaults (roadmap 0050): the answers kept are shared, the defaults its own.
        if !isPrivate, let defaults = settings.permissionDefaults {
            if let ownPermissions { return ownPermissions }
            let own = SitePermissions.sharing(.shared, defaults: defaults)
            ownPermissions = own
            return own
        }
        guard isPrivate else { return .shared }
        if let ownPermissions { return ownPermissions }
        let own = SitePermissions()
        own.defaults = SitePermissions.shared.defaults
        ownPermissions = own
        return own
    }
}
