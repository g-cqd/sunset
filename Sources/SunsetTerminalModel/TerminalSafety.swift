package import SunsetConfig
package import SunsetCore

/// What a terminal needs for pastes asked about and secure keyboard entry: the settings (the app's), the question
/// before a risky paste (the view's sheet), the holder of secure input (the view's), and what it last knew.
@MainActor
package struct TerminalSafety {
    package var settings: () -> (secureKeyboard: Configuration.Terminal.SecureKeyboard, pasteWarning: Bool) = {
        (.whenPassword, true)
    }
    package var askBeforePasting: ([PasteRisk], String, @escaping @MainActor () -> Void) -> Void = { _, _, paste in
        paste()
    }
    package var holdSecureInput: (Bool) -> Void = { _ in }
    package var secureInputHeld = false
    /// The program reads a password (echo off in line mode): read from the PTY at each change.
    package var asksSecret = false

    package init() {}
}
