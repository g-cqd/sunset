import SunsetShellModel
import SwiftUI

extension View {
    /// The key the command is run by: the table's, or the one the file gives it (`CommandKeys`).
    func commandKey(_ id: AppCommand.ID) -> some View {
        keyboardShortcut(CommandKeys.shared.key(for: id).map(KeyboardShortcut.init))
    }
}
