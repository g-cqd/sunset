extension Configuration.Documents {
    /// Reads and writes boolean Markdown rendering preferences by configuration key.
    subscript(flag key: String) -> Bool {
        get {
            switch key {
                case "fullWidth": fullWidth
                case "alignsLeft": alignsLeft
                case "smartPunctuation": smartPunctuation
                case "highlightsCode": highlightsCode
                case "showsLanguage": showsLanguage
                case "copyButton": copyButton
                case "rowLines": rowLines
                case "columnLines": columnLines
                case "outerBorder": outerBorder
                case "scrollsTables": scrollsTables
                case "bleedsTables": bleedsTables
                case "drawsDiagrams": drawsDiagrams
                case "opensFrontMatter": opensFrontMatter
                default: false
            }
        }
        set {
            switch key {
                case "fullWidth": fullWidth = newValue
                case "alignsLeft": alignsLeft = newValue
                case "smartPunctuation": smartPunctuation = newValue
                case "highlightsCode": highlightsCode = newValue
                case "showsLanguage": showsLanguage = newValue
                case "copyButton": copyButton = newValue
                case "rowLines": rowLines = newValue
                case "columnLines": columnLines = newValue
                case "outerBorder": outerBorder = newValue
                case "scrollsTables": scrollsTables = newValue
                case "bleedsTables": bleedsTables = newValue
                case "drawsDiagrams": drawsDiagrams = newValue
                case "opensFrontMatter": opensFrontMatter = newValue
                default: break
            }
        }
    }

    /// Reads and writes string Markdown rendering preferences by configuration key.
    subscript(font key: String) -> String {
        get {
            switch key {
                case "textFont": textFont
                case "headingFont": headingFont
                case "codeFont": codeFont
                case "diagramFont": diagramFont
                case "fontFeatures": fontFeatures
                default: ""
            }
        }
        set {
            switch key {
                case "textFont": textFont = newValue
                case "headingFont": headingFont = newValue
                case "codeFont": codeFont = newValue
                case "diagramFont": diagramFont = newValue
                case "fontFeatures": fontFeatures = newValue
                default: break
            }
        }
    }

    static let flagKeys: Set<String> = Set(
        "fullWidth alignsLeft smartPunctuation highlightsCode showsLanguage copyButton rowLines columnLines outerBorder scrollsTables bleedsTables drawsDiagrams opensFrontMatter"
            .split(separator: " ")
            .map(String.init)
    )
    static let fontKeys: Set<String> = Set(
        "textFont headingFont codeFont diagramFont fontFeatures".split(separator: " ").map(String.init)
    )
}
