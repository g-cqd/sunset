import SunsetPane
package import SwiftUI

package struct PaneGlyphView: View {
    let glyph: PaneGlyph

    package init(glyph: PaneGlyph) { self.glyph = glyph }

    package var body: some View {
        switch glyph {
            case .tab(let glyph): TabGlyphView(glyph: glyph)
            case .symbol(let name): PaneIconView(icon: .symbol(name))
        }
    }
}
