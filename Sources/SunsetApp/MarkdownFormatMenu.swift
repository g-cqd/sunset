import MarkdownLookKit
import SunsetMarkdown
import SwiftUI

/// Format menu items for Markdown documents (M-g / t210): inline styles, headings, lists, quote, code block, and table
/// insertion. Enabled when a Markdown document pane is in front.
struct MarkdownFormatMenu: View {
    let document: DocumentContent?

    private var disabled: Bool {
        document?.canFormatMarkdown != true
    }

    var body: some View {
        Button("Bold") { document?.performFormat(.bold) }
            .keyboardShortcut("b")
            .disabled(disabled)
        Button("Italic") { document?.performFormat(.italic) }
            .keyboardShortcut("i")
            .disabled(disabled)
        Button("Strikethrough") { document?.performFormat(.strikethrough) }
            .keyboardShortcut("x", modifiers: [.command, .shift])
            .disabled(disabled)
        Button("Inline Code") { document?.performFormat(.code) }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            .disabled(disabled)
        Button("Link") { document?.performFormat(.link) }
            .keyboardShortcut("k")
            .disabled(disabled)
        Divider()
        Menu("Heading") {
            ForEach(1 ... 6, id: \.self) { level in
                Button("Heading \(level)") { document?.performFormat(.heading(level)) }
            }
        }
        .disabled(disabled)
        Divider()
        Button("Bullet List") { document?.performFormat(.bulletList) }.disabled(disabled)
        Button("Numbered List") { document?.performFormat(.numberedList) }.disabled(disabled)
        Button("Task List") { document?.performFormat(.taskList) }.disabled(disabled)
        Button("Blockquote") { document?.performFormat(.quote) }.disabled(disabled)
        Button("Code Block") { document?.performFormat(.codeBlock) }.disabled(disabled)
        Button("Insert Table") { document?.insertMarkdownTable() }.disabled(disabled)
    }
}
