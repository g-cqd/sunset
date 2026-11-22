import Observation
import SunsetConfig
import SunsetPane
import SunsetShell
import SwiftUI

/// The settings as the content of a pane: a tab like any other, one in a window, showing one topic at a time or what a search
/// finds. The sidebar's list of sections and topics (the gear of the Library's rail) says which; the page carries that list
/// itself when the sidebar does not show it.
@MainActor @Observable
final class SettingsContent: PaneContent, PaneViewMaking {
    static let kind = PaneDescriptor.settingsKind

    /// The topic shown ("terminal.cursor").
    var topic: String {
        didSet {
            if topic != oldValue { onChange() }
        }
    }
    /// What is searched for; while it is not blank the page shows what it finds, under each option's section and topic.
    var query = ""
    /// The profile whose own settings are shown; nil: all profiles'.
    var scope: UUID?
    /// The topic's More is open.
    var showsMore = false {
        didSet {
            if showsMore != oldValue { onChange() }
        }
    }
    @ObservationIgnored var onExit: () -> Void = {}
    @ObservationIgnored var onFocusRequest: () -> Void = {}
    /// Something the session keeps has changed (which topic).
    @ObservationIgnored var onChange: () -> Void = {}
    /// The window it is in.
    @ObservationIgnored weak var tabs: TabsModel?

    /// The page a saved descriptor says; a topic that is no longer one is the first.
    init(_ descriptor: PaneDescriptor) {
        topic = SettingsSection.shown(for: descriptor.state["topic"]) ?? SettingsSection.all[0].topics[0].id
        showsMore = descriptor.state["more"] == "true"
    }

    var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// A row of a list of sections and topics was chosen: its page is shown, and the search ends.
    func show(_ selection: String) {
        guard let shown = SettingsSection.shown(for: selection, profileOnly: scope != nil) else { return }
        query = ""
        topic = shown
    }

    // MARK: PaneContent

    var title: String {
        "Settings"
    }
    var detail: String? {
        isSearching ? "Search" : SettingsSection.heading(of: topic)
    }
    var glyph: PaneGlyph {
        .symbol(PaneDescriptor.settingsSymbol)
    }
    var progress: Double? {
        nil
    }
    var closeWarning: String? {
        nil
    }
    var searchTerms: [String] {
        ["preferences", "options", "configuration"]
    }
    var descriptor: PaneDescriptor {
        var descriptor = PaneDescriptor.settings(topic: topic)
        if showsMore { descriptor.state["more"] = "true" }
        return descriptor
    }

    func setState(focused: Bool, visible: Bool) {}
    func stop() {}
    func makeView(_ context: PaneViewContext) -> AnyView {
        AnyView(SettingsPage(content: self, context: context))
    }
}
