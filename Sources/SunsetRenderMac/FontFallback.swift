package import CoreText

/// The font for a name, or Menlo (monospaced, always installed) when no installed font has that name: CoreText alone substitutes Helvetica,
/// which is not monospaced (the default family, JetBrains Mono, is not installed everywhere: owner, 2026-11-12).
///
/// No descriptor matching: matching (or asking for a missing name) from many threads at once left every thread of the test process waiting on
/// the font server (2026-11-12). The font is made from the name, and the names CoreText gives back tell whether it was found.
package enum FontFallback {
    package static let fallbackName = "Menlo"

    package static func font(named name: String, size: CGFloat) -> CTFont {
        let made = CTFontCreateWithName(name as CFString, size, nil)
        let names = [CTFontCopyFamilyName(made), CTFontCopyFullName(made), CTFontCopyPostScriptName(made)]
            .map { $0 as String }
        return isMatch(name, names: names) ? made : CTFontCreateWithName(fallbackName as CFString, size, nil)
    }

    /// Whether a font with these names is the one asked for (letter case, spaces and hyphens aside).
    package static func isMatch(_ wanted: String, names: [String]) -> Bool {
        names.map(simplified).contains(simplified(wanted))
    }

    private static func simplified(_ name: String) -> String {
        name.lowercased().filter { !$0.isWhitespace && $0 != "-" }
    }
}
