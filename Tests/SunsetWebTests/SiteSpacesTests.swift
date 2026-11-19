import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0022 W-d: a site can name its Space; a link to it opens there, from a page of any other Space.
@MainActor @Suite("The Space a site opens in")
struct SiteSpacesTests {
    @Test func `a site and its subdomains open in their Space; from that Space, or with none, nothing moves`() throws {
        let sites = SiteSpaces.make()
        let work = UUID()
        let home = UUID()
        sites.set(work, for: "www.Tracker.example")
        #expect(sites.space(for: "tracker.example") == work && sites.space(for: "app.tracker.example") == work)
        #expect(sites.space(for: "example") == nil && sites.space(for: "other.example") == nil)
        let link = try #require(URL(string: "https://app.tracker.example/board"))
        #expect(sites.elsewhere(link, from: home) == work, "a link from Home opens in Work")
        #expect(sites.elsewhere(link, from: work) == nil, "already there")
        #expect(sites.elsewhere(try #require(URL(string: "https://other.example/")), from: home) == nil)
        #expect(sites.elsewhere(try #require(URL(string: "file:///tmp/a.html")), from: home) == nil)
        sites.set(nil, for: "tracker.example")
        #expect(sites.space(for: "tracker.example") == nil && sites.rules.isEmpty)
    }
}
