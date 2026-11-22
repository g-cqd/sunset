/// What WebKit offers each navigation, as the settings name it.
extension Configuration.Web {
    /// An http address: as asked, tried over https first and fallen back to http (Not Secure shown, as Safari does), the same
    /// after the person's answer to a warning, or https only.
    public enum HTTPSUpgrade: String, Sendable, Equatable, CaseIterable {
        case off, fallback, ask, only
    }

    /// WebKit's hardened mode (macOS 26.4): no JIT and more memory tagging, for pages that are more exposed than fast.
    public enum Hardening: String, Sendable, Equatable, CaseIterable {
        case off, noJIT
    }

    /// The Global Privacy Control signal (macOS 27): `navigator.globalPrivacyControl` and `Sec-GPC: 1`.
    public enum PrivacyControl: String, Sendable, Equatable, CaseIterable {
        case off, privateWindows, always
    }
}
