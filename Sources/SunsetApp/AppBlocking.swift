import Foundation
import SunsetAppCore
import SunsetConfig
import SunsetPane
import SunsetRuntime
import SunsetShell
import SunsetStorage
import SunsetWeb
import WebKit

/// The app's side of blocking: the pauses kept sealed; the lists read from where they were kept, and fetched again when
/// older than four days (EasyList's own "Expires"), checked every six hours. These are the only requests Sunset makes
/// on its own: https only, at most 20 MB a list, no cookies (`WebFetch`).
@MainActor enum AppBlocking {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    static var runtime = Runtime.live

    private static var loop: Task<Void, Never>?
    private static let limit = 20 * 1024 * 1024

    static func start() {
        let storage = SunsetStore.shared
        ContentBlocker.shared.pauses.table = storage.table("blocking-pauses")
        HiddenElements.shared.table = storage.table("hidden-elements")
        // Beside what else Sunset keeps (a debug build's apart).
        ContentBlocker.shared.folder = URL(fileURLWithPath: storage.places.directory)
            .appending(
                path: "Blocking",
                directoryHint: .isDirectory
            )
        apply(AppConfiguration.shared.configuration.web)
        guard loop == nil else { return }
        loop = runtime.task(role: .observation) {
            while !Task.isCancelled {
                await refresh()
                await runtime.sleep(for: .seconds(6 * 3600))
            }
        }
    }

    /// The settings changed: on or off at once; other lists fetched; the proxy given to the stores of pages made from now,
    /// and to the stores that exist.
    static func apply(_ web: Configuration.Web) {
        let proxy = WebProxy(web.proxy)
        WebProxy.current = proxy
        // Each profile's store its own proxy, else the app's; the first's is WebKit's default store.
        for model in AppSpaces.all.profiles.profiles {
            let profile = model.profile
            let own = ProfileOverrides.apply(profile.overrides, to: AppConfiguration.shared.configuration).web.proxy
            let store = profile.isFirst ? WKWebsiteDataStore.default() : WKWebsiteDataStore(forIdentifier: profile.id)
            if let given = WebProxy(own) { given.apply(to: store) } else { WebProxy.clear(store) }
        }
        ContentBlocker.shared.enabled = web.blocking
        if web.blockingLists != addresses, loop != nil {
            addresses = web.blockingLists
            runtime.task { await refresh() }
        }
    }

    private static var addresses: [String] = []

    /// The lists as kept go on pages first (looked up once compiled), then each list older than `maxAge` or not kept is
    /// fetched again, and the lists are put on pages again only if one changed: blocking never waits on the network.
    static func refresh() async {
        await ContentBlocker.shared.compileHidden()
        let web = AppConfiguration.shared.configuration.web
        addresses = web.blockingLists
        guard web.blocking else { return }
        let folder = ContentBlocker.shared.folder.appending(path: "lists", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let kept = sources(web.blockingLists, in: folder)
        if !kept.isEmpty { await ContentBlocker.shared.load(kept) }
        var fetchedAny = false
        for address in web.blockingLists {
            guard let url = BlockingListPlan.address(address) else { continue }
            let file = folder.appending(path: BlockingListPlan.fileName(for: address))
            let keptAt = try? FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
            guard BlockingListPlan.isStale(keptAt: keptAt, now: runtime.now()),
                let fetched = await WebFetch.data(
                    url,
                    agent: PaneContentKinds.webSettings.userAgent,
                    limit: limit,
                    for: nil,
                    proxy: WebProxy.current
                ),
                (fetched.response as? HTTPURLResponse)?.statusCode == 200
            else { continue }
            try? fetched.data.write(to: file, options: .atomic)
            fetchedAny = true
        }
        if fetchedAny || kept.isEmpty { await ContentBlocker.shared.load(sources(web.blockingLists, in: folder)) }
    }

    /// The lists as kept in `folder`, in the order of `addresses`; those not kept are not there.
    private static func sources(_ addresses: [String], in folder: URL) -> [ContentBlocker.Source] {
        addresses.compactMap { address in
            let file = folder.appending(path: BlockingListPlan.fileName(for: address))
            guard BlockingListPlan.address(address) != nil, let data = try? Data(contentsOf: file),
                let text = String(data: data, encoding: .utf8)
            else { return nil }
            let updated = try? FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
            return ContentBlocker.Source(address: address, text: text, updated: updated ?? runtime.now())
        }
    }
}
