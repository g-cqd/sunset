/// What a merge of a change on disk put in the text by itself, to be shown for a moment: the blocks that came from the
/// disk are tinted, and the merge can be undone. One step of undo, while nothing was done after it.
public struct DocumentMergeNotice: Identifiable, Equatable, Sendable {
    /// Another for each merge.
    public let id: Int
    /// Where the blocks from the disk are in the text as it was just after the merge, in UTF-16 units; a block the disk
    /// removed is an empty range where it was.
    public let ranges: [Range<Int>]
    /// The revision of the text just after the merge: it can be undone as one step while the text is still at it.
    public let revision: Int
}
