import Foundation
import MarkdownLookKit
import SunsetConfig

extension ViewerSettings {
    /// The preferences domain Sunset writes and its Quick Look preview extension reads.
    static let sunsetQuickLookDomain = "studio.aemi.sunset.quicklook"

    /// Converts Sunset's `documents.*` configuration into MarkdownLookKit's `ViewerSettings`.
    init(_ documents: Configuration.Documents) {
        self.init()
        textSize = Int(documents.textSize.rounded())
        fullWidth = documents.fullWidth
        alignsLeft = documents.alignsLeft
        smartPunctuation = documents.smartPunctuation
        fonts.text = FontFace(documents.textFont)
        fonts.heading = documents.headingFont == "text" ? nil : FontFace(documents.headingFont)
        fonts.code = FontFace(documents.codeFont)
        fonts.diagram = documents.diagramFont == "text" ? nil : FontFace(documents.diagramFont)
        fonts.features = ViewerFonts.features(documents.fontFeatures)
        highlightsCode = documents.highlightsCode
        showsLanguage = documents.showsLanguage
        copyButton = documents.copyButton
        tabSize = Int(documents.tabSize.rounded())
        rowLines = documents.rowLines
        columnLines = documents.columnLines
        outerBorder = documents.outerBorder
        scrollsTables = documents.scrollsTables
        bleedsTables = documents.bleedsTables
        drawsDiagrams = documents.drawsDiagrams
        opensFrontMatter = documents.opensFrontMatter
    }

    /// Writes these settings to `domain` so Sunset's sandboxed Quick Look preview extension reads the same choices.
    func writeToQuickLookDomain(_ domain: String = ViewerSettings.sunsetQuickLookDomain) {
        guard let defaults = UserDefaults(suiteName: domain) else { return }
        let values: [String: Any] = [
            Key.textSize: textSize,
            Key.fullWidth: fullWidth,
            Key.alignsLeft: alignsLeft,
            Key.smartPunctuation: smartPunctuation,
            Key.textFont: fonts.text.raw,
            Key.headingFont: fonts.heading?.raw ?? "text",
            Key.codeFont: fonts.code.raw,
            Key.diagramFont: fonts.diagram?.raw ?? "text",
            Key.fontFeatures: fonts.featureWords,
            Key.highlightsCode: highlightsCode,
            Key.showsLanguage: showsLanguage,
            Key.copyButton: copyButton,
            Key.tabSize: tabSize,
            Key.rowLines: rowLines,
            Key.columnLines: columnLines,
            Key.outerBorder: outerBorder,
            Key.scrollsTables: scrollsTables,
            Key.bleedsTables: bleedsTables,
            Key.drawsDiagrams: drawsDiagrams,
            Key.opensFrontMatter: opensFrontMatter
        ]
        for (key, value) in values { defaults.set(value, forKey: key) }
    }
}
