import Testing

@testable import SunsetConfig

@Suite("The web pane's settings") struct WebSettingsTests {
    @Test func `defaults: links open in Sunset, the inspector can be opened, a page's tab shows its site's icon`() {
        let web = Configuration().web
        #expect(web.openLinksInSunset && web.developer && web.tabIcon == .favicon)
    }

    @Test func `the address is in the sidebar by default, the window bar at the top; both are read`() throws {
        let web = Configuration().web
        #expect(web.address == .sidebar && web.windowBar == .top)
        let read = try ConfigurationParser.parse(#"{ "web": { "address": "pane", "windowBar": "bottom" } }"#)
        #expect(read.configuration.web.address == .pane && read.configuration.web.windowBar == .bottom)
        let bad = try ConfigurationParser.parse(#"{ "web": { "address": "toolbar" } }"#)
        #expect(bad.configuration.web.address == .sidebar && bad.issues.map(\.path) == ["web.address"])
    }

    @Test func `each is read, and nonsense is an issue that keeps the default`() throws {
        let read = try ConfigurationParser.parse(
            #"{ "web": { "openLinksInSunset": false, "developer": false, "tabIcon": "globe" } }"#
        )
        #expect(!read.configuration.web.openLinksInSunset && !read.configuration.web.developer)
        #expect(read.configuration.web.tabIcon == .globe && read.issues.isEmpty)
        let bad = try ConfigurationParser.parse(#"{ "web": { "tabIcon": "emoji", "nope": 1 } }"#)
        #expect(
            bad.configuration.web.tabIcon == .favicon && bad.issues.map(\.path).sorted() == ["web.nope", "web.tabIcon"]
        )
    }
}
