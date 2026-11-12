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
    /// The engine picked by its keyword and a space, shown as a chip at the start of the field (web step c).
    package var engine: String?
    /// The selected row's actions are listed (Cmd-K), with what is typed to filter them and the one selected.
    package var showsActions = false
    package var actionsQuery = ""
    package var actionsSelection = 0
    /// Up in an empty field went back this many entries (`TabsModel.barRecall`).
    package var recalled = 0

    package init(purpose: Purpose) { self.purpose = purpose }

    package var prompt: String {
        switch purpose {
            case .search: "Go to a tab…"
            case .splitWith: "Split with…"
        }
    }
}
