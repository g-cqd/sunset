import SunsetPane
import SwiftUI

@testable import SunsetShell

/// A content that records what the tab model tells it.
@MainActor final class FakeContent: PaneContent {
    var title = "fake"
    var detail: String?
    var glyph: PaneGlyph { .symbol("square") }
    var progress: Double?
    var closeWarning: String?
    var searchTerms: [String] = []
    var descriptor: PaneDescriptor
    var onExit: () -> Void = {}
    var onFocusRequest: () -> Void = {}
    private(set) var focused = false
    private(set) var visible = false
    private(set) var stopped = false

    init(_ descriptor: PaneDescriptor? = nil) { self.descriptor = descriptor ?? PaneDescriptor(kind: "fake") }

    func setState(focused: Bool, visible: Bool) {
        self.focused = focused
        self.visible = visible
    }

    func stop() { stopped = true }
    func makeView(_ context: PaneViewContext) -> AnyView { AnyView(EmptyView()) }
}
