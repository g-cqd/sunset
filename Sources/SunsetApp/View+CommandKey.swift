import SunsetShellModel
import SwiftUI

extension View {
    /// The key the command table gives the command.
    func commandKey(_ id: AppCommand.ID) -> some View {
        keyboardShortcut(AppCommand[id].key.map(KeyboardShortcut.init))
    }
}
