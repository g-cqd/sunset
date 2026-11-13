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
            // A filled rounded square with the letter, as an app's icon; a site's icon clipped to the same square (owner,
            // 2026-11-13).
            case .initial(let letter):
                Text(letter)
                    .font(Design.Text.small.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: Design.Size.glyphSymbol, height: Design.Size.glyphSymbol)
                    .background(Self.square.fill(.secondary))
                    .frame(width: Design.Size.glyphFrame)
            case .image(let image):
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: Design.Size.glyphSymbol, height: Design.Size.glyphSymbol)
                    .clipShape(Self.square)
                    .frame(width: Design.Size.glyphFrame)
        }
    }

    /// The square of an initial or a site's icon: slightly rounded.
    private static var square: RoundedRectangle {
        RoundedRectangle(cornerRadius: Design.Radius.small(LayoutMetrics()), style: .continuous)
    }
}
