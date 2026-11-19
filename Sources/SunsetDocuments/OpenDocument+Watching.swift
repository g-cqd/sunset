internal import Foundation
internal import MarkdownLookKit
internal import SunsetHost
import SunsetRuntime

/// The file behind a document, watched (R6: "reloaded silently if unedited; merged if edited", `OpenDocument+Merging`).
extension OpenDocument {
    func startWatching() {
        guard case .file(let path) = place, watcher == nil else { return }
        let watcher = FileWatcher(path: path)
        self.watcher = watcher
        watcher.start()
        watching = runtime.task(role: .observation) { [weak self] in
            for await _ in watcher.changes {
                let read = await FileContent.readConcurrently(path)
                await self?.fileSettled(read)
            }
        }
    }

    func stopWatching() {
        watcher?.stop()
        watching?.cancel()
        (watcher, watching) = (nil, nil)
    }

    /// Reads the file now and takes what it says as a change would be (the watcher does this by itself after each change).
    public func checkFile() {
        guard case .file(let path) = place else { return }
        fileChanged(.read(path))
    }

    /// The person chose the file over the edits made here: the text is the file's, and the edits and their history are gone.
    public func reloadFromDisk() {
        guard case .file(let path) = place else { return }
        let read = FileContent.read(path)
        known = read.mark
        problem = read.problem
        changedOnDisk = false
        if read.problem == nil { take(read.text) }
    }

    /// The text is the file's, whole: nothing of before is left to ask about or to undo.
    func take(_ text: String) {
        base = text
        savedElsewhere = false
        conflicts = []
        lastMerge = nil
        source.reload(text: text)
    }

    /// The person chose the edits made here over the file: nothing is read, and saving writes this text over it.
    public func keepEdits() {
        changedOnDisk = false
    }

    /// The file settled after a change, and was read again.
    func fileChanged(_ read: FileContent) {
        guard read.mark != known else { return }
        known = read.mark
        if read.problem == .missing {
            // Deleted, or moved away: the text stays here, and saving makes the file again.
            problem = .missing
            return
        }
        guard !isEdited else {
            // Text on both sides is merged; a file that is no longer text is said, and nothing is touched.
            if read.problem == nil, let base { merge(theirs: read.text, base: base) } else { changedOnDisk = true }
            return
        }
        problem = read.problem
        changedOnDisk = false
        if read.problem == nil {
            take(read.text)
        } else {
            base = nil
            source.reload(text: read.text)
        }
    }
}
