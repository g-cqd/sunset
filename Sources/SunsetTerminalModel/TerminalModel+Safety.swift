import SunsetConfig
import SunsetCore
import SunsetHost
import SunsetRuntime

/// Pastes asked about, secure keyboard entry (task t116, white paper §9).
extension TerminalModel {
    /// Text pasted (the menu, a drop): what would run or hide is asked about first, by `terminal.pasteWarning`.
    package func paste(_ text: String) {
        guard let session else { return }
        runtime.task { @MainActor [weak self] in
            let risks = await session.pasteRisks(text)
            guard let self else { return }
            guard !risks.isEmpty, safety.settings().pasteWarning else { return send(.paste(text)) }
            safety.askBeforePasting(risks, text) { [weak self] in self?.send(.paste(text)) }
        }
    }

    /// The program's echo state, as last read.
    func noteSecret(_ asking: Bool) {
        guard asking != safety.asksSecret else { return }
        safety.asksSecret = asking
        updateSecureInput()
    }

    /// Secure input held while this pane has the keyboard in the window in front, by `terminal.secureKeyboard`.
    package func updateSecureInput() {
        let hold = safety.settings().secureKeyboard
            .holds(asking: safety.asksSecret, focused: gates.hasFocus && appIsActive())
        guard hold != safety.secureInputHeld else { return }
        safety.secureInputHeld = hold
        safety.holdSecureInput(hold)
    }
}
