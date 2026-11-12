/// A private page (web step h): its store in memory, its answers its own.
extension WebContent {
    package var isPrivate: Bool { settings.privacy != nil }

    /// Where this page's site answers are: the kept ones, or for a private page its own, in memory, starting from the defaults.
    package var permissions: SitePermissions {
        guard isPrivate else { return .shared }
        if let ownPermissions { return ownPermissions }
        let own = SitePermissions()
        own.defaults = SitePermissions.shared.defaults
        ownPermissions = own
        return own
    }
}
