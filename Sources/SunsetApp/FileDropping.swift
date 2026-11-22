import AppKit
import SunsetPane
import SunsetShell
import SunsetTerminal

/// Files dropped on the panes: on a terminal their paths are typed, as a paste, and that terminal takes the keyboard;
/// anywhere else each opens as a document. What is done with them is `FileDrop`'s to say.
///
/// A view that takes drops itself is asked before this: a web page keeps what is dropped on it, an editor's text view too.
@MainActor enum FileDropping {
    /// The files of the drag in progress, read from its pasteboard.
    static var dragged: [String] {
        let read = NSPasteboard(name: .drag)
            .readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
        return (read as? [URL] ?? []).map(\.path)
    }

    /// Does the drop at `point` among `frames`.
    /// - Returns: whether anything was done with it.
    static func perform(at point: CGPoint, frames: [PaneID: CGRect], tabs: TabsModel) -> Bool {
        let pane = DropZone.target(at: point, among: frames)?.pane
        let terminal = pane.flatMap { tabs.terminal($0) }
        switch FileDrop.outcome(of: dragged, onTerminal: terminal != nil, isFolder: isFolder) {
            case .type(let text):
                if let pane { tabs.focus(pane) }
                terminal?.paste(text)
            case .open(let files): AppActions.shared.open(files: files)
            case .nothing: return false
        }
        return true
    }

    private static func isFolder(_ path: String) -> Bool {
        var folder: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &folder) && folder.boolValue
    }
}
