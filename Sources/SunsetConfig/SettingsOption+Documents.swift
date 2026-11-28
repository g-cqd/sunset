/// The options of Documents > Editing.
extension SettingsOption {
    /// Saving, source appearance, Quick Look integration, and Markdown rendering (brought over from MarkdownLook).
    static let documents: [Self] =
        [
            number(
                "documents.saveAfter",
                "Save files automatically after",
                "autosave document markdown timer seconds write edits",
                \.documents.saveAfter,
                0 ... 3600,
                step: 1,
                unit: "s",
                digits: 0
            )
            .noted(
                "A file is written this long after its first unsaved edit; 0 is never. It is never written over a change "
                    + "made elsewhere, and a deleted file is not made again."
            ),
            toggle(
                "documents.saveOnFocusLoss",
                "Save a file when it loses focus",
                "autosave document markdown focus switch pane app background",
                \.documents.saveOnFocusLoss
            )
            .noted(
                "When another pane takes the keyboard, or another app comes to the front. A document that has no file is "
                    + "always kept by Sunset, whatever these say."
            ),
            toggle(
                "documents.largerHeadings",
                "Show headings larger in the source",
                "markdown source editor heading size font page look rendered",
                \.documents.largerHeadings
            )
            .noted("A heading's text is at the size the page gives it; off, every line of the source has one height."),
            choice(
                "documents.linksOpen",
                "Open links from documents",
                "link click markdown rendered page tab split beside open",
                \.documents.linksOpen,
                [(.tab, "In a new tab"), (.beside, "Beside the document")]
            )
            .noted(
                "⌘-click opens a link in a tab behind, ⇧⌘-click in a tab shown, ⇧-click in a new window, ⌥-click beside."
            ),
            toggle(
                "documents.pagesReachNetwork",
                "Pages reach the network",
                "html svg web page file local internet load fonts scripts styles offline",
                \.documents.pagesReachNetwork,
                label: "HTML and SVG files may load from the internet"
            )
            .noted("Off, a file drawn as a page reads only its own folder. It keeps no website data either way.")
            .grouped("Pages"),
            custom(
                "documents.quickLook",
                "Quick Look for Markdown",
                "quick look quicklook finder preview thumbnail markdown mermaid extension",
                .quickLookMarkdown
            )
            .setting([])
            .grouped("Quick Look")
        ] + markdownOptions

    /// Documents › Library: how the Library lists documents.
    static let documentsLibrary: [Self] =
        [
            choice(
                "sidebar.documentSort",
                "Order of documents",
                "sort latest name kind changed",
                \.sidebar.documentSort,
                [(.changed, "Last changed"), (.made, "Last created"), (.name, "Name"), (.kind, "Kind")]
            )
        ]

    private static let markdownOptions: [Self] = {
        let textSize = number(
            "documents.textSize",
            "Text size",
            "markdown font size points rendered zoom",
            \.documents.textSize,
            11 ... 20,
            step: 1,
            unit: "pt",
            digits: 0
        )
        .grouped("Markdown text")
        let tabSize = number(
            "documents.tabSize",
            "Tab width in code",
            "markdown code tab size spaces",
            \.documents.tabSize,
            1 ... 8,
            step: 1,
            unit: "sp",
            digits: 0
        )
        .grouped("Markdown code")

        let first = MarkdownSettingSpec.parse(
            from: #"""
                "documents.fullWidth"|Use the full width of the window|markdown width column wide prose full|Markdown text
                "documents.alignsLeft"|Align text to the leading edge|markdown align left leading edge margin|Markdown text
                "documents.smartPunctuation"|Curly quotes and ellipses|markdown smart punctuation quotes typographer|Markdown text
                "documents.textFont"|Text font|markdown typeface family system serif rounded mono|system, serif, rounded, mono, or family name
                "documents.headingFont"|Heading font|markdown heading typeface family text system serif|text, system, serif, rounded, mono, or family name
                "documents.codeFont"|Code font|markdown code monospace typeface family|mono, system, serif, rounded, or family name
                "documents.diagramFont"|Diagram font|markdown mermaid diagram typeface family|text, system, serif, rounded, mono, or family name
                "documents.fontFeatures"|OpenType features|markdown font features opentype ss01 tnum|ss01, tnum, cv11=2|Applied to rendered Markdown text, headings, code and diagrams.
                "documents.highlightsCode"|Syntax color in code blocks|markdown code syntax highlight color|Markdown code
                "documents.showsLanguage"|Show the language of a code block|markdown code fence language label|Markdown code
                "documents.copyButton"|Copy button on code blocks|markdown code copy button|Markdown code
                """#
        )
        let second = MarkdownSettingSpec.parse(
            from: #"""
                "documents.rowLines"|Lines between table rows|markdown table rows border lines|Markdown tables
                "documents.columnLines"|Lines between table columns|markdown table columns border lines|Markdown tables
                "documents.outerBorder"|Outline around tables|markdown table outer border outline|Markdown tables
                "documents.scrollsTables"|Keep table cells on one line and scroll|markdown table nowrap scroll sideways|Markdown tables
                "documents.bleedsTables"|Scroll wide tables across the whole pane|markdown table bleed wide full|Markdown tables
                "documents.drawsDiagrams"|Draw Mermaid diagrams|markdown mermaid diagram render svg|Diagrams and front matter
                "documents.opensFrontMatter"|Show front matter open|markdown yaml front matter properties|Diagrams and front matter
                """#
        )
        return [textSize] + first + [tabSize] + second
    }()
}
