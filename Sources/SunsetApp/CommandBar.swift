/// The state of the command bar of one window: what it was opened for, what has been typed and which row is selected.
struct CommandBar: Equatable {
    enum Purpose: Equatable {
        /// Pick a tab to go to.
        case search
        /// A tab was dropped on its own content: pick the tab to put beside it.
        case splitWith(SplitChoice)
    }

    let purpose: Purpose
    var query = ""
    var selection = 0

    init(purpose: Purpose) { self.purpose = purpose }

    var prompt: String {
        switch purpose {
            case .search: "Go to a tab…"
            case .splitWith: "Split with…"
        }
    }
}
