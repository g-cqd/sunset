import Foundation
import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetWeb
import Testing

@testable import SunsetAppCore

/// Roadmap 0086 D (the owner's note n55): what the app decides, out of the app target, under tests. Before, none of it had any.
@Suite("The app's decisions, tested")
struct AppDecisionsTests {
    @Test func `the command line: our flags, a program after -- or as the first word, the login shell otherwise`() {
        let shell = LaunchOptions.parse(["sunset"], environment: ["SHELL": "/bin/fish"])
        #expect(shell.command == ["/bin/fish", "-l"] && !shell.namedCommand)
        let named = LaunchOptions.parse(
            ["sunset", "--font", "Menlo", "--size", "13", "--ligatures", "--scrollback", "900", "--", "vim", "a.txt"],
            environment: [:]
        )
        #expect(named.command == ["vim", "a.txt"] && named.namedCommand)
        #expect(named.fontName == "Menlo" && named.fontSize == 13 && named.ligatures == true && named.scrollback == 900)
        let system = LaunchOptions.parse(
            ["sunset", "-psn_0_1", "-NSQuitAlwaysKeepsWindows"],
            environment: ["SHELL": "/bin/zsh"]
        )
        #expect(system.command == ["/bin/zsh", "-l"] && !system.namedCommand, "the system's flags are not ours")
        #expect(LaunchOptions.parse(["sunset", "htop"], environment: [:]).command == ["htop"])
    }

    @Test func `how far back Clear History goes, from a fixed now`() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let midnight = calendar.startOfDay(for: now)
        #expect(ClearSpan.lastHour.start(now: now, calendar: calendar) == now.addingTimeInterval(-3_600))
        #expect(ClearSpan.today.start(now: now, calendar: calendar) == midnight)
        #expect(ClearSpan.todayAndYesterday.start(now: now, calendar: calendar) == midnight.addingTimeInterval(-86_400))
        #expect(ClearSpan.all.start(now: now, calendar: calendar) == .distantPast)
    }

    @Test func `a profile's page settings: its own values over all profiles', all profiles' where it set none`() {
        var app = Configuration()
        app.web.engine = "DuckDuckGo"
        app.web.suggestions = true
        let plain = PageSettingsMaker(applicationName: "Version/26.0 Safari/605.1.15")
        #expect(plain.settings(app: app, own: nil).engine.name == "DuckDuckGo")
        var work = Profile(name: "Work")
        work.overrides = ["web.engine": "\"Google\"", "web.suggestions": "false"]
        let mine = plain.settings(app: app, own: work)
        #expect(mine.engine.name == "Google" && !mine.suggestions)
        #expect(mine.applicationName == "Version/26.0 Safari/605.1.15")
        #expect(plain.settings(app: app, own: Profile(name: "Empty")).engine.name == "DuckDuckGo", "nothing of its own")
    }
}

extension AppDecisionsTests {
    @Test
    func `the window from the configuration: a docked sidebar makes the terminal a card with room for its corners`() {
        var configuration = Configuration()
        configuration.sidebar.enabled = true
        configuration.sidebar.autoHide = false
        configuration.window.padding = 2
        #expect(configuration.sidebarShown == configuration.presentation.showsSidebar)
        #expect(configuration.sidebarDocked == configuration.sidebarShown)
        #expect(configuration.terminalPadding == (configuration.sidebarDocked ? 6 : 2))
        configuration.sidebar.autoHide = true
        #expect(
            !configuration.sidebarDocked && configuration.terminalPadding == 2,
            "floating: the window's own padding"
        )
        configuration.window.material = .opaque
        #expect(configuration.backgroundAlpha == 255)
        configuration.window.material = .glass
        configuration.terminal.opacity = 0.5
        #expect(configuration.backgroundAlpha == 128)
    }
}
