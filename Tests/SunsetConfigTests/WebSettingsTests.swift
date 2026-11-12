import Testing

@testable import SunsetConfig

@Suite("The web pane's settings") struct WebSettingsTests {
    @Test func `defaults: links open in Sunset, the inspector can be opened, a page's tab shows its initial`() {
        let web = Configuration().web
        #expect(web.openLinksInSunset && web.developer && web.tabIcon == .initial)
    }

    @Test func `each is read, and nonsense is an issue that keeps the default`() throws {
        let read = try ConfigurationParser.parse(
            #"{ "web": { "openLinksInSunset": false, "developer": false, "tabIcon": "globe" } }"#
        )
        #expect(!read.configuration.web.openLinksInSunset && !read.configuration.web.developer)
        #expect(read.configuration.web.tabIcon == .globe && read.issues.isEmpty)
        let bad = try ConfigurationParser.parse(#"{ "web": { "tabIcon": "favicon", "nope": 1 } }"#)
        #expect(
            bad.configuration.web.tabIcon == .initial && bad.issues.map(\.path).sorted() == ["web.nope", "web.tabIcon"]
        )
    }
}
