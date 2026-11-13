/// The address of the link under the pointer, as shown at the bottom of its page (roadmap 0029 step 6). It comes from the page, an
/// untrusted program (white paper §9): only a string is taken, without characters that do not show or that turn the text around,
/// and cut in the middle to a length.
enum LinkStatus {
    /// Characters shown at most.
    static let limit = 120

    static func text(_ raw: Any?) -> String? {
        guard let raw = raw as? String else { return nil }
        let clean = UntrustedText.oneLine(raw)
        guard !clean.isEmpty else { return nil }
        guard clean.count > limit else { return clean }
        // More of the start (the site) than of the end.
        let head = (limit - 1) * 2 / 3
        return clean.prefix(head) + "\u{2026}" + clean.suffix(limit - 1 - head)
    }
}
