import AppKit
import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetShell
import SunsetTerminal
import SunsetWeb

/// What a terminal asks of the app: what its programs may do, the font zoom, and the links Cmd-clicked in it (a page beside it, or the default browser,
/// by `web.openLinksInSunset`, R1).
extension TerminalModel {
    func wire(to tabs: TabsModel) {
        hostPolicy = { HostPolicy(clipboardWrite: AppConfiguration.shared.configuration.terminal.clipboardWrite) }
        onZoomRequest = { AppActions.shared.zoomFont(by: $0) }
        openURL = { [weak self, weak tabs] url in
            guard AppConfiguration.shared.configuration.web.openLinksInSunset, let self, let tabs else {
                NSWorkspace.shared.open(url)
                return
            }
            let page = WebContent(url: url, settings: PaneContentKinds.webSettings)
            WebOpening.wire(page, in: tabs)
            tabs.split(.right, with: page, beside: self)
        }
    }
}
