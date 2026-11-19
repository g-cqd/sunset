package import SunsetPane
package import SwiftUI

/// What one tab shows: its title, and, as the configuration says, the working directory and the progress the program reported.
package struct TabLabel: View {
    let model: (any PaneContent)?
    var showIcon = false
    var showTitle = true
    var showDirectory = false
    var showProgress = true
    /// Whether the label says its document has edits that are not saved; a sidebar row says it itself, at its end (owner note n76).
    var showEdited = true
    /// Whether the label shows the sound, the microphone and the camera; a sidebar row has them as buttons at its end.
    var showControls = true
    /// The name and the icon a person gave the tab: shown instead of the program's title and of the tab's own picture.
    var name: String?
    var icon: PaneIcon?
    /// What a pane that is not running would start from (a kept entry that is not open): it gives the picture, the title and the second line.
    var saved: PaneDescriptor?
    /// The command a kept terminal that is not open would run: its picture is a terminal and its title the command.
    var savedCommand: String?
    @Environment(\.monospacedDetail) private var monospacedDetail

    package init(
        model: (any PaneContent)?,
        showIcon: Bool = false,
        showTitle: Bool = true,
        showDirectory: Bool = false,
        showProgress: Bool = true,
        showEdited: Bool = true,
        showControls: Bool = true,
        name: String? = nil,
        icon: PaneIcon? = nil,
        saved: PaneDescriptor? = nil,
        savedCommand: String? = nil
    ) {
        self.model = model
        self.showIcon = showIcon
        self.showTitle = showTitle
        self.showDirectory = showDirectory
        self.showProgress = showProgress
        self.showEdited = showEdited
        self.showControls = showControls
        self.name = name
        self.icon = icon
        self.saved = saved
        self.savedCommand = savedCommand
    }

    /// What a pane that is not running would start from: a kept entry with nothing saved is a new terminal.
    private var notRunning: PaneDescriptor { saved ?? PaneDescriptor(kind: PaneDescriptor.terminalKind) }

    package var body: some View {
        HStack(spacing: GlyphSpacing.toText) {
            if showIcon {
                TabIcon(model: model, icon: icon, saved: saved, savedCommand: savedCommand, showsProgress: showProgress)
            }
            lines
            if showEdited, model?.isEdited == true { EditedMark() }
            if showControls, let sound = model?.sound {
                Button {
                    model?.toggleMuted()
                } label: {
                    Image(systemName: sound.symbol)
                        .font(.system(size: Design.Symbol.badge, weight: Design.Symbol.weight))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(sound.help)
            }
            // Loaded as another profile than its Space's (roadmap 0050 D): its name, small.
            if let mark = Self.profileMark(model: model, saved: saved) {
                Text(mark)
                    .font(Design.Text.detail.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, Design.Space.xs)
                    .background(.quaternary, in: .capsule)
                    .fixedSize()
                    .accessibilityLabel("Loaded as \(mark)")
            }
            // The microphone and the camera it uses, each muted from here (the owner's note n47); the screen's dot stays.
            if showControls, let model {
                ForEach(PaneCapture.Device.allCases, id: \.self) { device in
                    if let state = model.devices[device] {
                        Button {
                            model.toggle(device)
                        } label: {
                            Image(systemName: PaneCapture.symbol(device, state))
                                .font(.system(size: Design.Symbol.badge, weight: Design.Symbol.weight))
                                .foregroundStyle(state == .live ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                        }
                        .buttonStyle(.plain)
                        .help(PaneCapture.help(device, state))
                        .accessibilityLabel(PaneCapture.help(device, state))
                    }
                }
            }
            if let dot = model?.captureDot, model?.devices.isEmpty != false {
                Circle().fill(dot).frame(width: 7, height: 7).help("Sharing the screen")
            }
        }
    }

    private var lines: some View {
        VStack(alignment: .leading, spacing: Design.Space.hair) {
            if showTitle {
                Text(name ?? model?.title ?? Self.title(of: notRunning, command: savedCommand)).lineLimit(1)
            }
            if showDirectory, let directory = model?.detail ?? saved?.directory {
                Text(Self.shortened(directory))
                    .font(monospacedDetail ? Design.Text.detail.monospaced() : Design.Text.detail)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    /// The profile a page is loaded as, when not its Space's: the page's own say, or, not loaded, its saved state's.
    static func profileMark(model: (any PaneContent)?, saved: PaneDescriptor?) -> String? {
        if let model { return model.profileMark }
        return saved?.state["as"].flatMap(ProfileNames.mark)
    }

    /// The picture of a pane that is not running: a terminal that runs a command its terminal mark, one in a folder the folder with its
    /// letter, another kind its generic mark.
    static func glyph(of saved: PaneDescriptor, command: String? = nil) -> PaneGlyph {
        if saved.state["url"] != nil { return .symbol("globe") }
        if saved.kind == PaneDescriptor.documentKind {
            let rendered = saved.state["view"] == "rendered"
            return .symbol(rendered ? PaneDescriptor.renderedDocumentSymbol : PaneDescriptor.documentSymbol)
        }
        if saved.kind == PaneDescriptor.settingsKind { return .symbol(PaneDescriptor.settingsSymbol) }
        guard saved.kind == PaneDescriptor.terminalKind else { return .symbol("square.dashed") }
        if let command, !command.isEmpty { return .tab(TabGlyph(kind: .command, letter: nil)) }
        return .tab(TabGlyph.make(directory: saved.directory, command: nil, home: NSHomeDirectory()))
    }

    /// The title of a pane that is not running: the command a terminal would run, else its directory by its name; another kind by its kind.
    static func title(of saved: PaneDescriptor, command: String? = nil) -> String {
        if saved.kind == PaneDescriptor.terminalKind, let command, !command.isEmpty { return command }
        if let title = saved.state["title"], !title.isEmpty { return title }
        if let host = saved.state["url"].flatMap(URL.init(string:))?.host() { return host }
        guard let directory = saved.directory else {
            return saved.kind == PaneDescriptor.terminalKind ? "Terminal" : saved.kind
        }
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
