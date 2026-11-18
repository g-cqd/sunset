import Testing

@testable import SunsetConfig

/// `web.keep` (ADR-0081, roadmap 0051 H): what WebKit keeps between runs. The cache and the traces kept, a site's data kept
/// only for the sites chosen or signed in to; the old `web.clearWebsiteDataOnQuit` read as clearing all three.
@Suite("Configuration: what WebKit keeps between runs")
struct ConfigurationKeepTests {
    @Test func `the defaults are the owner's`() throws {
        let keep = try ConfigurationParser.parse("{}").configuration.web.keep
        #expect(keep == .init(cache: .keep, traces: .keep, siteData: .keepChosen))
    }

    @Test func `each is read, written and read back`() throws {
        let read = try ConfigurationParser.parse(
            #"{ "web": { "keep": { "cache": "clearOnQuit", "traces": "clearOnQuit", "siteData": "keep" } } }"#
        )
        #expect(read.issues.isEmpty)
        #expect(read.configuration.web.keep == .init(cache: .clearOnQuit, traces: .clearOnQuit, siteData: .keep))
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: read.configuration))
        #expect(back.issues.isEmpty && back.configuration.web.keep == read.configuration.web.keep)
        for key in ["web.keep.cache", "web.keep.traces", "web.keep.siteData"] {
            #expect(ConfigurationKeys.all.contains(key) && SettingsOption.named(key) != nil, "\(key)")
        }
    }

    @Test func `a file of before that cleared website data on quit clears all three`() throws {
        let old = try ConfigurationParser.parse(#"{ "web": { "clearWebsiteDataOnQuit": true } }"#)
        #expect(old.configuration.web.keep == .init(cache: .clearOnQuit, traces: .clearOnQuit, siteData: .clearOnQuit))
        #expect(!ConfigurationKeys.all.contains("web.clearWebsiteDataOnQuit"))
    }
}

extension ConfigurationKeepTests {
    /// "Both should be possible" (the owner, 2026-11-18): a profile's own choice wins; none, or one not known, is the app's.
    @Test func `a profile's choices win over the app's, one by one`() {
        let app = Configuration.Web.Keep(cache: .keep, traces: .clearOnQuit, siteData: .keepChosen)
        #expect(app.overriding(cache: nil, traces: nil, siteData: nil) == app)
        #expect(
            app.overriding(cache: "clearOnQuit", traces: nil, siteData: "keep")
                == .init(cache: .clearOnQuit, traces: .clearOnQuit, siteData: .keep)
        )
        #expect(app.overriding(cache: "sometimes", traces: nil, siteData: nil) == app)
    }
}
