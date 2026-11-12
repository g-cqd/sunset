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
}
