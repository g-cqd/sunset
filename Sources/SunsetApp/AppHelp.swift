import SunsetHelp
import SunsetPane
import SunsetShell

/// Where Help shows: a window of its own that reuses the shell, opened by the Help menu; from Settings, the Help tab of
/// the window Settings are in.
@MainActor enum AppHelp {
    /// Shows Help in `tabs` on `topic` (nil: where it was): its tab, the one there or a new one.
    static func show(_ topic: HelpTopic? = nil, in tabs: TabsModel) {
        let shown = tabs.showSingle(.help(topic: (topic ?? HelpTopic.allCases[0]).rawValue)) as? HelpContent
        if let topic { shown?.topic = topic }
    }
}

extension AppActions {
    /// Help > Sunset Help (⌘?): a new window holding the Help tab.
    func showHelp() {
        handoff.append(HelpContent(.help(topic: HelpTopic.allCases[0].rawValue)))
        openTerminalWindow()
    }
}
