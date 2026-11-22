/// What a page's navigations ask of WebKit: its settings' `httpsUpgrade`, `hardening`, `globalPrivacyControl`.
package enum GlobalPrivacyControl: String, Sendable, Equatable {
    case off, privateWindows, always
}
