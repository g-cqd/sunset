import SunsetPane
import SwiftUI

/// What one tab shows: its title, and, as the configuration says, the working directory and the progress the program reported.
struct TabLabel: View {
    let model: TerminalModel?
    var showIcon = false
    var showTitle = true
    var showDirectory = false
    var showProgress = true
    /// The name and the icon a person gave the tab: shown instead of the program's title and of the tab's own picture.
    var name: String?
    var icon: PaneIcon?

    var body: some View {
        HStack(spacing: 6) {
            if showIcon {
                if let icon {
                    PaneIconView(icon: icon)
                } else if let model {
                    TabGlyphView(glyph: Self.glyph(of: model))
                }
            }
            lines
        }
    }

    /// What the tab is about: the folder the program is in (with its first letter), or the command in front.
    static func glyph(of model: TerminalModel) -> TabGlyph {
        TabGlyph.make(directory: model.directory, command: model.foregroundCommand, home: NSHomeDirectory())
    }

    private var lines: some View {
        VStack(alignment: .leading, spacing: 1) {
            if showTitle { Text(name ?? model?.title ?? "Sunset").lineLimit(1) }
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
