import SunsetMetrics
import SunsetPane
package import SwiftUI

package struct PaneGlyphView: View {
    let glyph: PaneGlyph
    /// A pane that is not running: its picture in outline.
    var outlined = false

    package init(glyph: PaneGlyph, outlined: Bool = false) {
        self.glyph = glyph
        self.outlined = outlined
    }

    package var body: some View {
        switch glyph {
            case .tab(let glyph): TabGlyphView(glyph: glyph, outlined: outlined)
            case .symbol(let name): PaneIconView(icon: .symbol(name))
            case .initial(let letter):
                Text(letter)
                    .font(Design.Text.small.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 15, height: 15)
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.small(LayoutMetrics()), style: .continuous)
                            .strokeBorder(.secondary, lineWidth: 1)
                    )
                    .frame(width: 18)
        }
    }
}
