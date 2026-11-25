package import SunsetShell
package import SwiftUI

/// The terminal's view, made for its pane.
extension TerminalModel: PaneViewMaking {
    package func makeView(_ context: PaneViewContext) -> AnyView {
        AnyView(
            TerminalPaneView(
                model: self,
                optionAsMeta: context.optionAsMeta,
                translucent: context.translucent,
                focused: context.focused,
                topInset: context.topInset
            )
        )
    }
}
