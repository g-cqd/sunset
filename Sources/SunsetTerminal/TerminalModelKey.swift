import SwiftUI

/// How the focused window's model reaches the menu commands.
package struct TerminalModelKey: FocusedValueKey {
    package typealias Value = TerminalModel
}

extension FocusedValues {
    package var terminalModel: TerminalModel? {
        get { self[TerminalModelKey.self] }
        set { self[TerminalModelKey.self] = newValue }
    }
}
