import SunsetPane
package import SwiftUI

/// Its view: that this build cannot show it.
extension UnknownContent: PaneViewMaking {
    package func makeView(_ context: PaneViewContext) -> AnyView {
        AnyView(
            ContentUnavailableView(
                "A \(descriptor.kind) pane",
                systemImage: "questionmark.square.dashed",
                description: Text("This version of Sunset cannot show it. It is kept as it was.")
            )
            .padding(.top, context.topInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .paneBackdrop(context.backdrop)
        )
    }
}
