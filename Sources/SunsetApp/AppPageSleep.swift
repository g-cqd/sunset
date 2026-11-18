import Foundation
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetWeb

/// Hidden pages let go of their memory (roadmap 0021 S-f, ADR-0071): once a minute, those hidden longer than
/// `web.unloadAfter`; while macOS says memory is short (`web.unloadUnderPressure`), the one hidden the longest. Never a page
/// on screen, one that plays, captures or asks something, one kept awake, one in a Pinned grid, nor one holding unsent text.
@MainActor enum AppPageSleep {
    private static var loop: Task<Void, Never>?

    static func start() {
        guard loop == nil else { return }
        loop = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await tick()
            }
        }
    }

    /// One look at the pages.
    static func tick(now: Date = Date()) async {
        let web = AppConfiguration.shared.configuration.web
        let pages = candidates()
        let chosen = PageSleep.choose(
            pages.map(\.candidate),
            now: now,
            unloadAfter: web.unloadAfter,
            pressure: MemoryPressure.isShort,
            unloadsUnderPressure: web.unloadUnderPressure
        )
        for index in chosen {
            let page = pages[index].page
            guard !(await page.holdsUnsentText()) else { continue }
            page.unload()
        }
    }

    /// Every loaded page of the app's Spaces, of their windows' private Spaces and of the Favorites, with whether it is
    /// exempt; the Pinned grids' are not among them.
    private static func candidates() -> [(page: WebContent, candidate: PageSleep.Candidate)] {
        var lists: [[PaneID: any PaneContent]] = AppSpaces.all.spaces.map(\.contents)
        for (_, tabs) in TabRegistry.shared.allWindows() where !AppSpaces.all.contains(tabs.space) {
            lists.append(tabs.space.contents)
        }
        lists += AppSpaces.kept
            .filter { kept in
                !AppSpaces.all.profiles.profiles.contains { $0.pinned === kept }
            }
            .map(\.contents)
        var seen = Set<ObjectIdentifier>()
        var found: [(WebContent, PageSleep.Candidate)] = []
        for list in lists {
            for (pane, content) in list {
                guard let page = content as? WebContent, page.webView != nil,
                    seen.insert(ObjectIdentifier(page)).inserted
                else { continue }
                let exempt = page.mustStayLoaded || KeepAwakePanes.shared.keepsAwake(pane)
                found.append((page, PageSleep.Candidate(hiddenSince: page.hiddenSince, exempt: exempt)))
            }
        }
        return found
    }
}
