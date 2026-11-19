/// An item a pane adds to its tab's menu: a command, or a submenu of them (Reload As, roadmap 0050 D).
package struct PaneMenuAction {
    package let title: String
    package let run: @MainActor () -> Void
    /// Its items, when it is a submenu.
    package let children: [Self]

    package init(_ title: String, run: @escaping @MainActor () -> Void) {
        self.title = title
        self.run = run
        children = []
    }

    package init(_ title: String, children: [Self]) {
        self.title = title
        run = {}
        self.children = children
    }
}
