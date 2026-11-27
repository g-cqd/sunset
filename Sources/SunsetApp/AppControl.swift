import Foundation
import SunsetConfig
import SunsetControl
import SunsetCore
import SunsetPane
import SunsetShellModel
import SunsetTerminalModel
import SunsetWeb

/// The app asked from outside (`sunset`, ADR-0129): the control socket listens while `control.enabled` is on, and each
/// request is answered on the main actor from the windows' panes.
@MainActor enum AppControl {
    private static var server: ControlServer?
    private static var control = Configuration.Control()

    /// Listens or stops as `control` says.
    static func apply(_ new: Configuration.Control) {
        control = new
        guard new.enabled != (server != nil) else { return }
        if new.enabled {
            let started = ControlServer()
            do {
                try started.start { request in await answer(request) }
                server = started
            } catch {
                FileHandle.standardError.write(Data("sunset: the control socket did not open: \(error)\n".utf8))
            }
        } else {
            server?.stop()
            server = nil
        }
    }

    static func answer(_ request: ControlRequest) async -> ControlReply {
        guard control.enabled else { return .failure("control from outside is off") }
        switch request.verb {
            case .list: return ControlReply(panes: panes())
            case .commands:
                return ControlReply(
                    commands: AppCommand.table.filter(\.inBar)
                        .map { command in
                            let key = CommandKeys.shared.key(for: command.id)?.symbols ?? ""
                            return "\(command.id.rawValue)\t\(command.title)\t\(key)"
                        }
                )
            case .run: return run(request.text ?? "")
            case .read: return read(request)
            case .type: return type(request)
            case .wait: return await wait(request)
        }
    }

    /// Every pane of every window's tabs, the window in front first.
    private static func panes() -> [ControlReply.Pane] {
        TabRegistry.shared.allWindows().enumerated()
            .flatMap { index, entry in
                entry.tabs.workspace.items.flatMap(\.panes)
                    .compactMap { pane in
                        guard let content = entry.tabs.content(pane) else { return nil }
                        return ControlReply.Pane(
                            id: pane.uuidString,
                            kind: content.descriptor.kind,
                            title: content.title,
                            detail: content.detail,
                            window: index,
                            shown: entry.tabs.shownPane == pane
                        )
                    }
            }
    }

    /// The pane `name` names, marked as driven (`DrivenPanes`); nil when there is none or the person stopped it.
    private static func content(_ name: String?) -> (any PaneContent)? {
        guard let content = found(name), DrivenPanes.shared.drive(content) else { return nil }
        return content
    }

    /// The pane `name` names: "shown" (the window in front's), else an id from `list`.
    private static func found(_ name: String?) -> (any PaneContent)? {
        let windows = TabRegistry.shared.allWindows()
        if name == nil || name == "shown" {
            guard let tabs = windows.first?.tabs, let pane = tabs.shownPane else { return nil }
            return tabs.content(pane)
        }
        guard let name, let id = PaneID(uuidString: name) else { return nil }
        return windows.lazy.compactMap { $0.tabs.content(id) }.first
    }

    private static func run(_ name: String) -> ControlReply {
        guard let id = AppCommand.ID(rawValue: name) else { return .failure("no command \(name) (sunset commands)") }
        guard AppCommandRunner.isEnabled(id) else { return .failure("\(name) would do nothing now") }
        AppCommandRunner.run(id)
        return ControlReply()
    }

    private static func read(_ request: ControlRequest) -> ControlReply {
        switch content(request.pane) {
            case let terminal as TerminalModel:
                guard let screen = terminal.lastScreen else { return ControlReply(text: "") }
                return ControlReply(text: text(of: screen, scrollback: min(max(request.lines ?? 0, 0), 100_000)))
            case let page as WebContent:
                return ControlReply(text: [page.url?.absoluteString ?? "", page.title].joined(separator: "\n"))
            case let other?: return ControlReply(text: [other.title, other.detail ?? ""].joined(separator: "\n"))
            case nil: return .failure("no pane \(request.pane ?? "shown") (sunset list), or it was stopped")
        }
    }

    private static func type(_ request: ControlRequest) -> ControlReply {
        guard control.typing else { return .failure("typing into terminals is off (Settings › General › Control)") }
        guard let terminal = content(request.pane) as? TerminalModel else { return .failure("not a terminal") }
        terminal.send(.text(request.text ?? ""))
        return ControlReply()
    }

    /// Until the terminal's screen shows the text; at most ten minutes.
    private static func wait(_ request: ControlRequest) async -> ControlReply {
        guard let wanted = request.text, !wanted.isEmpty else { return .failure("wait for what?") }
        let seconds = min(max(request.timeout ?? 30, 0), 600)
        let clock = ContinuousClock()
        let end = clock.now + .seconds(seconds)
        var turn = 0
        while clock.now < end {
            // Marked (and the person's stop heard) every five seconds, not every look.
            let pane = turn % 50 == 0 ? content(request.pane) : found(request.pane)
            turn += 1
            guard let terminal = pane as? TerminalModel else { return .failure("not a terminal, or it was stopped") }
            if let screen = terminal.lastScreen, text(of: screen, scrollback: 0).contains(wanted) {
                return ControlReply(text: wanted)
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return .failure("not shown after \(Int(seconds)) s")
    }

    /// The screen's rows as text, `scrollback` lines of history before them; trailing empty rows left out.
    private static func text(of screen: Screen, scrollback: Int) -> String {
        let history = max(screen.scrollbackCount - scrollback, 0) ..< screen.scrollbackCount
        var lines = history.map { screen.scrollbackText(line: $0) } + (0 ..< screen.rows).map { screen.text(row: $0) }
        while lines.last?.isEmpty == true { lines.removeLast() }
        return lines.joined(separator: "\n")
    }
}
