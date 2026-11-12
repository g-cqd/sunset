import ApplicationServices

/// The app's main window, set through accessibility: the app's menus act on it, and the app is not activated.
enum Windows {
    static func makeMain(pid: pid_t, title: String?) -> Int32 {
        let app = AXUIElementCreateApplication(pid)
        let windows = Node.elements(app, kAXWindowsAttribute)
            .filter {
                Node.string($0, kAXRoleAttribute) == "AXWindow" && (Node.frame($0)?.width ?? 0) > 100
            }
        guard
            let window = windows.first(where: { candidate in
                title.map { Node.string(candidate, kAXTitleAttribute).lowercased().contains($0.lowercased()) } ?? true
            })
        else { return Commands.fail("no window \(title ?? "")") }
        AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(window, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        print("main: \"\(Node.string(window, kAXTitleAttribute))\"")
        return 0
    }
}
