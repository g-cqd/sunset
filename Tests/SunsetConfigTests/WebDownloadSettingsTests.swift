import Testing

@testable import SunsetConfig

@Suite("Downloads' settings") struct WebDownloadSettingsTests {
    @Test func `defaults: ~/Downloads, no asking, nothing opened, notified, risky kinds approved, kept by hand`() {
        let web = Configuration().web
        #expect(web.downloadFolder.isEmpty && !web.askWhereToSave && !web.openSafeDownloads)
        #expect(web.notifyDownloads && web.approveRiskyDownloads && web.keepDownloads == .byHand)
    }

    @Test func `each is read`() throws {
        let read = try ConfigurationParser.parse(
            #"""
            { "web": { "downloadFolder": "/tmp/d", "askWhereToSave": true, "openSafeDownloads": true, "notifyDownloads": false,
              "approveRiskyDownloads": false, "keepDownloads": "untilQuit" } }
            """#
        )
        let web = read.configuration.web
        #expect(web.downloadFolder == "/tmp/d" && web.askWhereToSave && web.openSafeDownloads && !web.notifyDownloads)
        #expect(!web.approveRiskyDownloads && web.keepDownloads == .untilQuit && read.issues.isEmpty)
    }
}
