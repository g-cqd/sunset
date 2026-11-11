import SunsetPane
import SwiftUI

struct PaneGlyphView: View {
    let glyph: PaneGlyph

    var body: some View {
        switch glyph {
            case .tab(let glyph): TabGlyphView(glyph: glyph)
            case .symbol(let name): PaneIconView(icon: .symbol(name))
        }
    }
}
