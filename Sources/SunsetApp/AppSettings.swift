import Foundation
import SunsetConfig
import SunsetPane
import SunsetShell

/// The settings in the window (roadmap 0032): their one tab in a window, and the ways to it.
@MainActor
enum AppSettings {
    /// The window's page of settings, when it has one.
    static func content(in tabs: TabsModel) -> SettingsContent? {
        tabs.single(kind: SettingsContent.kind) as? SettingsContent
    }

    /// Shows the settings in `tabs`: their tab (the one that is there, else a new one) on `selection` (a topic, or a section's
    /// row; nil: where it was), and the list of sections and topics in the sidebar.
    static func show(_ selection: String? = nil, in tabs: TabsModel) {
        let topic =
            SettingsSection.shown(for: selection, profileOnly: content(in: tabs)?.scope != nil) ?? content(in: tabs)?
            .topic ?? SettingsSection.all[0].topics[0].id
        let shown = tabs.showSingle(.settings(topic: topic)) as? SettingsContent
        if selection != nil { shown?.show(topic) }
        tabs.sections.show(library: .settings)
    }

    /// What a search field of the settings holds goes to the page, which is opened for it when there is none.
    static func search(_ query: String, in tabs: TabsModel) {
        if let page = content(in: tabs) {
            page.query = query
        } else if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            show(in: tabs)
            content(in: tabs)?.query = query
        }
    }
}

extension AppActions {
    /// Sunset > Settings (Cmd-,): in the window in front; with no window, a standard one opens showing them.
    func showSettings() {
        if let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow) {
            AppSettings.show(in: tabs)
        } else {
            pendingSettings = true
            tabParent = nil
            joinsRemaining = 0
            openTerminalWindow()
        }
    }
}
