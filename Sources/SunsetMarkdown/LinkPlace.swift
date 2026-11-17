package import AppKit

/// Where a click on a document's link opens it (the owner, 2026-11-17), by the keys held, as browsers document theirs
/// (Safari's and Chrome's help, read 2026-11-17): Command, a new tab behind; Command-Shift, a new tab shown; Shift, a new
/// window. Sunset's own: Option, beside the document. No key: as `documents.linksOpen` says (`besideByDefault`).
package enum LinkPlace: Equatable, Sendable {
    case tab, backgroundTab, beside, window

    package init(modifiers: NSEvent.ModifierFlags, besideByDefault: Bool) {
        let keys = modifiers.intersection([.command, .shift, .option, .control])
        switch keys {
            case [.command]: self = .backgroundTab
            case [.command, .shift]: self = .tab
            case [.shift]: self = .window
            case [.option]: self = .beside
            default: self = besideByDefault ? .beside : .tab
        }
    }
}
