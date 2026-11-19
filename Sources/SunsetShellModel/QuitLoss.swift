package import Foundation
package import SunsetPane

/// What quitting now would lose (web step q): shown in the sheet that asks, each with the tab it is in when it has one.
package struct QuitLoss: Identifiable, Sendable, Equatable {
    package enum Kind: Sendable, Equatable { case command, form, download, unrestored, document }

    package let id = UUID()
    package let kind: Kind
    package let text: String
    /// The pane it is in (a click on the row shows it), and the window's model by identity.
    package let pane: PaneID?
    /// The file of a document no pane shows any more (a click on the row opens it, with its edits).
    package let file: String?

    package init(kind: Kind, text: String, pane: PaneID? = nil, file: String? = nil) {
        self.kind = kind
        self.text = text
        self.pane = pane
        self.file = file
    }

    package var symbol: String {
        switch kind {
            case .command: "terminal"
            case .form: "character.cursor.ibeam"
            case .download: "arrow.down.circle"
            case .unrestored: "rectangle.stack.badge.minus"
            case .document: PaneDescriptor.documentSymbol
        }
    }

    /// Whether quitting asks: never, always, or when something would be lost. Edits to a file are not something a setting
    /// can throw away: with them, it asks at every level.
    package static func asks(level: String, losses: [Self]) -> Bool {
        switch level {
            case "never": losses.contains { $0.kind == .document }
            case "always": true
            default: !losses.isEmpty
        }
    }
}
