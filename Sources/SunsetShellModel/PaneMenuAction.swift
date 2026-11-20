/// An item a pane adds to its tab's menu: a command, or a submenu of them (Reload As, roadmap 0050 D).
package struct PaneMenuAction {
    package let title: String
    package let run: @MainActor () -> Void
    /// Its items, when it is a submenu.
    package let children: [Self]
    /// What it becomes while Option is held (the owner, 2026-11-20, task t135: less used items behind Option, as macOS's
    /// menus have them).
    package var alternate: PaneMenuAction? {
        boxed?.action
    }

    private var boxed: Box?

    /// The alternate, boxed: a struct cannot hold itself.
    private final class Box {
        let action: PaneMenuAction

        init(_ action: PaneMenuAction) {
            self.action = action
        }
    }

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

    /// This item, with `alternate` in its place while Option is held.
    package func withOption(_ alternate: Self) -> Self {
        var item = self
        item.boxed = Box(alternate)
        return item
    }
}
