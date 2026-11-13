import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetTerminal
import SunsetWeb
import SwiftUI

/// What the scene makes for a pane: a terminal with its settings, or the content another kind says.
extension TerminalScene {
    /// A terminal for nil or a terminal's descriptor (in its directory, when that is still there); else what `PaneContentKinds` makes of it.
    func makeContent(_ descriptor: PaneDescriptor?) -> any PaneContent {
        if let descriptor, descriptor.kind != PaneDescriptor.terminalKind {
            // In a private window a page is private: in the window's group, or one of its own when the window's pages do not share.
            let privacy = tabs.privateGroup.map { tabs.privateShares ? PagePrivacy(group: $0) : PagePrivacy() }
            let content = PaneContentKinds.make(descriptor, privacy: privacy) { SessionStore.shared.scheduleSave() }
            if let page = content as? WebContent { WebOpening.wire(page, in: tabs) }
            return content
        }
        let model = TerminalModel()
        model.startDirectory =
            descriptor?.directory.flatMap { PaneContentKinds.isDirectory($0) ? $0 : nil } ?? configuredStartDirectory
        model.topInsetPoints = topInset
        configure(model)
        let integrated = configuration.terminal.shellIntegration
        model.start(
            command: launch.command,
            environment: Self.shellEnvironment(for: launch.command, integrated: integrated),
            font: font,
            scrollback: launch.scrollback ?? configuration.scrollbackLines
        )
        return model
    }

    /// `terminal.directory` with `~` expanded, when it is a folder; else the home folder (never the app's own directory).
    var configuredStartDirectory: String {
        let path = (configuration.terminal.directory as NSString).expandingTildeInPath
        return PaneContentKinds.isDirectory(path) ? path : NSHomeDirectory()
    }
}
