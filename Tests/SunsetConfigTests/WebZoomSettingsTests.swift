import Testing

@testable import SunsetConfig

@Suite("Page zoom's settings") struct WebZoomSettingsTests {
    @Test func `zoom is per site and remembered, everything zoomed, by default; both read`() throws {
        let web = Configuration().web
        #expect(web.zoomScope == .site && !web.textOnlyZoom)
        let read = try ConfigurationParser.parse(#"{ "web": { "zoomScope": "page", "textOnlyZoom": true } }"#)
        #expect(read.configuration.web.zoomScope == .page && read.configuration.web.textOnlyZoom && read.issues.isEmpty)
    }
}
