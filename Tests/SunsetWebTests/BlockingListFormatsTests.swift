import Foundation
import Testing

@testable import SunsetWeb

/// Other lists than EasyList's. A hosts file (StevenBlack, OISD's hosts form) blocks its hosts and never `localhost`; a `#`
/// comment is not element hiding; a site written as a regular expression is left out (AdGuard Base was refused whole by
/// WebKit for one); a list past WebKit's limit is split, its exceptions in every part.
@Suite("Blocking lists: other formats and sizes")
struct BlockingListFormatsTests {
    @Test func `a hosts file blocks its hosts, never the machine's own names; its comments are comments`() throws {
        let made = BlockingRules.convert(
            """
            # Title: a hosts file
            ### Version Information #
            # START HOSTS LIST ### DO NOT EDIT THIS LINE AT ALL ###
            127.0.0.1 localhost
            127.0.0.1 localhost.localdomain
            ::1 ip6-localhost ip6-loopback
            0.0.0.0 0.0.0.0
            255.255.255.255 broadcasthost
            0.0.0.0 ads.example.com
            0.0.0.0 tracker.example.net # a comment after
            127.0.0.1 one.example two.example
            """
        )
        #expect(made.skipped == 0, "a comment or the machine's own name is neither a rule nor left out")
        #expect(made.rules.allSatisfy { $0.action.type == "block" })
        let filters = try made.rules.map { try Regex($0.trigger.urlFilter) }
        let blocked = { (url: String) in filters.contains { url.contains($0) } }
        #expect(blocked("https://ads.example.com/x.js") && blocked("https://cdn.ads.example.com/"))
        #expect(
            blocked("https://tracker.example.net/p") && blocked("http://one.example/") && blocked("http://two.example/")
        )
        #expect(!blocked("http://localhost:8770/") && !blocked("http://localhost.localdomain/"))
        #expect(made.rules.count == 4)
    }

    @Test func `a site is a host name: a regular expression or a wildcard ending is left out, not given to WebKit`() {
        let made = BlockingRules.convert(
            """
            /^kiryuu0\\d+\\.com/##div[class*=" ads-"] > a > img
            example.*##.banner
            ||ads.example^$domain=/^news\\d+\\.example/
            news.example##.ok
            ||ok.example^$domain=news.example|~sub.news.example
            """
        )
        #expect(made.skipped == 3)
        #expect(made.rules.count == 2)
        let sites = made.rules.flatMap { ($0.trigger.ifDomain ?? []) + ($0.trigger.unlessDomain ?? []) }
        #expect(sites.allSatisfy { $0.wholeMatch(of: /\*[a-z0-9.-]+/) != nil })
    }

    @Test func `past the limit a list is split, each part with every exception; bounded by a count of parts`() {
        let blocks = (0 ..< 25).map { "||site\($0).example^" }
        let text = (blocks + ["@@||site3.example^$script", "@@||site7.example^"]).joined(separator: "\n")
        let made = BlockingRules.convert(text, limit: 10, parts: 4)
        #expect(made.skipped == 0)
        let parts = made.parts(limit: 10)
        #expect(parts.count == 4, "25 blocks, 8 a part beside the 2 exceptions")
        #expect(parts.allSatisfy { $0.count <= 10 })
        #expect(parts.allSatisfy { $0.suffix(2).allSatisfy { $0.action.type == "ignore-previous-rules" } })
        #expect(parts.flatMap { $0.dropLast(2) }.count == 25)
        let bounded = BlockingRules.convert(text, limit: 10, parts: 2)
        #expect(bounded.parts(limit: 10).flatMap { $0.dropLast(2) }.count == 16 && bounded.skipped == 9)
    }
}
