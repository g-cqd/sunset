import SwiftUI

/// A symbol struck through as SF Symbols' own `.slash` variants are (the owner, 2026-11-19): the symbol cut away along a
/// band around the slash, so that the two never touch, and the slash as thick as the symbol's strokes at its weight. For a
/// symbol that has no slashed variant (the cup).
struct SlashedSymbol: View {
    let name: String
    let size: Double
    var weight = Design.Symbol.weight
    let slashed: Bool

    /// The slash's thickness, at least a point.
    private var line: Double {
        max(1, size * Self.strokeShare)
    }
    /// Its length: a little past the symbol's square, as the symbols' slashes are.
    private var length: Double {
        size * Self.lengthShare
    }

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: weight))
            .mask {
                ZStack {
                    Rectangle()
                    if slashed {
                        // The gap: a band on each side of the slash, as wide on both, cut out of the symbol.
                        Capsule()
                            .frame(width: line * (1 + 2 * Self.gapShare), height: length + line)
                            .rotationEffect(.degrees(Self.angle))
                            .blendMode(.destinationOut)
                    }
                }
                .compositingGroup()
            }
            .overlay {
                if slashed {
                    Capsule()
                        .fill(.foreground)
                        .frame(width: line, height: length)
                        .rotationEffect(.degrees(Self.angle))
                }
            }
    }

    /// From the top left to the bottom right, as the symbols' slashes go.
    private static let angle = -45.0
    /// Measured on `speaker.slash.fill`, `mic.slash.fill`, `video.slash.fill`, `bell.slash.fill` drawn at 60 pt: the stroke a
    /// tenth of the size, each gap 0.7 of the stroke.
    private static let strokeShare = 0.1
    private static let gapShare = 0.7
    private static let lengthShare = 1.25
}
