import Foundation
package import SunsetRenderMac

/// The font the terminal is drawn with, as the settings store it.
package struct FontSettings: Sendable, Equatable {
    package var name = "Menlo"
    package var size = 14.0
    package var ligatures = false
    /// OpenType features as `tag` or `tag=value`, separated by commas: `zero, ss01, cv02=3`.
    package var featureList = ""

    package init(name: String = "Menlo", size: Double = 14, ligatures: Bool = false, featureList: String = "") {
        self.name = name
        self.size = size
        self.ligatures = ligatures
        self.featureList = featureList
    }

    package var features: [FontFeature] {
        featureList.split(separator: ",")
            .compactMap { entry in
                let parts = entry.split(separator: "=").map { $0.trimmingCharacters(in: .whitespaces) }
                guard let tag = parts.first, !tag.isEmpty else { return nil }
                return FontFeature(tag, parts.count > 1 ? Int(parts[1]) ?? 1 : 1)
            }
    }
}
