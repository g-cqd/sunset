extension Configuration {
    /// When a file shown in a document pane is written by itself, and how Markdown documents are rendered (brought over
    /// from AemiMarkdown's MarkdownLook, shared with Sunset's Quick Look extension).
    public struct Documents: Sendable, Equatable {
        /// A file is written this many seconds after its first unsaved edit; 0 is never.
        public var saveAfter = 2.0
        /// A file is written when its pane, or Sunset, stops being the one typed in.
        public var saveOnFocusLoss = true
        /// The source shows a heading at the page's size for its level: closer to what it becomes.
        public var largerHeadings = true
        /// Where a plain click on a document's link opens it.
        public var linksOpen = LinksOpen.tab
        /// What a file that can be drawn (Markdown, Mermaid, HTML, SVG) opens as: drawn, or its source.
        public var opensAs = OpensAs.rendered
        public enum OpensAs: String, Sendable, Equatable, CaseIterable {
            case rendered, source
        }
        /// A page document (HTML, SVG) drawn as a page may load what is not in its folder: off, it reads only its folder.
        public var pagesReachNetwork = false

        // MARK: Markdown rendering (shared with Quick Look)

        /// The size of the body text in points (11 to 20); everything else is in em of it.
        public var textSize = 13.0
        /// Text runs the whole width of the pane instead of a column of about 40 em.
        public var fullWidth = false
        /// The text column sits on the leading edge of the pane instead of in its middle.
        public var alignsLeft = false
        /// Curly quotes and ellipses in prose (never in code).
        public var smartPunctuation = true
        /// Text font: `system`, `serif`, `rounded`, `mono`, or an installed family name.
        public var textFont = "system"
        /// Heading font: `text` (follows body text), `system`, `serif`, `rounded`, `mono`, or an installed family name.
        public var headingFont = "text"
        /// Code font: `mono`, `system`, `serif`, `rounded`, or an installed family name.
        public var codeFont = "mono"
        /// Diagram font: `text` (follows body text), `system`, `serif`, `rounded`, `mono`, or an installed family name.
        public var diagramFont = "text"
        /// OpenType feature tags for rendered Markdown, e.g. `ss01, tnum, cv11=2`.
        public var fontFeatures = ""
        /// Colour in fenced code blocks.
        public var highlightsCode = true
        /// The language a fence names, in the corner of its block.
        public var showsLanguage = true
        /// A button in the corner of a code block that copies its code.
        public var copyButton = true
        /// The width of a tab character in code, in spaces (1 to 8).
        public var tabSize = 4.0
        /// A hairline between the rows of a table.
        public var rowLines = true
        /// A hairline between the columns of a table.
        public var columnLines = false
        /// A rounded outline around a table.
        public var outerBorder = false
        /// Keep table cells on one line and scroll wide tables sideways.
        public var scrollsTables = false
        /// Scroll wide tables across the whole pane, past the text margins.
        public var bleedsTables = false
        /// Draw Mermaid fences as diagrams; off shows them as code.
        public var drawsDiagrams = true
        /// Show a document's front matter open by default.
        public var opensFrontMatter = false

        public enum LinksOpen: String, Sendable, Equatable, CaseIterable {
            /// In a new tab, shown, as a browser.
            case tab
            /// Beside the document, in a split.
            case beside
        }

        public init() {}
    }
}
