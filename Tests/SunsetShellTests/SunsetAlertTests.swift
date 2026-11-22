import SunsetShellModel
import Testing

/// Alerts and confirmations in Sunset's own look, one model for all of them; which button Return and Escape press is
/// the model's, so every alert keeps the rule its NSAlert had.
@Suite("Sunset's alerts")
struct SunsetAlertTests {
    @Test func `Escape presses Cancel; Return the default button, none when Cancel is the default`() {
        let risky = SunsetAlert(
            title: "Download it?",
            message: "It runs code.",
            buttons: [.cancel("Cancel"), .plain("Download")],
            defaultButton: 0
        )
        #expect(risky.escapeButton == 0)
        #expect(risky.returnButton == 0, "Cancel is the default: Return does not download")
        let save = SunsetAlert(
            title: "Save?",
            message: "",
            buttons: [.plain("Save All and Quit"), .cancel("Cancel"), .destructive("Quit Without Saving")],
            defaultButton: 0
        )
        #expect(save.escapeButton == 1 && save.returnButton == 0)
        #expect(save.buttons[2].role == .destructive)
    }

    @Test func `the buttons show as macOS orders them: the default last, Cancel before it, a destructive one first`() {
        let save = SunsetAlert(
            title: "Save?",
            message: "",
            buttons: [.plain("Save All and Quit"), .cancel("Cancel"), .destructive("Quit Without Saving")],
            defaultButton: 0
        )
        #expect(save.shownOrder == [2, 1, 0])
        let info = SunsetAlert(title: "It failed", message: "Why.", buttons: [.plain("OK")], defaultButton: 0)
        #expect(info.shownOrder == [0] && info.escapeButton == 0)
    }
}
