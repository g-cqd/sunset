import AppKit

/// What a page's file field asked for (`<input type=file>`), and the system's panel for it. The page gets only what the
/// person chose there.
struct FileChoice: Equatable, Sendable {
    let multiple: Bool
    let folders: Bool

    @MainActor
    func panel(host: String) -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = folders
        panel.allowsMultipleSelection = multiple
        panel.resolvesAliases = true
        let what = folders ? (multiple ? "files or folders" : "a file or folder") : (multiple ? "files" : "a file")
        panel.message = "\(host.isEmpty ? "This page" : host) asks for \(what)."
        panel.prompt = "Choose"
        return panel
    }
}
