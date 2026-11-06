import Foundation
import SunsetRenderMac

/// The font the terminal is drawn with, as the settings store it.
struct FontSettings: Sendable, Equatable {
    var name = "Menlo"
    var size = 14.0
    var ligatures = false
    /// OpenType features as `tag` or `tag=value`, separated by commas: `zero, ss01, cv02=3`.
    var featureList = ""

    var features: [FontFeature] {
        featureList.split(separator: ",")
            .compactMap { entry in
                let parts = entry.split(separator: "=").map { $0.trimmingCharacters(in: .whitespaces) }
                guard let tag = parts.first, !tag.isEmpty else { return nil }
                return FontFeature(tag, parts.count > 1 ? Int(parts[1]) ?? 1 : 1)
            }
    }
}
