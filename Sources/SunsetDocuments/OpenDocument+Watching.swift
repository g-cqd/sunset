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
