import SunsetPane
import SwiftUI

/// The tab's picture: a folder with its first letter in it, or a terminal mark while a command runs. Filled for a running tab (the letter cut
/// out of the folder, so that it shows what is behind the tab); in outline for a kept entry that is not open (the letter drawn in it).
struct TabGlyphView: View {
    let glyph: TabGlyph
    var outlined = false

    var body: some View {
        switch glyph.kind {
            case .folder:
                Image(systemName: outlined ? "folder" : "folder.fill")
                    .font(.system(size: Self.symbolSize))
                    .foregroundStyle(.secondary)
                    .overlay {
                        if let letter = glyph.letter {
                            Text(String(letter))
                                .font(.system(size: Self.initialSize, weight: .heavy, design: .rounded))
                                .offset(y: Self.initialDrop)
                                .foregroundStyle(outlined ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                                .blendMode(outlined ? .normal : .destinationOut)
                        }
                    }
                    .compositingGroup()
                    .frame(width: Design.Size.glyphFrame)
            case .command:
                Image(systemName: outlined ? "terminal" : "terminal.fill")
                    .font(.system(size: Self.symbolSize))
                    .foregroundStyle(.secondary)
                    .frame(width: Design.Size.glyphFrame)
        }
    }

    /// The folder's and the command mark's size: any tab symbol's (the owner, 2026-11-19: the folder was drawn at the bar's
    /// size, bigger than the folder symbol on other tabs).
    static let symbolSize = PaneIconView.symbolSize
    /// The letter in the folder, and how far below the middle it sits (into the folder's body, under its tab): the sizes
    /// tuned at the bar's size, scaled to this one.
    static let initialSize = Design.Optical.folderInitialSize * symbolSize / Design.Symbol.bar
    static let initialDrop = Design.Optical.folderInitialDrop * symbolSize / Design.Symbol.bar
}
