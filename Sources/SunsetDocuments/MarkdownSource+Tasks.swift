package import MarkdownLookKit

extension MarkdownSource {
    /// Checks a task off, or on again, from its box on the page: its `[ ]` becomes `[x]`, `[x]` or `[X]` becomes `[ ]`, as one
    /// step of undo (AemiMarkdown ADR-0011).
    /// - Parameter offset: Where the box's `[` is in the text, in bytes, as the page's marker says.
    /// - Returns: Whether the text changed: not when the bytes there are no longer a box (the text moved under the page).
    @discardableResult
    package func toggleTask(at offset: Int) -> Bool {
        let bytes = Array(text.utf8)
        guard let (range, replacement) = NativeMarker.toggle(in: bytes, at: offset) else { return false }
        // The text storage counts UTF-16 units; the box is three ASCII characters, so only where it starts needs counting.
        let start = String(decoding: bytes[..<range.lowerBound], as: UTF8.self).utf16.count
        let end = start + range.count
        apply(MarkdownEdit(range: start ..< end, replacement: replacement, selection: end ..< end))
        return true
    }
}
