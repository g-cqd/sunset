import SwiftUI

/// How the focused window's model reaches the menu commands.
struct TerminalModelKey: FocusedValueKey {
    typealias Value = TerminalModel
}

extension FocusedValues {
    var terminalModel: TerminalModel? {
        get { self[TerminalModelKey.self] }
        set { self[TerminalModelKey.self] = newValue }
    }
}
