import Testing

@testable import SunsetConfig

@Suite("History's settings") struct WebHistorySettingsTests {
    @Test func `a year, nothing cleared at quit, by default; each read`() throws {
        let web = Configuration().web
        #expect(web.historyKeep == .year && !web.clearHistoryOnQuit && !web.clearWebsiteDataOnQuit)
        let read = try ConfigurationParser.parse(
            #"{ "web": { "historyKeep": "twoWeeks", "clearHistoryOnQuit": true, "clearWebsiteDataOnQuit": true } }"#
        )
        let got = read.configuration.web
        #expect(
            got.historyKeep == .twoWeeks && got.clearHistoryOnQuit && got.clearWebsiteDataOnQuit && read.issues.isEmpty
        )
        #expect(
            Configuration.Web.HistoryKeep.forever.seconds == nil && Configuration.Web.HistoryKeep.day.seconds == 86_400
        )
    }
}
