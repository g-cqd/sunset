package import Foundation
import Observation
package import SunsetPane

/// A Space stopped when no window shows it, and its pages started again.
extension SpaceModel {
    // MARK: Stopping and starting

    /// The last window went: what runs is stopped, and the tabs stay with what brings each pane back. What is private
    /// keeps nothing: its tabs go.
    package func stopKeeping(at date: Date) {
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

    /// Lets go of what runs in the tab `id` by hand: its contents stop and what brings each back is kept, the tab stays in the
    /// list, not loaded, and is made again where it was when a window shows it. Not a tab a window shows, nor one with
    /// something private (it keeps nothing to come back from) edited and not saved (it would lose the edits) or running a command.
    /// - Returns: whether it was unloaded.
    @discardableResult
    package func unload(item id: Workspace.ItemID) -> Bool {
        guard let item = tabs.items.first(where: { $0.id == id }),
            !currentViewers.contains(where: { $0.shownTab == id }),
            !item.panes.contains(where: { holdsSomething($0) })
        else { return false }
        var any = false
        for pane in item.panes {
            guard let content = contents[pane] else { continue }
            // A page lets go of its view and keeps its place; a content that is made again is stopped and kept.
            if content.unloadsInPlace {
                if content.unload() { any = true }
                continue
            }
            pending[pane] = content.descriptor
            content.onExit = {}
            content.stop()
            contents[pane] = nil
            any = true
        }
        live[id] = nil
        syncStates()
        return any
    }

    private func holdsSomething(_ pane: PaneID) -> Bool {
        guard let content = contents[pane] else { return false }
        return content.isPrivate || content.isEdited || content.runsCommand
    }

    /// What brings back the content of `pane`, which has none; taken, since the content is about to be made.
    package func takePending(_ pane: PaneID) -> PaneDescriptor? {
        stopped = nil
        return pending.removeValue(forKey: pane)
    }
}
