import SwiftUI

/// What one tab shows: its title, and, as the configuration says, the working directory and the progress the program reported.
struct TabLabel: View {
    let model: TerminalModel?
    var showTitle = true
    var showDirectory = false
    var showProgress = true

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if showTitle { Text(model?.title ?? "Sunset").lineLimit(1) }
            if showDirectory, let directory = model?.directory {
                Text(Self.shortened(directory)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            if showProgress, let progress = model?.progress {
                ProgressView(value: progress).progressViewStyle(.linear).controlSize(.mini)
            }
        }
    }

    /// The last two components of a path, with `~` for the home directory.
    static func shortened(_ path: String) -> String {
        let home = NSHomeDirectory()
        var text = path
        if text == home { return "~" }
        if text.hasPrefix(home + "/") { text = "~" + text.dropFirst(home.count) }
        let parts = text.split(separator: "/", omittingEmptySubsequences: true)
        return parts.count <= 2 ? text : "…/" + parts.suffix(2).joined(separator: "/")
    }
}
