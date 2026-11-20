import AppKit
import SunsetWeb

/// "Add “Name”?" with what it may do, as Safari asks (ADR-0109: all or nothing). Cancel first: Return does not install, a click
/// on "Add Extension" does.
enum ExtensionPrompt {
    @MainActor static func ask(_ candidate: ExtensionHost.Candidate) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Add \u{201C}\(candidate.name)\u{201D}?"
        let lines = candidate.lines
        let what =
            lines.isEmpty
            ? "It asks for nothing more than its own storage."
            : "It will be able to:\n" + lines.map { "• " + $0 }.joined(separator: "\n")
        alert.informativeText = [candidate.summary, what].filter { !$0.isEmpty }.joined(separator: "\n\n")
        if let icon = candidate.icon { alert.icon = icon }
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Add Extension")
        return alert.runModal() == .alertSecondButtonReturn
    }
}
