import ApplicationServices

/// A menu bar item by its path ("History>Back"), each step ranked like any query, pressed without opening the menu.
enum Menus {
    static func press(pid: pid_t, path: String) -> Int32 {
        let steps = path.split(separator: ">").map { $0.trimmingCharacters(in: .whitespaces) }
        let app = AXUIElementCreateApplication(pid)
        guard var current = Node.element(app, kAXMenuBarAttribute) else { return Commands.fail("no menu bar") }
        for (index, step) in steps.enumerated() {
            // A menu bar item and a menu item hold their menu as their only child.
            var items = Node.elements(current, kAXChildrenAttribute)
            if index > 0, items.count == 1, Node.string(items[0], kAXRoleAttribute) == "AXMenu" {
                items = Node.elements(items[0], kAXChildrenAttribute)
            }
            let nodes = items.map { Node($0, path: "", window: "menu") }
            guard let match = Ranking.clearWinner(Ranking.rank(nodes, query: step, role: nil)) else {
                return Commands.fail(
                    "no clear menu item \"\(step)\" among \(nodes.map(\.title).filter { !$0.isEmpty })"
                )
            }
            current = match.node.element
            if index == steps.count - 1 { return Commands.perform(match.node, kAXPressAction) }
        }
        return 3
    }

    /// The app's own Quit: the item of the application menu (the one after Apple's) whose title is "Quit" and the app's
    /// name, which a debug build and the installed one do not share. Waits for the process to end: a question it asks
    /// first (unsaved edits, running commands) leaves it running, and that is said.
    static func quit(pid: pid_t) -> Int32 {
        let app = AXUIElementCreateApplication(pid)
        guard let bar = Node.element(app, kAXMenuBarAttribute) else { return Commands.fail("no menu bar") }
        let menus = Node.elements(bar, kAXChildrenAttribute)
        guard menus.count > 1, let menu = Node.elements(menus[1], kAXChildrenAttribute).first else {
            return Commands.fail("no application menu")
        }
        let items = Node.elements(menu, kAXChildrenAttribute).map { Node($0, path: "", window: "menu") }
        guard let item = items.first(where: { $0.title.hasPrefix("Quit ") && !$0.title.hasPrefix("Quit and ") }) else {
            return Commands.fail("no Quit among \(items.map(\.title).filter { !$0.isEmpty })")
        }
        let pressed = Commands.perform(item, kAXPressAction)
        guard pressed == 0 else { return pressed }
        for _ in 0 ..< 50 {
            if kill(pid, 0) != 0 { return 0 }
            usleep(100_000)
        }
        return Commands.fail("\(pid) is still running 5 s after \(item.title): it may be asking a question")
    }
}
