import Foundation
import SunsetPane
import SunsetShell
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

@MainActor @Suite("A web page as a pane's content") struct WebContentTests {
    private let settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")

    @Test func `the page is made only when it is first shown`() {
        let page = WebContent(url: URL(string: "https://example.com"), settings: settings)
        #expect(page.webView == nil)
        page.setState(focused: false, visible: false)
        #expect(page.webView == nil)
        page.setState(focused: true, visible: true)
        #expect(page.webView != nil)
        #expect(page.webView?.configuration.applicationNameForUserAgent == "Version/26.0 Safari/605.1.15")
        #expect(page.webView?.configuration.websiteDataStore.isPersistent == true)
        page.stop()
        #expect(page.webView == nil)
    }

    /// Profiles (ADR-0053): a profile's pages have a website data store of their own; the first profile's is the one
    /// there always was; a private page's is never a profile's.
    @Test func `a page of a profile has that profile's website data; of the first, the default one; private, its own`()
    {
        let profile = UUID()
        var own = settings
        own.profile = profile
        let page = WebContent(url: URL(string: "https://example.com"), settings: own)
        page.setState(focused: true, visible: true)
        let store = page.webView?.configuration.websiteDataStore
        #expect(store?.identifier == profile && store?.isPersistent == true)
        let first = WebContent(url: URL(string: "https://example.com"), settings: settings)
        first.setState(focused: true, visible: true)
        #expect(first.webView?.configuration.websiteDataStore === WKWebsiteDataStore.default())
        own.privacy = PagePrivacy()
        let hidden = WebContent(url: URL(string: "https://example.com"), settings: own)
        hidden.setState(focused: true, visible: true)
        #expect(hidden.webView?.configuration.websiteDataStore.isPersistent == false)
        for one in [page, first, hidden] { one.stop() }
    }

    @Test func `its descriptor keeps the address and the title, and reads back`() {
        let page = WebContent(url: URL(string: "https://example.com/a"), title: "Example", settings: settings)
        let descriptor = page.descriptor
        #expect(
            descriptor.kind == "web" && descriptor.state["url"] == "https://example.com/a"
                && descriptor.state["title"] == "Example"
        )
        let back = WebContent(descriptor: descriptor, settings: settings)
        #expect(back.url == page.url && back.title == "Example")
    }

    @Test func `an empty page is titled New Page and its descriptor holds no address`() {
        let page = WebContent(url: nil, settings: settings)
        #expect(page.title == "New Page" && page.descriptor.state.isEmpty)
    }

    @Test func `the tab shows the first letter of the title, or a globe by the setting`() {
        #expect(WebContent(url: nil, title: "github", settings: settings).glyph == .initial("G"))
        var globe = settings
        globe.initialIcon = false
        #expect(WebContent(url: nil, title: "github", settings: globe).glyph == .symbol("globe"))
        #expect(
            WebContent(url: nil, title: "123", settings: settings).glyph == .symbol("globe"),
            "no letter in the title"
        )
    }

    @Test func `a cancelled load is no failure; a certificate the system refuses is one, and says so`() {
        #expect(WebFailure(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled), url: nil) == nil)
        #expect(WebFailure(NSError(domain: "WebKitErrorDomain", code: 102), url: nil) == nil)
        let url = URL(string: "https://self-signed.local")
        let certificate = WebFailure(
            NSError(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted),
            url: url
        )
        #expect(certificate?.isCertificate == true && certificate?.url == url)
        #expect(
            WebFailure(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet), url: url)?
                .isCertificate == false
        )
    }

    @Test func `Visit Anyway accepts that host's certificate for this page`() {
        let url = URL(string: "https://box.local:8443/")
        let page = WebContent(url: url, settings: settings)
        page.failure = WebFailure(
            NSError(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted),
            url: url
        )
        page.acceptCertificate()
        #expect(page.acceptedHosts == ["box.local"] && page.failure == nil)
    }
}
