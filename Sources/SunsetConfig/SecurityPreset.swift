/// The security model asked about in the welcome: one choice for the settings that weigh safety against pages working,
/// each still its own in Settings ▸ Privacy.
public enum SecurityPreset: String, Sendable, Equatable, CaseIterable {
    /// What Sunset ships with.
    case balanced
    /// Safer, at the cost of some pages: HTTPS only, the engine hardened, Global Privacy Control always.
    case strict
    /// Pages first: no blocking, no privacy signal, addresses as written.
    case compatible

    /// The settings a model stands for.
    private struct Settings {
        let https: Configuration.Web.HTTPSUpgrade
        let hardening: Configuration.Web.Hardening
        let gpc: Configuration.Web.PrivacyControl
        let blocking: Bool
    }

    private var settings: Settings {
        switch self {
            case .balanced: Settings(https: .fallback, hardening: .off, gpc: .privateWindows, blocking: true)
            case .strict: Settings(https: .only, hardening: .noJIT, gpc: .always, blocking: true)
            case .compatible: Settings(https: .fallback, hardening: .off, gpc: .off, blocking: false)
        }
    }

    /// Its name where it is offered.
    public var title: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }

    /// What it does, in a line.
    public var summary: String {
        switch self {
            case .balanced: "Ads and trackers blocked, HTTPS tried first, privacy asked for in private windows."
            case .strict: "HTTPS only, the web engine hardened, privacy asked for everywhere. Some pages break."
            case .compatible: "Nothing blocked, addresses as written. For pages that refuse the others."
        }
    }

    /// Sets the settings it stands for.
    public func apply(to web: inout Configuration.Web) {
        let settings = settings
        web.httpsUpgrade = settings.https
        web.hardening = settings.hardening
        web.globalPrivacyControl = settings.gpc
        web.blocking = settings.blocking
    }

    /// The preset `web` is set as; nil when it was set by hand to something else.
    public static func matching(_ web: Configuration.Web) -> Self? {
        allCases.first { preset in
            let settings = preset.settings
            return web.httpsUpgrade == settings.https && web.hardening == settings.hardening
                && web.globalPrivacyControl == settings.gpc && web.blocking == settings.blocking
        }
    }
}
