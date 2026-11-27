import AppKit
import SunsetControl

/// The person's say over who controls Sunset from outside (ADR-0129): the first request of a session (a terminal's shell,
/// the app that started the tool) asks them; their answer holds for that session until it ends, the app quits or control
/// is turned off. Requests that come while they are asked wait for the one answer.
@MainActor enum ControlApprovals {
    private static var allowed: Set<ControlPeer.Session> = []
    private static var refused: Set<ControlPeer.Session> = []
    private static var waiting: [ControlPeer.Session: [CheckedContinuation<Bool, Never>]] = [:]

    /// Whether `peer`'s session may control Sunset: asked once, then remembered.
    static func allows(_ peer: ControlPeer, typing: Bool) async -> Bool {
        // Sessions that ended are forgotten: a process id used again is asked again.
        allowed = allowed.filter(\.isAlive)
        refused = refused.filter(\.isAlive)
        let session = peer.session
        if allowed.contains(session) { return true }
        if refused.contains(session) { return false }
        if waiting[session] != nil {
            return await withCheckedContinuation { waiting[session, default: []].append($0) }
        }
        waiting[session] = []
        let answer = ask(peer, typing: typing)
        if answer { allowed.insert(session) } else { refused.insert(session) }
        for continuation in waiting.removeValue(forKey: session) ?? [] { continuation.resume(returning: answer) }
        return answer
    }

    /// Every answer forgotten: control was turned off.
    static func forget() {
        allowed = []
        refused = []
    }

    /// Asks the person, in front of everything.
    private static func ask(_ peer: ControlPeer, typing: Bool) -> Bool {
        let alert = NSAlert()
        let who = shownName(peer.leaderPath, fallback: peer.leaderName)
        alert.messageText = "Allow \(who) to control Sunset?"
        let tool = (peer.path as NSString).lastPathComponent
        let can =
            typing
            ? "list and read your panes, type into your terminals, and run the menus' commands"
            : "list and read your panes and run the menus' commands"
        alert.informativeText =
            "\(tool) (process \(peer.pid)) asks over the control socket, in the session of \(peer.leaderPath) "
            + "(process \(peer.session.leader)). Allowed, it can \(can) until that session ends or Sunset quits."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Don't Allow")
        alert.addButton(withTitle: "Allow for This Session")
        NSApp.activate()
        return alert.runModal() == .alertSecondButtonReturn
    }

    /// An app by its bundle's name ("Claude"), a program by its own.
    private static func shownName(_ path: String, fallback: String) -> String {
        if let range = path.range(of: ".app/", options: .backwards) {
            let bundle = path[..<range.lowerBound]
            return "\u{201C}\((String(bundle) as NSString).lastPathComponent)\u{201D}"
        }
        return "\u{201C}\(fallback)\u{201D}"
    }
}
