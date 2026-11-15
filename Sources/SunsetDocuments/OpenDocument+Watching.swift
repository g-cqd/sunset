internal import Foundation
internal import MarkdownLookKit
internal import SunsetHost

/// The file behind a document, watched (R6: "reloaded silently if unedited"; merging an edited one is step M-e).
extension OpenDocument {
    func startWatching() {
        guard case .file(let path) = place, watcher == nil else { return }
        let watcher = FileWatcher(path: path)
        self.watcher = watcher
        watcher.start()
        watching = Task { [weak self] in
            for await _ in watcher.changes {
                let read = await FileContent.readConcurrently(path)
                self?.fileChanged(read)
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
        if read.problem == nil { source.reload(text: read.text) }
    }

    /// The person chose the edits made here over the file: nothing is read, and saving writes this text over it.
    public func keepEdits() { changedOnDisk = false }

    /// The file settled after a change, and was read again.
    func fileChanged(_ read: FileContent) {
        guard read.mark != known else { return }
        known = read.mark
        if read.problem == .missing {
            // Deleted, or moved away: the text stays here, and saving makes the file again.
            problem = .missing
            return
        }
        guard !source.isEdited else {
            changedOnDisk = true
            return
        }
        problem = read.problem
        changedOnDisk = false
        source.reload(text: read.text)
    }
}
