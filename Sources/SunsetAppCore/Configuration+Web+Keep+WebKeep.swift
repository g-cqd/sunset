package import SunsetConfig
package import SunsetPane
package import SunsetWebModel

extension Configuration.Web.Keep {
    /// What a store of pages keeps, as the stores read it (ADR-0081): the cache and the traces cleared at quit or kept, the
    /// sites' data kept, kept for the chosen sites, or cleared.
    package var webKeep: WebKeep {
        let siteData: WebKeep.SiteData =
            switch self.siteData {
                case .keep: .keep
                case .keepChosen: .keepChosen
                case .clearOnQuit: .clearOnQuit
            }
        return WebKeep(clearsCache: cache == .clearOnQuit, clearsTraces: traces == .clearOnQuit, siteData: siteData)
    }

    /// What `profile` keeps: its own choices over all profiles' (`app`).
    package static func of(_ profile: Profile, app: Configuration) -> Self {
        ProfileOverrides.apply(profile.overrides, to: app).web.keep
    }
}
