import SunsetShell
import SunsetTerminalModel

extension TerminalFind: FindBarModel {
    package var findPrompt: String {
        isRegex ? "Find Regex in Terminal" : "Find in Terminal"
    }
    package var findIconSymbol: String {
        isRegex ? "asterisk" : "magnifyingglass"
    }
    package var secondaryOptionTitle: String {
        "Regular Expression (RE2)"
    }
    package var secondaryOption: Bool {
        get {
            isRegex
        }
        set {
            isRegex = newValue
        }
    }
    package var isFindError: Bool {
        if error != nil { return true }
        return !text.isEmpty && matches.isEmpty
    }

    package func findStep(backwards: Bool) {
        step(backwards: backwards)
    }

    package func findClose() {
        close()
    }

    package func findOptionsChanged() {
        restart()
    }

    package func findTextChanged() {
        restart()
    }
}
