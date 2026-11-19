package import SunsetPane

/// A pane whose kind this build cannot make (a session written by a newer one, or a kind since removed, as the note was at roadmap 0023 M-b): it
/// says so, and keeps what was saved so that it is written back as it was.
@MainActor package final class UnknownContent: PaneContent {
    package let descriptor: PaneDescriptor
    package var onExit: () -> Void = {}
    package var onFocusRequest: () -> Void = {}

    package init(_ descriptor: PaneDescriptor) {
        self.descriptor = descriptor
    }

    package var title: String {
        descriptor.kind
    }
    package var detail: String? {
        nil
    }
    package var glyph: PaneGlyph {
        .symbol("questionmark.square.dashed")
    }
    package var progress: Double? {
        nil
    }
    package var closeWarning: String? {
        nil
    }

    package func setState(focused: Bool, visible: Bool) {}
    package func stop() {}
}
