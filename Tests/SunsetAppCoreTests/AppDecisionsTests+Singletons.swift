import Foundation
import SunsetConfig
import SunsetPane
import SunsetWebModel
import Testing

@testable import SunsetAppCore

/// Roadmap 0086 D: the decisions the `App*` singletons made in the app target, where nothing tested them, made here from the
/// state given to them.
extension AppDecisionsTests {
    /// `AppConfiguration`: the configuration the windows are drawn with in the light scheme.
    @Test func `light, the light tint is used and a dark terminal theme stays opaque; dark, nothing changes`() {
        var configuration = Configuration()
        configuration.appearance.tintColor = [10, 20, 30]
        configuration.appearance.lightTintColor = [200, 210, 220]
        configuration.appearance.lightTintAlpha = 0.3
        configuration.terminal.opacity = 0.7
        configuration.colors.background = [20, 20, 20]
        #expect(ShownConfiguration.make(configuration, light: false) == configuration)
        let light = ShownConfiguration.make(configuration, light: true)
        #expect(light.appearance.tintColor == [200, 210, 220] && light.appearance.tintAlpha == 0.3)
        #expect(light.terminal.opacity == 1, "a dark theme over the light tint washed out to grey")
        configuration.colors.background = [250, 250, 250]
        #expect(
            ShownConfiguration.make(configuration, light: true).terminal.opacity == 0.7,
            "a light theme keeps its own"
        )
        #expect(ShownConfiguration.isDark(nil), "the terminal's default is black")
    }

    /// `AppScopes`: what the question says before a scope with open tabs is turned off.
    @Test func `turning a scope off says how many tabs close, what stops and what is kept`() {
        #expect(
            ScopeClosing.sentence(.terminal, open: 1)
                == "1 tab of it is open and closes. What runs in them is stopped. "
                + "What is kept of it (pinned, favorites) is hidden until it is on again."
        )
        let documents = ScopeClosing.sentence(.documents, open: 3)
        #expect(documents.hasPrefix("3 tabs of it are open and close."))
        #expect(documents.contains("Edits that are not saved are kept"))
        #expect(!ScopeClosing.sentence(.web, open: 2).contains("stopped"))
    }

    /// `AppDownloads`: the download center's settings from the file's.
    @Test func `the downloads' settings are the file's`() {
        var web = Configuration.Web()
        web.askWhereToSave = true
        web.openSafeDownloads = false
        web.notifyDownloads = true
        web.approveRiskyDownloads = false
        web.keepDownloads = .week
        let settings = DownloadSettingsMaker.make(web, folder: URL(filePath: "/tmp/d"))
        #expect(settings.folder == URL(filePath: "/tmp/d"))
        #expect(settings.askWhereToSave && !settings.openSafe && settings.notify && !settings.approveRisky)
        #expect(settings.keep == .week)
    }

    /// `AppShare`: which open tabs a page asking to share the screen is offered.
    @Test func `a page shares what is open but private pages and terminals never shown; the asker is marked`() {
        let asker = UUID()
        let offered = ShareOffer.sources(
            [
                .init(id: asker, kind: .page(host: "a.com", isPrivate: false), title: "A", space: "Home", profile: nil),
                .init(id: UUID(), kind: .page(host: "b.com", isPrivate: true), title: "B", space: "Home", profile: nil),
                .init(id: UUID(), kind: .terminal(started: false), title: "zsh", space: "Home", profile: nil),
                .init(id: UUID(), kind: .terminal(started: true), title: "vim", space: "Work", profile: nil),
                .init(id: UUID(), kind: .document, title: "notes.md", space: "Work", profile: nil)
            ],
            asking: asker
        )
        #expect(offered.map(\.title) == ["A", "vim", "notes.md"])
        #expect(offered[0].isAsking && offered[0].host == "a.com")
        #expect(offered[1].host == nil && !offered[1].isAsking)
    }
}
