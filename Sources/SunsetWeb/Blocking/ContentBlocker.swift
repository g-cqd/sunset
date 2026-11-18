package import Foundation
package import Observation
package import WebKit

/// Blocking on pages (roadmap 0022 W-c): the lists, converted (`BlockingRules`) and compiled by WebKit, put on every page's
/// content controller; taken off a page whose site is paused, or all of them when blocking is off.
@MainActor @Observable
package final class ContentBlocker {
    /// The app's: its folder is set where the app keeps its files, before the lists are loaded.
    package static let shared = ContentBlocker(
        folder: FileManager.default.temporaryDirectory.appending(path: "SunsetBlocking", directoryHint: .isDirectory),
        pauses: BlockingPauses()
    )

    /// A list as it was given: its address, its text, when it was fetched.
    package struct Source: Sendable {
        package var address: String
        package var text: String
        package var updated: Date

        package init(address: String, text: String, updated: Date) {
            self.address = address
            self.text = text
            self.updated = updated
        }
    }

    /// What Settings show of each list.
    package struct ListState: Sendable, Equatable {
        package var address: String
        package var rules: Int
        package var skipped: Int
        package var updated: Date?
        /// Why it is not in use; nil when it is.
        package var problem: String?
    }

    package private(set) var states: [ListState] = []
    /// Blocking is on (`web.blocking`): every page has the lists, but those of paused sites.
    @ObservationIgnored package var enabled = true {
        didSet { if enabled != oldValue { reapplyAll() } }
    }
    @ObservationIgnored package let pauses: BlockingPauses
    /// Where the lists and their compiled rules are kept.
    @ObservationIgnored package var folder: URL
    @ObservationIgnored private(set) var compiled: [WKContentRuleList] = []
    @ObservationIgnored private var views: [(view: WeakView, host: String?)] = []

    struct WeakView {
        weak var view: WKWebView?
    }

    package init(folder: URL, pauses: BlockingPauses) {
        self.folder = folder
        self.pauses = pauses
    }

    // MARK: Pages

    /// A page's view, made: it has the lists from now on, as its site says.
    package func attach(_ view: WKWebView, host: String?) {
        views.removeAll { $0.view.view == nil || $0.view.view === view }
        views.append((WeakView(view: view), host))
        apply(to: view, host: host)
    }

    /// Puts the lists on the view's content controller, or takes them off (blocking off, or the site paused): for the
    /// next load, decided before a page goes to `host`.
    package func apply(to view: WKWebView, host: String?) {
        if let index = views.firstIndex(where: { $0.view.view === view }) { views[index].host = host }
        let controller = view.configuration.userContentController
        controller.removeAllContentRuleLists()
        guard enabled, !pauses.isPaused(host) else { return }
        for list in compiled { controller.add(list) }
    }

    /// Every page again: the lists changed, or blocking was turned on or off.
    package func reapplyAll() {
        views.removeAll { $0.view.view == nil }
        for entry in views { if let view = entry.view.view { apply(to: view, host: entry.host) } }
    }

    // MARK: Lists

    /// Converts and compiles the lists, then puts them on every page. A list that does not compile is said in its state
    /// and left out; the others are used.
    package func load(_ sources: [Source]) async {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let store = WKContentRuleListStore(url: folder) else { return }
        var lists: [WKContentRuleList] = []
        var states: [ListState] = []
        for (index, source) in sources.enumerated() {
            let converted = BlockingRules.convert(source.text)
            var state = ListState(
                address: source.address,
                rules: converted.rules.count,
                skipped: converted.skipped,
                updated: source.updated
            )
            do {
                let json = String(decoding: try BlockingRules.json(converted.rules), as: UTF8.self)
                if let list = try await store.compileContentRuleList(
                    forIdentifier: "list-\(index)",
                    encodedContentRuleList: json
                ) {
                    lists.append(list)
                }
            } catch {
                state.problem = "WebKit could not compile it: \(error.localizedDescription)"
            }
            states.append(state)
        }
        compiled = lists
        self.states = states
        reapplyAll()
    }
}
