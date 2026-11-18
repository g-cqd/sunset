import Observation
import SunsetHelp
import SunsetPane
import SunsetShell
import SwiftUI

/// Help as the content of a pane (roadmap 0041 E): a tab like any other, one in a window, its topics listed by area on its
/// left with a search field, the topic chosen on its right with all of its text.
@MainActor @Observable
final class HelpContent: PaneContent {
    static let kind = PaneDescriptor.helpKind

    /// The window's tabs, for Settings (its row in the list).
    @ObservationIgnored weak var tabs: TabsModel?

    /// The topic shown.
    var topic: HelpTopic {
        didSet { if topic != oldValue { onChange() } }
    }
    /// What the list is narrowed to.
    var query = ""
    @ObservationIgnored var onExit: () -> Void = {}
    @ObservationIgnored var onFocusRequest: () -> Void = {}
    /// Something the session keeps has changed (which topic).
    @ObservationIgnored var onChange: () -> Void = {}

    /// The topic a saved descriptor says; one that is no longer a topic is the first.
    init(_ descriptor: PaneDescriptor) {
        topic = descriptor.state["topic"].flatMap(HelpTopic.init(rawValue:)) ?? HelpTopic.allCases[0]
    }

    /// The topics the list shows: those the search finds.
    var listed: [HelpTopic] { HelpCatalog.search(query) }

    // MARK: PaneContent

    var title: String { "Help" }
    var detail: String? { HelpTopicView.heading(topic) }
    var glyph: PaneGlyph { .symbol(PaneDescriptor.helpSymbol) }
    var progress: Double? { nil }
    var closeWarning: String? { nil }
    var searchTerms: [String] { ["help", "manual", "guide"] }
    var descriptor: PaneDescriptor { .help(topic: topic.rawValue) }

    func setState(focused: Bool, visible: Bool) {}
    func stop() {}
    func makeView(_ context: PaneViewContext) -> AnyView { AnyView(HelpPage(content: self, context: context)) }
}
