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
                    .font(.system(size: Design.Symbol.bar))
                    .foregroundStyle(.secondary)
                    .overlay {
                        if let letter = glyph.letter {
                            Text(String(letter))
                                .font(.system(size: Design.Optical.folderInitialSize, weight: .heavy, design: .rounded))
                                .offset(y: Design.Optical.folderInitialDrop)
                                .foregroundStyle(outlined ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                                .blendMode(outlined ? .normal : .destinationOut)
                        }
                    }
                    .compositingGroup()
                    .frame(width: Design.Size.glyphFrame)
            case .command:
                Image(systemName: outlined ? "terminal" : "terminal.fill")
                    .font(.system(size: Design.Symbol.row))
                    .foregroundStyle(.secondary)
                    .frame(width: Design.Size.glyphFrame)
        }
    }
}
