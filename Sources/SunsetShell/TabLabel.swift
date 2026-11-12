package import SunsetPane
package import SwiftUI

/// What one tab shows: its title, and, as the configuration says, the working directory and the progress the program reported.
package struct TabLabel: View {
    let model: (any PaneContent)?
    var showIcon = false
    var showTitle = true
    var showDirectory = false
    var showProgress = true
    /// The name and the icon a person gave the tab: shown instead of the program's title and of the tab's own picture.
    var name: String?
    var icon: PaneIcon?
    /// What a pane that is not running would start from (a kept entry that is not open): it gives the picture, the title and the second line.
    var saved: PaneDescriptor?

    package init(
        model: (any PaneContent)?,
        showIcon: Bool = false,
        showTitle: Bool = true,
        showDirectory: Bool = false,
        showProgress: Bool = true,
        name: String? = nil,
        icon: PaneIcon? = nil,
        saved: PaneDescriptor? = nil
    ) {
        self.model = model
        self.showIcon = showIcon
        self.showTitle = showTitle
        self.showDirectory = showDirectory
        self.showProgress = showProgress
        self.name = name
        self.icon = icon
        self.saved = saved
    }

    package var body: some View {
        HStack(spacing: GlyphSpacing.toText) {
            if showIcon {
                if let icon {
                    PaneIconView(icon: icon)
                } else if let model {
                    PaneGlyphView(glyph: model.glyph)
                } else if let saved {
                    PaneGlyphView(glyph: Self.glyph(of: saved))
                }
            }
            lines
        }
    }

    private var lines: some View {
        VStack(alignment: .leading, spacing: 1) {
            if showTitle { Text(name ?? model?.title ?? saved.map(Self.title) ?? "Sunset").lineLimit(1) }
            if showDirectory, let directory = model?.detail ?? saved?.directory {
                Text(Self.shortened(directory)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            if showProgress, let progress = model?.progress {
                ProgressView(value: progress).progressViewStyle(.linear).controlSize(.mini)
            }
        }
    }

    /// The picture of a pane that is not running: a terminal's folder with its letter, another kind's generic mark.
    static func glyph(of saved: PaneDescriptor) -> PaneGlyph {
        guard saved.kind == PaneDescriptor.terminalKind else { return .symbol("square.dashed") }
        return .tab(TabGlyph.make(directory: saved.directory, command: nil, home: NSHomeDirectory()))
    }

    /// The title of a pane that is not running: a terminal's directory by its name, another kind by its kind.
    static func title(of saved: PaneDescriptor) -> String {
        guard let directory = saved.directory else { return saved.kind }
        return (directory as NSString).lastPathComponent
    }

    /// The last two components of a path, with `~` for the home directory.
    package static func shortened(_ path: String) -> String {
        let home = NSHomeDirectory()
        var text = path
        if text == home { return "~" }
        if text.hasPrefix(home + "/") { text = "~" + text.dropFirst(home.count) }
        let parts = text.split(separator: "/", omittingEmptySubsequences: true)
        return parts.count <= 2 ? text : "…/" + parts.suffix(2).joined(separator: "/")
    }
}
