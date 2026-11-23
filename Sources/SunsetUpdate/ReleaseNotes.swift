/// A release's notes, as the update window shows them: the blocks of the Markdown our notes are written in (paragraphs,
/// headings, list items nested by two spaces, lines wrapped at 120 columns joined), inline Markdown left to the view.
/// What is about installing by hand (`**Install.**`, `**Check the download.**`) and GitHub's `Build N.` line are left out:
/// an update does those itself.
public enum ReleaseNotes {
    public enum Block: Equatable, Sendable {
        case heading(String)
        case paragraph(String)
        case item(level: Int, String)
    }

    static let leftOut = ["**Install.**", "**Check the download.**"]

    public static func blocks(_ notes: String) -> [Block] {
        var blocks: [Block] = []
        var open = false
        for line in notes.split(separator: "\n", omittingEmptySubsequences: false) {
            let text = line.drop { $0 == " " }
            let indent = line.count - text.count
            if text.isEmpty {
                open = false
            } else if let marker = ["- ", "* "].first(where: text.hasPrefix) {
                blocks.append(.item(level: indent / 2, String(text.dropFirst(marker.count))))
                open = true
            } else if text.hasPrefix("#") {
                blocks.append(.heading(String(text.drop { $0 == "#" }.drop { $0 == " " })))
                open = false
            } else if open, let last = blocks.last {
                blocks[blocks.count - 1] = joined(last, String(text))
            } else {
                blocks.append(.paragraph(String(text)))
                open = true
            }
        }
        return blocks.filter(isShown)
    }

    private static func joined(_ block: Block, _ more: String) -> Block {
        switch block {
            case .paragraph(let text): .paragraph(text + " " + more)
            case .item(let level, let text): .item(level: level, text + " " + more)
            case .heading: block
        }
    }

    private static func isShown(_ block: Block) -> Bool {
        guard case .paragraph(let text) = block else { return true }
        let isBuild =
            text.hasPrefix("Build ") && text.hasSuffix(".") && text.dropFirst(6).dropLast().allSatisfy(\.isNumber)
        return !isBuild && !leftOut.contains(where: text.hasPrefix)
    }
}
