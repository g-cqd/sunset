import SunsetShell

extension PageFind: FindBarModel {
    package var findPrompt: String {
        "Find on Page"
    }
    package var isFindError: Bool {
        count == 0
    }
    package var findIconSymbol: String {
        "magnifyingglass"
    }
    package var secondaryOptionTitle: String {
        "Starts With"
    }
    package var secondaryOption: Bool {
        get {
            startsWith
        }
        set {
            startsWith = newValue
        }
    }

    package func findTextChanged() {
        restart()
    }

    package func findOptionsChanged() {
        search()
    }

    package func findStep(backwards: Bool) {
        search(backwards: backwards)
    }

    package func findClose() {
        close()
    }
}
