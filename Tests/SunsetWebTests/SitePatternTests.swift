import Foundation
import Testing

@testable import SunsetWeb

/// n40 and the owner's answer: patterns of hosts and addresses, the most specific wins.
@Suite("What a site's rule is for") struct SitePatternTests {
    private func url(_ text: String) -> URL { URL(string: text) ?? URL(filePath: "/") }

    @Test func `read as a site, its subdomains, or an address prefix`() {
        #expect(SitePattern("Example.org") == .site("example.org"))
        #expect(SitePattern("www.example.org") == .site("example.org"))
        #expect(SitePattern("*.example.org") == .subdomains("example.org"))
        #expect(SitePattern("https://example.org/docs/") == .prefix("https://example.org/docs/"))
        #expect(SitePattern("") == nil && SitePattern("*.") == nil && SitePattern("org") == nil)
        #expect(SitePattern("*.example.org")?.key == "*.example.org")
    }

    @Test func `what each matches`() {
        let page = url("https://mail.example.org/inbox")
        #expect(SitePattern.site("example.org").specificity(for: page) != nil)
        #expect(SitePattern.site("example.org").specificity(for: url("https://example.org/")) != nil)
        #expect(SitePattern.subdomains("example.org").specificity(for: page) != nil)
        #expect(SitePattern.subdomains("example.org").specificity(for: url("https://example.org/")) == nil)
        #expect(SitePattern.site("example.org").specificity(for: url("https://badexample.org/")) == nil)
        #expect(SitePattern.prefix("https://mail.example.org/in").specificity(for: page) != nil)
        #expect(SitePattern.prefix("https://mail.example.org/out").specificity(for: page) == nil)
    }

    @Test func `the most specific wins: a prefix, the host itself, the nearest site, a pattern`() {
        let page = url("https://a.mail.example.org/inbox/1")
        let order: [SitePattern] = [
            .prefix("https://a.mail.example.org/inbox/"),
            .prefix("https://a.mail.example.org/"),
            .site("a.mail.example.org"),
            .site("mail.example.org"),
            .site("example.org"),
            .subdomains("mail.example.org"),
            .subdomains("example.org")
        ]
        let scores = order.compactMap { $0.specificity(for: page) }
        #expect(scores.count == order.count)
        #expect(scores == scores.sorted(by: >), "\(scores)")
        #expect(Set(scores).count == scores.count)
    }
}

extension SitePatternTests {
    @Test @MainActor func `a store's rules for hosts, patterns and prefixes, the most specific for each address`() {
        let rules = SiteRules<String>(encode: { $0 }, decode: { $0 })
        rules.set("site", for: "example.org")
        rules.set("pattern", for: SitePattern.subdomains("example.org"))
        rules.set("docs", for: SitePattern.prefix("https://example.org/docs/"))
        rules.set("mail", for: "mail.example.org")
        #expect(rules.value(for: url("https://example.org/")) == "site")
        #expect(rules.value(for: url("https://example.org/docs/a")) == "docs")
        #expect(rules.value(for: url("https://mail.example.org/")) == "mail")
        #expect(rules.value(for: url("https://news.example.org/")) == "site", "the site it is under beats a pattern")
        rules.set(nil, for: "example.org")
        #expect(rules.value(for: url("https://news.example.org/")) == "pattern")
        #expect(rules.value(for: "news.example.org") == "pattern", "by host too")
        #expect(rules.rules.map(\.host).contains("*.example.org"))
    }
}
