package import SunsetPane
package import SwiftUI

/// A pane whose kind this build cannot make (a session written by a newer one): it says so, and keeps what was saved so that it is written back as it
/// was.
@MainActor package final class UnknownContent: PaneContent {
    package let descriptor: PaneDescriptor
    package var onExit: () -> Void = {}
    package var onFocusRequest: () -> Void = {}

    package init(_ descriptor: PaneDescriptor) {
        self.descriptor = descriptor
    }

    package var title: String { descriptor.kind }
    package var detail: String? { nil }
    package var glyph: PaneGlyph { .symbol("questionmark.square.dashed") }
    package var progress: Double? { nil }
    package var closeWarning: String? { nil }

    package func setState(focused: Bool, visible: Bool) {}
    package func stop() {}
    package func makeView(_ context: PaneViewContext) -> AnyView {
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
