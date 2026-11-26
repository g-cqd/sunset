internal import Foundation
package import MarkdownLookKit
internal import SunsetDocuments

/// Document editing commands wired to `MarkdownEditorProxy` (M-g / t210): switches to source view if needed when
/// invoked from rendered mode on a Markdown document, and runs `MarkdownCommand` on the active editor selection as one
/// undoable step.
extension DocumentContent {
    /// Whether Markdown formatting commands apply to this document (a Markdown file/document that is editable text).
    package var canFormatMarkdown: Bool {
        document.kind == .markdown && document.problem != .notText && document.problem != .unreadable
    }

    /// Runs a Markdown formatting command (`MarkdownCommand`) in the source editor, switching into source view first if
    /// the document is currently rendered.
    package func performFormat(_ command: MarkdownCommand) {
        guard canFormatMarkdown else { return }
        if mode != .source {
            toggleMode()
        }
        proxy.focus()
        proxy.perform(command)
    }

    /// Inserts a Markdown table skeleton at the current caret/selection in one undoable edit (M-g / t210).
    package func insertMarkdownTable() {
        guard canFormatMarkdown else { return }
        if mode != .source { toggleMode() }
        proxy.focus()
        let selection = proxy.selection ?? (document.source.storage.length ..< document.source.storage.length)
        let template = "\n| Column 1 | Column 2 |\n| --- | --- |\n| Value 1 | Value 2 |\n"
        _ = document.source.apply(
            MarkdownEdit(
                range: selection,
                replacement: template,
                selection: (selection.lowerBound + 3) ..< (selection.lowerBound + 11)
            )
        )
    }
}
