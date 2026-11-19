import Foundation
import Observation
package import SunsetPane

/// A Space stopped when no window shows it, and its pages started again.
extension SpaceModel {
    // MARK: Stopping and starting

    /// The last window went: what runs is stopped, and the tabs stay with what brings each pane back. What is private
    /// keeps nothing: its tabs go.
    func stopKeeping(at date: Date) {
        for (pane, content) in contents {
            if content.isPrivate { tabs.close(pane: pane) } else { pending[pane] = content.descriptor }
            // Its end is not a pane closing: the tab stays.
            content.onExit = {}
            content.stop()
        }
        contents = [:]
        live = [:]
        stopped = tabs.isEmpty ? nil : date
    }

    /// Stops the contents of the kind `kind` and has them made again from where each is (a Space given another
    /// profile: its pages load again with that profile's website data): by a window that shows the Space, or, with
    /// none, by the next that does.
    package func restart(kind: String, panes only: Set<PaneID>? = nil, by viewer: TabsModel?) {
        for (pane, content) in contents
        where content.descriptor.kind == kind && !content.isPrivate && only.map({ $0.contains(pane) }) ?? true {
            pending[pane] = content.descriptor
            content.onExit = {}
            content.stop()
            contents[pane] = nil
        }
        viewer?.revive()
        syncStates()
    }

    /// What brings back the content of `pane`, which has none; taken, since the content is about to be made.
    func takePending(_ pane: PaneID) -> PaneDescriptor? {
        stopped = nil
        return pending.removeValue(forKey: pane)
    }
}
