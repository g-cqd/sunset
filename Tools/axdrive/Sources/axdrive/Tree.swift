import ApplicationServices

/// Walks an app's windows (and, when asked, its menu bar) breadth-first, to a depth and a count, so a web page's large tree stays bounded.
enum Tree {
    static func nodes(pid: pid_t, windowFilter: String?, includeMenus: Bool, maxDepth: Int = 40, limit: Int = 20_000)
        -> [Node]
    {
        let app = AXUIElementCreateApplication(pid)
        // Asks WebKit and others to build their full tree for an outside reader.
        AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        var roots: [(AXUIElement, String)] = []
        for window in Node.elements(app, kAXWindowsAttribute) {
            let title = Node.string(window, kAXTitleAttribute)
            if let windowFilter, !title.lowercased().contains(windowFilter.lowercased()) { continue }
            roots.append((window, title))
        }
        if includeMenus, let bar = Node.element(app, kAXMenuBarAttribute) { roots.append((bar, "menu bar")) }
        var found: [Node] = []
        var queue: [Visit] = roots.map { Visit(element: $0.0, path: "", depth: 0, window: $0.1) }
        var index = 0
        while index < queue.count, found.count < limit {
            let visit = queue[index]
            let element = visit.element
            let parentPath = visit.path
            let depth = visit.depth
            let window = visit.window
            index += 1
            let role = Node.string(element, kAXRoleAttribute)
            let path = parentPath.isEmpty ? role : parentPath + "/" + role
            found.append(Node(element, path: path, window: window))
            guard depth < maxDepth else { continue }
            for child in Node.elements(element, kAXChildrenAttribute) {
                queue.append(Visit(element: child, path: path, depth: depth + 1, window: window))
            }
        }
        return found
    }

    /// An element still to read, with the roles above it, its depth and its window.
    private struct Visit {
        let element: AXUIElement
        let path: String
        let depth: Int
        let window: String
    }
}
