package import Foundation
package import Observation
package import WebKit

/// Blocking on pages: the lists, converted (`BlockingRules`) and compiled by WebKit, put on every page's content
/// controller; taken off a page whose site is paused, or all of them when blocking is off.
@MainActor @Observable
package final class ContentBlocker {
    /// The app's: its folder is set where the app keeps its files, before the lists are loaded.
    package static let shared = ContentBlocker(
        folder: FileManager.default.temporaryDirectory.appending(path: "SunsetBlocking", directoryHint: .isDirectory),
        pauses: BlockingPauses(),
        hidden: HiddenElements.shared
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

    package internal(set) var states: [ListState] = []
    /// How many lists were compiled by WebKit since this was made (the rest were looked up).
    @ObservationIgnored package internal(set) var compilations = 0
    /// Blocking is on (`web.blocking`): every page has the lists, but those of paused sites.
    @ObservationIgnored package var enabled = true {
        didSet {
            if enabled != oldValue { reapplyAll() }
        }
    }
    @ObservationIgnored package let pauses: BlockingPauses
    /// The elements hidden for good, per site: on their sites whatever blocking says.
    @ObservationIgnored package let hidden: SiteRules<[String]>
    /// The elements hidden for good, compiled: all profiles' (nil), and each profile with its own's.
    @ObservationIgnored private var hiddenLists: [UUID?: WKContentRuleList] = [:]
    /// Where the lists and their compiled rules are kept.
    @ObservationIgnored package var folder: URL
    @ObservationIgnored var compiled: [WKContentRuleList] = []
    @ObservationIgnored private var views: [Attached] = []

    struct WeakView {
        weak var view: WKWebView?
    }

    /// A page blocking is put on: its site, whether its profile blocks, and its profile (for its own pauses).
    struct Attached {
        var view: WeakView
        var host: String?
        var blocks: Bool
        var profile: UUID?
    }

    package init(folder: URL, pauses: BlockingPauses, hidden: SiteRules<[String]> = HiddenElements.make()) {
        self.folder = folder
        self.pauses = pauses
        self.hidden = hidden
    }

    // MARK: Pages

    /// A page's view, made: it has the lists from now on, as its site says. `blocks`: its profile blocks; off, only the
    /// elements hidden for good are on it.
    package func attach(_ view: WKWebView, host: String?, blocks: Bool = true, profile: UUID? = nil) {
        views.removeAll { $0.view.view == nil || $0.view.view === view }
        views.append(Attached(view: WeakView(view: view), host: host, blocks: blocks, profile: profile))
        apply(to: view, host: host)
    }

    /// Puts the lists on the view's content controller, or takes them off (blocking off, or the site paused): for the
    /// next load, decided before a page goes to `host`.
    package func apply(to view: WKWebView, host: String?) {
        var blocks = true
        var profile: UUID?
        if let index = views.firstIndex(where: { $0.view.view === view }) {
            views[index].host = host
            blocks = views[index].blocks
            profile = views[index].profile
        }
        let controller = view.configuration.userContentController
        controller.removeAllContentRuleLists()
        if let hidden = hiddenLists[profile] ?? hiddenLists[nil] { controller.add(hidden) }
        guard enabled, blocks, !pauses.isPaused(host, profile: profile) else { return }
        for list in compiled { controller.add(list) }
    }

    /// Every page again: the lists changed, or blocking was turned on or off.
    package func reapplyAll() {
        views.removeAll { $0.view.view == nil }
        for entry in views { if let view = entry.view.view { apply(to: view, host: entry.host) } }
    }

    // MARK: Lists

    /// Compiles the elements hidden for good again, and puts them on every page.
    package func compileHidden() async {
        makeFolder()
        guard let store = WKContentRuleListStore(url: folder) else { return }
        var lists: [UUID?: WKContentRuleList] = [:]
        for profile in [nil] + hidden.profilesWithOwn.map(Optional.some) {
            let rules = Self.hiddenSites(hidden, profile: profile)
                .map { site in
                    BlockingRules.Rule(
                        trigger: .init(urlFilter: ".*", ifDomain: ["*" + site.host]),
                        action: .init(type: "css-display-none", selector: site.selectors.joined(separator: ", "))
                    )
                }
            guard !rules.isEmpty, let json = try? BlockingRules.json(rules) else { continue }
            lists[profile] = try? await store.compileContentRuleList(
                forIdentifier: "hidden" + (profile.map { "-" + $0.uuidString } ?? ""),
                encodedContentRuleList: String(decoding: json, as: UTF8.self)
            )
        }
        hiddenLists = lists
        reapplyAll()
    }

    /// The sites with elements hidden for a page of `profile`: its own for a site, else all profiles' (nil: all profiles').
    package static func hiddenSites(_ hidden: SiteRules<[String]>, profile: UUID?) -> [(
        host: String, selectors: [String]
    )] {
        var sites: [String: [String]] = [:]
        for rule in hidden.rules { sites[rule.host] = rule.value }
        if let profile {
            for rule in hidden.rules(profile: profile) { sites[rule.host] = rule.value }
        }
        return sites.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
}
