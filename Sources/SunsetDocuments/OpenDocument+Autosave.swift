internal import MarkdownLookKit
internal import Observation

/// A document saving itself (`DocumentAutosave`). It never writes over what it has not read: a file that changed on disk
/// under these edits is the person's to choose, a file that is gone is not made again, a file that was not read is not
/// written. Asked for (Cmd-S), the same save does all of these but the last.
///
/// Why a save nobody asked for failed is `saveFailure`, shown by every pane on the document until a save does or it is
/// dismissed.
extension OpenDocument {
    /// It lives in Sunset's own store, which keeps it without being asked.
    public var isStored: Bool {
        if case .stored = place { true } else { false }
    }

    /// Sunset keeps it without being asked, and nothing says it cannot: its edits need no question.
    public var keepsItself: Bool { isStored && saveFailure == nil && problem == nil && !changedOnDisk }

    /// The edits can be written without anyone being asked: not while a block changed here and on disk waits for an answer.
    var canSaveItself: Bool { isEdited && !changedOnDisk && problem == nil && !givenUp && conflicts.isEmpty }

    /// Watches the text: each edit is told to `textChanged`. Observation tells once, so it is asked again each time.
    func watchEdits() {
        guard !stoppedWatchingEdits else { return }
        withObservationTracking {
            _ = source.revision
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.textChanged()
                self?.watchEdits()
            }
        }
    }

    func stopAutosaving() {
        stoppedWatchingEdits = true
        pendingSave?.cancel()
        pendingSave = nil
    }

    /// The text changed: when it is to save itself after a time and no save waits, one does. The time is the setting's at the
    /// first unsaved edit.
    func textChanged() {
        guard isEdited, pendingSave == nil, let owner else { return }
        guard let delay = isStored ? owner.autosave.storedDelay : owner.autosave.fileDelay else { return }
        pendingSave = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            self.pendingSave = nil
            self.saveItself()
        }
    }

    /// Its pane, or the app, stopped being the one typed in.
    public func focusLost() {
        guard isStored || owner?.autosave.onFocusLoss == true else { return }
        saveItself()
    }

    /// Saves when that is safe; a failure is kept to be said (`saveFailure`), and the next edit tries again.
    func saveItself() {
        guard canSaveItself else { return }
        do { try save() } catch { saveFailure = error.sentence }
    }
}
