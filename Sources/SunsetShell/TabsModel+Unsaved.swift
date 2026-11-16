internal import SunsetPane

/// Unsaved edits are asked about before anything closes them (R6, roadmap 0023 step M-d): a pane, a tab, the other tabs, a
/// kept entry, the window. A running command is confirmed first (the tab goes red), then this.
extension TabsModel {
    /// The documents whose every pane is among `panes`, in the order of the panes: closing these loses their edits.
    func unsaved(lostBy panes: [PaneID]) -> (documents: [UnsavedEdits], holders: [PaneID]) {
        var documents: [UnsavedEdits] = []
        var holders: [PaneID] = []
        var counts: [ObjectIdentifier: Int] = [:]
        for pane in panes {
            guard let edits = content(pane)?.unsaved else { continue }
            if counts[edits.id] == nil {
                documents.append(edits)
                holders.append(pane)
            }
            counts[edits.id, default: 0] += 1
        }
        let lost = documents.indices.filter { (counts[documents[$0].id] ?? 0) >= documents[$0].paneCount }
        return (lost.map { documents[$0] }, lost.map { holders[$0] })
    }

    /// Does `close` at once when closing `panes` loses no edit; else asks, and does it once they are saved or given up.
    func losingNothing(closing panes: [PaneID], _ close: @escaping @MainActor () -> Void) {
        let lost = unsaved(lostBy: panes)
        guard !lost.documents.isEmpty else { return close() }
        // One question at a time: what is asked while one waits (only code can, the sheet being modal) is not done.
        guard unsavedQuestion == nil else { return }
        unsavedQuestion = UnsavedQuestion(documents: lost.documents, holders: lost.holders, proceed: close)
    }

    /// The answer to the sheet. A save that fails closes nothing: the pane of that document is shown, and says why.
    package func answerUnsaved(_ answer: UnsavedAnswer) {
        guard let question = unsavedQuestion else { return }
        unsavedQuestion = nil
        switch answer {
            case .cancel: return
            case .discard: for document in question.documents { document.discard() }
            case .save:
                for (document, holder) in zip(question.documents, question.holders) where !document.save() {
                    return show(holder)
                }
        }
        question.proceed()
    }

    /// The window is asked to close (its red button, Close Window): `close` runs at once when its tabs hold no edits that
    /// would be lost, else after the answer. A kept entry is not the window's: it runs on.
    package func closeWindow(then close: @escaping @MainActor () -> Void) {
        guard space.viewerCount <= 1 else { return close() }
        losingNothing(closing: workspace.allPanes, close)
    }

    /// Whether closing this window would lose edits (what `windowShouldClose` asks): not while another window shows its
    /// Space, since nothing closes then.
    package var windowHoldsUnsaved: Bool {
        space.viewerCount <= 1 && !unsaved(lostBy: workspace.allPanes).documents.isEmpty
    }

    private func show(_ pane: PaneID) {
        if let item = workspace.item(containing: pane)?.id { select(item: item) }
        focus(pane)
    }
}
