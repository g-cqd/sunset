import Foundation
import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetShellModel
import SunsetStorage
import SunsetWeb
import SunsetWebModel
import Testing

@testable import SunsetAppCore

/// Roadmap 0086 D (the owner's note n55): what the app decides, out of the app target, under tests. Before, none of it had any.
@MainActor @Suite("The app's decisions, tested")
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

extension AppDecisionsTests {
    @Test func `the tab colour setting as the rows read it`() {
        #expect(Configuration.Tabs.SiteColor.off.tintMode == .off)
        #expect(Configuration.Tabs.SiteColor.selected.tintMode == .selected)
        #expect(Configuration.Tabs.SiteColor.every.tintMode == .every)
    }
}

extension AppDecisionsTests {
    /// A named setup in a folder of its own: its key in a file there, never the Keychain.
    private func places() throws -> StoragePlaces {
        let folder = FileManager.default.temporaryDirectory.appending(path: "sunset-storage-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return StoragePlaces(environment: ["SUNSET_SESSION": folder.appending(path: "session.json").path], home: "/")
    }

    @Test func `storage: a new folder gets a key and a database; nothing is said wrong`() throws {
        let problems = StorageProblems()
        let storage = SunsetStore(places: try places(), problems: problems) { false }
        #expect(storage.key != nil && storage.database != nil && problems.items.isEmpty)
        storage.close()
    }

    @Test func `storage: sealed things without their key are left alone, and said locked`() throws {
        let here = try places()
        let first = SunsetStore(places: here, problems: StorageProblems()) { false }
        first.close()
        try FileManager.default.removeItem(atPath: here.directory + "/storage.key")
        let problems = StorageProblems()
        let second = SunsetStore(places: here, problems: problems) { false }
        #expect(second.key == nil && second.database == nil)
        #expect(problems.items.map(\.kind) == [.locked], "a new key would open none of them and write over them")
        #expect(FileManager.default.fileExists(atPath: here.state), "the sealed database is still there")
    }

    @Test func `storage: a file of before, once kept, goes; one not kept stays`() throws {
        let here = try places()
        let storage = SunsetStore(places: here, problems: StorageProblems()) { false }
        let legacy = here.directory + "/old.json"
        FileManager.default.createFile(atPath: legacy, contents: Data("{}".utf8))
        storage.retire(legacy, when: false)
        #expect(FileManager.default.fileExists(atPath: legacy))
        storage.retire(legacy, when: true)
        #expect(!FileManager.default.fileExists(atPath: legacy), "a named setup's are removed, not trashed")
        storage.close()
    }
}

extension AppDecisionsTests {
    @Test func `what WebKit keeps: each choice as the stores read it, a profile's own over all profiles'`() {
        var app = Configuration()
        app.web.keep.cache = .clearOnQuit
        app.web.keep.traces = .keep
        app.web.keep.siteData = .keepChosen
        let all = app.web.keep.webKeep
        #expect(all.clearsCache && !all.clearsTraces && all.siteData == .keepChosen)
        var work = Profile(name: "Work")
        work.overrides = ["web.keep.siteData": "\"clearOnQuit\"", "web.keep.traces": "\"clearOnQuit\""]
        let own = Configuration.Web.Keep.of(work, app: app)
        #expect(own.webKeep.siteData == .clearOnQuit && own.webKeep.clearsTraces && own.webKeep.clearsCache)
        #expect(Configuration.Web.Keep.of(Profile(name: "Plain"), app: app) == app.web.keep, "nothing of its own")
    }
}

extension AppDecisionsTests {
    /// The owner's note n63: a floating sidebar's field is the page's address, as the docked one's is; only with no sidebar at all
    /// does the window bar hold it.
    @Test
    func
        `the address asked in the sidebar stays in it while the sidebar floats, and goes to the window bar without one`()
    {
        var configuration = Configuration()
        configuration.sidebar.enabled = true
        configuration.web.address = .sidebar
        configuration.sidebar.autoHide = false
        #expect(configuration.addressPlace == .sidebar, "docked")
        configuration.sidebar.autoHide = true
        #expect(configuration.addressPlace == .sidebar, "floating")
        configuration.sidebar.enabled = false
        #expect(!configuration.sidebarShown)
        #expect(configuration.addressPlace == .window, "no sidebar")
        configuration.web.address = .pane
        #expect(configuration.addressPlace == .pane)
    }
}
