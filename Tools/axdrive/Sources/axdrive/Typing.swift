import ApplicationServices
import Foundation

/// Text into a field in the background (keys posted to a process do not reach a field of a window that is not key): the field focused in the
/// app (or the one `--into` names) gets its value set through accessibility, which also tells SwiftUI's binding; keys are the fallback.
enum Typing {
    static func type(_ text: String, pid: pid_t, into query: String?) async -> Int32 {
        var field: AXUIElement?
        if let query {
            // Only a strong match (name, prefix or word), waited for: a field still appearing must not lose the text to another one.
            let deadline = Date().addingTimeInterval(3)
            repeat {
                let nodes = Tree.nodes(pid: pid, windowFilter: nil, includeMenus: false)
                    .filter {
                        ["AXTextField", "AXTextArea", "AXSearchField", "AXComboBox"].contains($0.role)
                    }
                field =
                    Ranking.clearWinner(Ranking.rank(nodes, query: query, role: nil).filter { $0.tier <= 3 })?.node
                    .element
                if field == nil { try? await Task.sleep(for: .milliseconds(80)) }
            } while field == nil && Date() < deadline
            guard field != nil else { return Commands.fail("no text field \"\(query)\"") }
        } else {
            field = Node.element(AXUIElementCreateApplication(pid), kAXFocusedUIElementAttribute)
        }
        // Only a text field takes the value fallback; the focused element may be a terminal's view, which takes keys only.
        guard let field,
            ["AXTextField", "AXTextArea", "AXSearchField", "AXComboBox"].contains(Node.string(field, kAXRoleAttribute))
        else {
            Keys.type(text, pid: pid)
            print("typed (keys) into the focused element")
            return 0
        }
        let old = Node.string(field, kAXValueAttribute)
        // Keys first: when the field has the keyboard they go through the field editor and SwiftUI hears every letter. Then, if the value does
        // not show them (the window is not key), the value is set through accessibility.
        AXUIElementSetAttributeValue(field, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        Keys.type(text, pid: pid)
        let deadline = Date().addingTimeInterval(0.6)
        while Date() < deadline {
            if Node.string(field, kAXValueAttribute).hasSuffix(text) {
                print("typed (keys) into \(Node(field, path: "", window: "").summary)")
                return 0
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        let status = AXUIElementSetAttributeValue(field, kAXValueAttribute as CFString, (old + text) as CFString)
        guard status == .success else { return Commands.fail("could not type into the field (\(status.rawValue))") }
        print("typed (value) into \(Node(field, path: "", window: "").summary)")
        return 0
    }

    /// Sets a field's value, and proves it: the value attribute, read back; when the app ignores it (a web page's input), the field is focused,
    /// emptied and typed into by keys, then read back again.
    static func set(_ node: Node, to text: String, pid: pid_t) async -> Bool {
        AXUIElementSetAttributeValue(node.element, kAXValueAttribute as CFString, text as CFString)
        if await holds(node.element, text, within: 0.3) { return true }
        AXUIElementSetAttributeValue(node.element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        _ = Keys.chord("cmd+a", pid: pid)
        _ = Keys.chord("delete", pid: pid)
        Keys.type(text, pid: pid)
        return await holds(node.element, text, within: 1)
    }

    private static func holds(_ element: AXUIElement, _ text: String, within seconds: Double) async -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        repeat {
            if Node.string(element, kAXValueAttribute) == text { return true }
            try? await Task.sleep(for: .milliseconds(40))
        } while Date() < deadline
        return false
    }
}
