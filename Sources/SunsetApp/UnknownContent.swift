import SunsetPane
import SwiftUI

/// A pane whose kind this build cannot make (a session written by a newer one): it says so, and keeps what was saved so that it is written back as it
/// was.
@MainActor final class UnknownContent: PaneContent {
    let descriptor: PaneDescriptor
    var onExit: () -> Void = {}
    var onFocusRequest: () -> Void = {}

    init(_ descriptor: PaneDescriptor) {
        self.descriptor = descriptor
    }

    var title: String { descriptor.kind }
    var detail: String? { nil }
    var glyph: PaneGlyph { .symbol("questionmark.square.dashed") }
    var progress: Double? { nil }
    var closeWarning: String? { nil }

    func setState(focused: Bool, visible: Bool) {}
    func stop() {}
    func makeView(_ context: PaneViewContext) -> AnyView {
        AnyView(
            ContentUnavailableView(
                "A \(descriptor.kind) pane",
                systemImage: "questionmark.square.dashed",
                description: Text("This version of Sunset cannot show it. It is kept as it was.")
            )
            .padding(.top, context.topInset)
        )
    }
}
