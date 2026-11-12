package import SunsetPane
package import SwiftUI

/// A tab's picture alone: the icon a person gave it, its content's glyph, or, not running, what it would start from (in outline).
package struct TabIcon: View {
    let model: (any PaneContent)?
    var icon: PaneIcon?
    var saved: PaneDescriptor?
    var savedCommand: String?

    package init(
        model: (any PaneContent)?,
        icon: PaneIcon? = nil,
        saved: PaneDescriptor? = nil,
        savedCommand: String? = nil
    ) {
        self.model = model
        self.icon = icon
        self.saved = saved
        self.savedCommand = savedCommand
    }

    package var body: some View {
        if let icon {
            PaneIconView(icon: icon)
        } else if let model {
            PaneGlyphView(glyph: model.glyph)
        } else {
            PaneGlyphView(
                glyph: TabLabel.glyph(
                    of: saved ?? PaneDescriptor(kind: PaneDescriptor.terminalKind),
                    command: savedCommand
                ),
                outlined: true
            )
        }
    }
}
