import Foundation
import SunsetPane

/// The kinds of content besides the terminal (which the scene makes, with its configuration): what a saved descriptor becomes.
@MainActor enum PaneContentKinds {
    /// The content `descriptor` says; a kind this build does not have is kept as a placeholder. `changed` is called when the content has something
    /// new to save.
    static func make(_ descriptor: PaneDescriptor, changed: @escaping () -> Void) -> any PaneContent {
        switch descriptor.kind {
            case NoteContent.kind:
                let note = NoteContent(text: descriptor.state["text"] ?? "")
                note.onEdit = changed
                return note
            case WebContent.kind:
                let page = WebContent(address: descriptor.state["url"].flatMap { URL(string: $0) })
                page.onNavigate = changed
                return page
            default:
                return UnknownContent(descriptor)
        }
    }

    static func isDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
