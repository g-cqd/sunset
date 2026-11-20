import AemiTestKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Task t115: a page's view asks WebKit for what the settings say: HTTPS first, the hardened mode, Global Privacy Control
/// (read by the page as `navigator.globalPrivacyControl`, sent as `Sec-GPC`).
@MainActor @Suite("The web's protections: on the page", .timeLimit(.minutes(1)))
struct WebProtectionTests {
    @Test func `the view's navigations carry the settings' policy`() throws {
        var settings = WebSettings(applicationName: "x")
        settings.httpsUpgrade = .only
        settings.hardening = .noJIT
        let page = WebContent(url: nil, settings: settings)
        page.setState(focused: false, visible: true)
        let preferences = try #require(page.webView?.configuration.defaultWebpagePreferences)
        #expect(preferences.preferredHTTPSNavigationPolicy == .errorOnFailure)
        if #available(macOS 26.4, *) { #expect(preferences.securityRestrictionMode == .maximizeCompatibility) }
        page.stop()
    }

    @Test func `defaults: https first with a fallback, no hardened mode`() throws {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "x"))
        page.setState(focused: false, visible: true)
        let preferences = try #require(page.webView?.configuration.defaultWebpagePreferences)
        #expect(preferences.preferredHTTPSNavigationPolicy == .automaticFallbackToHTTP)
        if #available(macOS 26.4, *) { #expect(preferences.securityRestrictionMode == WKSecurityRestrictionMode.none) }
        page.stop()
    }

    @Test(arguments: [
        (GlobalPrivacyControl.always, false, true), (.privateWindows, false, false), (.privateWindows, true, true),
        (.off, true, false)
    ])
    func `Global Privacy Control as set, a private window by its own rule`(
        control: GlobalPrivacyControl,
        isPrivate: Bool,
        sent: Bool
    ) async throws {
        guard #available(macOS 27, *) else { return }
        var settings = WebSettings(applicationName: "x")
        settings.globalPrivacyControl = control
        if isPrivate { settings.privacy = PagePrivacy() }
        let page = WebContent(url: nil, settings: settings)
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString("<p>x</p>", baseURL: URL(string: "https://shop.example/"))
        try await waitForObservedState { !page.isLoading && page.webView?.url?.host() == "shop.example" }
        // Off, the property is not there at all, as in Safari (the inventory against a driven Safari, 2026-11-20): a page
        // reading `false` where Safari has nothing tells Sunset from it.
        let read = try await view.callAsyncJavaScript(
            "return 'globalPrivacyControl' in navigator ? String(navigator.globalPrivacyControl) : 'absent'",
            contentWorld: .page
        )
        #expect(read as? String == (sent ? "true" : "absent"))
        page.stop()
    }
}
