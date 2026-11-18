package import Foundation

/// What Settings' notes and Help's paragraphs say, with emphasis that means something (the owner's note n21): a file, a path,
/// a key or a command in monospace (between backticks), a place in Sunset in bold (`**Settings > Web**`), a term defined in
/// italics (`_…_`). Inline Markdown, nothing else; a text that does not parse is shown as it is written.
package enum RichText {
    package static func attributed(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}
