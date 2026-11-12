import AppKit
import Observation
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetTerminal
import SunsetWeb

/// Quitting (web step q, R1): by `tabs.askBeforeQuit`, what would be lost is gathered and a sheet on a window asks; meanwhile the app answers
/// "later" to the system, so nothing (a logout, a restart) quits it unless it is force-quit.
@MainActor @Observable
final class QuitGate {
    static let shared = QuitGate()

    /// The question shown, and the window it is shown on.
    private(set) var losses: [QuitLoss] = []
    private(set) var asking: ObjectIdentifier?
    @ObservationIgnored private var tabsOfPane: [PaneID: TabsModel] = [:]

    /// The app was asked to quit: now, or later once answered.
    func shouldTerminate() -> NSApplication.TerminateReply {
        let level = AppConfiguration.shared.configuration.tabs.askBeforeQuit
        guard level != .never else { return finishNow() }
        Task { await decide(level) }
        return .terminateLater
    }

    private func decide(_ level: Configuration.Tabs.QuitAsk) async {
        let found = await gather()
        guard QuitLoss.asks(level: level.rawValue, losses: found),
            let window = TabRegistry.shared.actingWindow ?? TabRegistry.shared.allWindows().first?.window,
            let tabs = TabRegistry.shared.tabs(for: window)
        else { return answer(quit: true) }
        losses = found
        asking = ObjectIdentifier(tabs)
    }

    func isAsking(_ tabs: TabsModel) -> Bool { asking == ObjectIdentifier(tabs) }

    /// The sheet's answer; `dontAskAgain` sets the setting to never.
    func answer(quit: Bool, dontAskAgain: Bool = false) {
        if dontAskAgain { AppConfiguration.shared.update { $0.tabs.askBeforeQuit = .never } }
        asking = nil
        losses = []
        if quit { _ = finish() }
        NSApp.reply(toApplicationShouldTerminate: quit)
    }

    /// A row was clicked: its tab is shown, the quit is cancelled.
    func show(_ loss: QuitLoss) {
        if let pane = loss.pane, let tabs = tabsOfPane[pane], let item = tabs.workspace.item(containing: pane) {
            tabs.select(item: item.id)
            tabs.focus(pane)
        }
        answer(quit: false)
    }

    private func finishNow() -> NSApplication.TerminateReply { finish() }

    @discardableResult
    private func finish() -> NSApplication.TerminateReply {
        SessionStore.shared.finish()
        AppConfiguration.shared.saveNow()
        DownloadCenter.shared.finish()
        WebClearing.clearAtQuit()
        return .terminateNow
    }

    // MARK: What would be lost

    private func gather() async -> [QuitLoss] {
        var found: [QuitLoss] = []
        tabsOfPane = [:]
        var pages: [(PaneID, WebContent)] = []
        var tabCount = 0
        for (_, tabs) in TabRegistry.shared.allWindows() {
            tabCount += tabs.isPrivateWindow ? 0 : tabs.workspace.count
            for (pane, content) in tabs.contents {
                tabsOfPane[pane] = tabs
                if let warning = content.closeWarning {
                    found.append(QuitLoss(kind: .command, text: "\(content.title): \(warning)", pane: pane))
                }
                if let page = content as? WebContent { pages.append((pane, page)) }
            }
        }
        for (_, content) in AppFavorites.shared.contents {
            if let warning = content.closeWarning {
                found.append(QuitLoss(kind: .command, text: "\(content.title): \(warning)"))
            }
        }
        for (pane, page) in pages where await page.hasUnsentForm() {
            found.append(QuitLoss(kind: .form, text: "Text typed and not sent on \(page.shownHost)", pane: pane))
        }
        for item in DownloadCenter.shared.running {
            found.append(QuitLoss(kind: .download, text: "\(item.name) is downloading (it can resume next time)"))
        }
        if !AppConfiguration.shared.configuration.tabs.restore, tabCount > 0 {
            found.append(
                QuitLoss(
                    kind: .unrestored,
                    text: "\(tabCount) tab\(tabCount == 1 ? "" : "s") will not come back (restoring tabs is off)"
                )
            )
        }
        return found
    }
}
