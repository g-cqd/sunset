package import AppKit
import WebKit

/// Each extension's action for the shown page, performed when its button is clicked; its popup shown by Sunset, anchored to
/// the button (WebKit's controller delegate asks).
extension ExtensionHost {
    /// The actions of the extensions running, for `tab` (nil: the window's default), in the order they were installed.
    package func actions(for tab: ExtensionTab?) -> [ExtensionActionItem] {
        _ = revision
        return installed.compactMap { entry in
            guard let context = context(of: entry.id), let action = context.action(for: tab) else { return nil }
            return ExtensionActionItem(
                id: context.uniqueIdentifier,
                label: action.label.isEmpty ? entry.name : action.label,
                icon: action.icon(for: CGSize(width: 16, height: 16)),
                badge: action.badgeText,
                enabled: action.isEnabled
            )
        }
    }

    /// The button was clicked: the extension's own (a popup asked for, or its click event).
    package func perform(_ id: String, for tab: ExtensionTab?) {
        contextWith(identifier: id)?.performAction(for: tab)
    }

    /// Where a button is, for its popup.
    package func anchor(_ id: String, _ view: NSView) {
        anchors[id] = view
    }

    /// WebKit asks for an action's popup: shown under its button, else not at all.
    func showPopup(_ action: WKWebExtension.Action, for context: WKWebExtensionContext) {
        let item = ExtensionActionItem(
            id: context.uniqueIdentifier,
            label: action.label,
            icon: nil,
            badge: action.badgeText,
            enabled: action.isEnabled
        )
        presentPopup(item, action)
    }

    /// Shows the popup under the button that was clicked: its own, or the puzzle piece's when it was chosen from its list.
    func showPopover(of action: WKWebExtension.Action, anchoredTo id: String) {
        guard let anchor = popupAnchor ?? anchors[id] else { return }
        popupAnchor = nil
        ExtensionPopupPanel.show(action, under: anchor)
    }

    /// Performed from the puzzle piece's list: its popup under the puzzle piece.
    package func perform(_ id: String, for tab: ExtensionTab?, under anchor: NSView?) {
        popupAnchor = anchor
        perform(id, for: tab)
    }

    /// The order of the buttons.
    package func move(_ id: String, by offset: Int) {
        guard let entry = installed.first(where: { context(of: $0.id)?.uniqueIdentifier == id }) else { return }
        moveEntry(entry.id, by: offset)
    }
}
