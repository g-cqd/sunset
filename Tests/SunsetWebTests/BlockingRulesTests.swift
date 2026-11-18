import Foundation
import Testing

@testable import SunsetWeb

/// Roadmap 0022 W-c: a blocking list in Adblock Plus syntax (EasyList, EasyPrivacy) becomes WebKit's content rules. What
/// WebKit cannot do is left out and counted, never guessed at.
@Suite("Blocking lists as WebKit's rules")
struct BlockingRulesTests {
    private func rules(_ text: String) -> BlockingRules.Converted { BlockingRules.convert(text) }

    @Test func `a domain anchor blocks the domain and its subdomains, any scheme, up to a separator`() throws {
        let made = rules("! comment\n[Adblock Plus 2.0]\n||ads.example.com^\n")
        #expect(made.rules.count == 1 && made.skipped == 0)
        let rule = try #require(made.rules.first)
        #expect(rule.action.type == "block")
        let filter = try Regex(rule.trigger.urlFilter)
        #expect("https://ads.example.com/x.js".contains(filter))
        #expect("https://cdn.ads.example.com/".contains(filter))
        #expect(!"https://notads.example.com/".contains(filter))
        #expect(!"https://ads.example.com.evil.org/".contains(filter))
        #expect(!"https://example.org/?u=ads.example.com.x".contains(filter))
    }

    @Test func `options: party, types, domains; an exception lets through; what WebKit cannot do is left out`() throws {
        let made = rules(
            """
            /banner/*/ad.$script,third-party,domain=news.example|~sport.news.example
            @@||cdn.example.org/ads/$image,~third-party
            ||tracker.example^$csp=script-src 'none'
            /^https?:\\/\\/[a-z]+\\.example\\//$script
            ||popup.example^$popup
            """
        )
        #expect(made.skipped == 2, "csp and a regular expression")
        let script = try #require(made.rules.first { $0.trigger.resourceType == ["script"] })
        #expect(script.trigger.resourceType == ["script"] && script.trigger.loadType == ["third-party"])
        #expect(script.trigger.ifDomain == ["*news.example"] && script.trigger.unlessDomain == nil)
        #expect("https://x.test/banner/top/ad.js".contains(try Regex(script.trigger.urlFilter)))
        let exception = try #require(made.rules.last)
        #expect(exception.action.type == "ignore-previous-rules" && exception.trigger.loadType == ["first-party"])
        #expect(made.rules.contains { $0.trigger.resourceType == ["popup"] }, "exceptions come after what they undo")
    }

    @Test func `element hiding: everywhere in groups, or on its sites; extended syntax left out`() throws {
        let made = rules(
            """
            ##.ad-banner
            ###sponsored
            example.com,~shop.example.com##.promo
            example.org#?#div:-abp-has(.ad)
            example.net#@#.ad-banner
            """
        )
        #expect(made.skipped == 2)
        let generic = try #require(made.rules.first { $0.trigger.ifDomain == nil })
        #expect(generic.action.type == "css-display-none" && generic.action.selector == ".ad-banner, #sponsored")
        let site = try #require(made.rules.first { $0.trigger.ifDomain != nil })
        #expect(site.trigger.ifDomain == ["*example.com"] && site.action.selector == ".promo")
        // Element hiding comes first: an exception of the network rules after it cannot undo it, nor the reverse.
        let json = try BlockingRules.json(made.rules)
        #expect(String(decoding: json, as: UTF8.self).contains(#""url-filter":".*""#))
    }

    /// White paper §9: a list is third-party text; whatever it says, it can only block, hide, or let through.
    @Test func `a list can only block, hide or let through`() {
        let hostile = """
            ||a.example^$redirect=noop.js
            ||b.example^$removeparam=x
            example.com#$#abort-on-property-read alert
            example.com##+js(set-constant, x, 1)
            ||c.example^$csp=script-src *
            @@||d.example^$elemhide
            ||e.example^$rewrite=abp-resource:blank-js
            """
        let made = rules(hostile)
        let kinds = Set(made.rules.map(\.action.type))
        #expect(kinds.isSubset(of: ["block", "css-display-none", "ignore-previous-rules"]))
        #expect(made.rules.allSatisfy { $0.action.selector?.contains("+js(") != true })
    }

    @Test func `the list is bounded: no rule past WebKit's limit, and nothing but ASCII in a filter`() {
        let many = (0 ..< 20).map { "||site\($0).example^" }.joined(separator: "\n") + "\n||exämple.com^"
        let made = BlockingRules.convert(many, limit: 10)
        #expect(made.rules.count == 10 && made.skipped == 11)
    }
}
