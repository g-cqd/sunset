import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// What WebKit is asked per navigation (probed 2026-11-20, `/tmp/n64probe`): `.userMediatedFallbackToHTTP` commits
/// `about:blank` where Safari would show its own warning, so "ask" loaded nothing for a site without HTTPS; this machine and
/// the local network are not upgraded at all; a host the person let over HTTP on this page is kept as asked.
@Suite("HTTPS first, per host")
struct HTTPSUpgradePolicyTests {
    @Test func `ask fails visibly; local hosts and hosts let through are kept as asked`() {
        #expect(HTTPSUpgrade.ask.policy(host: "neverssl.com", allowedOverHTTP: []) == .failVisibly)
        #expect(HTTPSUpgrade.ask.policy(host: "127.0.0.1", allowedOverHTTP: []) == .keepAsRequested)
        #expect(HTTPSUpgrade.only.policy(host: "nas.local", allowedOverHTTP: []) == .keepAsRequested)
        #expect(HTTPSUpgrade.ask.policy(host: "neverssl.com", allowedOverHTTP: ["neverssl.com"]) == .keepAsRequested)
        #expect(HTTPSUpgrade.fallback.policy(host: "neverssl.com", allowedOverHTTP: []) == .fallBackQuietly)
        #expect(HTTPSUpgrade.only.policy(host: "neverssl.com", allowedOverHTTP: ["neverssl.com"]) == .failVisibly)
        #expect(HTTPSUpgrade.off.policy(host: "neverssl.com", allowedOverHTTP: []) == .keepAsRequested)
    }

    /// The owner, 2026-11-20: one setting. An address typed without a scheme, failing over HTTPS, is tried over HTTP without a
    /// word only where Secure connections says so (or does not upgrade at all); "ask" shows the failure page with Load over
    /// HTTP; "only" stays failed.
    @Test func `a typed address falls back to http as Secure connections says`() {
        #expect(HTTPSUpgrade.fallback.retriesTypedOverHTTP)
        #expect(HTTPSUpgrade.off.retriesTypedOverHTTP)
        #expect(!HTTPSUpgrade.ask.retriesTypedOverHTTP)
        #expect(!HTTPSUpgrade.only.retriesTypedOverHTTP)
    }
}
