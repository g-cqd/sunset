import SunsetPane
import SwiftUI

/// The tab's picture: a folder with its first letter cut out of it (the letter shows what is behind the tab, so it blends with the folder instead of sitting on
/// it), or a terminal mark while a command runs.
struct TabGlyphView: View {
    let glyph: TabGlyph

    var body: some View {
        switch glyph.kind {
            case .folder:
                Image(systemName: "folder.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .overlay {
                        if let letter = glyph.letter {
                            Text(String(letter))
                                .font(.system(size: 7, weight: .heavy, design: .rounded))
                                .offset(y: 1.5)
                                .blendMode(.destinationOut)
                        }
                    }
                    .compositingGroup()
                    .frame(width: 18)
            case .command:
                Image(systemName: "terminal.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
        }
    }
}
