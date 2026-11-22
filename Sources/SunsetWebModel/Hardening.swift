/// What a page's navigations ask of WebKit: its settings' `httpsUpgrade`, `hardening`, `globalPrivacyControl`.
package enum Hardening: String, Sendable, Equatable {
    case off, noJIT
}
