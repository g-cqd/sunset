/// The options of General > Documents.
extension SettingsOption {
    /// When a file is written by itself, and how its source looks.
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
            )
        ]
}
