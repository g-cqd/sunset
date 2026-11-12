package import Foundation
package import SunsetPane

/// What quitting now would lose (web step q): shown in the sheet that asks, each with the tab it is in when it has one.
package struct QuitLoss: Identifiable, Sendable, Equatable {
    package enum Kind: Sendable, Equatable { case command, form, download, unrestored }

    package let id = UUID()
    package let kind: Kind
    package let text: String
    /// The pane it is in (a click on the row shows it), and the window's model by identity.
    package let pane: PaneID?

    package init(kind: Kind, text: String, pane: PaneID? = nil) {
        self.kind = kind
        self.text = text
        self.pane = pane
    }

    package var symbol: String {
        switch kind {
            case .command: "terminal"
            case .form: "character.cursor.ibeam"
            case .download: "arrow.down.circle"
            case .unrestored: "rectangle.stack.badge.minus"
        }
    }

    /// Whether quitting asks: never, always, or when something would be lost.
    package static func asks(level: String, losses: [Self]) -> Bool {
        switch level {
            case "never": false
            case "always": true
            default: !losses.isEmpty
        }
    }
}
