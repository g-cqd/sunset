public import Foundation

/// What a drag from the sidebar carries: a whole tab (all its panes) or one pane. It travels as text, so the drag is an ordinary text drag, and a drop that
/// does not understand it ignores it.
public enum PaneDragPayload: Sendable, Equatable {
    case item(Workspace.ItemID)
    case pane(PaneID)

    public var text: String {
        switch self {
            case .item(let id): "item:" + id.uuidString
            case .pane(let id): "pane:" + id.uuidString
        }
    }

    /// Reads the text form; a bare id (what the sidebar dragged before panes existed) is a tab. Anything else is nil.
    public init?(text: String) {
        if let id = UUID(uuidString: text) {
            self = .item(id)
        } else if text.hasPrefix("item:"), let id = UUID(uuidString: String(text.dropFirst(5))) {
            self = .item(id)
        } else if text.hasPrefix("pane:"), let id = UUID(uuidString: String(text.dropFirst(5))) {
            self = .pane(id)
        } else {
            return nil
        }
    }
}
