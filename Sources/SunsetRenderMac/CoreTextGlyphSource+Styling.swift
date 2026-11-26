internal import CoreText
internal import Foundation

/// Applies OpenType features, variable-font axes, and ordered fallback cascade lists to a `CTFont` (T-7 / t182).
extension CoreTextGlyphSource {
    struct ResolvedFaces {
        let regular: CTFont
        let bold: CTFont
        let italic: CTFont
        let boldItalic: CTFont
    }

    static func resolveFaces(
        from plain: CTFont,
        size: Double,
        features: [FontFeature],
        appearance: FontAppearance
    ) -> ResolvedFaces {
        let specs: [(String?, CTFontSymbolicTraits)] = [
            (nil, []),
            (appearance.boldName, .traitBold),
            (appearance.italicName, .traitItalic),
            (appearance.boldItalicName, [.traitBold, .traitItalic])
        ]
        let fonts = specs.map { name, traits in
            let raw = traits.isEmpty ? plain : styleFont(override: name, traits: traits, from: plain, size: size)
            return styledFont(raw, features: features, appearance: appearance)
        }
        return ResolvedFaces(regular: fonts[0], bold: fonts[1], italic: fonts[2], boldItalic: fonts[3])
    }
    /// Resolves a style font: prefers an explicit style override family/name when installed, otherwise derives from
    /// `plain` using CoreText symbolic traits.
    static func styleFont(
        override: String?,
        traits: CTFontSymbolicTraits,
        from plain: CTFont,
        size: Double
    ) -> CTFont {
        if let name = override?.trimmingCharacters(in: .whitespaces), !name.isEmpty {
            let candidate = CTFontCreateWithName(name as CFString, size, nil)
            let names = [
                CTFontCopyFamilyName(candidate),
                CTFontCopyFullName(candidate),
                CTFontCopyPostScriptName(candidate)
            ]
            .map { $0 as String }
            if FontFallback.isMatch(name, names: names) { return candidate }
        }
        return CTFontCreateCopyWithSymbolicTraits(plain, size, nil, traits, traits) ?? plain
    }

    /// Applies OpenType features, optional variable-font axes, and optional fallback cascade descriptors to `font`.
    static func styledFont(
        _ font: CTFont,
        features: [FontFeature],
        appearance: FontAppearance
    ) -> CTFont {
        var attributes: [CFString: Any] = [:]
        if !features.isEmpty {
            attributes[kCTFontFeatureSettingsAttribute] = features.map { feature -> [CFString: Any] in
                [
                    kCTFontOpenTypeFeatureTag: feature.tag as CFString,
                    kCTFontOpenTypeFeatureValue: feature.value as CFNumber
                ]
            }
        }
        if !appearance.variations.isEmpty {
            var variationDict: [NSNumber: NSNumber] = [:]
            for axis in appearance.variations {
                if let code = axis.fourCharCode {
                    variationDict[NSNumber(value: code)] = NSNumber(value: axis.value)
                }
            }
            if !variationDict.isEmpty {
                attributes[kCTFontVariationAttribute] = variationDict
            }
        }
        let cascadeDescriptors = appearance.fallbackNames
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { name in
                CTFontDescriptorCreateWithAttributes([kCTFontNameAttribute: name as CFString] as CFDictionary)
            }
        if !cascadeDescriptors.isEmpty {
            attributes[kCTFontCascadeListAttribute] = cascadeDescriptors
        }
        guard !attributes.isEmpty else { return font }
        let descriptor = CTFontDescriptorCreateCopyWithAttributes(
            CTFontCopyFontDescriptor(font),
            attributes as CFDictionary
        )
        return CTFontCreateWithFontDescriptor(descriptor, CTFontGetSize(font), nil)
    }
}
