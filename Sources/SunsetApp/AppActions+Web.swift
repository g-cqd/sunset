import Foundation
import SunsetPane
import SunsetShell
import SunsetWeb

/// The command bar's address row (web step b).
extension AppActions {
    /// An address typed in the command bar: loaded in the focused page, or in a new page tab when a terminal has the keyboard.
    func go(to address: URL, in tabs: TabsModel) {
        if let page = tabs.selectedContent as? WebContent {
            page.load(address)
            page.focusPage()
        } else {
            tabs.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": address.absoluteString]))
        }
    }
}
