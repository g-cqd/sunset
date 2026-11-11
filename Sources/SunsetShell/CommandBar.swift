/// The state of the command bar of one window: what it was opened for, what has been typed and which row is selected.
package struct CommandBar: Equatable {
    package enum Purpose: Equatable {
        /// Pick a tab to go to.
        case search
        /// A tab was dropped on its own content: pick the tab to put beside it.
        case splitWith(SplitChoice)
    }

    package let purpose: Purpose
    package var query = ""
    package var selection = 0

    package init(purpose: Purpose) { self.purpose = purpose }

    package var prompt: String {
        switch purpose {
            case .search: "Go to a tab…"
            case .splitWith: "Split with…"
        }
    }
}
