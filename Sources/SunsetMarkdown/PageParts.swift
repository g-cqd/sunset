internal import Foundation
internal import SunsetDocuments

/// A document's text cut where its conflicts are. The parts joined are the text.
enum PageParts {
    /// - Parameters:
    ///   - text: the text as it is.
    ///   - conflicts: the conflicts that wait, in the order of the text, their ranges in UTF-16 units of it.
    /// - Returns: the parts in order; a conflict whose blocks were removed here is a part with no text.
    /// - Complexity: O(the text).
    static func of(_ text: String, conflicts: [DocumentConflict]) -> [PagePart] {
        let whole = text as NSString
        var parts: [PagePart] = []
        var from = 0
        func between(upTo end: Int) {
            guard end > from else { return }
            let part = whole.substring(with: NSRange(location: from, length: end - from))
            parts.append(PagePart(id: -1 - parts.count, text: part, conflict: nil))
        }
        for conflict in conflicts {
            // A range is never past the text; cut to it all the same, so that a late one cannot trap.
            let low = min(max(conflict.range.lowerBound, from), whole.length)
            let high = min(max(conflict.range.upperBound, low), whole.length)
            between(upTo: low)
            let mine = whole.substring(with: NSRange(location: low, length: high - low))
            parts.append(PagePart(id: conflict.id, text: mine, conflict: conflict))
            from = high
        }
        between(upTo: whole.length)
        return parts
    }
}
