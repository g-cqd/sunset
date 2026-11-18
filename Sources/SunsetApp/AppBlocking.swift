import Foundation
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetStorage
import SunsetWeb
import WebKit

/// The app's side of blocking (roadmap 0022 W-c): the pauses kept sealed; the lists read from where they were kept, and
/// fetched again when older than four days (EasyList's own "Expires"), checked every six hours. These are the only
/// requests Sunset makes on its own: https only, at most 20 MB a list, no cookies (`WebFetch`).
@MainActor enum AppBlocking {
    private static var loop: Task<Void, Never>?
    private static let maxAge: TimeInterval = 4 * 24 * 3600
    private static let limit = 20 * 1024 * 1024

    static func start() {
        let storage = AppStorage.shared
        ContentBlocker.shared.pauses.table = storage.table("blocking-pauses")
        HiddenElements.shared.table = storage.table("hidden-elements")
        // Beside what else Sunset keeps (a debug build's apart: ADR-0042).
        ContentBlocker.shared.folder = URL(fileURLWithPath: storage.places.directory)
            .appending(
                path: "Blocking",
                directoryHint: .isDirectory
            )
        apply(AppConfiguration.shared.configuration.web)
        guard loop == nil else { return }
        loop = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(6 * 3600))
            }
        }
    }

    /// The settings changed: on or off at once; other lists fetched; the proxy given to the stores of pages made from now,
    /// and to the stores that exist (W-f).
    static func apply(_ web: Configuration.Web) {
        let proxy = WebProxy(web.proxy)
        if proxy != WebProxy.current {
            WebProxy.current = proxy
            WebProxy.applyCurrent(to: .default())
            for profile in AppSpaces.all.profiles.profiles where !profile.profile.isFirst {
                WebProxy.applyCurrent(to: WKWebsiteDataStore(forIdentifier: profile.profile.id))
            }
        }
        ContentBlocker.shared.enabled = web.blocking
        if web.blockingLists != addresses, loop != nil {
            addresses = web.blockingLists
            Task { await refresh() }
        }
    }

    private static var addresses: [String] = []

    /// Each list as kept, or fetched again when it is older than `maxAge` or not kept; then compiled and put on pages.
    static func refresh() async {
        await ContentBlocker.shared.compileHidden()
        let web = AppConfiguration.shared.configuration.web
        addresses = web.blockingLists
        guard web.blocking else { return }
        let folder = ContentBlocker.shared.folder.appending(path: "lists", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var sources: [ContentBlocker.Source] = []
        for address in web.blockingLists {
            guard let url = URL(string: address), url.scheme?.lowercased() == "https" else { continue }
            let file = folder.appending(path: fileName(for: address))
            let kept = try? FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
            if kept == nil || Date().timeIntervalSince(kept ?? .distantPast) > maxAge,
                let fetched = await WebFetch.data(url, agent: PaneContentKinds.webSettings.userAgent, limit: limit),
                (fetched.response as? HTTPURLResponse)?.statusCode == 200
            {
                try? fetched.data.write(to: file, options: .atomic)
            }
            guard let data = try? Data(contentsOf: file), let text = String(data: data, encoding: .utf8) else {
                continue
            }
            let updated = (try? FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date)
            sources.append(ContentBlocker.Source(address: address, text: text, updated: updated ?? Date()))
        }
        await ContentBlocker.shared.load(sources)
    }

    /// A file name for a list's address: its characters that are safe in a name.
    private static func fileName(for address: String) -> String {
        String(address.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : "_" }.suffix(120))
            + ".txt"
    }
}
