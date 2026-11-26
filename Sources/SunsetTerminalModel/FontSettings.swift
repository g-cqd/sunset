import Foundation
package import SunsetConfig
package import SunsetRenderMac

/// The font the terminal is drawn with, as the settings store it (T-7 / t182).
package struct FontSettings: Sendable, Equatable {
    package var name = "Menlo"
    package var size = 14.0
    package var ligatures = false
    /// OpenType features as `tag` or `tag=value`, separated by commas: `zero, ss01, cv02=3`.
    package var featureList = ""
    /// Per-style overrides, ordered fallback cascade, and variable-font axes.
    package var appearance = FontAppearance()

    package init(
        name: String = "Menlo",
        size: Double = 14,
        ligatures: Bool = false,
        featureList: String = "",
        appearance: FontAppearance = FontAppearance()
    ) {
        self.name = name
        self.size = size
        self.ligatures = ligatures
        self.featureList = featureList
        self.appearance = appearance
    }

    package init(
        configuration file: Configuration.Font,
        overrideName: String?,
        overrideSize: Double,
        overrideLigatures: Bool?
    ) {
        let fallbacks = file.fallbacks.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter {
                !$0.isEmpty
            }
        self.init(
            name: overrideName ?? file.family ?? "Menlo",
            size: overrideSize,
            ligatures: overrideLigatures ?? file.ligatures,
            featureList: file.features,
            appearance: FontAppearance(
                boldName: file.boldFamily,
                italicName: file.italicFamily,
                boldItalicName: file.boldItalicFamily,
                fallbackNames: fallbacks,
                variations: FontVariationAxis.parseList(file.variations)
            )
        )
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
