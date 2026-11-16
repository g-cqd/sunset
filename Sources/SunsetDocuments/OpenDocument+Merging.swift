internal import AppKit
internal import MarkdownLookKit

/// A change on disk merged into the edits made here (R6, roadmap 0023 step M-e; the owner's answers of 2026-11-16). The
/// blocks only the disk changed are put in the text as one step of undo, and named for a moment (`lastMerge`). A block both
/// changed stays as it is here, with the disk's kept beside it (`conflicts`), and the file is not written until each is
/// answered: `save` refuses, and the document does not save itself.
extension OpenDocument {
    /// The longest text (UTF-16 units) merged at once on the main actor: some 13 ms (measured in release: 10 ms at 200 KB,
    /// 97 ms at 2 MB, 485 ms at 10 MB, most of it the parser reading the three texts and the merged one).
    static let inlineMergeLimit = 262_144

    /// The file now holds `theirs`; it held `base` when this text was last what the file said.
    func merge(theirs: String, base: String) {
        take(DocumentMerge(base: base, mine: source.text, theirs: theirs, kind: kind), theirs: theirs)
    }

    /// The watcher's way in. As `fileChanged`, but a long text edited here is compared off the main actor, and what was
    /// found is used only if nothing moved meanwhile (the text, the file as it is known); else it is done again, and after
    /// three times done at once, as a short text is.
    func fileSettled(_ read: FileContent) async {
        for _ in 0 ..< 3 {
            guard read.mark != known, read.problem == nil, isEdited, let base,
                source.storage.length > Self.inlineMergeLimit
            else { break }
            let (revision, mark) = (source.revision, known)
            let plan = await DocumentMerge.made(base: base, mine: source.text, theirs: read.text, kind: kind)
            guard source.revision == revision, known == mark else { continue }
            known = read.mark
            take(plan, theirs: read.text)
            return
        }
        fileChanged(read)
    }

    /// Does what `plan` says, made from this text as it is and from `theirs`, which the file now holds.
    private func take(_ plan: DocumentMerge, theirs: String) {
        self.base = theirs
        savedElsewhere = true
        changedOnDisk = false
        followEdits()
        // The questions of before follow the text through what is put in now; one about blocks asked about again is renewed.
        var merged: [Range<Int>] = []
        if !plan.changes.isEmpty {
            source.undoManager.beginUndoGrouping()
            var shift = plan.changes.reduce(0) { $0 + $1.replacement.utf16.count - $1.range.count }
            for change in plan.changes.reversed() {
                shift -= change.replacement.utf16.count - change.range.count
                let low = change.range.lowerBound + shift
                merged.insert(low ..< low + change.replacement.utf16.count, at: 0)
                source.apply(MarkdownEdit(range: change.range, replacement: change.replacement, selection: 0 ..< 0))
            }
            source.undoManager.endUndoGrouping()
            source.undoManager.setActionName("Merge Changes from Disk")
            lastMerge = DocumentMergeNotice(id: source.revision, ranges: merged, revision: source.revision)
        }
        ask(plan, after: plan.changes)
        settleIfSame()
    }

    /// Adds the conflicts of `plan`, whose ranges are of the text before `changes` were done.
    private func ask(_ plan: DocumentMerge, after changes: [DocumentMerge.Change]) {
        for conflict in plan.conflicts {
            var shift = 0
            for change in changes where change.range.upperBound <= conflict.range.lowerBound {
                shift += change.replacement.utf16.count - change.range.count
            }
            let range = (conflict.range.lowerBound + shift) ..< (conflict.range.upperBound + shift)
            conflicts.removeAll { Self.touch($0.range, range) }
            nextConflict += 1
            conflicts.append(
                DocumentConflict(id: nextConflict, range: range, theirs: conflict.theirs, base: conflict.base)
            )
        }
        conflicts.sort { $0.range.lowerBound < $1.range.lowerBound }
    }

    private static func touch(_ first: Range<Int>, _ second: Range<Int>) -> Bool {
        if first.isEmpty || second.isEmpty {
            return first.lowerBound <= second.upperBound && second.lowerBound <= first.upperBound
        }
        return first.overlaps(second)
    }

    /// Answers the conflict `id`: what is here stays, or the disk's replaces it, or the disk's is put after it. One step of
    /// undo when the text changes; the question does not come back with it.
    public func resolve(_ id: Int, keeping answer: DocumentConflict.Answer) {
        guard let index = conflicts.firstIndex(where: { $0.id == id }) else { return }
        let conflict = conflicts.remove(at: index)
        let range = conflict.range
        switch answer {
            case .mine: break
            case .theirs:
                source.apply(
                    MarkdownEdit(
                        range: range,
                        replacement: conflict.theirs,
                        selection: range.lowerBound ..< range.lowerBound
                    )
                )
            case .both:
                let mine = source.storage.mutableString.substring(
                    with: NSRange(location: range.lowerBound, length: range.count)
                )
                let joint = Self.separator(after: mine, kind: kind)
                let end = range.upperBound
                source.apply(
                    MarkdownEdit(range: end ..< end, replacement: joint + conflict.theirs, selection: end ..< end)
                )
        }
        settleIfSame()
    }

    /// What must stand between two runs of blocks for the second not to run into the first: the end of a line, and for
    /// Markdown a blank line.
    private static func separator(after text: String, kind: DocumentKind) -> String {
        guard !text.isEmpty else { return "" }
        if kind != .markdown { return text.hasSuffix("\n") ? "" : "\n" }
        if text.hasSuffix("\n\n") || text.hasSuffix("\n\r\n") { return "" }
        return text.hasSuffix("\n") ? "\n" : "\n\n"
    }

    /// The notice of the last merge was read, or is no longer true.
    public func dismissMerge() { lastMerge = nil }

    /// Takes the last merge back, while nothing was done after it: the text is as it was before the disk's blocks came, and
    /// saving then writes it over them. The questions stay.
    public func undoMerge() {
        guard let merge = lastMerge, merge.revision == source.revision, source.undoManager.canUndo else { return }
        source.undoManager.undo()
        lastMerge = nil
    }

    /// The text is again exactly the file's: it is then saved as far as the text's own count goes, and tells by itself.
    private func settleIfSame() {
        guard savedElsewhere, let base, source.storage.mutableString.isEqual(to: base) else { return }
        source.markSaved()
        savedElsewhere = false
    }

    /// The document is forgotten: nothing follows its text any more.
    func stopFollowingEdits() {
        if let editObserver { NotificationCenter.default.removeObserver(editObserver) }
        editObserver = nil
    }

    /// Every edit of the text moves the questions that wait with it. Asked once, when the first merge is made.
    private func followEdits() {
        guard editObserver == nil else { return }
        editObserver = NotificationCenter.default.addObserver(
            forName: NSTextStorage.didProcessEditingNotification,
            object: source.storage,
            queue: nil
        ) { [weak self] _ in
            // Posted where the text is edited, which is the main actor (the source is bound to it).
            MainActor.assumeIsolated {
                guard let self else { return }
                let storage = self.source.storage
                guard storage.editedMask.contains(.editedCharacters) else { return }
                let edited = storage.editedRange
                let removed = edited.length - storage.changeInLength
                for index in self.conflicts.indices {
                    self.conflicts[index].follow(location: edited.location, removed: removed, inserted: edited.length)
                }
            }
        }
    }
}
