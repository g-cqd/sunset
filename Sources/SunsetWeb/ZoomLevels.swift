/// The zoom levels a page steps through (Safari's), from 50% to 300%.
package enum ZoomLevels {
    package static let all: [Double] = [0.5, 0.75, 0.85, 1, 1.15, 1.25, 1.5, 1.75, 2, 2.5, 3]

    /// The next level up (`steps` > 0) or down from `level`; a level between two goes to the nearer one in that direction.
    package static func step(from level: Double, by steps: Int) -> Double {
        if steps > 0 { return all.first { $0 > level + 0.001 } ?? all[all.count - 1] }
        if steps < 0 { return all.last { $0 < level - 0.001 } ?? all[0] }
        return level
    }

    /// "125%".
    package static func label(_ level: Double) -> String { "\(Int((level * 100).rounded()))%" }
}
