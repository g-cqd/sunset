/// What a page's navigations ask of WebKit (task t115): its settings' `httpsUpgrade`, `hardening`, `globalPrivacyControl`.
package enum GlobalPrivacyControl: String, Sendable, Equatable {
    case off, privateWindows, always
}
