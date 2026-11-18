import AppKit
import Foundation
import SunsetPane
import SunsetShell
import SunsetTerminal

/// The notifications of any pane, a terminal's too (S-e): they name the Space when there are several, mark its icon when no
/// window shows it, and a click goes there.
extension AppWebNotifications {
    /// Notes where a notification came from, and that its Space asked for attention.
    func remember(_ identifier: String, from content: any PaneContent, id: Int) {
        posted[identifier] = (WeakContent(content: content), id)
        posted = posted.filter { $0.value.from.content != nil }
        AppSpaces.all.space(holding: content)?.noteActivity()
    }

    /// The name of the Space that holds `content`, when there are several Spaces to tell apart.
    func spaceName(of content: any PaneContent) -> String? {
        guard AppSpaces.all.spaces.count > 1, let space = AppSpaces.all.space(holding: content) else { return nil }
        return space.space.name
    }

    /// Posts what a terminal's program asked for (OSC 9, 777, 99), admitted by the policy: its title, the Space beside the
    /// tab's name, its body.
    func post(title: String, body: String, from terminal: TerminalModel) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let identifier = UUID().uuidString
        remember(identifier, from: terminal, id: 0)
        let subtitle = [terminal.title, spaceName(of: terminal)].compactMap { $0 }.joined(separator: " \u{00B7} ")
        Task { await TerminalModel.show(title: title, subtitle: subtitle, body: body, identifier: identifier) }
    }

    /// Shows the tab that holds `content` in front: in a window that holds it, else in a window of the app's Spaces that
    /// goes to its Space first.
    func reveal(_ content: any PaneContent) {
        let windows = TabRegistry.shared.allWindows()
        var found = windows.first { $0.tabs.reveal(content) }
        if found == nil, let space = AppSpaces.all.space(holding: content),
            let other = windows.first(where: { !$0.tabs.isPrivateWindow && AppSpaces.all.contains($0.tabs.space) })
        {
            other.tabs.show(space: space, in: AppSpaces.all)
            if other.tabs.reveal(content) { found = other }
        }
        guard let (window, _) = found else { return }
        NSApp.activate()
        TabRegistry.shared.select(window)
        window.makeKeyAndOrderFront(nil)
    }
}
