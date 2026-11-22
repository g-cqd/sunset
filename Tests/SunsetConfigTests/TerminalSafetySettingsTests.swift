import Testing

@testable import SunsetConfig

/// Secure keyboard entry and the paste warning, as settings. Secure input is held only for the pane that has the
/// keyboard in the window in front (another app's event taps then see no key typed in it).
@Suite("Terminal safety: settings")
struct TerminalSafetySettingsTests {
    @Test func `defaults: secure while a password is asked, risky pastes asked about; each is read`() throws {
        let terminal = Configuration().terminal
        #expect(terminal.secureKeyboard == .whenPassword && terminal.pasteWarning)
        let read = try ConfigurationParser.parse(
            #"{ "terminal": { "secureKeyboard": "always", "pasteWarning": false } }"#
        )
        #expect(read.issues.isEmpty && read.configuration.terminal.secureKeyboard == .always)
        #expect(!read.configuration.terminal.pasteWarning)
    }

    @Test func `held only with the keyboard, by the setting and whether a password is asked`() {
        typealias Mode = Configuration.Terminal.SecureKeyboard
        #expect(Mode.whenPassword.holds(asking: true, focused: true))
        #expect(!Mode.whenPassword.holds(asking: false, focused: true))
        #expect(!Mode.whenPassword.holds(asking: true, focused: false))
        #expect(Mode.always.holds(asking: false, focused: true) && !Mode.always.holds(asking: true, focused: false))
        #expect(!Mode.off.holds(asking: true, focused: true))
    }

    /// Threat model A2: C1 controls inside UTF-8 are refused unless the person turns them on.
    @Test func `C1 controls inside UTF-8: off by default, read, and written`() throws {
        #expect(!Configuration().terminal.c1Controls)
        let read = try ConfigurationParser.parse(#"{ "terminal": { "c1Controls": true } }"#)
        #expect(read.issues.isEmpty && read.configuration.terminal.c1Controls)
        #expect(ConfigurationKeys.all.contains("terminal.c1Controls"))
    }
}
