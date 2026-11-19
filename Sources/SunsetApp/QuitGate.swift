import AppKit
import Observation
import SunsetConfig
import SunsetDocuments
import SunsetMarkdown
import SunsetPane
import SunsetShell
import SunsetTerminal
import SunsetWeb

/// Quitting (web step q, R1): by `tabs.askBeforeQuit`, what would be lost is gathered and a sheet on a window asks; meanwhile the app answers
/// "later" to the system, so nothing (a logout, a restart) quits it unless it is force-quit. Edits to a file that are not saved are asked
/// about at every level, with Save All (roadmap 0023 step M-d).
@MainActor @Observable
final class QuitGate {
    static let shared = QuitGate()

    /// The question shown, and the window it is shown on.
    private(set) var losses: [QuitLoss] = []
    private(set) var asking: ObjectIdentifier?
    @ObservationIgnored private var tabsOfPane: [PaneID: TabsModel] = [:]
    @ObservationIgnored private var spaceOfPane: [PaneID: SpaceModel] = [:]

    /// The app was asked to quit: now, or later once answered.
    func shouldTerminate() -> NSApplication.TerminateReply {
        let level = AppConfiguration.shared.configuration.tabs.askBeforeQuit
        // The documents Sunset keeps are kept now; what is left edited is a file's, and is asked about whatever the level.
        AppStorage.shared.openDocuments.keepStored()
        guard level != .never || !AppStorage.shared.openDocuments.edited.isEmpty else { return finish() }
        Task { await decide(level) }
        return .terminateLater
    }

    private func decide(_ level: Configuration.Tabs.QuitAsk) async {
        let found = await gather()
        guard QuitLoss.asks(level: level.rawValue, losses: found) else { return answer(quit: true) }
        guard let window = TabRegistry.shared.actingWindow ?? TabRegistry.shared.allWindows().first?.window,
            let tabs = TabRegistry.shared.tabs(for: window)
        else { return askWithoutWindow(found) }
        losses = found
        asking = ObjectIdentifier(tabs)
    }

    func isAsking(_ tabs: TabsModel) -> Bool {
        asking == ObjectIdentifier(tabs)
    }

    /// Whether the setting is why it asks (something else than unsaved edits would be lost, or it always asks).
    var asksBySetting: Bool {
        AppConfiguration.shared.configuration.tabs.askBeforeQuit != .never
            && (losses.isEmpty || losses.contains { $0.kind != .document })
    }

    /// Whether what would be lost includes edits that can be saved first.
    var hasUnsavedDocuments: Bool {
        losses.contains { $0.kind == .document }
    }

    /// The sheet's answer; `dontAskAgain` sets the setting to never.
    func answer(quit: Bool, dontAskAgain: Bool = false) {
        if dontAskAgain { AppConfiguration.shared.update { $0.tabs.askBeforeQuit = .never } }
        asking = nil
        losses = []
        if quit { finish() }
        NSApp.reply(toApplicationShouldTerminate: quit)
    }

    /// Save All and Quit: every edited document is written, then the app quits. One that cannot be written cancels the quit
    /// and is shown, saying why.
    func saveAllAndQuit(dontAskAgain: Bool = false) {
        let failed = AppStorage.shared.openDocuments.saveAll()
        guard let first = failed.first else { return answer(quit: true, dontAskAgain: dontAskAgain) }
        let shown = tabsOfPane.first { ($0.value.content($0.key) as? DocumentContent)?.document === first }
        answer(quit: false)
        if let shown {
            reveal(shown.key, in: shown.value)
        } else if case .file(let path) = first.place {
            AppActions.shared.openDocument(at: path)
        }
    }

    /// A row was clicked: its tab is shown (a document no pane shows any more opens, with its edits), the quit is cancelled.
    func show(_ loss: QuitLoss) {
        let tabs = loss.pane.flatMap { tabsOfPane[$0] }
        answer(quit: false)
        if let pane = loss.pane, let tabs {
            reveal(pane, in: tabs)
        } else if let file = loss.file {
            AppActions.shared.openDocument(at: file)
        }
    }

    private func reveal(_ pane: PaneID, in tabs: TabsModel) {
        // A pane of a Space the window does not show: the window changes to it.
        if let space = spaceOfPane[pane], space !== tabs.space, AppSpaces.all.contains(space) {
            tabs.show(space: space)
        }
        if let item = tabs.workspace.item(containing: pane) { tabs.select(item: item.id) }
        tabs.focus(pane)
    }

    /// No window is left to hold the sheet (the last one closed, which quits the app): edits are still asked about, in an
    /// alert; anything else lost with no window to show it goes.
    private func askWithoutWindow(_ found: [QuitLoss]) {
        let documents = found.filter { $0.kind == .document }
        guard !documents.isEmpty else { return answer(quit: true) }
        let alert = NSAlert()
        alert.messageText = "Do you want to save your changes before quitting?"
        alert.informativeText = documents.map(\.text).joined(separator: "\n")
        alert.addButton(withTitle: "Save All and Quit")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Quit Without Saving")
        switch alert.runModal() {
            case .alertFirstButtonReturn: saveAllAndQuit()
            case .alertThirdButtonReturn: answer(quit: true)
            default:
                answer(quit: false)
                for file in documents.compactMap(\.file) { AppActions.shared.openDocument(at: file) }
        }
    }

    @discardableResult
    private func finish() -> NSApplication.TerminateReply {
        AppStorage.shared.openDocuments.keepStored()
        SessionStore.shared.finish()
        AppConfiguration.shared.saveNow()
        DownloadCenter.shared.finish()
        WebClearing.clearAtQuit()
        return .terminateNow
    }

    // MARK: What would be lost

    /// Everything that runs, by Space: windows on one Space list the same tabs, and a Space left by changing runs with no
    /// window. Notes, for each pane, the Space it is in and a window that can show it.
    private func everything() -> (panes: [(PaneID?, any PaneContent)], tabCount: Int) {
        tabsOfPane = [:]
        spaceOfPane = [:]
        var panes: [(PaneID?, any PaneContent)] = []
        var tabCount = 0
        let windows = TabRegistry.shared.allWindows().map(\.tabs)
        var spaces = AppSpaces.all.spaces
        for tabs in windows where !spaces.contains(where: { $0 === tabs.space }) { spaces.append(tabs.space) }
        var favorites: [FavoritesModel] = AppSpaces.all.profiles.profiles.map(\.pinned)
        for space in spaces {
            // The window that shows it, else any window of the app's Spaces: it changes to it when a row is clicked.
            let shower = windows.first { $0.space === space } ?? windows.first { AppSpaces.all.contains($0.space) }
            if shower?.isPrivateWindow != true { tabCount += space.tabs.count }
            for (pane, content) in space.contents {
                spaceOfPane[pane] = space
                if let shower { tabsOfPane[pane] = shower }
                panes.append((pane, content))
            }
            if !favorites.contains(where: { $0 === space.favorites }) { favorites.append(space.favorites) }
        }
        panes += favorites.flatMap(\.contents).map { (nil, $0.value) }
        return (panes, tabCount)
    }

    private func gather() async -> [QuitLoss] {
        let (panes, tabCount) = everything()
        var found: [QuitLoss] = []
        var pages: [(PaneID, WebContent)] = []
        for (pane, content) in panes {
            if !(content is DocumentContent), let warning = content.closeWarning {
                found.append(QuitLoss(kind: .command, text: "\(content.title): \(warning)", pane: pane))
            }
            if let pane, let page = content as? WebContent { pages.append((pane, page)) }
        }
        found += DocumentContent.quitLosses(of: AppStorage.shared.openDocuments, in: panes)
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
