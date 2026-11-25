import Foundation
import Testing

@testable import SunsetWebModel

/// A store's page names the extension; Sunset fetches its package from the store itself (probed 2026-11-20: Chrome's
/// update service answers a CRX3 for an id; Firefox Add-ons' API names the `.xpi`).
@Suite("A store's page, and where its package is")
struct ExtensionStoreLinkTests {
    @Test func `Chrome Web Store and Firefox Add-ons pages are read; others are not`() throws {
        let chrome = try #require(
            URL(string: "https://chromewebstore.google.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh?hl=en")
        )
        #expect(ExtensionStoreLink(chrome) == .chrome(id: "eimadpbcbfnmbkopoojfekhnkhdbieeh"))
        let old = try #require(
            URL(string: "https://chrome.google.com/webstore/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh")
        )
        #expect(ExtensionStoreLink(old) == .chrome(id: "eimadpbcbfnmbkopoojfekhnkhdbieeh"))
        let firefox = try #require(URL(string: "https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/"))
        #expect(ExtensionStoreLink(firefox) == .firefox(slug: "ublock-origin"))
        #expect(
            ExtensionStoreLink(try #require(URL(string: "https://chromewebstore.google.com/category/extensions")))
                == nil
        )
        #expect(
            ExtensionStoreLink(
                try #require(URL(string: "https://example.com/detail/x/eimadpbcbfnmbkopoojfekhnkhdbieeh"))
            ) == nil
        )
        #expect(
            ExtensionStoreLink(try #require(URL(string: "http://addons.mozilla.org/en-US/firefox/addon/x/"))) == nil,
            "https only"
        )
    }

    @Test func `Chrome's package comes from its update service, Firefox's through the API`() throws {
        let chrome = ExtensionStoreLink.chrome(id: "eimadpbcbfnmbkopoojfekhnkhdbieeh").source
        #expect(chrome.host() == "clients2.google.com")
        #expect(chrome.query()?.contains("x=id%3Deimadpbcbfnmbkopoojfekhnkhdbieeh%26uc") == true)
        #expect(chrome.query()?.contains("acceptformat=crx2,crx3") == true)
        let firefox = ExtensionStoreLink.firefox(slug: "ublock-origin").source
        #expect(firefox.absoluteString == "https://addons.mozilla.org/api/v5/addons/addon/ublock-origin/")
        let api =
            #"{"current_version": {"file": {"url": "https://addons.mozilla.org/firefox/downloads/file/1/x.xpi"}}}"#
        #expect(ExtensionStoreLink.firefoxPackage(fromAPI: Data(api.utf8))?.lastPathComponent == "x.xpi")
        #expect(
            ExtensionStoreLink.firefoxPackage(
                fromAPI: Data(#"{"current_version": {"file": {"url": "http://evil/x.xpi"}}}"#.utf8)
            ) == nil
        )
        #expect(
            ExtensionStoreLink.firefoxPackage(
                fromAPI: Data(#"{"current_version": {"file": {"url": "https://evil.example/x.xpi"}}}"#.utf8)
            ) == nil,
            "refuse non-Mozilla HTTPS host (N-S4)"
        )
    }
}
